-- assignment_034_practical_workshop_3.sql
-- Session : 034_practical_workshop_3
-- Topic   : Practice - Practical Workshop 3
-- Purpose : 10 mini-scenarios combining previous concepts.

SET SERVEROUTPUT ON;

BEGIN
  BEGIN EXECUTE IMMEDIATE 'DROP TABLE demo34_dept_assign'; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN EXECUTE IMMEDIATE 'DROP TABLE demo34_emp_assign';  EXCEPTION WHEN OTHERS THEN NULL; END;
END;
/
CREATE TABLE demo34_dept_assign (
  dept_id   NUMBER PRIMARY KEY,
  dept_name VARCHAR2(50)
);
/
CREATE TABLE demo34_emp_assign (
  emp_id     NUMBER PRIMARY KEY,
  emp_name   VARCHAR2(100),
  dept_id    NUMBER REFERENCES demo34_dept_assign(dept_id),
  salary     NUMBER,
  active_flag CHAR(1) DEFAULT 'Y'
);
/
INSERT INTO demo34_dept_assign VALUES (10, 'IT');
INSERT INTO demo34_dept_assign VALUES (20, 'HR');
INSERT INTO demo34_dept_assign VALUES (30, 'Finance');

INSERT INTO demo34_emp_assign VALUES (1, 'Alpha', 10, 55000, 'Y');
INSERT INTO demo34_emp_assign VALUES (2, 'Beta',  20, 45000, 'Y');
INSERT INTO demo34_emp_assign VALUES (3, 'Gamma', 10, 60000, 'Y');
INSERT INTO demo34_emp_assign VALUES (4, 'Delta', 30, 70000, 'Y');
COMMIT;
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 1: Insert a new IT employee using %TYPE variables
--------------------------------------------------------------------------------
DECLARE
  v_id   demo34_emp_assign.emp_id%TYPE   := 10;
  v_name demo34_emp_assign.emp_name%TYPE := 'Workshop A1';
  v_dept demo34_dept_assign.dept_id%TYPE := 10;
  v_sal  demo34_emp_assign.salary%TYPE   := 52000;
BEGIN
  INSERT INTO demo34_emp_assign (emp_id, emp_name, dept_id, salary)
  VALUES (v_id, v_name, v_dept, v_sal);
  DBMS_OUTPUT.PUT_LINE('A1: Inserted ' || v_name);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 2: Fetch one row into %ROWTYPE and print details
--------------------------------------------------------------------------------
DECLARE
  v_emp demo34_emp_assign%ROWTYPE;
BEGIN
  SELECT * INTO v_emp FROM demo34_emp_assign WHERE emp_id = 1;
  DBMS_OUTPUT.PUT_LINE('A2: ' || v_emp.emp_name || ' salary=' || v_emp.salary);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 3: Show employees with department name using embedded subquery
--------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('A3: Employees with department name');
  FOR r IN (
    SELECT e.emp_id,
           e.emp_name,
           (SELECT d.dept_name
              FROM demo34_dept_assign d
             WHERE d.dept_id = e.dept_id) dept_name,
           e.salary
      FROM demo34_emp_assign e
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('  ' || r.emp_id || ' - ' || r.emp_name ||
                         ' (' || r.dept_name || '), salary=' || r.salary);
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 4: Give 5 percent raise to all Finance employees
--------------------------------------------------------------------------------
BEGIN
  UPDATE demo34_emp_assign
     SET salary = salary * 1.05
   WHERE dept_id = 30;
  DBMS_OUTPUT.PUT_LINE('A4: Rows updated = ' || SQL%ROWCOUNT);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 5: Soft delete the lowest paid IT employee
--------------------------------------------------------------------------------
DECLARE
  v_emp_id demo34_emp_assign.emp_id%TYPE;
BEGIN
  SELECT emp_id
    INTO v_emp_id
    FROM demo34_emp_assign
   WHERE dept_id = 10
   ORDER BY salary
   FETCH FIRST 1 ROWS ONLY;

  UPDATE demo34_emp_assign
     SET active_flag = 'N'
   WHERE emp_id = v_emp_id;

  DBMS_OUTPUT.PUT_LINE('A5: Soft deleted emp_id = ' || v_emp_id);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 6: Use SELECT INTO with aggregate to show max salary per dept
--------------------------------------------------------------------------------
DECLARE
  v_max NUMBER;
BEGIN
  SELECT MAX(salary) INTO v_max
    FROM demo34_emp_assign
   WHERE dept_id = 10;

  DBMS_OUTPUT.PUT_LINE('A6: Max IT salary = ' || v_max);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 7: Create a procedure that prints one employee using %ROWTYPE
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE a34_print_emp (
  p_emp IN demo34_emp_assign%ROWTYPE
) IS
BEGIN
  DBMS_OUTPUT.PUT_LINE('A7: ' || p_emp.emp_id || ' - ' || p_emp.emp_name ||
                       ' | dept_id=' || p_emp.dept_id ||
                       ' | salary=' || p_emp.salary ||
                       ' | active=' || p_emp.active_flag);
END;
/
DECLARE
  v demo34_emp_assign%ROWTYPE;
BEGIN
  SELECT * INTO v FROM demo34_emp_assign WHERE emp_id = 2;
  a34_print_emp(v);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 8: Insert multiple employees in a loop
--------------------------------------------------------------------------------
DECLARE
  v_base_id NUMBER := 50;
BEGIN
  FOR i IN 1 .. 3 LOOP
    INSERT INTO demo34_emp_assign (emp_id, emp_name, dept_id, salary)
    VALUES (v_base_id + i, 'LoopUser ' || i, 10, 40000 + i * 1000);
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('A8: Inserted 3 loop users.');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 9: Delete all inactive employees
--------------------------------------------------------------------------------
BEGIN
  DELETE FROM demo34_emp_assign
   WHERE active_flag = 'N';
  DBMS_OUTPUT.PUT_LINE('A9: Rows deleted = ' || SQL%ROWCOUNT);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 10: Final report of all employees
--------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('A10: Final employees report');
  FOR r IN (
    SELECT e.emp_id, e.emp_name, d.dept_name, e.salary, e.active_flag
      FROM demo34_emp_assign e
      JOIN demo34_dept_assign d ON d.dept_id = e.dept_id
     ORDER BY e.emp_id
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('  ' || r.emp_id || ' - ' || r.emp_name ||
                         ' - ' || r.dept_name ||
                         ' - ' || r.salary ||
                         ' - active=' || r.active_flag);
  END LOOP;
END;
/
--------------------------------------------------------------------------------
