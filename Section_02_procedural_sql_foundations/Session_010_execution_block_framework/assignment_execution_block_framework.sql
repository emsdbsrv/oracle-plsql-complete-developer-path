-- assignment_execution_block_framework.sql
-- Session : 010_execution_block_framework
-- Topic   : Practice on PL/SQL execution block structure
-- Purpose : Reinforce usage of DECLARE, BEGIN, EXCEPTION, END,
--           nested blocks, variable scope, and exceptions.
-- Style   : Each assignment provides a full example with detailed
--           comments and explanations so learners can follow step by step.

SET SERVEROUTPUT ON;



/**************************************************************************
 Assignment 1:
 -------------
 Problem:
   1. Write a simple anonymous block with DECLARE, BEGIN, and END.
   2. Declare a variable v_topic and assign the text
      'PL/SQL Execution Block Framework'.
   3. Print the topic with DBMS_OUTPUT.
**************************************************************************/
DECLARE
  v_topic VARCHAR2(100) := 'PL/SQL Execution Block Framework';
BEGIN
  DBMS_OUTPUT.PUT_LINE('Assignment 1: Topic = ' || v_topic);
END;
/
-------------------------------------------------------------------------------



/**************************************************************************
 Assignment 2:
 -------------
 Problem:
   1. Create a block that uses DECLARE, BEGIN, and EXCEPTION sections.
   2. In the BEGIN section, print a message saying that the block started.
   3. Do a simple arithmetic operation that does not fail.
   4. In EXCEPTION, handle WHEN OTHERS and print SQLERRM
      only if an error occurs.
**************************************************************************/
DECLARE
  v_num1 NUMBER := 20;
  v_num2 NUMBER := 5;
  v_result NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Assignment 2: Block started.');

  v_result := v_num1 / v_num2;

  DBMS_OUTPUT.PUT_LINE('Assignment 2: Result of division = ' || v_result);
  DBMS_OUTPUT.PUT_LINE('Assignment 2: Block completed without errors.');

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Assignment 2: Error occurred: ' || SQLERRM);
END;
/
-------------------------------------------------------------------------------



/**************************************************************************
 Assignment 3:
 -------------
 Problem:
   1. Intentionally cause a ZERO_DIVIDE error in the BEGIN section.
   2. Handle the ZERO_DIVIDE exception specifically.
   3. Print a friendly message when the exception is caught.
   4. Also use WHEN OTHERS as a safety net for unexpected errors.
**************************************************************************/
DECLARE
  v_numerator   NUMBER := 50;
  v_denominator NUMBER := 0;
  v_result      NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Assignment 3: Attempting division by zero for demo.');

  v_result := v_numerator / v_denominator;

  DBMS_OUTPUT.PUT_LINE('Assignment 3: Result = ' || v_result); -- will not run

EXCEPTION
  WHEN ZERO_DIVIDE THEN
    DBMS_OUTPUT.PUT_LINE('Assignment 3: Caught ZERO_DIVIDE. Division by zero is not allowed.');
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Assignment 3: Some other error occurred: ' || SQLERRM);
END;
/
-------------------------------------------------------------------------------



/**************************************************************************
 Assignment 4:
 -------------
 Problem:
   1. Use nested blocks to demonstrate scope.
   2. Outer block declares v_message = 'Outer block'.
   3. Inner block declares v_message = 'Inner block'.
   4. Print from both blocks and show which value is visible where.
**************************************************************************/
DECLARE
  v_message VARCHAR2(50) := 'Outer block';
BEGIN
  DBMS_OUTPUT.PUT_LINE('Assignment 4 (outer): v_message = ' || v_message);

  DECLARE
    v_message VARCHAR2(50) := 'Inner block';
  BEGIN
    DBMS_OUTPUT.PUT_LINE('Assignment 4 (inner): v_message = ' || v_message);
  END;

  DBMS_OUTPUT.PUT_LINE('Assignment 4 (outer after inner): v_message = ' || v_message);
END;
/
-------------------------------------------------------------------------------



/**************************************************************************
 Assignment 5:
 -------------
 Problem:
   1. Demonstrate an inner block that can see a variable from the outer
      block, but not vice versa.
   2. Outer block declares v_outer_value.
   3. Inner block declares v_inner_value and prints both.
   4. Attempting to print v_inner_value from the outer block should be
      avoided (it would cause a compilation error). Instead, just show
      correct usage in comments.
**************************************************************************/
DECLARE
  v_outer_value NUMBER := 10;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Assignment 5 (outer): v_outer_value = ' || v_outer_value);

  DECLARE
    v_inner_value NUMBER := 20;
  BEGIN
    DBMS_OUTPUT.PUT_LINE('Assignment 5 (inner): v_outer_value = ' || v_outer_value);
    DBMS_OUTPUT.PUT_LINE('Assignment 5 (inner): v_inner_value = ' || v_inner_value);
  END;

  -- The following line would cause an error because v_inner_value
  -- is not visible here in the outer block scope:
  -- DBMS_OUTPUT.PUT_LINE(v_inner_value);
  DBMS_OUTPUT.PUT_LINE('Assignment 5 (outer): v_inner_value is not visible here.');
END;
/
-------------------------------------------------------------------------------



/**************************************************************************
 Assignment 6:
 -------------
 Problem:
   1. Create a block that uses WHEN OTHERS to catch any unexpected error.
   2. Inside BEGIN, intentionally reference a non-existent table to cause
      an exception.
   3. In the EXCEPTION section, print SQLCODE and SQLERRM.
**************************************************************************/
DECLARE
  v_dummy NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Assignment 6: About to select from a non-existent table.');

  -- This will raise ORA-00942 (table or view does not exist).
  SELECT 1
    INTO v_dummy
    FROM table_that_does_not_exist;

  DBMS_OUTPUT.PUT_LINE('Assignment 6: This line will never execute.');

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Assignment 6: Error code   = ' || SQLCODE);
    DBMS_OUTPUT.PUT_LINE('Assignment 6: Error message = ' || SQLERRM);
END;
/
-------------------------------------------------------------------------------



/**************************************************************************
 Assignment 7:
 -------------
 Problem:
   1. Declare a user-defined exception e_invalid_score.
   2. Declare v_score and set it to a value greater than 100 (for example 120).
   3. If v_score > 100 OR v_score < 0, raise e_invalid_score.
   4. Handle e_invalid_score and print a friendly error message.
**************************************************************************/
DECLARE
  v_score NUMBER := 120;
  e_invalid_score EXCEPTION;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Assignment 7: Validating score = ' || v_score);

  IF v_score > 100 OR v_score < 0 THEN
    RAISE e_invalid_score;
  END IF;

  DBMS_OUTPUT.PUT_LINE('Assignment 7: Score is valid.');

EXCEPTION
  WHEN e_invalid_score THEN
    DBMS_OUTPUT.PUT_LINE('Assignment 7: Invalid score. It must be between 0 and 100.');
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Assignment 7: Unexpected error: ' || SQLERRM);
END;
/
-------------------------------------------------------------------------------



/**************************************************************************
 Assignment 8:
 -------------
 Problem:
   1. Declare v_employee_name and v_employee_salary.
   2. In a BEGIN block, print them, then deliberately raise an error using
      RAISE_APPLICATION_ERROR (for example with error number -20001).
   3. Catch the error in EXCEPTION using WHEN OTHERS and print SQLERRM.
**************************************************************************/
DECLARE
  v_employee_name   VARCHAR2(50) := 'Sample Employee';
  v_employee_salary NUMBER       := 45000;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Assignment 8: Employee Name   = ' || v_employee_name);
  DBMS_OUTPUT.PUT_LINE('Assignment 8: Employee Salary = ' || v_employee_salary);

  -- Simulate a business rule violation using RAISE_APPLICATION_ERROR.
  RAISE_APPLICATION_ERROR(-20001, 'Assignment 8: Simulated application error for demo.');

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Assignment 8: Error captured in EXCEPTION section.');
    DBMS_OUTPUT.PUT_LINE('Assignment 8: SQLCODE = ' || SQLCODE);
    DBMS_OUTPUT.PUT_LINE('Assignment 8: SQLERRM = ' || SQLERRM);
END;
/
-------------------------------------------------------------------------------



/**************************************************************************
 Assignment 9:
 -------------
 Problem:
   1. Write a nested block where the inner block has its own EXCEPTION section.
   2. Inner block should attempt division by zero and handle ZERO_DIVIDE.
   3. Outer block should simply print a message before and after the inner
      block execution to show control flow.
**************************************************************************/
BEGIN
  DBMS_OUTPUT.PUT_LINE('Assignment 9 (outer): Starting outer block.');

  DECLARE
    v_num1 NUMBER := 5;
    v_num2 NUMBER := 0;
    v_result NUMBER;
  BEGIN
    DBMS_OUTPUT.PUT_LINE('Assignment 9 (inner): About to divide 5 by 0.');

    v_result := v_num1 / v_num2;

    DBMS_OUTPUT.PUT_LINE('Assignment 9 (inner): Result = ' || v_result);

  EXCEPTION
    WHEN ZERO_DIVIDE THEN
      DBMS_OUTPUT.PUT_LINE('Assignment 9 (inner): Caught ZERO_DIVIDE inside inner block.');
  END;

  DBMS_OUTPUT.PUT_LINE('Assignment 9 (outer): Inner block completed.');
END;
/
-------------------------------------------------------------------------------



/**************************************************************************
 Assignment 10:
 --------------
 Problem:
   1. Create a block with:
        - A DECLARE section with two variables: v_limit and v_current.
        - A BEGIN section that checks if v_current exceeds v_limit.
        - If v_current > v_limit, raise a user-defined exception e_limit_exceeded.
   2. In the EXCEPTION section, handle e_limit_exceeded and print a message.
**************************************************************************/
DECLARE
  v_limit         NUMBER := 1000;
  v_current       NUMBER := 1500;
  e_limit_exceeded EXCEPTION;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Assignment 10: Limit = ' || v_limit || ', Current = ' || v_current);

  IF v_current > v_limit THEN
    RAISE e_limit_exceeded;
  END IF;

  DBMS_OUTPUT.PUT_LINE('Assignment 10: Current value is within limit.');

EXCEPTION
  WHEN e_limit_exceeded THEN
    DBMS_OUTPUT.PUT_LINE('Assignment 10: e_limit_exceeded raised - current value is above the limit.');
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Assignment 10: Unexpected error: ' || SQLERRM);
END;
/
-------------------------------------------------------------------------------
