-- assignment_022_pretest_loop_structures.sql
-- Session : 022_pretest_loop_structures
-- Topic   : Practice - Pretest Loops (WHILE / FOR)

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Assignment 1: WHILE loop printing numbers 1..7
--------------------------------------------------------------------------------
DECLARE
  v_i NUMBER := 1;
BEGIN
  WHILE v_i <= 7 LOOP
    DBMS_OUTPUT.PUT_LINE('A1: i = ' || v_i);
    v_i := v_i + 1;
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 2: WHILE loop generating multiplication table of 5
--------------------------------------------------------------------------------
DECLARE
  v_i NUMBER := 1;
BEGIN
  WHILE v_i <= 10 LOOP
    DBMS_OUTPUT.PUT_LINE('A2: 5 x ' || v_i || ' = ' || (5 * v_i));
    v_i := v_i + 1;
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 3: WHILE loop that stops when running total exceeds 100
--------------------------------------------------------------------------------
DECLARE
  v_value NUMBER := 10;
  v_sum   NUMBER := 0;
BEGIN
  WHILE v_sum <= 100 LOOP
    v_sum   := v_sum + v_value;
    v_value := v_value + 10;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('A3: Final Sum > 100, Sum = ' || v_sum);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 4: FOR loop printing even numbers from 2 to 20
--------------------------------------------------------------------------------
BEGIN
  FOR i IN 2 .. 20 LOOP
    IF MOD(i, 2) = 0 THEN
      DBMS_OUTPUT.PUT_LINE('A4: Even = ' || i);
    END IF;
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 5: FOR loop to iterate over characters in a string (by position)
--------------------------------------------------------------------------------
DECLARE
  v_text VARCHAR2(20) := 'PLSQL';
BEGIN
  FOR i IN 1 .. LENGTH(v_text) LOOP
    DBMS_OUTPUT.PUT_LINE('A5: Position ' || i || ' = ' || SUBSTR(v_text, i, 1));
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 6: Reverse FOR loop countdown from 10 to 1
--------------------------------------------------------------------------------
BEGIN
  FOR i IN REVERSE 1 .. 10 LOOP
    DBMS_OUTPUT.PUT_LINE('A6: Countdown = ' || i);
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 7: WHILE loop with IF condition inside
--------------------------------------------------------------------------------
DECLARE
  v_i NUMBER := 1;
BEGIN
  WHILE v_i <= 15 LOOP
    IF MOD(v_i, 3) = 0 THEN
      DBMS_OUTPUT.PUT_LINE('A7: Multiple of 3 = ' || v_i);
    END IF;
    v_i := v_i + 1;
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 8: FOR loop summing squares of numbers 1..5
--------------------------------------------------------------------------------
DECLARE
  v_sum NUMBER := 0;
BEGIN
  FOR i IN 1 .. 5 LOOP
    v_sum := v_sum + (i * i);
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('A8: Sum of squares 1..5 = ' || v_sum);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 9: WHILE loop with EXIT when a condition is met
--------------------------------------------------------------------------------
DECLARE
  v_i NUMBER := 1;
BEGIN
  WHILE v_i <= 100 LOOP
    IF v_i * v_i > 50 THEN
      DBMS_OUTPUT.PUT_LINE('A9: First i where i^2 > 50 is ' || v_i);
      EXIT;
    END IF;
    v_i := v_i + 1;
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 10: FOR loop to compute factorial of 6
--------------------------------------------------------------------------------
DECLARE
  v_fact NUMBER := 1;
BEGIN
  FOR i IN 1 .. 6 LOOP
    v_fact := v_fact * i;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('A10: 6! (factorial) = ' || v_fact);
END;
/
--------------------------------------------------------------------------------
