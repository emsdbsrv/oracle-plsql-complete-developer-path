-- demo_034_practical_workshop_3.sql
-- Session : 034_practical_workshop_3
-- Topic   : Practical Workshop 3
-- Purpose : Combine embedded queries, %TYPE, %ROWTYPE, INSERT, UPDATE, DELETE
--           into a realistic mini-scenario.

SET SERVEROUTPUT ON;

BEGIN
  BEGIN EXECUTE IMMEDIATE 'DROP TABLE demo34_dept'; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN EXECUTE IMMEDIATE 'DROP TABLE demo34_emp';  EXCEPTION WHEN OTHERS THEN NULL; END;
END;
/
CREATE TABLE demo34_dept (
  dept_id   NUMBER PRIMARY KEY,
  dept_name VARCHAR2(50)
);
/
CREATE TABLE demo34_emp (
  emp_id     NUMBER PRIMARY KEY,
  emp_name   VARCHAR2(100),
  dept_id    NUMBER REFERENCES demo34_dept(dept_id),
  salary     NUMBER,
  active_flag CHAR(1) DEFAULT 'Y'
);
/
INSERT INTO demo34_dept VALUES (10, 'IT');
INSERT INTO demo34_dept VALUES (20, 'HR');
INSERT INTO demo34_dept VALUES (30, 'Finance');

INSERT INTO demo34_emp VALUES (1, 'Amit',   10, 55000, 'Y');
INSERT INTO demo34_emp VALUES (2, 'Bhavna', 20, 45000, 'Y');
INSERT INTO demo34_emp VALUES (3, 'Chirag', 10, 60000, 'Y');
INSERT INTO demo34_emp VALUES (4, 'Divya',  30, 70000, 'Y');
COMMIT;
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 1: Insert a new employee using %TYPE
--------------------------------------------------------------------------------
DECLARE
  v_name  demo34_emp.emp_name%TYPE := 'Workshop User';
  v_id    demo34_emp.emp_id%TYPE   := 99;
  v_dept  demo34_dept.dept_id%TYPE := 10;
  v_sal   demo34_emp.salary%TYPE   := 50000;
BEGIN
  INSERT INTO demo34_emp (emp_id, emp_name, dept_id, salary)
  VALUES (v_id, v_name, v_dept, v_sal);
  DBMS_OUTPUT.PUT_LINE('Demo 1: Inserted new employee ' || v_name);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 2: Use %ROWTYPE to fetch a single employee and print details
--------------------------------------------------------------------------------
DECLARE
  v_emp demo34_emp%ROWTYPE;
BEGIN
  SELECT *
    INTO v_emp
    FROM demo34_emp
   WHERE emp_id = 1;

  DBMS_OUTPUT.PUT_LINE('Demo 2: ' || v_emp.emp_name ||
                       ' belongs to dept_id ' || v_emp.dept_id ||
                       ' with salary ' || v_emp.salary);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 3: Embedded query to show employee with department name
--------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 3: Employees with department names');

  FOR r IN (
    SELECT e.emp_id,
           e.emp_name,
           (SELECT d.dept_name FROM demo34_dept d WHERE d.dept_id = e.dept_id) dept_name,
           e.salary
      FROM demo34_emp e
     ORDER BY e.emp_id
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('  ' || r.emp_id || ' - ' || r.emp_name ||
                         ' (' || r.dept_name || '), salary=' || r.salary);
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 4: Give a raise to IT employees and soft delete the lowest salary
--------------------------------------------------------------------------------
DECLARE
  v_min_emp_id demo34_emp.emp_id%TYPE;
BEGIN
  UPDATE demo34_emp
     SET salary = salary * 1.10
   WHERE dept_id = 10;

  SELECT emp_id
    INTO v_min_emp_id
    FROM demo34_emp
   WHERE dept_id = 10
   ORDER BY salary
   FETCH FIRST 1 ROWS ONLY;

  UPDATE demo34_emp
     SET active_flag = 'N'
   WHERE emp_id = v_min_emp_id;

  DBMS_OUTPUT.PUT_LINE('Demo 4: Increased IT salaries and soft-deleted lowest-paid IT employee.');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 5: Show final state of all employees
--------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 5: Final employees state');

  FOR r IN (SELECT e.emp_id, e.emp_name, d.dept_name, e.salary, e.active_flag
              FROM demo34_emp e
              JOIN demo34_dept d ON d.dept_id = e.dept_id
             ORDER BY e.emp_id) LOOP
    DBMS_OUTPUT.PUT_LINE('  ' || r.emp_id || ' - ' || r.emp_name ||
                         ' - ' || r.dept_name ||
                         ' - ' || r.salary ||
                         ' - active=' || r.active_flag);
  END LOOP;
END;
/
--------------------------------------------------------------------------------
