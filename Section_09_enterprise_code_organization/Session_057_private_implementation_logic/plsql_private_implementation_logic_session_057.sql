SET SERVEROUTPUT ON SIZE UNLIMITED;
/*
Session: 057 – Private Implementation Logic
Topic: Encapsulating implementation details in the PACKAGE BODY.
Context: Builds on Session 056 (order_pub SPEC). This lesson focuses on BODY refactoring,
         private helpers, caching, and instrumentation without SPEC changes.

Purpose:
  (1) Show private helpers and canonical implementations
  (2) Add session‑scoped state: debug flag, counters, cache
  (3) Centralize validation and error mapping
  (4) Demonstrate refactoring with zero SPEC changes
  (5) Provide ≥ 5 worked examples with expected outcomes

Error Code Range: −20700..−20799
How to Run:
  • Run the entire script in order. Each block is separated by '/'.
  • If you did not run Session 056, this script creates required objects.
*/

--------------------------------------------------------------------------------
-- 0) Lab setup (idempotent): base table and seed data
--------------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'DROP TABLE pi_orders PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE TABLE pi_orders(
  order_id     NUMBER        CONSTRAINT pi_orders_pk PRIMARY KEY,
  customer     VARCHAR2(60)  NOT NULL,
  amount       NUMBER(12,2)  NOT NULL,
  status       VARCHAR2(12)  DEFAULT 'NEW' NOT NULL,
  created_at   DATE          DEFAULT SYSDATE NOT NULL
);

INSERT INTO pi_orders VALUES (101, 'Avi',  15000, 'NEW',    SYSDATE-2);
INSERT INTO pi_orders VALUES (102, 'Neha',  9000, 'NEW',    SYSDATE-1);
INSERT INTO pi_orders VALUES (103, 'Raj',  22000, 'ACTIVE', SYSDATE-3);
COMMIT;
/

--------------------------------------------------------------------------------
-- 1) SPEC (recreated for completeness): public contract unchanged from 056
--------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE order_pub AS
  SUBTYPE t_order_id IS NUMBER;

  c_status_new     CONSTANT VARCHAR2(12) := 'NEW';
  c_status_active  CONSTANT VARCHAR2(12) := 'ACTIVE';
  c_status_hold    CONSTANT VARCHAR2(12) := 'HOLD';

  e_not_found          EXCEPTION;   PRAGMA EXCEPTION_INIT(e_not_found,      -20710);
  e_invalid_amount     EXCEPTION;   PRAGMA EXCEPTION_INIT(e_invalid_amount, -20711);
  e_invalid_status     EXCEPTION;   PRAGMA EXCEPTION_INIT(e_invalid_status, -20712);

  FUNCTION version         RETURN VARCHAR2;
  FUNCTION calls_made      RETURN PLS_INTEGER;
  FUNCTION last_init_time  RETURN DATE;

  PROCEDURE set_amount(p_id IN t_order_id, p_amount IN NUMBER);
  PROCEDURE set_amount(p_id IN t_order_id, p_amount IN NUMBER, p_reason IN VARCHAR2);
  PROCEDURE set_amount(p_id IN t_order_id, p_amount IN NUMBER, p_reason IN VARCHAR2, p_hard_cap IN NUMBER);

  PROCEDURE activate(p_id IN t_order_id);
  PROCEDURE hold(p_id IN t_order_id, p_reason IN VARCHAR2 DEFAULT NULL);

  FUNCTION  get_amount(p_id IN t_order_id) RETURN NUMBER DETERMINISTIC;
  FUNCTION  status_of(p_id IN t_order_id)  RETURN VARCHAR2;

  PROCEDURE enable_debug;
  PROCEDURE disable_debug;
  PROCEDURE clear_state;
END order_pub;
/
SHOW ERRORS

--------------------------------------------------------------------------------
-- 2) BODY (enhanced): private helpers, caching, and instrumentation
--------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE BODY order_pub AS
  ----------------------------------------------------------------------------
  -- Private state: counters, debug toggle, session cache
  ----------------------------------------------------------------------------
  g_calls        PLS_INTEGER := 0;
  g_last_init    DATE        := SYSDATE;
  g_debug        BOOLEAN     := FALSE;
  g_version      CONSTANT VARCHAR2(10) := '1.1.0'; -- BODY bumped, SPEC unchanged

  -- Simple session cache for amounts to reduce SELECTs
  TYPE t_amt_cache IS TABLE OF NUMBER INDEX BY PLS_INTEGER; -- key = order_id
  g_amt_cache t_amt_cache;

  ----------------------------------------------------------------------------
  -- Private helpers
  ----------------------------------------------------------------------------
  PROCEDURE dbg(p IN VARCHAR2) IS
  BEGIN IF g_debug THEN DBMS_OUTPUT.PUT_LINE('[order_pub] '||p); END IF; END;

  PROCEDURE bump IS BEGIN g_calls := NVL(g_calls,0) + 1; END;

  PROCEDURE cache_put(p_id IN t_order_id, p_amt IN NUMBER) IS
  BEGIN g_amt_cache(p_id) := p_amt; END;

  FUNCTION cache_get(p_id IN t_order_id) RETURN NUMBER IS
  BEGIN
    RETURN CASE WHEN g_amt_cache.EXISTS(p_id) THEN g_amt_cache(p_id) ELSE NULL END;
  END;

  FUNCTION exists_id(p_id IN t_order_id) RETURN BOOLEAN IS
    v NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v FROM pi_orders WHERE order_id = p_id;
    RETURN v = 1;
  END;

  PROCEDURE ensure_id(p_id IN t_order_id) IS
  BEGIN
    IF NOT exists_id(p_id) THEN
      RAISE e_not_found; -- −20710 via PRAGMA
    END IF;
  END;

  PROCEDURE validate_amount(p_amt IN NUMBER) IS
  BEGIN
    IF p_amt IS NULL OR p_amt < 0 THEN
      RAISE e_invalid_amount; -- −20711 via PRAGMA
    END IF;
  END;

  PROCEDURE validate_status(p_sta IN VARCHAR2) IS
  BEGIN
    IF p_sta NOT IN (c_status_new, c_status_active, c_status_hold) THEN
      RAISE e_invalid_status; -- −20712 via PRAGMA
    END IF;
  END;

  ----------------------------------------------------------------------------
  -- Canonical implementation with caching touch points
  ----------------------------------------------------------------------------
  PROCEDURE set_amount_canon(p_id IN t_order_id, p_amount IN NUMBER,
                             p_reason IN VARCHAR2, p_hard_cap IN NUMBER) IS
    v_old NUMBER;
  BEGIN
    ensure_id(p_id);
    validate_amount(p_amount);
    IF p_hard_cap IS NOT NULL AND p_amount > p_hard_cap THEN
      RAISE e_invalid_amount;
    END IF;

    SELECT amount INTO v_old FROM pi_orders WHERE order_id = p_id;
    UPDATE pi_orders SET amount = p_amount WHERE order_id = p_id;
    cache_put(p_id, p_amount);

    dbg('amount change id='||p_id||' old='||v_old||' new='||p_amount||
        CASE WHEN p_reason IS NOT NULL THEN ' reason='||p_reason ELSE '' END);
    bump;
  END;

  ----------------------------------------------------------------------------
  -- Thin wrappers (public), unchanged signatures
  ----------------------------------------------------------------------------
  PROCEDURE set_amount(p_id IN t_order_id, p_amount IN NUMBER) IS
  BEGIN set_amount_canon(p_id, p_amount, p_reason => NULL, p_hard_cap => NULL); END;

  PROCEDURE set_amount(p_id IN t_order_id, p_amount IN NUMBER, p_reason IN VARCHAR2) IS
  BEGIN set_amount_canon(p_id, p_amount, p_reason, p_hard_cap => NULL); END;

  PROCEDURE set_amount(p_id IN t_order_id, p_amount IN NUMBER, p_reason IN VARCHAR2,
                       p_hard_cap IN NUMBER) IS
  BEGIN set_amount_canon(p_id, p_amount, p_reason, p_hard_cap); END;

  ----------------------------------------------------------------------------
  -- Public ops
  ----------------------------------------------------------------------------
  PROCEDURE activate(p_id IN t_order_id) IS
  BEGIN
    ensure_id(p_id);
    UPDATE pi_orders SET status = c_status_active WHERE order_id = p_id;
    dbg('activate id='||p_id); bump;
  END;

  PROCEDURE hold(p_id IN t_order_id, p_reason IN VARCHAR2 DEFAULT NULL) IS
  BEGIN
    ensure_id(p_id);
    UPDATE pi_orders SET status = c_status_hold WHERE order_id = p_id;
    IF p_reason IS NOT NULL THEN dbg('hold reason='||p_reason); END IF; bump;
  END;

  FUNCTION get_amount(p_id IN t_order_id) RETURN NUMBER DETERMINISTIC IS
    v NUMBER;
  BEGIN
    ensure_id(p_id);
    v := cache_get(p_id);
    IF v IS NOT NULL THEN
      dbg('cache hit id='||p_id||' amt='||v); RETURN v;
    END IF;
    SELECT amount INTO v FROM pi_orders WHERE order_id = p_id;
    cache_put(p_id, v);
    dbg('cache miss id='||p_id||' amt='||v);
    RETURN v;
  END;

  FUNCTION status_of(p_id IN t_order_id) RETURN VARCHAR2 IS
    v VARCHAR2(12);
  BEGIN
    ensure_id(p_id);
    SELECT status INTO v FROM pi_orders WHERE order_id = p_id;
    RETURN v;
  END;

  ----------------------------------------------------------------------------
  -- Diagnostics & admin
  ----------------------------------------------------------------------------
  FUNCTION version RETURN VARCHAR2 IS BEGIN RETURN g_version; END;
  FUNCTION calls_made RETURN PLS_INTEGER IS BEGIN RETURN NVL(g_calls,0); END;
  FUNCTION last_init_time RETURN DATE IS BEGIN RETURN g_last_init; END;

  PROCEDURE enable_debug  IS BEGIN g_debug := TRUE;  END;
  PROCEDURE disable_debug IS BEGIN g_debug := FALSE; END;

  PROCEDURE clear_state IS
  BEGIN
    g_calls := 0;
    g_amt_cache.DELETE;
    dbg('state cleared');
  END;
END order_pub;
/
SHOW ERRORS

--------------------------------------------------------------------------------
-- 3) WORKED EXAMPLES (≥5) with expected outputs noted
--------------------------------------------------------------------------------

-- Example 1: BODY version bump without SPEC change
BEGIN
  order_pub.enable_debug;
  DBMS_OUTPUT.PUT_LINE('version='||order_pub.version||' init='||TO_CHAR(order_pub.last_init_time,'YYYY-MM-DD HH24:MI:SS'));
  DBMS_OUTPUT.PUT_LINE('calls='||order_pub.calls_made);
END;
/
-- Expect: version prints '1.1.0'; calls = 0 at start of session.

-- Example 2: set_amount via wrappers (2/3/4‑arity); cache updated
BEGIN
  order_pub.set_amount(101, 18100);                                       -- 2‑arity
  order_pub.set_amount(102, 11100, 'price update');                       -- 3‑arity
  order_pub.set_amount(103, 24100, 'uplift', p_hard_cap => 26000);        -- 4‑arity
  DBMS_OUTPUT.PUT_LINE('calls(after set)='||order_pub.calls_made);
END;
/
SELECT order_id, amount FROM pi_orders ORDER BY order_id;
/
-- Expect: amounts reflect changes; calls increased by 3.

-- Example 3: Cache behavior — first get_amount is miss, second is hit
BEGIN
  DBMS_OUTPUT.PUT_LINE('first get  id=101 -> '||order_pub.get_amount(101)); -- miss, loads cache
  DBMS_OUTPUT.PUT_LINE('second get id=101 -> '||order_pub.get_amount(101)); -- hit
END;
/
-- Expect: debug shows 'cache miss' then 'cache hit'. Same numeric value printed twice.

-- Example 4: Input validation errors raised from centralized helpers
BEGIN
  BEGIN order_pub.set_amount(101, -5); EXCEPTION WHEN order_pub.e_invalid_amount THEN DBMS_OUTPUT.PUT_LINE('caught invalid amount'); END;
  BEGIN order_pub.set_amount(103, 999999, 'overcap', p_hard_cap=>5000); EXCEPTION WHEN order_pub.e_invalid_amount THEN DBMS_OUTPUT.PUT_LINE('caught cap violation'); END;
END;
/
-- Expect: two messages confirming error handling.

-- Example 5: Status transitions remain unchanged by BODY refactoring
BEGIN
  order_pub.activate(101);
  order_pub.hold(102, 'audit');
  DBMS_OUTPUT.PUT_LINE('status(101)='||order_pub.status_of(101));
  DBMS_OUTPUT.PUT_LINE('status(102)='||order_pub.status_of(102));
END;
/
-- Expect: 101 -> ACTIVE, 102 -> HOLD, messages printed accordingly.

-- Example 6: Clear state resets counters and cache
BEGIN
  DBMS_OUTPUT.PUT_LINE('calls before clear='||order_pub.calls_made);
  order_pub.clear_state;
  DBMS_OUTPUT.PUT_LINE('calls after  clear='||order_pub.calls_made);
END;
/
-- Expect: calls reset to 0; cache emptied (subsequent get will miss).

-- End of Lesson File
