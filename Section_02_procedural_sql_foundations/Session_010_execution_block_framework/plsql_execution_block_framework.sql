-- Script: plsql_execution_block_framework.sql
-- Objective: Demonstrate PL/SQL Execution Block Concepts

SET SERVEROUTPUT ON;

-- Example 1: Basic block
BEGIN
  DBMS_OUTPUT.PUT_LINE('Hello, PL/SQL World!');
END;
/

-- Example 2: Block with variable declaration and math
DECLARE
  v_num1 NUMBER := 10;
  v_num2 NUMBER := 20;
  v_sum  NUMBER;
BEGIN
  v_sum := v_num1 + v_num2;
  DBMS_OUTPUT.PUT_LINE('Sum of numbers: ' || v_sum);
END;
/

-- Example 3: Nested block with variable scope
DECLARE
  v_outer VARCHAR2(30) := 'Outer Value';
BEGIN
  DBMS_OUTPUT.PUT_LINE(v_outer);
  DECLARE
    v_inner VARCHAR2(30) := 'Inner Value';
  BEGIN
    DBMS_OUTPUT.PUT_LINE(v_inner);
  END;
  DBMS_OUTPUT.PUT_LINE('Back to outer scope');
END;
/

-- Example 4: Exception handling
BEGIN
  DBMS_OUTPUT.PUT_LINE('Attempting division by zero');
  DBMS_OUTPUT.PUT_LINE(100/0);
EXCEPTION
  WHEN ZERO_DIVIDE THEN
    DBMS_OUTPUT.PUT_LINE('Caught division by zero error');
END;
/

-- Example 5: User-defined exception
DECLARE
  e_low_salary EXCEPTION;
  v_salary NUMBER := 1500;
BEGIN
  IF v_salary < 3000 THEN
    RAISE e_low_salary;
  END IF;
  DBMS_OUTPUT.PUT_LINE('Salary check passed.');
EXCEPTION
  WHEN e_low_salary THEN
    DBMS_OUTPUT.PUT_LINE('Error: Salary too low for operation.');
END;
/