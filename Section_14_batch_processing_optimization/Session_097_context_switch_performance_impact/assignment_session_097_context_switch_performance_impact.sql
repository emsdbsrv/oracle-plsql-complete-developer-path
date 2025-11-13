SET SERVEROUTPUT ON SIZE UNLIMITED;

--------------------------------------------------------------------------------
-- Script: assignment_session_097_context_switch_performance_impact.sql
-- Session: 097 - Context Switch Performance Impact
-- Format:
--   • 10 questions with fully commented solutions.
--   • Focus is on identifying, explaining, and fixing context switch issues.
--------------------------------------------------------------------------------


/*********************************
Q1 – Explain the problem
Task:
  Explain why calling SELECT from inside a loop for each row can be slow.
*********************************/
-- SOLUTION (conceptual):
-- • Every SELECT call from PL/SQL enters the SQL engine and returns.
-- • In a loop of N iterations, that means N context switches.
-- • The overhead of switching back and forth adds up and slows the code.


/*********************************
Q2 – Rewrite SELECT in loop → BULK COLLECT
Task:
  Using dept_id = 10, fetch emp_id and emp_name in one BULK COLLECT and print.
*********************************/
-- SOLUTION:
-- DECLARE
--   TYPE t_id_tab   IS TABLE OF tg_employees.emp_id%TYPE;
--   TYPE t_name_tab IS TABLE OF tg_employees.emp_name%TYPE;
--   v_ids   t_id_tab;
--   v_names t_name_tab;
-- BEGIN
--   SELECT emp_id, emp_name
--   BULK COLLECT INTO v_ids, v_names
--   FROM tg_employees
--   WHERE dept_id = 10;
--
--   FOR i IN 1 .. v_ids.COUNT LOOP
--     DBMS_OUTPUT.PUT_LINE('ID='||v_ids(i)||' NAME='||v_names(i));
--   END LOOP;
-- END;
-- /
--------------------------------------------------------------------------------


/*********************************
Q3 – Rewrite row-by-row UPDATE → FORALL
Task:
  Original:
--   FOR r IN (SELECT emp_id FROM tg_employees WHERE dept_id = 30) LOOP
--     UPDATE tg_employees SET salary = salary + 500 WHERE emp_id = r.emp_id;
--   END LOOP;
  Rewrite using BULK COLLECT and FORALL.
*********************************/
-- SOLUTION:
-- DECLARE
--   TYPE t_id_tab IS TABLE OF tg_employees.emp_id%TYPE;
--   v_ids t_id_tab;
-- BEGIN
--   SELECT emp_id BULK COLLECT INTO v_ids
--   FROM tg_employees
--   WHERE dept_id = 30;
--
--   FORALL i IN 1 .. v_ids.COUNT
--     UPDATE tg_employees
--        SET salary = salary + 500
--      WHERE emp_id = v_ids(i);
-- END;
-- /
--------------------------------------------------------------------------------


/*********************************
Q4 – Timing skeleton: naive vs bulk
Task:
  Write a timing skeleton that compares naive SELECT-in-loop and BULK pattern.
*********************************/
-- SOLUTION (template):
-- DECLARE
--   v_dummy   tg_employees.emp_name%TYPE;
--   v_tab     SYS.ODCIVARCHAR2LIST;
--   v_iters   PLS_INTEGER := 500;
--   t1_start  NUMBER;
--   t1_end    NUMBER;
--   t2_start  NUMBER;
--   t2_end    NUMBER;
-- BEGIN
--   t1_start := DBMS_UTILITY.GET_TIME;
--   FOR i IN 1 .. v_iters LOOP
--     SELECT emp_name INTO v_dummy
--     FROM tg_employees WHERE emp_id = 1;
--   END LOOP;
--   t1_end := DBMS_UTILITY.GET_TIME;
--
--   t2_start := DBMS_UTILITY.GET_TIME;
--   SELECT emp_name BULK COLLECT INTO v_tab
--   FROM tg_employees WHERE emp_id = 1;
--   FOR i IN 1 .. v_iters LOOP
--     IF v_tab.COUNT > 0 THEN
--       NULL;
--     END IF;
--   END LOOP;
--   t2_end := DBMS_UTILITY.GET_TIME;
--
--   DBMS_OUTPUT.PUT_LINE('Naive='||(t1_end - t1_start));
--   DBMS_OUTPUT.PUT_LINE('Bulk ='||(t2_end - t2_start));
-- END;
-- /
--------------------------------------------------------------------------------


/*********************************
Q5 – Set-based UPDATE instead of cursor loop
Task:
  Replace a cursor loop that updates all emp in dept 40 by 10% with one UPDATE.
*********************************/
-- SOLUTION:
-- UPDATE tg_employees
--    SET salary = salary * 1.10
--  WHERE dept_id = 40;
-- /
--------------------------------------------------------------------------------


/*********************************
Q6 – Bulk INSERT via FORALL
Task:
  Show pattern to insert a collection of employee records into tg_employees.
*********************************/
-- SOLUTION (pattern):
-- DECLARE
--   TYPE t_emp_rec IS RECORD (
--     emp_id   tg_employees.emp_id%TYPE,
--     emp_name tg_employees.emp_name%TYPE,
--     salary   tg_employees.salary%TYPE,
--     dept_id  tg_employees.dept_id%TYPE
--   );
--   TYPE t_emp_tab IS TABLE OF t_emp_rec;
--   v_emps t_emp_tab;
-- BEGIN
--   -- Assume v_emps is populated
--   FORALL i IN 1 .. v_emps.COUNT
--     INSERT INTO tg_employees(emp_id, emp_name, salary, dept_id)
--     VALUES (v_emps(i).emp_id,
--             v_emps(i).emp_name,
--             v_emps(i).salary,
--             v_emps(i).dept_id);
-- END;
-- /
--------------------------------------------------------------------------------


/*********************************
Q7 – Memory risk of BULK COLLECT
Task:
  Explain when BULK COLLECT can be dangerous and how BULK COLLECT ... LIMIT helps.
*********************************/
-- SOLUTION (conceptual):
-- • BULK COLLECT can pull a huge result set into memory (PGA).
-- • For very large tables, this may exhaust memory.
-- • BULK COLLECT ... LIMIT fetches rows in manageable chunks,
--   processing each chunk and then discarding it before fetching the next.


/*********************************
Q8 – Rewrite row-by-row DELETE → set-based DELETE
Task:
  Original:
--   FOR r IN (SELECT emp_id FROM tg_employees WHERE salary < 2000) LOOP
--     DELETE FROM tg_employees WHERE emp_id = r.emp_id;
--   END LOOP;
  Rewrite as a single DELETE.
*********************************/
-- SOLUTION:
-- DELETE FROM tg_employees
--  WHERE salary < 2000;
-- /
--------------------------------------------------------------------------------


/*********************************
Q9 – Convert cursor UPDATE to MERGE for sync
Task:
  Given a staging table tg_emp_stage(emp_id, salary), sync salaries to
  tg_employees without a row-by-row loop, using MERGE.
*********************************/
-- SOLUTION:
-- MERGE INTO tg_employees tgt
-- USING tg_emp_stage src
--    ON (tgt.emp_id = src.emp_id)
-- WHEN MATCHED THEN
--   UPDATE SET tgt.salary = src.salary;
-- /
--------------------------------------------------------------------------------


/*********************************
Q10 – When is simple row-by-row code acceptable?
Task:
  Give a realistic scenario where you would keep a small row-by-row loop and
  not bother with bulk logic.
*********************************/
-- SOLUTION (conceptual):
-- • For administrative scripts that touch only a handful of rows
--   (e.g., updating fewer than 20 employees once a month), the clarity of a
--   simple loop can outweigh the tiny performance gain from bulk processing.
-- • Bulk logic mainly matters when row counts are large or the code runs often.

--------------------------------------------------------------------------------
-- End of Assignment: Session 097 - Context Switch Performance Impact
--------------------------------------------------------------------------------
