-- demo_028_embedded_query_statements.sql
-- Session : 028_embedded_query_statements
-- Topic   : Embedded Query Statements in PL/SQL
-- Purpose : Demonstrate how to run SELECT queries inside PL/SQL blocks
--           using SELECT INTO, cursor FOR loops, subqueries and aggregates.
-- Style   : 5 demos with detailed, step-by-step comments.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Setup section for this demo file
-- We create small demo tables so the script is self-contained and repeatable.
--------------------------------------------------------------------------------
BEGIN
  -- Drop existing tables if present to avoid ORA-00942 errors.
  BEGIN EXECUTE IMMEDIATE 'DROP TABLE demo28_employees';   EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN EXECUTE IMMEDIATE 'DROP TABLE demo28_departments'; EXCEPTION WHEN OTHERS THEN NULL; END;
END;
/

-- Master table: departments
CREATE TABLE demo28_departments (
  dept_id     NUMBER       PRIMARY KEY,
  dept_name   VARCHAR2(50)
);
/
-- Child table: employees
CREATE TABLE demo28_employees (
  emp_id      NUMBER       PRIMARY KEY,
  first_name  VARCHAR2(30),
  last_name   VARCHAR2(30),
  salary      NUMBER,
  dept_id     NUMBER       REFERENCES demo28_departments(dept_id)
);
/
-- Seed data
INSERT INTO demo28_departments VALUES (10, 'HR');
INSERT INTO demo28_departments VALUES (20, 'IT');
INSERT INTO demo28_departments VALUES (30, 'Finance');

INSERT INTO demo28_employees VALUES (1, 'Amit',  'Sharma', 45000, 10);
INSERT INTO demo28_employees VALUES (2, 'Bhavna','Kumar',  60000, 20);
INSERT INTO demo28_employees VALUES (3, 'Chirag','Patel',  52000, 20);
INSERT INTO demo28_employees VALUES (4, 'Divya', 'Singh',  70000, 30);
COMMIT;
--------------------------------------------------------------------------------
-- At this point:
--   * 3 departments (HR, IT, Finance)
--   * 4 employees linked to these departments
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Demo 1: Simple SELECT ... INTO for a single row
-- Key ideas:
--   - Use SELECT ... INTO when you expect exactly one row.
--   - The INTO clause maps columns to PL/SQL variables.
--------------------------------------------------------------------------------
DECLARE
  v_emp_name   VARCHAR2(61);  -- first_name || space || last_name
  v_emp_salary NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 1: Simple SELECT INTO for emp_id = 1');

  SELECT first_name || ' ' || last_name,
         salary
    INTO v_emp_name,
         v_emp_salary
    FROM demo28_employees
   WHERE emp_id = 1;  -- we know this row exists (inserted above)

  DBMS_OUTPUT.PUT_LINE('  Name   = ' || v_emp_name);
  DBMS_OUTPUT.PUT_LINE('  Salary = ' || v_emp_salary);
END;
/
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Demo 2: Handling NO_DATA_FOUND and TOO_MANY_ROWS with SELECT INTO
-- Key ideas:
--   - NO_DATA_FOUND when query returns 0 rows
--   - TOO_MANY_ROWS when query returns > 1 row
--   - We can handle both errors in the EXCEPTION block.
--------------------------------------------------------------------------------
DECLARE
  v_salary NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 2: Handling NO_DATA_FOUND for non-existing emp_id');

  BEGIN
    -- Choose an employee id that does not exist
    SELECT salary
      INTO v_salary
      FROM demo28_employees
     WHERE emp_id = 999;

    DBMS_OUTPUT.PUT_LINE('  Salary = ' || v_salary);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('  No employee found with emp_id = 999.');
    WHEN TOO_MANY_ROWS THEN
      DBMS_OUTPUT.PUT_LINE('  More than one row returned (unexpected here).');
  END;
END;
/
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Demo 3: Cursor FOR loop for multi-row query
-- Key ideas:
--   - Cursor FOR loop automatically opens, fetches, and closes the cursor.
--   - Each iteration returns one record variable (r_emp).
--   - We do not need explicit FETCH or CLOSE statements.
--------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 3: Cursor FOR loop for all IT employees');

  FOR r_emp IN (
    SELECT e.emp_id,
           e.first_name,
           e.last_name,
           e.salary
      FROM demo28_employees e
      JOIN demo28_departments d ON d.dept_id = e.dept_id
     WHERE d.dept_name = 'IT'
     ORDER BY e.emp_id
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('  Emp ' || r_emp.emp_id || ': ' ||
                         r_emp.first_name || ' ' || r_emp.last_name ||
                         ', salary = ' || r_emp.salary);
  END LOOP;
END;
/
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Demo 4: Using subqueries inside SELECT for derived values
-- Scenario:
--   For each employee we want to display the department name as an extra column.
--   We use an embedded subquery for department name in the SELECT list.
--------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 4: Embedded subquery to fetch department name');

  FOR r_emp IN (
    SELECT e.emp_id,
           e.first_name,
           e.last_name,
           e.salary,
           (SELECT d.dept_name
              FROM demo28_departments d
             WHERE d.dept_id = e.dept_id) AS dept_name
      FROM demo28_employees e
     ORDER BY e.emp_id
  ) LOOP
    DBMS_OUTPUT.PUT_LINE(
      '  ' || r_emp.emp_id || ' - ' ||
      r_emp.first_name || ' ' || r_emp.last_name ||
      ' works in ' || r_emp.dept_name ||
      ' with salary ' || r_emp.salary
    );
  END LOOP;
END;
/
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Demo 5: Aggregation query embedded in PL/SQL
-- Scenario:
--   Compute the average salary of employees in the IT department.
--   We use GROUP BY, AVG(), and SELECT INTO.
--------------------------------------------------------------------------------
DECLARE
  v_dept_name  demo28_departments.dept_name%TYPE;
  v_avg_salary NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 5: Average salary for IT department');

  SELECT d.dept_name,
         AVG(e.salary)
    INTO v_dept_name,
         v_avg_salary
    FROM demo28_employees e
    JOIN demo28_departments d ON d.dept_id = e.dept_id
   WHERE d.dept_name = 'IT'
   GROUP BY d.dept_name;

  DBMS_OUTPUT.PUT_LINE('  Department   = ' || v_dept_name);
  DBMS_OUTPUT.PUT_LINE('  Avg. Salary  = ' || ROUND(v_avg_salary, 2));
END;
/
--------------------------------------------------------------------------------
