-- assignment_023_countercontrolled_iterations.sql
-- Session : 023_countercontrolled_iterations
-- Topic   : Practice - Counter-Controlled Iterations

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Assignment 1: Print first 10 natural numbers using FOR loop
--------------------------------------------------------------------------------
BEGIN
  FOR v_counter IN 1 .. 10 LOOP
    DBMS_OUTPUT.PUT_LINE('A1: ' || v_counter);
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 2: Compute sum of even numbers 2..20
--------------------------------------------------------------------------------
DECLARE
  v_sum NUMBER := 0;
BEGIN
  FOR v_counter IN 2 .. 20 LOOP
    IF MOD(v_counter, 2) = 0 THEN
      v_sum := v_sum + v_counter;
    END IF;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('A2: Sum of even numbers 2..20 = ' || v_sum);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 3: Print multiplication table of 9 using counter-controlled loop
--------------------------------------------------------------------------------
BEGIN
  FOR v_counter IN 1 .. 10 LOOP
    DBMS_OUTPUT.PUT_LINE('A3: 9 x ' || v_counter || ' = ' || (9 * v_counter));
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 4: Display squares of numbers 1..8
--------------------------------------------------------------------------------
BEGIN
  FOR v_counter IN 1 .. 8 LOOP
    DBMS_OUTPUT.PUT_LINE('A4: ' || v_counter || '^2 = ' || (v_counter * v_counter));
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 5: Reverse FOR loop from 15 down to 5
--------------------------------------------------------------------------------
BEGIN
  FOR v_counter IN REVERSE 5 .. 15 LOOP
    DBMS_OUTPUT.PUT_LINE('A5: ' || v_counter);
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 6: Count multiples of 4 between 1 and 40
--------------------------------------------------------------------------------
DECLARE
  v_count NUMBER := 0;
BEGIN
  FOR v_counter IN 1 .. 40 LOOP
    IF MOD(v_counter, 4) = 0 THEN
      v_count := v_count + 1;
    END IF;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('A6: Multiples of 4 between 1 and 40 = ' || v_count);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 7: Generate simple interest table for different years
--------------------------------------------------------------------------------
DECLARE
  v_principal NUMBER := 10000;
  v_rate      NUMBER := 8; -- percent
  v_interest  NUMBER;
BEGIN
  FOR v_years IN 1 .. 5 LOOP
    v_interest := (v_principal * v_rate * v_years) / 100;
    DBMS_OUTPUT.PUT_LINE('A7: Years=' || v_years ||
                         ', Interest=' || v_interest);
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 8: Print pattern of stars with counter
--------------------------------------------------------------------------------
DECLARE
  v_line VARCHAR2(10);
BEGIN
  FOR v_counter IN 1 .. 5 LOOP
    v_line := RPAD('*', v_counter, '*');
    DBMS_OUTPUT.PUT_LINE('A8: ' || v_line);
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 9: Use FOR loop to find factorial of 5
--------------------------------------------------------------------------------
DECLARE
  v_fact NUMBER := 1;
BEGIN
  FOR v_counter IN 1 .. 5 LOOP
    v_fact := v_fact * v_counter;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('A9: 5! = ' || v_fact);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 10: Use FOR loop with condition to print numbers not divisible by 3
--------------------------------------------------------------------------------
BEGIN
  FOR v_counter IN 1 .. 20 LOOP
    IF MOD(v_counter, 3) != 0 THEN
      DBMS_OUTPUT.PUT_LINE('A10: ' || v_counter || ' is not divisible by 3');
    END IF;
  END LOOP;
END;
/
--------------------------------------------------------------------------------
