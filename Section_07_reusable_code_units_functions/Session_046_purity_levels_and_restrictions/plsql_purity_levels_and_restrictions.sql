-- Script: plsql_purity_levels_and_restrictions.sql
-- Session: 046 - Purity Levels and Restrictions
-- Purpose:
--   Explain and demonstrate PL/SQL purity constraints using PRAGMA RESTRICT_REFERENCES,
--   what each flag implies (WNDS, RNDS, WNPS, RNPS), how to keep functions SQL-callable,
--   and modern substitutes (side-effect-free design, DETERMINISTIC, RESULT_CACHE).
-- How to run:
--   SET SERVEROUTPUT ON; execute each block separately (terminated by '/').
-- Notes:
--   • PRAGMA RESTRICT_REFERENCES is informational to the compiler and a contract for the programmer.
--   • Violations may trigger compile-time errors when using the pragma.
--   • Keep SQL-callable functions free of side effects and use %TYPE/%ROWTYPE where possible.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Setup: sample state (idempotent)
--------------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'DROP TABLE pr_orders PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE TABLE pr_orders (
  order_id   NUMBER CONSTRAINT pr_orders_pk PRIMARY KEY,
  amount     NUMBER(12,2) NOT NULL,
  status     VARCHAR2(20) DEFAULT 'NEW'
);

INSERT INTO pr_orders VALUES (1, 1000, 'NEW');
INSERT INTO pr_orders VALUES (2,  250, 'PAID');
COMMIT;
/

--------------------------------------------------------------------------------
-- Example 1: Package with a read-only pure function (RNDS, RNPS, WNDS, WNPS)
-- Intention:
--   Declare a function that neither reads/writes database state nor package state.
--   We compute a simple tax value; such a function is safe inside SQL.
--------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE pr_math AS
  FUNCTION tax10(p_amount IN NUMBER) RETURN NUMBER;
  PRAGMA RESTRICT_REFERENCES(tax10, WNDS, WNPS, RNDS, RNPS);
END pr_math;
/

CREATE OR REPLACE PACKAGE BODY pr_math AS
  FUNCTION tax10(p_amount IN NUMBER) RETURN NUMBER IS
  BEGIN
    RETURN ROUND(NVL(p_amount,0) * 0.10, 2);
  END tax10;
END pr_math;
/

-- Use in SQL safely (pure)
SELECT order_id, amount, pr_math.tax10(amount) AS tax
  FROM pr_orders
 ORDER BY order_id;
/

--------------------------------------------------------------------------------
-- Example 2: Function that reads database state violates RNDS unless declared appropriately
-- Intention:
--   A function that queries a table is NOT RNDS; it reads database state.
--   If we claim RNDS, it should fail to compile.
--------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE pr_bad AS
  FUNCTION status_of(p_id IN pr_orders.order_id%TYPE) RETURN VARCHAR2;
  -- Incorrect claim below (shows the restriction effect)
  PRAGMA RESTRICT_REFERENCES(status_of, RNDS); -- claims: reads NO database state (not true)
END pr_bad;
/

-- Expect compilation error for the body when we actually read DB.
BEGIN
  NULL;
END;
/
-- Now define the body to illustrate the violation.
CREATE OR REPLACE PACKAGE BODY pr_bad AS
  FUNCTION status_of(p_id IN pr_orders.order_id%TYPE) RETURN VARCHAR2 IS
    v_status pr_orders.status%TYPE;
  BEGIN
    SELECT status INTO v_status FROM pr_orders WHERE order_id = p_id; -- reads DB state
    RETURN v_status;
  END;
END pr_bad;
/
-- Depending on Oracle version/settings, the pragma may raise PLS errors because RNDS is violated.
-- In practice: either remove RNDS or use a pragma set that matches behavior.

--------------------------------------------------------------------------------
-- Example 3: Correct declaration for a function that READS DB but does not WRITE DB or package state
-- Intention:
--   Reads database state only -> remove RNDS claim and keep WNDS/WNPS.
--------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE pr_lookup AS
  FUNCTION status_of(p_id IN pr_orders.order_id%TYPE) RETURN VARCHAR2;
  PRAGMA RESTRICT_REFERENCES(status_of, WNDS, WNPS); -- claims: does NOT write DB nor package state
END pr_lookup;
/

CREATE OR REPLACE PACKAGE BODY pr_lookup AS
  FUNCTION status_of(p_id IN pr_orders.order_id%TYPE) RETURN VARCHAR2 IS
    v_status pr_orders.status%TYPE;
  BEGIN
    SELECT status INTO v_status FROM pr_orders WHERE order_id = p_id; -- read ok
    RETURN v_status;
  END;
END pr_lookup;
/

SELECT order_id, pr_lookup.status_of(order_id) status
  FROM pr_orders
 ORDER BY order_id;
/

--------------------------------------------------------------------------------
-- Example 4: Package state dependency violates RNPS/WNPS
-- Intention:
--   Show that reading/writing package variables conflicts with RNPS/WNPS claims.
--------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE pr_stateful AS
  g_rate NUMBER := 0.05; -- package state
  FUNCTION price_with_rate(p_amount IN NUMBER) RETURN NUMBER;
  -- If we claimed RNPS/WNPS, it would be wrong because function reads g_rate.
END pr_stateful;
/

CREATE OR REPLACE PACKAGE BODY pr_stateful AS
  FUNCTION price_with_rate(p_amount IN NUMBER) RETURN NUMBER IS
  BEGIN
    RETURN ROUND(NVL(p_amount,0) * (1 + NVL(g_rate,0)), 2);
  END;
END pr_stateful;
/

-- Use in SQL (allowed), but purity contract must not incorrectly claim RNPS.
SELECT order_id, pr_stateful.price_with_rate(amount) total
  FROM pr_orders
 ORDER BY order_id;
/

--------------------------------------------------------------------------------
-- Example 5: Modern alternative — pure function + DETERMINISTIC
-- Intention:
--   Instead of using pragma flags, design a side-effect-free function and mark DETERMINISTIC.
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION pr_norm_status(p IN VARCHAR2)
  RETURN VARCHAR2 DETERMINISTIC
IS
BEGIN
  RETURN UPPER(TRIM(p));
END;
/
SELECT pr_norm_status(' paid ') FROM dual;
/

--------------------------------------------------------------------------------
-- Example 6: RESULT_CACHE for read-mostly lookups
-- Intention:
--   Cache mapping of order_id -> status for repeated calls (if server cache enabled).
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION pr_status_cached(p_id IN pr_orders.order_id%TYPE)
  RETURN VARCHAR2
  RESULT_CACHE RELIES_ON (pr_orders)
IS
  v pr_orders.status%TYPE;
BEGIN
  SELECT status INTO v FROM pr_orders WHERE order_id = p_id;
  RETURN v;
EXCEPTION
  WHEN NO_DATA_FOUND THEN RETURN 'UNKNOWN';
END;
/
BEGIN
  DBMS_OUTPUT.PUT_LINE('first='||pr_status_cached(1));
  DBMS_OUTPUT.PUT_LINE('second='||pr_status_cached(1));
END;
/
--------------------------------------------------------------------------------
-- End of File
--------------------------------------------------------------------------------
