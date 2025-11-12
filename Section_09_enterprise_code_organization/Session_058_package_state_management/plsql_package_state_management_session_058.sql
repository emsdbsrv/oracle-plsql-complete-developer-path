SET SERVEROUTPUT ON SIZE UNLIMITED;
/*
Session: 058 – Package State Management
Topic: Managing session-scoped variables and caches inside PACKAGE BODY.

Purpose:
  (1) Show session lifecycle of package variables
  (2) Track counters, timestamps, and user context safely
  (3) Provide explicit reset (clear_state) and initialization patterns
  (4) Demonstrate persistence across calls with ≥ 5 worked examples
  (5) Keep state private; expose only controlled diagnostic getters

Error Code Range: −20700..−20799
How to Run:
  • Execute each block separated by '/'.
  • If 056/057 not executed, this script creates required objects.
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
-- 1) SPEC: order_pub with explicit state diagnostics and safe APIs
--------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE order_pub AS
  SUBTYPE t_order_id IS NUMBER;

  c_status_new     CONSTANT VARCHAR2(12) := 'NEW';
  c_status_active  CONSTANT VARCHAR2(12) := 'ACTIVE';
  c_status_hold    CONSTANT VARCHAR2(12) := 'HOLD';

  e_not_found          EXCEPTION;   PRAGMA EXCEPTION_INIT(e_not_found,      -20710);
  e_invalid_amount     EXCEPTION;   PRAGMA EXCEPTION_INIT(e_invalid_amount, -20711);
  e_invalid_status     EXCEPTION;   PRAGMA EXCEPTION_INIT(e_invalid_status, -20712);

  -- Diagnostics & versioning
  FUNCTION version           RETURN VARCHAR2;
  FUNCTION calls_made        RETURN PLS_INTEGER;
  FUNCTION last_init_time    RETURN DATE;
  FUNCTION cache_hits        RETURN PLS_INTEGER;
  FUNCTION cache_misses      RETURN PLS_INTEGER;
  FUNCTION last_user         RETURN VARCHAR2;
  FUNCTION last_action_time  RETURN DATE;

  -- Public operations
  PROCEDURE set_amount(p_id IN t_order_id, p_amount IN NUMBER);
  PROCEDURE set_amount(p_id IN t_order_id, p_amount IN NUMBER, p_reason IN VARCHAR2);
  PROCEDURE set_amount(p_id IN t_order_id, p_amount IN NUMBER, p_reason IN VARCHAR2, p_hard_cap IN NUMBER);

  PROCEDURE activate(p_id IN t_order_id);
  PROCEDURE hold(p_id IN t_order_id, p_reason IN VARCHAR2 DEFAULT NULL);

  FUNCTION  get_amount(p_id IN t_order_id) RETURN NUMBER DETERMINISTIC;
  FUNCTION  status_of(p_id IN t_order_id)  RETURN VARCHAR2;

  -- Admin/diagnostic controls
  PROCEDURE enable_debug;
  PROCEDURE disable_debug;
  PROCEDURE clear_state;
  PROCEDURE set_user(p_user IN VARCHAR2);
END order_pub;
/
SHOW ERRORS

--------------------------------------------------------------------------------
-- 2) BODY: adds state variables, counters, cache, and user context
--------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE BODY order_pub AS
  -- Private session state
  g_calls        PLS_INTEGER := 0;
  g_last_init    DATE        := SYSDATE;
  g_debug        BOOLEAN     := FALSE;
  g_version      CONSTANT VARCHAR2(10) := '1.2.0';

  -- Session cache for amounts and hit/miss counters
  TYPE t_amt_cache IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
  g_amt_cache  t_amt_cache;
  g_hits       PLS_INTEGER := 0;
  g_misses     PLS_INTEGER := 0;

  -- User context
  g_last_user  VARCHAR2(60) := NULL;
  g_last_time  DATE := NULL;

  -- Helpers
  PROCEDURE dbg(p IN VARCHAR2) IS
  BEGIN IF g_debug THEN DBMS_OUTPUT.PUT_LINE('[order_pub] '||p); END IF; END;
  PROCEDURE bump IS BEGIN g_calls := NVL(g_calls,0) + 1; END;

  PROCEDURE touch_user IS
  BEGIN
    g_last_time := SYSTIMESTAMP;
    -- g_last_user can be set by set_user; if NULL, we derive from USER
    IF g_last_user IS NULL THEN g_last_user := USER; END IF;
  END;

  PROCEDURE cache_put(p_id IN t_order_id, p_amt IN NUMBER) IS
  BEGIN g_amt_cache(p_id) := p_amt; END;

  FUNCTION cache_get(p_id IN t_order_id) RETURN NUMBER IS
  BEGIN
    IF g_amt_cache.EXISTS(p_id) THEN
      g_hits := g_hits + 1;
      RETURN g_amt_cache(p_id);
    ELSE
      g_misses := g_misses + 1;
      RETURN NULL;
    END IF;
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
      RAISE e_not_found;
    END IF;
  END;

  PROCEDURE validate_amount(p_amt IN NUMBER) IS
  BEGIN
    IF p_amt IS NULL OR p_amt < 0 THEN
      RAISE e_invalid_amount;
    END IF;
  END;

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
    touch_user;

    dbg('amount change id='||p_id||' old='||v_old||' new='||p_amount||
        CASE WHEN p_reason IS NOT NULL THEN ' reason='||p_reason ELSE '' END);
    bump;
  END;

  -- Thin wrappers
  PROCEDURE set_amount(p_id IN t_order_id, p_amount IN NUMBER) IS
  BEGIN set_amount_canon(p_id, p_amount, p_reason => NULL, p_hard_cap => NULL); END;

  PROCEDURE set_amount(p_id IN t_order_id, p_amount IN NUMBER, p_reason IN VARCHAR2) IS
  BEGIN set_amount_canon(p_id, p_amount, p_reason, p_hard_cap => NULL); END;

  PROCEDURE set_amount(p_id IN t_order_id, p_amount IN NUMBER, p_reason IN VARCHAR2, p_hard_cap IN NUMBER) IS
  BEGIN set_amount_canon(p_id, p_amount, p_reason, p_hard_cap); END;

  PROCEDURE activate(p_id IN t_order_id) IS
  BEGIN
    ensure_id(p_id);
    UPDATE pi_orders SET status = c_status_active WHERE order_id = p_id;
    touch_user; bump; dbg('activate '||p_id);
  END;

  PROCEDURE hold(p_id IN t_order_id, p_reason IN VARCHAR2 DEFAULT NULL) IS
  BEGIN
    ensure_id(p_id);
    UPDATE pi_orders SET status = c_status_hold WHERE order_id = p_id;
    touch_user; bump; IF p_reason IS NOT NULL THEN dbg('hold '||p_id||' reason='||p_reason); END IF;
  END;

  FUNCTION get_amount(p_id IN t_order_id) RETURN NUMBER DETERMINISTIC IS
    v NUMBER;
  BEGIN
    ensure_id(p_id);
    v := cache_get(p_id);
    IF v IS NOT NULL THEN dbg('cache hit '||p_id||' = '||v); RETURN v; END IF;
    SELECT amount INTO v FROM pi_orders WHERE order_id = p_id;
    cache_put(p_id, v);
    dbg('cache miss '||p_id||' = '||v);
    RETURN v;
  END;

  FUNCTION status_of(p_id IN t_order_id) RETURN VARCHAR2 IS
    v VARCHAR2(12);
  BEGIN
    ensure_id(p_id);
    SELECT status INTO v FROM pi_orders WHERE order_id = p_id;
    RETURN v;
  END;

  -- Diagnostics and admin
  FUNCTION version RETURN VARCHAR2 IS BEGIN RETURN g_version; END;
  FUNCTION calls_made RETURN PLS_INTEGER IS BEGIN RETURN NVL(g_calls,0); END;
  FUNCTION last_init_time RETURN DATE IS BEGIN RETURN g_last_init; END;
  FUNCTION cache_hits RETURN PLS_INTEGER IS BEGIN RETURN NVL(g_hits,0); END;
  FUNCTION cache_misses RETURN PLS_INTEGER IS BEGIN RETURN NVL(g_misses,0); END;
  FUNCTION last_user RETURN VARCHAR2 IS BEGIN RETURN g_last_user; END;
  FUNCTION last_action_time RETURN DATE IS BEGIN RETURN g_last_time; END;

  PROCEDURE enable_debug  IS BEGIN g_debug := TRUE;  END;
  PROCEDURE disable_debug IS BEGIN g_debug := FALSE; END;
  PROCEDURE set_user(p_user IN VARCHAR2) IS BEGIN g_last_user := p_user; END;

  PROCEDURE clear_state IS
  BEGIN
    g_calls := 0; g_hits := 0; g_misses := 0;
    g_amt_cache.DELETE;
    g_last_user := NULL; g_last_time := NULL;
    dbg('state cleared');
  END;
END order_pub;
/
SHOW ERRORS

--------------------------------------------------------------------------------
-- 3) WORKED EXAMPLES (≥5) demonstrating state persistence and reset
--------------------------------------------------------------------------------

-- Example 1: Initial diagnostics and state snapshot
BEGIN
  order_pub.enable_debug;
  DBMS_OUTPUT.PUT_LINE('v='||order_pub.version||' init='||TO_CHAR(order_pub.last_init_time,'YYYY-MM-DD HH24:MI:SS'));
  DBMS_OUTPUT.PUT_LINE('calls='||order_pub.calls_made||' hits='||order_pub.cache_hits||' misses='||order_pub.cache_misses);
  DBMS_OUTPUT.PUT_LINE('last_user='||NVL(order_pub.last_user,'<NULL>')||' last_time='||TO_CHAR(order_pub.last_action_time,'YYYY-MM-DD HH24:MI:SS'));
END;
/
-- Expect: zeroed counters; last_user/time null; version 1.2.0

-- Example 2: Perform operations; observe counters and user context
BEGIN
  order_pub.set_user('avi@app');
  order_pub.set_amount(101, 19000, 'promo');
  order_pub.activate(101);
  order_pub.hold(102, 'audit');
  DBMS_OUTPUT.PUT_LINE('calls='||order_pub.calls_made||' hits='||order_pub.cache_hits||' misses='||order_pub.cache_misses);
  DBMS_OUTPUT.PUT_LINE('last_user='||order_pub.last_user||' last_time='||TO_CHAR(order_pub.last_action_time,'YYYY-MM-DD HH24:MI:SS'));
END;
/
-- Expect: calls increased; last_user='avi@app'; last_time updated

-- Example 3: Cache hit/miss demonstration
BEGIN
  DBMS_OUTPUT.PUT_LINE('get 101 -> '||order_pub.get_amount(101)); -- first: miss (after set cleared cache? no) may be hit
  DBMS_OUTPUT.PUT_LINE('get 101 -> '||order_pub.get_amount(101)); -- second: hit
  DBMS_OUTPUT.PUT_LINE('hit/miss='||order_pub.cache_hits||'/'||order_pub.cache_misses);
END;
/
-- Expect: one additional hit; misses unchanged if value was cached by set_amount

-- Example 4: Reset state and verify
BEGIN
  order_pub.clear_state;
  DBMS_OUTPUT.PUT_LINE('after clear calls='||order_pub.calls_made||' hits='||order_pub.cache_hits||' misses='||order_pub.cache_misses);
  DBMS_OUTPUT.PUT_LINE('after clear last_user='||NVL(order_pub.last_user,'<NULL>'));
END;
/
-- Expect: all counters zero; user cleared

-- Example 5: New activity proves fresh state
BEGIN
  order_pub.set_amount(103, 25500, 'uplift', p_hard_cap=>26000);
  DBMS_OUTPUT.PUT_LINE('calls='||order_pub.calls_made);
  DBMS_OUTPUT.PUT_LINE('get 103 -> '||order_pub.get_amount(103));
  DBMS_OUTPUT.PUT_LINE('hit/miss='||order_pub.cache_hits||'/'||order_pub.cache_misses);
END;
/
-- Expect: calls incremented; first get may hit cache if set_amount cached it

-- Example 6: Negative test – invalid amount
BEGIN
  BEGIN order_pub.set_amount(103, -1); EXCEPTION WHEN order_pub.e_invalid_amount THEN DBMS_OUTPUT.PUT_LINE('caught invalid amount'); END;
END;
/
-- Expect: handled invalid amount

-- End of Lesson File
