-- Script: assignment_column_anchoring_with_percent_type.sql
-- Session: 029 - Column Anchoring with %TYPE
-- Format:
--   • 10 questions with complete commented answers.

SET SERVEROUTPUT ON;

-- Q1
-- DECLARE v emp_type_demo.emp_name%TYPE; BEGIN SELECT emp_name INTO v FROM emp_type_demo WHERE emp_id=1; DBMS_OUTPUT.PUT_LINE(v); END; /

-- Q2
-- DECLARE n emp_type_demo.emp_name%TYPE; s emp_type_demo.salary%TYPE; BEGIN SELECT emp_name,salary INTO n,s FROM emp_type_demo WHERE emp_id=2; DBMS_OUTPUT.PUT_LINE(n||' '||s); END; /

-- Q3
-- DECLARE PROCEDURE set_mail(p_id IN emp_type_demo.emp_id%TYPE, p_mail IN emp_type_demo.email%TYPE) IS BEGIN UPDATE emp_type_demo SET email=p_mail WHERE emp_id=p_id; DBMS_OUTPUT.PUT_LINE('rows='||SQL%ROWCOUNT); END; BEGIN set_mail(3,'mani.new@example.com'); END; /

-- Q4
-- DECLARE a emp_type_demo.emp_name%TYPE; b dept_type_demo.dept_name%TYPE; BEGIN SELECT e.emp_name,d.dept_name INTO a,b FROM emp_type_demo e JOIN dept_type_demo d ON d.dept_id=e.dept_id WHERE e.emp_id=1; DBMS_OUTPUT.PUT_LINE(a||' ('||b||')'); END; /

-- Q5
-- DECLARE v emp_type_demo.salary%TYPE; BEGIN UPDATE emp_type_demo SET salary=salary+250 WHERE emp_id=2 RETURNING salary INTO v; DBMS_OUTPUT.PUT_LINE('rows='||SQL%ROWCOUNT||' new='||v); END; /

-- Q6
-- DECLARE TYPE t IS TABLE OF emp_type_demo.emp_name%TYPE; x t; BEGIN SELECT emp_name BULK COLLECT INTO x FROM emp_type_demo WHERE dept_id=10 ORDER BY emp_id; FOR i IN 1..x.COUNT LOOP DBMS_OUTPUT.PUT_LINE(x[i]); END LOOP; END; /

-- Q7
-- DECLARE FUNCTION f(p IN emp_type_demo.emp_id%TYPE) RETURN emp_type_demo.email%TYPE IS r emp_type_demo.email%TYPE; BEGIN SELECT email INTO r FROM emp_type_demo WHERE emp_id=p; RETURN r; END; BEGIN DBMS_OUTPUT.PUT_LINE(f(1)); END; /

-- Q8
-- DECLARE PROCEDURE bump(p_id IN emp_type_demo.emp_id%TYPE, p_delta IN emp_type_demo.salary%TYPE) IS BEGIN UPDATE emp_type_demo SET salary=salary+p_delta WHERE emp_id=p_id; DBMS_OUTPUT.PUT_LINE('rows='||SQL%ROWCOUNT); END; BEGIN bump(1,100); END; /

-- Q9
-- DECLARE d dept_type_demo.dept_name%TYPE; m emp_type_demo.email%TYPE; BEGIN SELECT d.dept_name, e.email INTO d, m FROM emp_type_demo e JOIN dept_type_demo d ON d.dept_id=e.dept_id WHERE e.emp_id=3; DBMS_OUTPUT.PUT_LINE(d||' '||m); END; /

-- Q10
-- DECLARE nm emp_type_demo.emp_name%TYPE; ml emp_type_demo.email%TYPE; BEGIN SELECT emp_name,email INTO nm,ml FROM emp_type_demo WHERE emp_id=2; DBMS_OUTPUT.PUT_LINE(nm||' <'||ml||'>'); END; /

-- End of Assignment
