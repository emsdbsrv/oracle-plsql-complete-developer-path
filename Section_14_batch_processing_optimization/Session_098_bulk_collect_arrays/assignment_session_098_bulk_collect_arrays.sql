SET SERVEROUTPUT ON SIZE UNLIMITED;

--------------------------------------------------------------------------------
-- Script: assignment_session_098_bulk_collect_arrays.sql
-- Session: 098 - BULK COLLECT Arrays
-- Format:
--   • 10 questions centered on BULK COLLECT usage, performance, and safety.
--   • Each question includes a fully commented solution block.
--   • Copy a solution, remove leading '--', and run it to test.
-- Guidance:
--   • Aim to avoid row-by-row SQL calls when row counts are large.
--   • Practice both full-result and chunked (LIMIT) patterns.
--   • Use descriptive collection type names to improve readability.
--------------------------------------------------------------------------------


/*********************************
Q1 – Basic BULK COLLECT into one collection
Task:
  For dept_id = 10, fetch all emp_name values into a nested table and print them.
*********************************/
-- SOLUTION:
-- DECLARE
--   TYPE t_name_tab IS TABLE OF tg_employees.emp_name%TYPE;
--   v_names t_name_tab;
-- BEGIN
--   SELECT emp_name
--   BULK COLLECT INTO v_names
--   FROM tg_employees
--   WHERE dept_id = 10
--   ORDER BY emp_id;
--
--   DBMS_OUTPUT.PUT_LINE('Rows fetched='||v_names.COUNT);
--   FOR i IN 1 .. v_names.COUNT LOOP
--     DBMS_OUTPUT.PUT_LINE('NAME='||v_names(i));
--   END LOOP;
-- END;
-- /
--------------------------------------------------------------------------------


/*********************************
Q2 – BULK COLLECT into two parallel collections
Task:
  Fetch emp_id and salary for dept_id = 20 into two collections and print them.
*********************************/
-- SOLUTION:
-- DECLARE
--   TYPE t_id_tab  IS TABLE OF tg_employees.emp_id%TYPE;
--   TYPE t_sal_tab IS TABLE OF tg_employees.salary%TYPE;
--   v_ids  t_id_tab;
--   v_sals t_sal_tab;
-- BEGIN
--   SELECT emp_id, salary
--   BULK COLLECT INTO v_ids, v_sals
--   FROM tg_employees
--   WHERE dept_id = 20
--   ORDER BY emp_id;
--
--   FOR i IN 1 .. v_ids.COUNT LOOP
--     DBMS_OUTPUT.PUT_LINE('ID='||v_ids(i)||' SAL='||v_sals(i));
--   END LOOP;
-- END;
-- /
--------------------------------------------------------------------------------


/*********************************
Q3 – BULK COLLECT with LIMIT using cursor
Task:
  Using a cursor over dept_id = 30, fetch emp_id chunks of size 5 using
  BULK COLLECT ... LIMIT and print each chunk size.
*********************************/
-- SOLUTION:
-- DECLARE
--   CURSOR c_emp IS
--     SELECT emp_id FROM tg_employees
--     WHERE dept_id = 30
--     ORDER BY emp_id;
--
--   TYPE t_id_tab IS TABLE OF tg_employees.emp_id%TYPE;
--   v_ids t_id_tab;
--   c_limit CONSTANT PLS_INTEGER := 5;
-- BEGIN
--   OPEN c_emp;
--   LOOP
--     FETCH c_emp BULK COLLECT INTO v_ids LIMIT c_limit;
--     EXIT WHEN v_ids.COUNT = 0;
--
--     DBMS_OUTPUT.PUT_LINE('Chunk size='||v_ids.COUNT);
--     FOR i IN 1 .. v_ids.COUNT LOOP
--       DBMS_OUTPUT.PUT_LINE('ID='||v_ids(i));
--     END LOOP;
--   END LOOP;
--   CLOSE c_emp;
-- END;
-- /
--------------------------------------------------------------------------------


/*********************************
Q4 – BULK COLLECT into a record collection
Task:
  Define a RECORD type for (emp_id, emp_name) and a TABLE OF that record.
  Use BULK COLLECT to load all rows of dept_id = 40.
*********************************/
-- SOLUTION:
-- DECLARE
--   TYPE t_emp_rec IS RECORD (
--     emp_id   tg_employees.emp_id%TYPE,
--     emp_name tg_employees.emp_name%TYPE
--   );
--   TYPE t_emp_tab IS TABLE OF t_emp_rec;
--   v_emps t_emp_tab;
-- BEGIN
--   SELECT emp_id, emp_name
--   BULK COLLECT INTO v_emps
--   FROM tg_employees
--   WHERE dept_id = 40
--   ORDER BY emp_id;
--
--   DBMS_OUTPUT.PUT_LINE('Rows fetched='||v_emps.COUNT);
--   FOR i IN 1 .. v_emps.COUNT LOOP
--     DBMS_OUTPUT.PUT_LINE('ID='||v_emps(i).emp_id||' NAME='||v_emps(i).emp_name);
--   END LOOP;
-- END;
-- /
--------------------------------------------------------------------------------


/*********************************
Q5 – Empty result and COUNT
Task:
  Use BULK COLLECT to fetch all employees for dept_id = 9999 and print a
  message whether any rows were found.
*********************************/
-- SOLUTION:
-- DECLARE
--   TYPE t_id_tab IS TABLE OF tg_employees.emp_id%TYPE;
--   v_ids t_id_tab;
-- BEGIN
--   SELECT emp_id
--   BULK COLLECT INTO v_ids
--   FROM tg_employees
--   WHERE dept_id = 9999;
--
--   IF v_ids.COUNT = 0 THEN
--     DBMS_OUTPUT.PUT_LINE('No employees found in dept 9999');
--   ELSE
--     DBMS_OUTPUT.PUT_LINE('Found '||v_ids.COUNT||' rows');
--   END IF;
-- END;
-- /
--------------------------------------------------------------------------------


/*********************************
Q6 – BULK COLLECT helper procedure
Task:
  Write a procedure get_dept_ids(p_dept_id, p_ids OUT collection) that loads
  all emp_id values for the department using BULK COLLECT.
*********************************/
-- SOLUTION:
-- DECLARE
--   TYPE t_id_tab IS TABLE OF tg_employees.emp_id%TYPE;
--
--   PROCEDURE get_dept_ids(
--     p_dept_id IN tg_employees.dept_id%TYPE,
--     p_ids     OUT t_id_tab
--   ) IS
--   BEGIN
--     SELECT emp_id
--     BULK COLLECT INTO p_ids
--     FROM tg_employees
--     WHERE dept_id = p_dept_id
--     ORDER BY emp_id;
--   END;
--
--   v_ids t_id_tab;
-- BEGIN
--   get_dept_ids(10, v_ids);
--   DBMS_OUTPUT.PUT_LINE('Rows='||v_ids.COUNT);
-- END;
-- /
--------------------------------------------------------------------------------


/*********************************
Q7 – BULK COLLECT into associative array
Task:
  Create an associative array of salary indexed by PLS_INTEGER and populate it
  with salaries for dept_id = 20 using BULK COLLECT plus a small loop.
*********************************/
-- SOLUTION:
-- DECLARE
--   TYPE t_sal_tab IS TABLE OF tg_employees.salary%TYPE INDEX BY PLS_INTEGER;
--   v_sals t_sal_tab;
--   v_ids  SYS.ODCINUMBERLIST;
-- BEGIN
--   SELECT emp_id BULK COLLECT INTO v_ids
--   FROM tg_employees
--   WHERE dept_id = 20
--   ORDER BY emp_id;
--
--   SELECT salary BULK COLLECT INTO v_sals
--   FROM tg_employees
--   WHERE emp_id IN (SELECT COLUMN_VALUE FROM TABLE(v_ids))
--   ORDER BY emp_id;
--
--   FOR i IN 1 .. v_ids.COUNT LOOP
--     DBMS_OUTPUT.PUT_LINE('ID='||v_ids(i)||' SAL='||v_sals(i));
--   END LOOP;
-- END;
-- /
--------------------------------------------------------------------------------


/*********************************
Q8 – BULK COLLECT vs row-by-row discussion
Task:
  In comments, explain when BULK COLLECT is preferable to simple SELECT-INTO
  loops, and when it may not be worth the added complexity.
*********************************/
-- SOLUTION (conceptual):
-- • Prefer BULK COLLECT when processing many rows (hundreds, thousands),
--   especially when combined with FORALL for DML.
-- • For small row counts or rarely run maintenance scripts, the simpler
--   row-by-row code may be acceptable and easier to read.
-- • For very large result sets, use BULK COLLECT ... LIMIT to avoid memory issues.


/*********************************
Q9 – BULK COLLECT with LIMIT template
Task:
  Write a generic template that uses BULK COLLECT ... LIMIT 100 over
  tg_employees ordered by emp_id, printing each chunk.
*********************************/
-- SOLUTION:
-- DECLARE
--   CURSOR c_emp IS
--     SELECT emp_id FROM tg_employees ORDER BY emp_id;
--   TYPE t_id_tab IS TABLE OF tg_employees.emp_id%TYPE;
--   v_ids t_id_tab;
--   c_limit CONSTANT PLS_INTEGER := 100;
-- BEGIN
--   OPEN c_emp;
--   LOOP
--     FETCH c_emp BULK COLLECT INTO v_ids LIMIT c_limit;
--     EXIT WHEN v_ids.COUNT = 0;
--
--     DBMS_OUTPUT.PUT_LINE('Chunk count='||v_ids.COUNT);
--   END LOOP;
--   CLOSE c_emp;
-- END;
-- /
--------------------------------------------------------------------------------


/*********************************
Q10 – Combination: BULK COLLECT now, FORALL later
Task:
  Explain how BULK COLLECT works together with FORALL in a typical pattern
  for reading then updating many rows.
*********************************/
-- SOLUTION (conceptual):
-- • BULK COLLECT loads keys and possibly old values into PL/SQL collections
--   in a small number of SQL calls.
-- • FORALL then sends many DML operations (INSERT/UPDATE/DELETE) back to
--   the SQL engine in a single bulk dispatch.
-- • Together they significantly reduce SQL ⇄ PL/SQL context switches.


--------------------------------------------------------------------------------
-- End of Assignment: Session 098 - BULK COLLECT Arrays
--------------------------------------------------------------------------------
