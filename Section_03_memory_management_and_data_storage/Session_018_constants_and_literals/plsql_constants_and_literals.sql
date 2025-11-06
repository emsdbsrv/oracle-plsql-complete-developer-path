-- Script: plsql_constants_and_literals.sql
-- Session: 018 - Constants and Literals
-- Purpose: Demonstrate CONSTANT declarations and literal usage with best practices.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Example 1: Basic CONSTANTS (numeric) and usage
--------------------------------------------------------------------------------
DECLARE
  c_tax_rate CONSTANT NUMBER := 0.18;
  c_pi       CONSTANT NUMBER := 3.14159;
  v_price    NUMBER := 1000;
  v_total    NUMBER;
BEGIN
  v_total := v_price + (v_price * c_tax_rate);
  DBMS_OUTPUT.PUT_LINE('Total with tax = ' || v_total);
  DBMS_OUTPUT.PUT_LINE('Pi constant    = ' || c_pi);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 2: Character, Date/Time and Boolean literals
--------------------------------------------------------------------------------
DECLARE
  v_msg   VARCHAR2(50) := 'Hello, PL/SQL!';
  v_quote VARCHAR2(50) := q'[John's bike]';
  v_date  DATE         := DATE '2025-11-06';
  v_ts    TIMESTAMP    := TIMESTAMP '2025-11-06 17:30:00';
  v_on    BOOLEAN      := TRUE;
BEGIN
  DBMS_OUTPUT.PUT_LINE(v_msg);
  DBMS_OUTPUT.PUT_LINE(v_quote);
  DBMS_OUTPUT.PUT_LINE('DATE literal = ' || TO_CHAR(v_date, 'DD-MON-YYYY'));
  DBMS_OUTPUT.PUT_LINE('TS literal   = ' || TO_CHAR(v_ts, 'DD-MON-YYYY HH24:MI:SS'));
  DBMS_OUTPUT.PUT_LINE('Boolean flag = ' || CASE WHEN v_on THEN 'TRUE' ELSE 'FALSE' END);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 3: %TYPE with CONSTANT for schema-aligned typing
-- Note: Requires EMPLOYEES table; otherwise handle NO_DATA_FOUND in Example 4.
--------------------------------------------------------------------------------
DECLARE
  c_max_salary CONSTANT employees.salary%TYPE := 200000;
  v_salary     employees.salary%TYPE;
BEGIN
  -- Hypothetical fetch of first salary
  SELECT salary INTO v_salary FROM employees WHERE ROWNUM = 1;
  IF v_salary > c_max_salary THEN
    DBMS_OUTPUT.PUT_LINE('Salary exceeds allowed cap.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Salary within cap.');
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('No employee rows found; skipping check.');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 4: Derived CONSTANTS from expressions
--------------------------------------------------------------------------------
DECLARE
  c_base_price CONSTANT NUMBER := 250;
  c_discount   CONSTANT NUMBER := 0.20;
  c_net_price  CONSTANT NUMBER := c_base_price * (1 - c_discount);
BEGIN
  DBMS_OUTPUT.PUT_LINE('Base   = ' || c_base_price);
  DBMS_OUTPUT.PUT_LINE('Disc   = ' || c_discount);
  DBMS_OUTPUT.PUT_LINE('Net    = ' || c_net_price);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 5: Scoped constants (inner block shadowing)
--------------------------------------------------------------------------------
DECLARE
  c_rate CONSTANT NUMBER := 0.10;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Outer rate = ' || c_rate);
  DECLARE
    c_rate CONSTANT NUMBER := 0.15; -- shadows outer constant
  BEGIN
    DBMS_OUTPUT.PUT_LINE('Inner rate = ' || c_rate);
  END;
  DBMS_OUTPUT.PUT_LINE('Back to outer rate = ' || c_rate);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 6: Quoted string literal convenience with q'[ ]'
--------------------------------------------------------------------------------
DECLARE
  v_text VARCHAR2(200) := q'[She said, "It's fine!"]';
BEGIN
  DBMS_OUTPUT.PUT_LINE(v_text);
END;
/
--------------------------------------------------------------------------------
-- End of File
--------------------------------------------------------------------------------
