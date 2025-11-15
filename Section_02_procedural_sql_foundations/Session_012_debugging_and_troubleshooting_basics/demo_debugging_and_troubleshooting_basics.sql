-- demo_debugging_and_troubleshooting_basics.sql
-- Session : 012_debugging_and_troubleshooting_basics
-- Topic   : Debugging and Troubleshooting in PL/SQL
-- Purpose : Demonstrate structured debugging techniques similar to Session_010 style.
-- Includes: DBMS_OUTPUT tracing, SQLCODE/SQLERRM, custom errors, nested block debugging,
--           variable inspection and controlled failure simulations.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Demo 1: Structured Debug Trace with Detailed Step Logging
--------------------------------------------------------------------------------
DECLARE
  v_num NUMBER := 10;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 1: Starting debug trace');
  DBMS_OUTPUT.PUT_LINE('Step 1: v_num initial = ' || v_num);

  v_num := v_num + 25;
  DBMS_OUTPUT.PUT_LINE('Step 2: v_num updated = ' || v_num);

  v_num := v_num * 2;
  DBMS_OUTPUT.PUT_LINE('Step 3: v_num multiplied = ' || v_num);

  DBMS_OUTPUT.PUT_LINE('Demo 1: Ending debug trace');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 2: Capturing Exceptions Using SQLCODE and SQLERRM
--------------------------------------------------------------------------------
DECLARE
  v_res NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 2: Forcing a divide‑by‑zero error');

  v_res := 100 / 0;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Demo 2: ERROR DETECTED');
    DBMS_OUTPUT.PUT_LINE('  Error Code    = ' || SQLCODE);
    DBMS_OUTPUT.PUT_LINE('  Error Message = ' || SQLERRM);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 3: Debugging Variable Scope in Nested Blocks
--------------------------------------------------------------------------------
DECLARE
  v_value NUMBER := 50;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 3: Outer block v_value = ' || v_value);

  DECLARE
    v_value NUMBER := 200;
  BEGIN
    DBMS_OUTPUT.PUT_LINE('Demo 3: Inner block v_value = ' || v_value);
  END;

  DBMS_OUTPUT.PUT_LINE('Demo 3: After inner block, outer v_value = ' || v_value);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 4: Using RAISE_APPLICATION_ERROR for Controlled Failures
--------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 4: Triggering custom error via RAISE_APPLICATION_ERROR');

  RAISE_APPLICATION_ERROR(-20100, 'Demo 4: Custom debugging error raised intentionally');

END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 5: Step‑By‑Step Validation Debug Trace
--------------------------------------------------------------------------------
DECLARE
  v_a NUMBER := 12;
  v_b NUMBER := 0;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 5: Begin computation debug trace');

  DBMS_OUTPUT.PUT_LINE('  Step 1: v_a = ' || v_a);
  DBMS_OUTPUT.PUT_LINE('  Step 2: v_b = ' || v_b);

  v_a := v_a + 8;
  DBMS_OUTPUT.PUT_LINE('  Step 3: v_a updated = ' || v_a);

  IF v_b = 0 THEN
    DBMS_OUTPUT.PUT_LINE('  Step 4: Cannot divide by zero, skipping calculation');
  ELSE
    DBMS_OUTPUT.PUT_LINE('  Step 4: Division result = ' || (v_a / v_b));
  END IF;

  DBMS_OUTPUT.PUT_LINE('Demo 5: End of debug trace');
END;
/
--------------------------------------------------------------------------------
