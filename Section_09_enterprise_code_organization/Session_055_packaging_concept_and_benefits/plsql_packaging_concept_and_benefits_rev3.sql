SET SERVEROUTPUT ON SIZE UNLIMITED;
/*
Session: 055 - Packaging Concept and Benefits
Goal:
  A production-style walkthrough of packages with deep commentary:
  (1) Idempotent lab setup
  (2) SPEC that reads like a public contract (types/constants/signatures only)
  (3) BODY hiding helpers/state/algorithms
  (4) Read-only diagnostics (calls_made), debug toggle, error-code policy
  (5) Overloading example (fetch_name with and without formatting)
  (6) Usage examples (at least five) and expected effects
  (7) Note on recompilation and state reset

How to run:
  • Execute each block terminated by '/' separately.
  • Keep SERVEROUTPUT enabled to view commentary.

Important conventions in this file:
  • Error codes: -20500..-20599 reserved for this lesson
  • No public mutable variables
  • SPEC remains minimal and stable
*/

--------------------------------------------------------------------------------
-- 1) Idempotent LAB SETUP (objects reused by the package)
--    We create a small table with customer records. This is the only schema-level
--    object the package will modify. Everything else remains encapsulated.
--------------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'DROP TABLE pkg_customers PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE pkg_customers(
  cust_id    NUMBER        CONSTRAINT pkg_customers_pk PRIMARY KEY,
  full_name  VARCHAR2(50)  NOT NULL,
  status     VARCHAR2(10)  DEFAULT 'NEW' NOT NULL,
  created_at DATE          DEFAULT SYSDATE NOT NULL
);

-- Seed rows; these are used by examples to show state transitions.
INSERT INTO pkg_customers VALUES (1, 'Avi',  'NEW',    SYSDATE-2);
INSERT INTO pkg_customers VALUES (2, 'Neha', 'ACTIVE', SYSDATE-1);
INSERT INTO pkg_customers VALUES (3, 'Raj',  'HOLD',   SYSDATE);
COMMIT;
/
--------------------------------------------------------------------------------
-- 2) PACKAGE SPEC (Public Contract)
--    Principles:
--      • SPEC must expose only stable surface: constants, types, signatures
--      • No business rules or private state leaks here
--      • Comments document contract: inputs, outputs, error codes
--------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE customer_api AS
  ----------------------------------------------------------------------------
  -- Types intended for consumers (compile-time visibility)
  ----------------------------------------------------------------------------
  SUBTYPE t_cust_id IS NUMBER;

  ----------------------------------------------------------------------------
  -- Public constants (avoid magic literals in callers)
  ----------------------------------------------------------------------------
  c_status_new    CONSTANT VARCHAR2(10) := 'NEW';
  c_status_active CONSTANT VARCHAR2(10) := 'ACTIVE';
  c_status_hold   CONSTANT VARCHAR2(10) := 'HOLD';

  ----------------------------------------------------------------------------
  -- Diagnostics (read-only). These reveal state without exposing variables.
  ----------------------------------------------------------------------------
  FUNCTION calls_made RETURN PLS_INTEGER;
  FUNCTION last_init_time RETURN DATE;

  ----------------------------------------------------------------------------
  -- Public operations (documented error contracts):
  --   • activate: -20510 if id missing
  --   • hold:     -20511 if id missing; reason optional for observability
  --   • set_name: -20512 if name empty; -20510 if id missing
  ----------------------------------------------------------------------------
  PROCEDURE activate(p_id IN t_cust_id);
  PROCEDURE hold(p_id IN t_cust_id, p_reason IN VARCHAR2 DEFAULT NULL);
  PROCEDURE set_name(p_id IN t_cust_id, p_name IN VARCHAR2);

  ----------------------------------------------------------------------------
  -- Overloaded getters: same semantic action (fetch name), different signatures
  --   • fetch_name(p_id) -> return raw name
  --   • fetch_name(p_id, p_case) -> 'UPPER'/'LOWER' transformation
  ----------------------------------------------------------------------------
  FUNCTION fetch_name(p_id IN t_cust_id) RETURN VARCHAR2;
  FUNCTION fetch_name(p_id IN t_cust_id, p_case IN VARCHAR2) RETURN VARCHAR2;

  ----------------------------------------------------------------------------
  -- SQL-usable predicate for reporting: 1 if ACTIVE else 0
  ----------------------------------------------------------------------------
  FUNCTION is_active(p_id IN t_cust_id) RETURN NUMBER DETERMINISTIC;

  ----------------------------------------------------------------------------
  -- Administration: toggle debug output and clear state
  ----------------------------------------------------------------------------
  PROCEDURE enable_debug;
  PROCEDURE disable_debug;
  PROCEDURE clear_state;
END customer_api;
/
SHOW ERRORS
--------------------------------------------------------------------------------
-- 3) PACKAGE BODY (Private Implementation)
--    Implementation details live here. We keep helpers and session-scoped state
--    private. SPEC remains unchanged as logic evolves.
--------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE BODY customer_api AS
  ----------------------------------------------------------------------------
  -- Private state: session-scoped variables
  ----------------------------------------------------------------------------
  g_calls      PLS_INTEGER := 0;     -- increments on each public entry
  g_last_init  DATE;                 -- captured in initialization section
  g_debug      BOOLEAN := FALSE;     -- gated debug output

  ----------------------------------------------------------------------------
  -- Private helpers (no visibility outside the package)
  ----------------------------------------------------------------------------
  PROCEDURE dbg(p_msg IN VARCHAR2) IS
  BEGIN
    IF g_debug THEN
      DBMS_OUTPUT.PUT_LINE('[customer_api] '||p_msg);
    END IF;
  END;

  PROCEDURE bump IS
  BEGIN
    g_calls := NVL(g_calls,0) + 1;
  END;

  FUNCTION exists_id(p_id IN t_cust_id) RETURN BOOLEAN IS
    v NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v FROM pkg_customers WHERE cust_id = p_id;
    RETURN v = 1;
  END;

  PROCEDURE ensure_id(p_id IN t_cust_id) IS
  BEGIN
    IF NOT exists_id(p_id) THEN
      RAISE_APPLICATION_ERROR(-20510, 'customer not found id='||p_id);
    END IF;
  END;

  ----------------------------------------------------------------------------
  -- Public diagnostics
  ----------------------------------------------------------------------------
  FUNCTION calls_made RETURN PLS_INTEGER IS
  BEGIN
    RETURN NVL(g_calls,0);
  END;

  FUNCTION last_init_time RETURN DATE IS
  BEGIN
    RETURN g_last_init;
  END;

  ----------------------------------------------------------------------------
  -- Public operations with validation and error policy
  ----------------------------------------------------------------------------
  PROCEDURE activate(p_id IN t_cust_id) IS
  BEGIN
    ensure_id(p_id);
    UPDATE pkg_customers SET status = c_status_active WHERE cust_id = p_id;
    dbg('activate id='||p_id);
    bump;
  END;

  PROCEDURE hold(p_id IN t_cust_id, p_reason IN VARCHAR2 DEFAULT NULL) IS
  BEGIN
    ensure_id(p_id);
    UPDATE pkg_customers SET status = c_status_hold WHERE cust_id = p_id;
    IF p_reason IS NOT NULL THEN dbg('hold reason='||p_reason); END IF;
    bump;
  END;

  PROCEDURE set_name(p_id IN t_cust_id, p_name IN VARCHAR2) IS
  BEGIN
    IF p_name IS NULL OR TRIM(p_name) = '' THEN
      RAISE_APPLICATION_ERROR(-20512, 'name must be non-empty');
    END IF;
    ensure_id(p_id);
    UPDATE pkg_customers SET full_name = p_name WHERE cust_id = p_id;
    dbg('set_name id='||p_id||' -> '||p_name);
    bump;
  END;

  ----------------------------------------------------------------------------
  -- Overloaded getters (illustrate overloading by arity and semantics)
  ----------------------------------------------------------------------------
  FUNCTION fetch_name(p_id IN t_cust_id) RETURN VARCHAR2 IS
    v_name pkg_customers.full_name%TYPE;
  BEGIN
    ensure_id(p_id);
    SELECT full_name INTO v_name FROM pkg_customers WHERE cust_id = p_id;
    bump;
    RETURN v_name;
  END;

  FUNCTION fetch_name(p_id IN t_cust_id, p_case IN VARCHAR2) RETURN VARCHAR2 IS
    v_name VARCHAR2(50);
    v_norm VARCHAR2(10) := UPPER(NVL(p_case,'RAW'));
  BEGIN
    v_name := fetch_name(p_id); -- reuse the other overload (DRY)
    CASE v_norm
      WHEN 'UPPER' THEN RETURN UPPER(v_name);
      WHEN 'LOWER' THEN RETURN LOWER(v_name);
      WHEN 'RAW'   THEN RETURN v_name;
      ELSE
        RAISE_APPLICATION_ERROR(-20513, 'p_case must be RAW|UPPER|LOWER');
    END CASE;
  END;

  ----------------------------------------------------------------------------
  -- SQL-usable predicate
  ----------------------------------------------------------------------------
  FUNCTION is_active(p_id IN t_cust_id) RETURN NUMBER DETERMINISTIC IS
    v_status pkg_customers.status%TYPE;
  BEGIN
    SELECT status INTO v_status FROM pkg_customers WHERE cust_id = p_id;
    RETURN CASE WHEN v_status = c_status_active THEN 1 ELSE 0 END;
  EXCEPTION WHEN NO_DATA_FOUND THEN
    RETURN 0;
  END;

  ----------------------------------------------------------------------------
  -- Administration
  ----------------------------------------------------------------------------
  PROCEDURE enable_debug  IS BEGIN g_debug := TRUE;  END;
  PROCEDURE disable_debug IS BEGIN g_debug := FALSE; END;

  PROCEDURE clear_state IS
  BEGIN
    g_calls := 0;
    dbg('state cleared');
  END;

BEGIN
  -- Initialization section (runs once per session on first reference)
  g_calls     := 0;
  g_last_init := SYSDATE;
  g_debug     := FALSE;
END customer_api;
/
SHOW ERRORS
--------------------------------------------------------------------------------
-- 4) EXAMPLES (at least five). Each block explains purpose, inputs, and outputs.
--------------------------------------------------------------------------------

-- Example 1: Basic activation flow
-- Purpose:
--   Show a read -> write path through public API. Observe diagnostics.
BEGIN
  customer_api.enable_debug;
  DBMS_OUTPUT.PUT_LINE('init='||TO_CHAR(customer_api.last_init_time,'YYYY-MM-DD HH24:MI:SS'));
  customer_api.activate(1);
  DBMS_OUTPUT.PUT_LINE('calls='||customer_api.calls_made);
END;
/
SELECT cust_id, full_name, status, customer_api.is_active(cust_id) AS active_flag
FROM   pkg_customers
ORDER  BY cust_id;
/

-- Example 2: Hold with reason; debug traces appear due to enable_debug()
BEGIN
  customer_api.hold(2, 'KYC pending');
  DBMS_OUTPUT.PUT_LINE('calls='||customer_api.calls_made);
END;
/
SELECT cust_id, full_name, status FROM pkg_customers WHERE cust_id=2;
/

-- Example 3: Overloaded fetch_name(p_id) and fetch_name(p_id, p_case)
-- Expected:
--   • raw name
--   • upper-cased
--   • lower-cased
BEGIN
  DBMS_OUTPUT.PUT_LINE('raw='   || customer_api.fetch_name(1));
  DBMS_OUTPUT.PUT_LINE('upper=' || customer_api.fetch_name(1,'UPPER'));
  DBMS_OUTPUT.PUT_LINE('lower=' || customer_api.fetch_name(1,'LOWER'));
END;
/
-- Error path for invalid p_case (uncomment to test)
-- BEGIN
--   DBMS_OUTPUT.PUT_LINE(customer_api.fetch_name(1, 'TITLE'));
-- END;
-- /

-- Example 4: Validation error for empty name (raises -20512)
BEGIN
  BEGIN
    customer_api.set_name(3, '   ');
  EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('[err] '||SQLCODE||' '||SQLERRM);
  END;
END;
/
-- Successful rename
BEGIN
  customer_api.set_name(3, 'Raj Kumar');
  DBMS_OUTPUT.PUT_LINE('renamed -> '||customer_api.fetch_name(3));
END;
/
SELECT cust_id, full_name, status FROM pkg_customers WHERE cust_id=3;
/

-- Example 5: clear_state resets diagnostics
BEGIN
  DBMS_OUTPUT.PUT_LINE('before clear -> calls='||customer_api.calls_made);
  customer_api.clear_state;
  DBMS_OUTPUT.PUT_LINE('after  clear -> calls='||customer_api.calls_made);
END;
/
-- Disable debug for cleaner output going forward
BEGIN
  customer_api.disable_debug;
END;
/
-- Example 6: SQL-only consumption of predicate (reporting)
SELECT cust_id, status, customer_api.is_active(cust_id) AS active_flag
FROM   pkg_customers
ORDER  BY cust_id;
/
--------------------------------------------------------------------------------
-- 5) RECOMPILATION NOTE (demonstration)
--    BODY recompilation typically resets state on next reference. SPEC changes
--    invalidate dependents. We keep this as a commented sequence to run ad‑hoc.
--------------------------------------------------------------------------------
-- BEGIN DBMS_OUTPUT.PUT_LINE('pre-compile calls='||customer_api.calls_made); END; /
-- ALTER PACKAGE customer_api COMPILE BODY; /
-- BEGIN DBMS_OUTPUT.PUT_LINE('post-compile calls='||customer_api.calls_made); END; /

--------------------------------------------------------------------------------
-- 6) CLEANUP (optional) — leave commented when using in your course repo
--------------------------------------------------------------------------------
-- BEGIN EXECUTE IMMEDIATE 'DROP PACKAGE customer_api'; EXCEPTION WHEN OTHERS THEN NULL; END; /
-- BEGIN EXECUTE IMMEDIATE 'DROP TABLE pkg_customers PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END; /

-- End of File
