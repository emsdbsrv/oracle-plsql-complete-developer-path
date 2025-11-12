SET SERVEROUTPUT ON SIZE UNLIMITED;
/*
Session: 056 – Public Interface Declaration
Topic: Designing stable package specifications (SPEC) that act as public contracts.

Purpose:
  This lesson shows how to design a production‑ready package SPEC that:
    (1) Declares types, constants, exceptions, and subprogram signatures only
    (2) Hides implementation details in the BODY
    (3) Publishes diagnostics (version, init time, call counts) safely
    (4) Uses a canonical implementation + thin overloads pattern
    (5) Enforces a clear error policy with named exceptions
    (6) Provides ≥ 5 worked examples with expected outcomes

Error Code Range for this lesson: −20700..−20799
How to Run:
  • Execute each block (terminated by '/') one at a time.
  • Keep SERVEROUTPUT ON to see commentary.
  • Script is idempotent (safe re‑runs): objects are dropped if they exist.
*/

--------------------------------------------------------------------------------
-- 0) Lab setup: persistent object used by the public package (pi_orders table)
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
-- 1) PACKAGE SPEC: order_pub — Public Interface (no implementation/logic here)
--    Principles enforced:
--      • SPEC is a stable contract: types, constants, exceptions, signatures
--      • No public mutable variables; use getters/setters if needed
--      • Error contracts are explicit and mapped via PRAGMA EXCEPTION_INIT
--      • Diagnostics are read‑only and side‑effect free
--------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE order_pub AS
  -- Types visible to callers (compile‑time):
  SUBTYPE t_order_id IS NUMBER;

  -- Constants (avoid magic strings/numbers in client code):
  c_status_new     CONSTANT VARCHAR2(12) := 'NEW';
  c_status_active  CONSTANT VARCHAR2(12) := 'ACTIVE';
  c_status_hold    CONSTANT VARCHAR2(12) := 'HOLD';

  -- Named exceptions (mapped to −207xx error codes):
  e_not_found          EXCEPTION;   -- maps to −20710
  e_invalid_amount     EXCEPTION;   -- maps to −20711
  e_invalid_status     EXCEPTION;   -- maps to −20712
  PRAGMA EXCEPTION_INIT(e_not_found,      -20710);
  PRAGMA EXCEPTION_INIT(e_invalid_amount, -20711);
  PRAGMA EXCEPTION_INIT(e_invalid_status, -20712);

  -- Diagnostics & versioning (read‑only; safe to expose):
  FUNCTION version         RETURN VARCHAR2;   -- e.g., '1.0.0'
  FUNCTION calls_made      RETURN PLS_INTEGER;
  FUNCTION last_init_time  RETURN DATE;

  -- Public operations (thin overloads + canonical):
  PROCEDURE set_amount(p_id IN t_order_id, p_amount IN NUMBER);
  PROCEDURE set_amount(p_id IN t_order_id, p_amount IN NUMBER, p_reason IN VARCHAR2);
  PROCEDURE set_amount(p_id IN t_order_id, p_amount IN NUMBER, p_reason IN VARCHAR2, p_hard_cap IN NUMBER);

  PROCEDURE activate(p_id IN t_order_id);
  PROCEDURE hold(p_id IN t_order_id, p_reason IN VARCHAR2 DEFAULT NULL);

  FUNCTION  get_amount(p_id IN t_order_id) RETURN NUMBER DETERMINISTIC;
  FUNCTION  status_of(p_id IN t_order_id)  RETURN VARCHAR2;

  -- Admin/diagnostics toggles (exposed by design):
  PROCEDURE enable_debug;
  PROCEDURE disable_debug;
  PROCEDURE clear_state;
END order_pub;
/
SHOW ERRORS

--------------------------------------------------------------------------------
-- 2) PACKAGE BODY: Implementation hidden behind the SPEC
--    Contains private state, helpers, canonical implementation, debug
--------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE BODY order_pub AS
  -- Private session‑scoped state (never exposed directly)
  g_calls        PLS_INTEGER := 0;      -- increments on each public entry
  g_last_init    DATE;                  -- captured at first reference
  g_debug        BOOLEAN := FALSE;      -- gated debug output
  g_version      CONSTANT VARCHAR2(10) := '1.0.0';

  -- Private helpers
  PROCEDURE dbg(p IN VARCHAR2) IS
  BEGIN
    IF g_debug THEN DBMS_OUTPUT.PUT_LINE('[order_pub] '||p); END IF;
  END;

  PROCEDURE bump IS BEGIN g_calls := NVL(g_calls,0) + 1; END;

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

  -- Canonical implementation: full parameter set
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

    dbg('amount change id='||p_id||' old='||v_old||' new='||p_amount||
        CASE WHEN p_reason IS NOT NULL THEN ' reason='||p_reason ELSE '' END);
    bump;
  END;

  -- Thin overloads forwarding to canonical
  PROCEDURE set_amount(p_id IN t_order_id, p_amount IN NUMBER) IS
  BEGIN set_amount_canon(p_id, p_amount, p_reason => NULL, p_hard_cap => NULL); END;

  PROCEDURE set_amount(p_id IN t_order_id, p_amount IN NUMBER, p_reason IN VARCHAR2) IS
  BEGIN set_amount_canon(p_id, p_amount, p_reason, p_hard_cap => NULL); END;

  PROCEDURE set_amount(p_id IN t_order_id, p_amount IN NUMBER, p_reason IN VARCHAR2,
                       p_hard_cap IN NUMBER) IS
  BEGIN set_amount_canon(p_id, p_amount, p_reason, p_hard_cap); END;

  -- Public operations
  PROCEDURE activate(p_id IN t_order_id) IS
  BEGIN
    ensure_id(p_id);
    UPDATE pi_orders SET status = c_status_active WHERE order_id = p_id;
    dbg('activate id='||p_id);
    bump;
  END;

  PROCEDURE hold(p_id IN t_order_id, p_reason IN VARCHAR2 DEFAULT NULL) IS
  BEGIN
    ensure_id(p_id);
    UPDATE pi_orders SET status = c_status_hold WHERE order_id = p_id;
    IF p_reason IS NOT NULL THEN dbg('hold reason='||p_reason); END IF;
    bump;
  END;

  FUNCTION get_amount(p_id IN t_order_id) RETURN NUMBER DETERMINISTIC IS
    v NUMBER;
  BEGIN
    ensure_id(p_id);
    SELECT amount INTO v FROM pi_orders WHERE order_id = p_id;
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

  PROCEDURE enable_debug  IS BEGIN g_debug := TRUE;  END;
  PROCEDURE disable_debug IS BEGIN g_debug := FALSE; END;

  PROCEDURE clear_state IS
  BEGIN
    g_calls := 0;
    dbg('state cleared');
  END;

BEGIN
  -- Initialization runs once per session at first reference of order_pub
  g_calls     := 0;
  g_last_init := SYSDATE;
  g_debug     := FALSE;
END order_pub;
/
SHOW ERRORS

--------------------------------------------------------------------------------
-- 3) WORKED EXAMPLES (≥5). Each block documents purpose and expected behavior.
--------------------------------------------------------------------------------

-- Example 1: Diagnostics and version — read‑only and side‑effect free
BEGIN
  order_pub.enable_debug;
  DBMS_OUTPUT.PUT_LINE('version='||order_pub.version||'; init='||TO_CHAR(order_pub.last_init_time,'YYYY-MM-DD HH24:MI:SS'));
  DBMS_OUTPUT.PUT_LINE('calls(before)='||order_pub.calls_made);
END;
/
-- Expectation:
--   • Prints version and initialization timestamp
--   • calls(before) = 0 (first use after init)

-- Example 2: set_amount thin overloads (2‑arity, 3‑arity, 4‑arity)
BEGIN
  order_pub.set_amount(101, 18000);                                       -- 2‑arity
  order_pub.set_amount(102, 11000, 'price update');                       -- 3‑arity
  order_pub.set_amount(103, 24000, 'annual uplift', p_hard_cap => 25000); -- 4‑arity
  DBMS_OUTPUT.PUT_LINE('calls(after set)='||order_pub.calls_made);
END;
/
SELECT order_id, customer, amount, status FROM pi_orders ORDER BY order_id;
/
-- Expectation:
--   • Amounts updated as specified
--   • calls(after set) increased by 3

-- Example 3: Activate and hold with reason; show status via status_of()
BEGIN
  order_pub.activate(101);
  order_pub.hold(102, 'manual review');
  DBMS_OUTPUT.PUT_LINE('status(101)='||order_pub.status_of(101));
  DBMS_OUTPUT.PUT_LINE('status(102)='||order_pub.status_of(102));
END;
/
-- Expectation:
--   • order 101 -> ACTIVE; order 102 -> HOLD; DBMS_OUTPUT shows statuses

-- Example 4: Validation errors — negative amount and hard‑cap violation
BEGIN
  BEGIN
    order_pub.set_amount(101, -1);
  EXCEPTION
    WHEN order_pub.e_invalid_amount THEN
      DBMS_OUTPUT.PUT_LINE('caught e_invalid_amount (negative)');
  END;
  BEGIN
    order_pub.set_amount(103, 999999, 'bad cap', p_hard_cap => 5000);
  EXCEPTION
    WHEN order_pub.e_invalid_amount THEN
      DBMS_OUTPUT.PUT_LINE('caught e_invalid_amount (cap)');
  END;
END;
/
-- Expectation:
--   • Both inner blocks catch and print their respective invalid_amount messages

-- Example 5: SQL consumption of DETERMINISTIC function
SELECT order_id,
       order_pub.get_amount(order_id) AS amt,
       order_pub.status_of(order_id)  AS st
FROM   pi_orders
ORDER  BY order_id;
/
-- Expectation:
--   • get_amount(status_of) used inline in a query without side effects

-- Example 6: Clear state and observe diagnostics reset
BEGIN
  DBMS_OUTPUT.PUT_LINE('before clear calls='||order_pub.calls_made);
  order_pub.clear_state;
  DBMS_OUTPUT.PUT_LINE('after  clear calls='||order_pub.calls_made);
  order_pub.disable_debug;
END;
/
-- Expectation:
--   • calls reset to 0; debug disabled

-- Example 7 (optional): BODY recompilation resets state on next use
-- BEGIN DBMS_OUTPUT.PUT_LINE('pre-compile calls='||order_pub.calls_made); END; /
-- ALTER PACKAGE order_pub COMPILE BODY; /
-- BEGIN DBMS_OUTPUT.PUT_LINE('post-compile calls='||order_pub.calls_made); END; /

-- End of Lesson File
