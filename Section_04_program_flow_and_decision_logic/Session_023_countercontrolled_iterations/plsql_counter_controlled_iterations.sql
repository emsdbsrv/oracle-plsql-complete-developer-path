-- Script: plsql_counter_controlled_iterations.sql
-- Session: 023 - Counter-Controlled Iterations (FOR)
-- Purpose :
--   Demonstrate FOR loops (ascending/descending), skip/break logic, collection
--   iteration, and cursor FOR loops with detailed commentary.
-- Notes   :
--   • The loop index is implicitly declared and cannot be assigned to (read-only).
--   • Use REVERSE for descending iteration and CONTINUE/EXIT for control flow.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Example 1: Basic ascending FOR (1..5)
-- Explanation:
--   Index i is implicit (PLS_INTEGER), scoped to loop, and read-only.
--------------------------------------------------------------------------------
BEGIN
  FOR i IN 1 .. 5 LOOP
    DBMS_OUTPUT.PUT_LINE('i = ' || i);
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 2: Descending FOR with REVERSE
-- Explanation:
--   Iterate from high to low using REVERSE.
--------------------------------------------------------------------------------
BEGIN
  FOR i IN REVERSE 3 .. 1 LOOP
    DBMS_OUTPUT.PUT_LINE('down -> ' || i);
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 3: Skip rule (CONTINUE WHEN) and early exit (EXIT WHEN)
-- Explanation:
--   Skip multiples of 4 and exit at first value >= 9.
--------------------------------------------------------------------------------
BEGIN
  FOR i IN 1 .. 12 LOOP
    CONTINUE WHEN MOD(i,4) = 0;       -- skip 4,8,12
    EXIT WHEN i >= 9;                 -- break at 9
    DBMS_OUTPUT.PUT_LINE('val='||i);
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 4: Collection iteration with COUNT
-- Explanation:
--   Loop over a nested table using 1..COUNT; guard against empty collection.
--------------------------------------------------------------------------------
DECLARE
  TYPE t_nums IS TABLE OF NUMBER;
  v_tab t_nums := t_nums(10, 20, 30);
BEGIN
  IF v_tab.COUNT > 0 THEN
    FOR i IN 1 .. v_tab.COUNT LOOP
      DBMS_OUTPUT.PUT_LINE('tab['||i||']='||v_tab(i));
    END LOOP;
  ELSE
    DBMS_OUTPUT.PUT_LINE('Collection empty');
  END IF;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 5: Cursor FOR loop (implicit open/fetch/close)
-- Explanation:
--   Cursor FOR simplifies explicit OPEN/FETCH/CLOSE; record variable is implicit.
--   Replace the SELECT with your schema table (employees shown as example).
--------------------------------------------------------------------------------
BEGIN
  FOR r IN (SELECT 1 AS emp_id, 'Avi' AS emp_name FROM dual
            UNION ALL SELECT 2, 'Raj' FROM dual) LOOP
    DBMS_OUTPUT.PUT_LINE('emp_id='||r.emp_id||', name='||r.emp_name);
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 6: Nested FOR loops (grid)
-- Explanation:
--   Demonstrates nested ranges for cartesian iteration.
--------------------------------------------------------------------------------
BEGIN
  FOR i IN 1 .. 3 LOOP
    FOR j IN 1 .. 2 LOOP
      DBMS_OUTPUT.PUT_LINE('('||i||','||j||')');
    END LOOP;
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 7: Using EXIT WHEN with a running total
-- Explanation:
--   Accumulate until threshold, then break.
--------------------------------------------------------------------------------
DECLARE
  v_sum NUMBER := 0;
BEGIN
  FOR i IN 1 .. 20 LOOP
    v_sum := v_sum + i;
    EXIT WHEN v_sum >= 50;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('Sum='||v_sum);
END;
/
--------------------------------------------------------------------------------
-- End of File
--------------------------------------------------------------------------------
