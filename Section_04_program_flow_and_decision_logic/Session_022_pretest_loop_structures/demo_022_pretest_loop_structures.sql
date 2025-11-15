-- demo_022_pretest_loop_structures.sql
-- Session : 022_pretest_loop_structures
-- Topic   : Pretest Loop Structures (WHILE and FOR loops)
-- Purpose : Understand loops where the condition is evaluated before entry.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Demo 1: Basic WHILE loop
--------------------------------------------------------------------------------
DECLARE
  v_counter NUMBER := 1;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 1: WHILE loop from 1 to 5');

  WHILE v_counter <= 5 LOOP
    DBMS_OUTPUT.PUT_LINE('  Counter = ' || v_counter);
    v_counter := v_counter + 1;
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 2: WHILE loop with running total
--------------------------------------------------------------------------------
DECLARE
  v_num   NUMBER := 1;
  v_sum   NUMBER := 0;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 2: Sum of integers 1..10 using WHILE');

  WHILE v_num <= 10 LOOP
    v_sum := v_sum + v_num;
    v_num := v_num + 1;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('  Final Sum = ' || v_sum);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 3: Basic FOR loop (counter-controlled pretest)
--------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 3: FOR loop from 1 to 5');

  FOR i IN 1 .. 5 LOOP
    DBMS_OUTPUT.PUT_LINE('  i = ' || i);
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 4: Reverse FOR loop
--------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 4: Reverse FOR loop from 5 down to 1');

  FOR i IN REVERSE 5 .. 1 LOOP
    DBMS_OUTPUT.PUT_LINE('  i = ' || i);
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 5: FOR loop iterating over a collection count
--------------------------------------------------------------------------------
DECLARE
  TYPE t_num_tab IS TABLE OF NUMBER;
  v_numbers t_num_tab := t_num_tab(10, 20, 30, 40);
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 5: FOR loop over nested table elements');

  FOR i IN 1 .. v_numbers.COUNT LOOP
    DBMS_OUTPUT.PUT_LINE('  Element ' || i || ' = ' || v_numbers(i));
  END LOOP;
END;
/
--------------------------------------------------------------------------------
