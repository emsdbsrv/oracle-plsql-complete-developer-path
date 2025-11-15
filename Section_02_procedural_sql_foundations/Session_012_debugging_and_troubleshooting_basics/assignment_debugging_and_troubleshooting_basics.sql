-- assignment_debugging_and_troubleshooting_basics.sql
-- Session : 012_debugging_and_troubleshooting_basics
-- Topic   : Debugging and Troubleshooting Assignments
-- Purpose : 10 detailed assignments with structured comments and explanations.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Assignment 1: Print variable states at multiple debug checkpoints
--------------------------------------------------------------------------------
DECLARE
  v_x NUMBER := 5;
  v_y NUMBER := 15;
BEGIN
  DBMS_OUTPUT.PUT_LINE('A1‑Debug: Initial v_x = ' || v_x);
  DBMS_OUTPUT.PUT_LINE('A1‑Debug: Initial v_y = ' || v_y);

  v_x := v_x + 10;
  v_y := v_y * 2;

  DBMS_OUTPUT.PUT_LINE('A1‑Debug: Updated v_x = ' || v_x);
  DBMS_OUTPUT.PUT_LINE('A1‑Debug: Updated v_y = ' || v_y);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 2: Catch divide‑by‑zero and print SQLERRM + SQLCODE
--------------------------------------------------------------------------------
DECLARE
  v_res NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('A2: About to divide by zero');
  v_res := 100 / 0;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('A2‑Error Code: ' || SQLCODE);
    DBMS_OUTPUT.PUT_LINE('A2‑Error Msg : ' || SQLERRM);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 3: Debug conversion error using nested exceptions
--------------------------------------------------------------------------------
DECLARE
  v_text VARCHAR2(10) := 'XYZ';
  v_num  NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('A3: Starting conversion');

  BEGIN
    v_num := TO_NUMBER(v_text);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('A3‑Debug: Conversion failed: ' || SQLERRM);
  END;

END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 4: Insert debug markers in a computation flow
--------------------------------------------------------------------------------
DECLARE
  v_a NUMBER := 20;
  v_b NUMBER := 30;
  v_sum NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('A4‑Step 1: Starting block');
  v_sum := v_a + v_b;
  DBMS_OUTPUT.PUT_LINE('A4‑Step 2: Computed sum = ' || v_sum);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 5: Generate custom error if age is invalid
--------------------------------------------------------------------------------
DECLARE
  v_age NUMBER := -3;
BEGIN
  IF v_age < 0 THEN
    RAISE_APPLICATION_ERROR(-20025, 'A5: Age cannot be negative');
  END IF;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 6: Debug loop execution with EXIT WHEN
--------------------------------------------------------------------------------
DECLARE
  v_i NUMBER := 1;
BEGIN
  DBMS_OUTPUT.PUT_LINE('A6: Entering LOOP');
  LOOP
    DBMS_OUTPUT.PUT_LINE('A6‑Loop Iteration = ' || v_i);
    EXIT WHEN v_i = 6;
    v_i := v_i + 1;
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 7: Debug nested block variable shadowing
--------------------------------------------------------------------------------
DECLARE
  v_val NUMBER := 99;
BEGIN
  DBMS_OUTPUT.PUT_LINE('A7‑Outer v_val = ' || v_val);

  DECLARE
    v_val NUMBER := 199;
  BEGIN
    DBMS_OUTPUT.PUT_LINE('A7‑Inner v_val = ' || v_val);
  END;

  DBMS_OUTPUT.PUT_LINE('A7‑Outer v_val remains = ' || v_val);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 8: Identify exception and print full error trace
--------------------------------------------------------------------------------
DECLARE
  v_n NUMBER;
BEGIN
  v_n := 50 / 0;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('A8‑Trace: Code=' || SQLCODE);
    DBMS_OUTPUT.PUT_LINE('A8‑Trace: Msg =' || SQLERRM);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 9: Add debug points inside IF logic
--------------------------------------------------------------------------------
DECLARE
  v_marks NUMBER := 42;
BEGIN
  DBMS_OUTPUT.PUT_LINE('A9‑Debug: Checking marks = ' || v_marks);

  IF v_marks >= 50 THEN
    DBMS_OUTPUT.PUT_LINE('A9: Result = Pass');
  ELSE
    DBMS_OUTPUT.PUT_LINE('A9: Result = Fail');
  END IF;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 10: Step‑by‑step trace of variable transformations
--------------------------------------------------------------------------------
DECLARE
  v_counter NUMBER := 10;
BEGIN
  DBMS_OUTPUT.PUT_LINE('A10‑Step 1: v_counter = ' || v_counter);

  v_counter := v_counter + 7;
  DBMS_OUTPUT.PUT_LINE('A10‑Step 2: After +7 = ' || v_counter);

  v_counter := v_counter * 3;
  DBMS_OUTPUT.PUT_LINE('A10‑Step 3: After ×3 = ' || v_counter);

  v_counter := v_counter - 5;
  DBMS_OUTPUT.PUT_LINE('A10‑Step 4: Final value = ' || v_counter);
END;
/
--------------------------------------------------------------------------------
