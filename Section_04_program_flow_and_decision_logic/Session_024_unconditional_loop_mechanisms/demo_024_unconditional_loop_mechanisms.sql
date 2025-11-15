-- demo_024_unconditional_loop_mechanisms.sql
-- Session : 024_unconditional_loop_mechanisms
-- Topic   : Unconditional LOOP, EXIT, EXIT WHEN
-- Purpose : Show LOOP structure where termination is controlled from inside.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Demo 1: Basic LOOP with EXIT WHEN
--------------------------------------------------------------------------------
DECLARE
  v_counter NUMBER := 1;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 1: LOOP with EXIT WHEN v_counter > 5');

  LOOP
    DBMS_OUTPUT.PUT_LINE('  Counter = ' || v_counter);
    v_counter := v_counter + 1;

    EXIT WHEN v_counter > 5;
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 2: LOOP that runs until a condition is met (search pattern)
--------------------------------------------------------------------------------
DECLARE
  v_num    NUMBER := 1;
  v_found  BOOLEAN := FALSE;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 2: Find first number whose square > 50');

  LOOP
    IF v_num * v_num > 50 THEN
      v_found := TRUE;
      DBMS_OUTPUT.PUT_LINE('  Found number = ' || v_num);
      EXIT;
    END IF;

    v_num := v_num + 1;
  END LOOP;

  IF NOT v_found THEN
    DBMS_OUTPUT.PUT_LINE('  No number found (this will not happen here).');
  END IF;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 3: Simulating DO-WHILE behaviour
-- Concept:
--   Execute body at least once, then check condition and EXIT.
--------------------------------------------------------------------------------
DECLARE
  v_value NUMBER := 1;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 3: Simulated DO-WHILE using LOOP');

  LOOP
    DBMS_OUTPUT.PUT_LINE('  Value = ' || v_value);
    v_value := v_value + 1;

    EXIT WHEN v_value > 3; -- condition checked at bottom
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 4: LOOP with multiple EXIT points
--------------------------------------------------------------------------------
DECLARE
  v_counter NUMBER := 0;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 4: LOOP with different EXIT scenarios');

  LOOP
    v_counter := v_counter + 1;

    IF v_counter = 3 THEN
      DBMS_OUTPUT.PUT_LINE('  Reached special point at 3.');
    ELSIF v_counter = 5 THEN
      DBMS_OUTPUT.PUT_LINE('  Reached 5, exiting loop.');
      EXIT;
    END IF;

    DBMS_OUTPUT.PUT_LINE('  Current value = ' || v_counter);
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 5: Infinite-looking loop with safe EXIT WHEN (guard condition)
--------------------------------------------------------------------------------
DECLARE
  v_attempts NUMBER := 0;
  v_max_attempts CONSTANT NUMBER := 5;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 5: LOOP with guard using EXIT WHEN');

  LOOP
    v_attempts := v_attempts + 1;
    DBMS_OUTPUT.PUT_LINE('  Iteration #' || v_attempts);

    -- Guard: ensure we always exit when attempts exceed maximum.
    EXIT WHEN v_attempts >= v_max_attempts;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('  Loop finished after ' || v_attempts || ' iterations.');
END;
/
--------------------------------------------------------------------------------
