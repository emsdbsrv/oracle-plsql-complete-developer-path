-- assignment_028_embedded_query_statements.sql
-- Session : 028_embedded_query_statements
-- Topic   : Practice - Embedded Query Statements
-- Purpose : 10 tasks to practice SELECT INTO, cursor loops, aggregates,
--           subqueries and error handling.
-- Style   : Each block is executable and self-explanatory.
SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Shared setup for assignments
--------------------------------------------------------------------------------
BEGIN
  BEGIN EXECUTE IMMEDIATE 'DROP TABLE demo28_emp_assign';  EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN EXECUTE IMMEDIATE 'DROP TABLE demo28_dept_assign'; EXCEPTION WHEN OTHERS THEN NULL; END;
END;
/

CREATE TABLE demo28_dept_assign (
  dept_id   NUMBER PRIMARY KEY,
  dept_name VARCHAR2(50)
);
/
CREATE TABLE demo28_emp_assign (
  emp_id     NUMBER PRIMARY KEY,
  first_name VARCHAR2(30),
  last_name  VARCHAR2(30),
  salary     NUMBER,
  dept_id    NUMBER REFERENCES demo28_dept_assign(dept_id)
);
/
INSERT INTO demo28_dept_assign VALUES (10, 'HR');
INSERT INTO demo28_dept_assign VALUES (20, 'IT');
INSERT INTO demo28_dept_assign VALUES (30, 'Finance');
INSERT INTO demo28_dept_assign VALUES (40, 'Sales');

INSERT INTO demo28_emp_assign VALUES (1, 'Amit',   'Sharma', 45000, 10);
INSERT INTO demo28_emp_assign VALUES (2, 'Bhavna', 'Kumar',  60000, 20);
INSERT INTO demo28_emp_assign VALUES (3, 'Chirag', 'Patel',  52000, 20);
INSERT INTO demo28_emp_assign VALUES (4, 'Divya',  'Singh',  70000, 30);
INSERT INTO demo28_emp_assign VALUES (5, 'Esha',   'Rao',    38000, 40);
COMMIT;
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Assignment 1: SELECT INTO for a specific employee
-- Task:
--   Fetch first_name, last_name and salary for emp_id = 3.
--------------------------------------------------------------------------------
DECLARE
  v_fname  demo28_emp_assign.first_name%TYPE;
  v_lname  demo28_emp_assign.last_name%TYPE;
  v_salary demo28_emp_assign.salary%TYPE;
BEGIN
  SELECT first_name, last_name, salary
    INTO v_fname, v_lname, v_salary
    FROM demo28_emp_assign
   WHERE emp_id = 3;

  DBMS_OUTPUT.PUT_LINE('A1: ' || v_fname || ' ' || v_lname ||
                       ' earns ' || v_salary);
END;
/
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Assignment 2: Handle NO_DATA_FOUND gracefully
-- Task:
--   Try to fetch salary for non-existing emp_id = 999 and print a friendly
--   message when no row is found.
--------------------------------------------------------------------------------
DECLARE
  v_salary demo28_emp_assign.salary%TYPE;
BEGIN
  BEGIN
    SELECT salary
      INTO v_salary
      FROM demo28_emp_assign
     WHERE emp_id = 999;   -- non-existing

    DBMS_OUTPUT.PUT_LINE('A2: Salary = ' || v_salary);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('A2: No employee with emp_id = 999.');
  END;
END;
/
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Assignment 3: Cursor FOR loop listing all departments and headcount
-- Task:
--   Show department name and number of employees in each department.
--------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('A3: Department-wise headcount');

  FOR r IN (
    SELECT d.dept_name,
           COUNT(e.emp_id) AS headcount
      FROM demo28_dept_assign d
      LEFT JOIN demo28_emp_assign e
        ON e.dept_id = d.dept_id
     GROUP BY d.dept_name
     ORDER BY d.dept_name
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('  ' || RPAD(r.dept_name, 10) ||
                         ' -> ' || NVL(r.headcount,0) || ' employees');
  END LOOP;
END;
/
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Assignment 4: Embedded subquery in SELECT list
-- Task:
--   For each employee, show full name and department name using a subquery.
--------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('A4: Employee with department (embedded subquery)');

  FOR r IN (
    SELECT e.emp_id,
           e.first_name,
           e.last_name,
           (SELECT d.dept_name
              FROM demo28_dept_assign d
             WHERE d.dept_id = e.dept_id) AS dept_name
      FROM demo28_emp_assign e
     ORDER BY e.emp_id
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('  ' || r.emp_id || ': ' ||
                         r.first_name || ' ' || r.last_name ||
                         ' -> ' || r.dept_name);
  END LOOP;
END;
/
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Assignment 5: Use SELECT INTO with aggregate (AVG) for IT department
--------------------------------------------------------------------------------
DECLARE
  v_avg_salary NUMBER;
BEGIN
  SELECT AVG(salary)
    INTO v_avg_salary
    FROM demo28_emp_assign e
    JOIN demo28_dept_assign d ON d.dept_id = e.dept_id
   WHERE d.dept_name = 'IT';

  DBMS_OUTPUT.PUT_LINE('A5: Average salary in IT = ' ||
                       ROUND(v_avg_salary, 2));
END;
/
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Assignment 6: Use correlated subquery to find employees who earn
--               above department average salary.
--------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('A6: Employees earning above their department average');

  FOR r IN (
    SELECT e.emp_id,
           e.first_name,
           e.last_name,
           e.salary,
           d.dept_name
      FROM demo28_emp_assign e
      JOIN demo28_dept_assign d ON d.dept_id = e.dept_id
     WHERE e.salary > (
             SELECT AVG(e2.salary)
               FROM demo28_emp_assign e2
              WHERE e2.dept_id = e.dept_id
           )
     ORDER BY d.dept_name, e.salary DESC
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('  ' || r.first_name || ' ' || r.last_name ||
                         ' (' || r.dept_name || '): ' || r.salary);
  END LOOP;
END;
/
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Assignment 7: Use SELECT COUNT(*) INTO to validate business rule
-- Rule:
--   IT department should have at least 2 employees.
--------------------------------------------------------------------------------
DECLARE
  v_cnt NUMBER;
BEGIN
  SELECT COUNT(*)
    INTO v_cnt
    FROM demo28_emp_assign e
    JOIN demo28_dept_assign d ON d.dept_id = e.dept_id
   WHERE d.dept_name = 'IT';

  IF v_cnt >= 2 THEN
    DBMS_OUTPUT.PUT_LINE('A7: IT has required headcount: ' || v_cnt);
  ELSE
    DBMS_OUTPUT.PUT_LINE('A7: IT does NOT meet headcount requirement.');
  END IF;
END;
/
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Assignment 8: Use SELECT MAX(salary) INTO to find top earner
--------------------------------------------------------------------------------
DECLARE
  v_max_sal NUMBER;
BEGIN
  SELECT MAX(salary)
    INTO v_max_sal
    FROM demo28_emp_assign;

  DBMS_OUTPUT.PUT_LINE('A8: Highest salary in company = ' || v_max_sal);
END;
/
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Assignment 9: Use BULK COLLECT to load all full names into a PL/SQL table
--------------------------------------------------------------------------------
DECLARE
  TYPE t_name_tab IS TABLE OF VARCHAR2(100);
  v_names t_name_tab;
BEGIN
  SELECT first_name || ' ' || last_name
    BULK COLLECT INTO v_names
    FROM demo28_emp_assign
   ORDER BY emp_id;

  DBMS_OUTPUT.PUT_LINE('A9: Names loaded using BULK COLLECT');
  FOR i IN 1 .. v_names.COUNT LOOP
    DBMS_OUTPUT.PUT_LINE('  ' || v_names(i));
  END LOOP;
END;
/
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Assignment 10: Cursor FOR loop with parameterized department
-- Task:
--   Print employees for a chosen department (e.g., Sales).
--------------------------------------------------------------------------------
DECLARE
  v_target_dept demo28_dept_assign.dept_name%TYPE := 'Sales';
BEGIN
  DBMS_OUTPUT.PUT_LINE('A10: Employees in ' || v_target_dept);

  FOR r IN (
    SELECT e.emp_id,
           e.first_name,
           e.last_name,
           e.salary
      FROM demo28_emp_assign e
      JOIN demo28_dept_assign d ON d.dept_id = e.dept_id
     WHERE d.dept_name = v_target_dept
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('  ' || r.emp_id || ': ' ||
                         r.first_name || ' ' || r.last_name ||
                         ' salary=' || r.salary);
  END LOOP;
END;
/
--------------------------------------------------------------------------------
