-- demo_031_data_insertion_techniques.sql
-- Session : 031_data_insertion_techniques
-- Topic   : Data Insertion Techniques in PL/SQL
-- Purpose : Show different ways to insert data: VALUES, variables,
--           INSERT-SELECT, loops, and RETURNING clause.

SET SERVEROUTPUT ON;

BEGIN
  BEGIN EXECUTE IMMEDIATE 'DROP TABLE demo31_emp'; EXCEPTION WHEN OTHERS THEN NULL; END;
END;
/
CREATE TABLE demo31_emp (
  emp_id     NUMBER PRIMARY KEY,
  emp_name   VARCHAR2(100),
  hire_date  DATE,
  salary     NUMBER
);
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 1: Simple INSERT using literal VALUES
--------------------------------------------------------------------------------
BEGIN
  INSERT INTO demo31_emp (emp_id, emp_name, hire_date, salary)
  VALUES (1, 'Avi Dev', SYSDATE, 60000);

  DBMS_OUTPUT.PUT_LINE('Demo 1: Inserted one row using simple VALUES.');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 2: INSERT using PL/SQL variables
--------------------------------------------------------------------------------
DECLARE
  v_id    demo31_emp.emp_id%TYPE   := 2;
  v_name  demo31_emp.emp_name%TYPE := 'Bhavna Tester';
  v_sal   demo31_emp.salary%TYPE   := 55000;
BEGIN
  INSERT INTO demo31_emp (emp_id, emp_name, hire_date, salary)
  VALUES (v_id, v_name, SYSDATE, v_sal);

  DBMS_OUTPUT.PUT_LINE('Demo 2: Inserted row using variables.');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 3: INSERT using SELECT (INSERT-SELECT)
--------------------------------------------------------------------------------
BEGIN
  INSERT INTO demo31_emp (emp_id, emp_name, hire_date, salary)
  SELECT 3, 'Copy Source', SYSDATE, 70000 FROM dual;

  DBMS_OUTPUT.PUT_LINE('Demo 3: Inserted row using INSERT-SELECT.');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 4: Bulk insert with FOR loop
--------------------------------------------------------------------------------
DECLARE
  v_base_id NUMBER := 10;
BEGIN
  FOR i IN 1 .. 3 LOOP
    INSERT INTO demo31_emp (emp_id, emp_name, hire_date, salary)
    VALUES (v_base_id + i, 'Loop Emp ' || i, SYSDATE, 40000 + i * 1000);
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('Demo 4: Inserted multiple rows in a loop.');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 5: INSERT with RETURNING clause
--------------------------------------------------------------------------------
DECLARE
  v_new_id    demo31_emp.emp_id%TYPE;
  v_new_name  demo31_emp.emp_name%TYPE := 'Returned Emp';
BEGIN
  INSERT INTO demo31_emp (emp_id, emp_name, hire_date, salary)
  VALUES (99, v_new_name, SYSDATE, 80000)
  RETURNING emp_id INTO v_new_id;

  DBMS_OUTPUT.PUT_LINE('Demo 5: Inserted row, new emp_id = ' || v_new_id);
END;
/
--------------------------------------------------------------------------------
