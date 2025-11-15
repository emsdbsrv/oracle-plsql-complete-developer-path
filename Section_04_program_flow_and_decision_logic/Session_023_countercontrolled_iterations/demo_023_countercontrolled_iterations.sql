-- demo_023_countercontrolled_iterations.sql
-- Session : 023_countercontrolled_iterations
-- Topic   : Counter-Controlled Iterations (FOR loops with counters)
-- Purpose : Use loop counters to control exact number of repetitions.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Demo 1: Simple counter-controlled FOR loop
--------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 1: Counter-controlled loop 1..5');

  FOR v_counter IN 1 .. 5 LOOP
    DBMS_OUTPUT.PUT_LINE('  Counter = ' || v_counter);
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 2: Counter-controlled loop for cumulative sum
--------------------------------------------------------------------------------
DECLARE
  v_sum NUMBER := 0;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 2: Sum of first 10 natural numbers');

  FOR v_counter IN 1 .. 10 LOOP
    v_sum := v_sum + v_counter;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('  Sum = ' || v_sum);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 3: Using step-like behaviour inside FOR loop
--------------------------------------------------------------------------------
DECLARE
  v_value NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 3: Printing every 3rd number from 3 to 30');

  FOR v_counter IN 1 .. 10 LOOP
    v_value := v_counter * 3;
    DBMS_OUTPUT.PUT_LINE('  Value = ' || v_value);
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 4: Reverse counter-controlled FOR loop
--------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 4: Reverse loop 10..1');

  FOR v_counter IN REVERSE 1 .. 10 LOOP
    DBMS_OUTPUT.PUT_LINE('  Counter = ' || v_counter);
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 5: Counter-controlled loop with conditional logic inside
--------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 5: Counter with conditional labeling');

  FOR v_counter IN 1 .. 10 LOOP
    IF MOD(v_counter, 2) = 0 THEN
      DBMS_OUTPUT.PUT_LINE('  ' || v_counter || ' -> EVEN');
    ELSE
      DBMS_OUTPUT.PUT_LINE('  ' || v_counter || ' -> ODD');
    END IF;
  END LOOP;
END;
/
--------------------------------------------------------------------------------
