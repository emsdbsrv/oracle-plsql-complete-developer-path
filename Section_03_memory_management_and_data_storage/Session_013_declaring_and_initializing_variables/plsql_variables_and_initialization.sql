-- Script: plsql_variables_and_initialization.sql
-- Session: 013 - Declaring and Initializing Variables
-- Purpose : Explore variable declaration, initialization, and scope in PL/SQL.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Example 1: Basic Variable Declaration and Output
-- Concept : Declare a single variable and print its value.
--------------------------------------------------------------------------------
DECLARE
  v_message VARCHAR2(50) := 'Hello from PL/SQL variable!';
BEGIN
  DBMS_OUTPUT.PUT_LINE(v_message);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 2: Arithmetic Initialization Using Expressions
-- Concept : Initialize variable using arithmetic expressions.
--------------------------------------------------------------------------------
DECLARE
  v_price  NUMBER := 150;
  v_qty    NUMBER := 3;
  v_total  NUMBER;
BEGIN
  v_total := v_price * v_qty;
  DBMS_OUTPUT.PUT_LINE('Total price = ' || v_total);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 3: Using Constants and NOT NULL Variables
-- Concept : Define constants and ensure variables are initialized immediately.
--------------------------------------------------------------------------------
DECLARE
  c_tax_rate CONSTANT NUMBER := 0.18;  -- constant must be initialized
  v_subtotal NUMBER := 1000;
  v_tax      NUMBER;
BEGIN
  v_tax := v_subtotal * c_tax_rate;
  DBMS_OUTPUT.PUT_LINE('Tax amount = ' || v_tax);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 4: Using %TYPE to Match Table Column Data Types
-- Concept : Declare variables based on existing table columns.
--------------------------------------------------------------------------------
DECLARE
  v_emp_name employees.first_name%TYPE;
  v_salary   employees.salary%TYPE;
BEGIN
  SELECT first_name, salary INTO v_emp_name, v_salary
  FROM employees
  WHERE ROWNUM = 1;

  DBMS_OUTPUT.PUT_LINE('Employee: ' || v_emp_name || ', Salary: ' || v_salary);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('No data available in employees table.');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 5: Nested Block Variable Scope
-- Concept : Demonstrate variable shadowing and scoping rules.
--------------------------------------------------------------------------------
DECLARE
  v_counter NUMBER := 10;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Outer counter = ' || v_counter);

  DECLARE
    v_counter NUMBER := 20; -- same name, local to inner block
  BEGIN
    DBMS_OUTPUT.PUT_LINE('Inner counter = ' || v_counter);
  END;

  DBMS_OUTPUT.PUT_LINE('After inner block, outer counter = ' || v_counter);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 6: Using SELECT INTO for Initialization
-- Concept : Assign value from query result into a variable.
--------------------------------------------------------------------------------
DECLARE
  v_today DATE;
BEGIN
  SELECT SYSDATE INTO v_today FROM dual;
  DBMS_OUTPUT.PUT_LINE('Today''s date: ' || TO_CHAR(v_today, 'DD-MON-YYYY'));
END;
/
--------------------------------------------------------------------------------
-- End of File
--------------------------------------------------------------------------------
