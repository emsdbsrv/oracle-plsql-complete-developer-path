-- Script: plsql_column_anchoring_with_percent_type.sql
-- Session: 029 - Column Anchoring with %TYPE
-- Purpose:
--   Patterns for anchoring PL/SQL variables and parameters to table columns using %TYPE:
--   (1) basic anchoring, (2) multi-column SELECT INTO, (3) anchored proc params,
--   (4) join + %TYPE, (5) RETURNING INTO, (6) collection of column%TYPE,
--   (7) function returning column%TYPE, (8) defensive updates.
-- How to run:
--   SET SERVEROUTPUT ON; Execute each block separately (terminated by '/').

SET SERVEROUTPUT ON;

BEGIN EXECUTE IMMEDIATE 'DROP TABLE emp_type_demo PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE dept_type_demo PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE dept_type_demo (dept_id NUMBER PRIMARY KEY, dept_name VARCHAR2(50));
CREATE TABLE emp_type_demo (
  emp_id   NUMBER PRIMARY KEY,
  emp_name VARCHAR2(50) NOT NULL,
  dept_id  NUMBER REFERENCES dept_type_demo(dept_id),
  salary   NUMBER(10,2),
  email    VARCHAR2(120),
  hired_on DATE
);
INSERT INTO dept_type_demo VALUES (10,'Engineering');
INSERT INTO dept_type_demo VALUES (20,'Finance');
INSERT INTO emp_type_demo VALUES (1,'Avi',10,90000,'avi@example.com',DATE '2022-01-10');
INSERT INTO emp_type_demo VALUES (2,'Raj',10,80000,'raj@example.com',DATE '2022-06-15');
INSERT INTO emp_type_demo VALUES (3,'Mani',20,75000,'mani@example.com',DATE '2023-02-01');
COMMIT;

-- 1) Basic %TYPE anchoring
DECLARE v_name emp_type_demo.emp_name%TYPE; BEGIN
  SELECT emp_name INTO v_name FROM emp_type_demo WHERE emp_id=1;
  DBMS_OUTPUT.PUT_LINE('emp#1 name='||v_name);
END;
/

-- 2) Multi-column %TYPE
DECLARE
  v_name emp_type_demo.emp_name%TYPE;
  v_sal  emp_type_demo.salary%TYPE;
  v_dt   emp_type_demo.hired_on%TYPE;
BEGIN
  SELECT emp_name,salary,hired_on INTO v_name,v_sal,v_dt FROM emp_type_demo WHERE emp_id=2;
  DBMS_OUTPUT.PUT_LINE('name='||v_name||', sal='||v_sal||', hired='||TO_CHAR(v_dt,'YYYY-MM-DD'));
END;
/

-- 3) Proc params anchored
DECLARE
  PROCEDURE set_email(p_emp IN emp_type_demo.emp_id%TYPE, p_mail IN emp_type_demo.email%TYPE) IS
  BEGIN
    UPDATE emp_type_demo SET email=p_mail WHERE emp_id=p_emp;
    DBMS_OUTPUT.PUT_LINE('rows='||SQL%ROWCOUNT);
  END;
BEGIN
  set_email(2,'raj.new@example.com');
END;
/

-- 4) JOIN with anchored targets
DECLARE
  v_emp  emp_type_demo.emp_name%TYPE;
  v_dept dept_type_demo.dept_name%TYPE;
BEGIN
  SELECT e.emp_name, d.dept_name INTO v_emp, v_dept
  FROM emp_type_demo e JOIN dept_type_demo d ON d.dept_id=e.dept_id
  WHERE e.emp_id=1;
  DBMS_OUTPUT.PUT_LINE(v_emp||' ('||v_dept||')');
END;
/

-- 5) RETURNING INTO anchored
DECLARE v_new emp_type_demo.salary%TYPE; BEGIN
  UPDATE emp_type_demo SET salary=salary+600 WHERE emp_id=3
  RETURNING salary INTO v_new;
  DBMS_OUTPUT.PUT_LINE('rows='||SQL%ROWCOUNT||' new='||v_new);
END;
/

-- 6) Collection of column%TYPE
DECLARE
  TYPE t_names IS TABLE OF emp_type_demo.emp_name%TYPE;
  v t_names;
BEGIN
  SELECT emp_name BULK COLLECT INTO v FROM emp_type_demo WHERE dept_id=10 ORDER BY emp_id;
  FOR i IN 1..v.COUNT LOOP DBMS_OUTPUT.PUT_LINE('name='||v(i)); END LOOP;
END;
/

-- 7) Function returning column%TYPE
DECLARE
  FUNCTION get_email(p_id IN emp_type_demo.emp_id%TYPE) RETURN emp_type_demo.email%TYPE IS
    v emp_type_demo.email%TYPE;
  BEGIN
    SELECT email INTO v FROM emp_type_demo WHERE emp_id=p_id; RETURN v;
  END;
BEGIN
  DBMS_OUTPUT.PUT_LINE('email(1)='||get_email(1));
END;
/

-- 8) Defensive update with anchored params
DECLARE
  PROCEDURE bump(p_id IN emp_type_demo.emp_id%TYPE, p_delta IN emp_type_demo.salary%TYPE) IS
  BEGIN
    UPDATE emp_type_demo SET salary=salary+p_delta WHERE emp_id=p_id;
    DBMS_OUTPUT.PUT_LINE('bumped rows='||SQL%ROWCOUNT);
  END;
BEGIN
  bump(1, 500);
END;
/

-- End of File
