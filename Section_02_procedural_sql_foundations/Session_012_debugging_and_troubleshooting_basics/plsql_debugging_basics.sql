-- Script: plsql_debugging_basics.sql
-- Session: 012 - Debugging and Troubleshooting Basics
-- Purpose : Demonstrate different debugging and exception techniques

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Example 1: Simple Block with Syntax Error (fixed)
-- Concept : Understanding compilation errors.
--------------------------------------------------------------------------------
-- Wrong: BEGIIN instead of BEGIN (will cause syntax error)
-- Corrected version below:
BEGIN
  DBMS_OUTPUT.PUT_LINE('Syntax error fixed successfully.');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 2: Catching ZERO_DIVIDE Exception
-- Concept : Using EXCEPTION block to handle runtime errors.
--------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('Attempting division...');
  DBMS_OUTPUT.PUT_LINE(10/0);
EXCEPTION
  WHEN ZERO_DIVIDE THEN
    DBMS_OUTPUT.PUT_LINE('Error handled: Division by zero not allowed.');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 3: Using SQLERRM for Dynamic Error Messages
-- Concept : Retrieve and print the actual Oracle error message.
--------------------------------------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE fake_table';
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error Code: ' || SQLCODE);
    DBMS_OUTPUT.PUT_LINE('Error Message: ' || SQLERRM);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 4: Using RAISE_APPLICATION_ERROR for Custom Errors
-- Concept : Define and raise custom application-level exceptions.
--------------------------------------------------------------------------------
BEGIN
  RAISE_APPLICATION_ERROR(-20001, 'Custom error: Invalid operation detected!');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Custom error handled -> ' || SQLERRM);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 5: Nested Exception Handling
-- Concept : Using inner and outer blocks for controlled debugging.
--------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('Entering outer block...');
  BEGIN
    DBMS_OUTPUT.PUT_LINE('Entering inner block...');
    DBMS_OUTPUT.PUT_LINE(5/0); -- Will raise ZERO_DIVIDE
  EXCEPTION
    WHEN ZERO_DIVIDE THEN
      DBMS_OUTPUT.PUT_LINE('Inner block handled division error.');
  END;
  DBMS_OUTPUT.PUT_LINE('Continuing after inner block.');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Outer block caught unexpected error: ' || SQLERRM);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 6: Using DBMS_OUTPUT for Step-by-Step Debugging
-- Concept : Printing variable values to trace logic flow.
--------------------------------------------------------------------------------
DECLARE
  v_counter NUMBER := 0;
BEGIN
  FOR i IN 1..3 LOOP
    v_counter := v_counter + 1;
    DBMS_OUTPUT.PUT_LINE('Processing iteration: ' || v_counter);
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('Final counter = ' || v_counter);
END;
/
--------------------------------------------------------------------------------
-- End of File
--------------------------------------------------------------------------------
