-- demo_execution_block_framework.sql
-- Session : 010_execution_block_framework
-- Topic   : PL/SQL Execution Block Framework
-- Purpose : Understand the structure of PL/SQL anonymous blocks and
--           how DECLARE, BEGIN, EXCEPTION, and END work together.
-- Focus   : Basic block, exception section, nested blocks, variable scope,
--           user-defined exceptions, SQLCODE and SQLERRM.

SET SERVEROUTPUT ON;



--------------------------------------------------------------------------------
-- Demo 1: Full Anonymous Block Structure (DECLARE-BEGIN-EXCEPTION-END)
-- Goal:
--   See the complete structure of a PL/SQL anonymous block:
--     DECLARE   -- optional
--       -- variable declarations
--     BEGIN
--       -- executable statements
--     EXCEPTION -- optional
--       -- error handling
--     END;
--------------------------------------------------------------------------------
DECLARE
  v_message VARCHAR2(100) := 'Demo 1: Basic execution block with all sections.';
BEGIN
  DBMS_OUTPUT.PUT_LINE(v_message);

  -- This statement executes normally without error.
  DBMS_OUTPUT.PUT_LINE('Demo 1: Everything executed successfully inside BEGIN section.');

EXCEPTION
  WHEN OTHERS THEN
    -- This section would run only if an exception occurs above.
    DBMS_OUTPUT.PUT_LINE('Demo 1: An unexpected error occurred: ' || SQLERRM);
END;
/
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Demo 2: Exception Section Handling a Specific Error (ZERO_DIVIDE)
-- Goal:
--   Learn how EXCEPTION handles specific predefined exceptions.
--   We intentionally cause a divide-by-zero error and handle it.
--------------------------------------------------------------------------------
DECLARE
  v_num1 NUMBER := 10;
  v_num2 NUMBER := 0;
  v_result NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 2: About to divide 10 by 0 to demonstrate ZERO_DIVIDE.');

  -- This will raise ZERO_DIVIDE.
  v_result := v_num1 / v_num2;

  DBMS_OUTPUT.PUT_LINE('Demo 2: Result = ' || v_result); -- this line will not run

EXCEPTION
  WHEN ZERO_DIVIDE THEN
    DBMS_OUTPUT.PUT_LINE('Demo 2: Caught ZERO_DIVIDE exception. Division by zero is not allowed.');
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Demo 2: Some other error occurred: ' || SQLERRM);
END;
/
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Demo 3: Nested Blocks and Variable Scope
-- Goal:
--   Show how inner blocks can have their own variables and how name
--   conflicts are resolved using scope rules.
--------------------------------------------------------------------------------
DECLARE
  v_value NUMBER := 100; -- outer block variable
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 3: Outer block v_value = ' || v_value);

  DECLARE
    v_value NUMBER := 200; -- inner block variable with same name
  BEGIN
    DBMS_OUTPUT.PUT_LINE('Demo 3 (inner): v_value = ' || v_value);
  END;

  -- After inner block ends, we are back to the outer block variable.
  DBMS_OUTPUT.PUT_LINE('Demo 3 (outer after inner): v_value still = ' || v_value);
END;
/
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Demo 4: WHEN OTHERS with SQLCODE and SQLERRM
-- Goal:
--   Understand how to use SQLCODE (numeric error code) and
--   SQLERRM (error message text) in the EXCEPTION section.
--------------------------------------------------------------------------------
DECLARE
  v_dummy NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 4: Intentionally raising an error using 1/0.');

  -- This raises ZERO_DIVIDE, which will be handled by WHEN OTHERS.
  v_dummy := 1 / 0;

  DBMS_OUTPUT.PUT_LINE('Demo 4: This line will never execute.');

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Demo 4: Error code   = ' || SQLCODE);
    DBMS_OUTPUT.PUT_LINE('Demo 4: Error message = ' || SQLERRM);
END;
/
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Demo 5: User-Defined Exception and RAISE
-- Goal:
--   Learn how to:
--     1. Declare your own exception in DECLARE.
--     2. Check a business rule in BEGIN.
--     3. Use RAISE to trigger your custom exception.
--     4. Handle the custom exception in EXCEPTION.
--------------------------------------------------------------------------------
DECLARE
  v_age NUMBER := 15;
  e_underage EXCEPTION; -- user-defined exception
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 5: Validating age = ' || v_age);

  IF v_age < 18 THEN
    -- Business rule: must be at least 18.
    RAISE e_underage;
  END IF;

  DBMS_OUTPUT.PUT_LINE('Demo 5: Age is valid, registration allowed.');

EXCEPTION
  WHEN e_underage THEN
    DBMS_OUTPUT.PUT_LINE('Demo 5: Custom exception e_underage raised - age must be at least 18.');
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Demo 5: Some unexpected error occurred: ' || SQLERRM);
END;
/
--------------------------------------------------------------------------------
