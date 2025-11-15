-- demo_variables_and_data_types.sql
-- Session : 012_variables_and_data_types
-- Topic   : Variables and Data Types in PL/SQL
-- Purpose : Understand how to declare, initialize, and use variables
--           with different data types in PL/SQL.
-- Focus   : Scalar types, %TYPE, %ROWTYPE, assignments, conversions,
--           and printing values using DBMS_OUTPUT.

SET SERVEROUTPUT ON;



--------------------------------------------------------------------------------
-- Demo 1: Basic Scalar Variable Declarations
-- Goal:
--   See how to declare and use simple scalar variables of different types:
--     - NUMBER
--     - VARCHAR2
--     - DATE
--     - BOOLEAN (PL/SQL only)
--------------------------------------------------------------------------------
DECLARE
  v_employee_id    NUMBER        := 101;
  v_employee_name  VARCHAR2(50)  := 'Avi Jha';
  v_join_date      DATE          := DATE '2024-01-15';
  v_is_permanent   BOOLEAN       := TRUE;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 1: Basic scalar variables');
  DBMS_OUTPUT.PUT_LINE('  Employee ID    = ' || v_employee_id);
  DBMS_OUTPUT.PUT_LINE('  Employee Name  = ' || v_employee_name);
  DBMS_OUTPUT.PUT_LINE('  Join Date      = ' || TO_CHAR(v_join_date, 'YYYY-MM-DD'));

  IF v_is_permanent THEN
    DBMS_OUTPUT.PUT_LINE('  Permanent      = YES');
  ELSE
    DBMS_OUTPUT.PUT_LINE('  Permanent      = NO');
  END IF;
END;
/
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Setup: Small Demo Table for %TYPE and %ROWTYPE Examples
-- We create a simple employees table only for this session's examples.
--------------------------------------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE s012_demo_employees';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
/
CREATE TABLE s012_demo_employees
(
  emp_id      NUMBER        PRIMARY KEY,
  emp_name    VARCHAR2(50)  NOT NULL,
  salary      NUMBER(10,2),
  hire_date   DATE,
  department  VARCHAR2(30)
);
/
INSERT INTO s012_demo_employees (emp_id, emp_name, salary, hire_date, department)
VALUES (1, 'John Doe', 60000, DATE '2023-06-01', 'IT');
INSERT INTO s012_demo_employees (emp_id, emp_name, salary, hire_date, department)
VALUES (2, 'Jane Smith', 75000, DATE '2022-10-15', 'HR');
COMMIT;
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Demo 2: Anchored Declarations Using %TYPE
-- Goal:
--   Use the %TYPE attribute to anchor variable data types to table columns.
--   This keeps PL/SQL code in sync with table definitions automatically.
--------------------------------------------------------------------------------
DECLARE
  v_emp_id   s012_demo_employees.emp_id%TYPE;
  v_emp_name s012_demo_employees.emp_name%TYPE;
  v_salary   s012_demo_employees.salary%TYPE;
BEGIN
  -- Selecting from the table into variables declared using %TYPE.
  SELECT emp_id, emp_name, salary
    INTO v_emp_id, v_emp_name, v_salary
    FROM s012_demo_employees
   WHERE emp_id = 1;

  DBMS_OUTPUT.PUT_LINE('Demo 2: Using %TYPE for variable declarations');
  DBMS_OUTPUT.PUT_LINE('  Emp ID   = ' || v_emp_id);
  DBMS_OUTPUT.PUT_LINE('  Emp Name = ' || v_emp_name);
  DBMS_OUTPUT.PUT_LINE('  Salary   = ' || v_salary);
END;
/
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Demo 3: Working with Records Using %ROWTYPE
-- Goal:
--   Use %ROWTYPE to create a record variable that matches an entire row
--   structure of a table.
--------------------------------------------------------------------------------
DECLARE
  r_emp s012_demo_employees%ROWTYPE; -- record with all columns of the table
BEGIN
  SELECT *
    INTO r_emp
    FROM s012_demo_employees
   WHERE emp_id = 2;

  DBMS_OUTPUT.PUT_LINE('Demo 3: Using %ROWTYPE for row records');
  DBMS_OUTPUT.PUT_LINE('  Emp ID     = ' || r_emp.emp_id);
  DBMS_OUTPUT.PUT_LINE('  Emp Name   = ' || r_emp.emp_name);
  DBMS_OUTPUT.PUT_LINE('  Salary     = ' || r_emp.salary);
  DBMS_OUTPUT.PUT_LINE('  Hire Date  = ' || TO_CHAR(r_emp.hire_date, 'YYYY-MM-DD'));
  DBMS_OUTPUT.PUT_LINE('  Department = ' || r_emp.department);
END;
/
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Demo 4: Implicit and Explicit Data Type Conversions
-- Goal:
--   Show how PL/SQL can implicitly convert some values between types,
--   and when it is better to perform explicit conversions using TO_CHAR,
--   TO_NUMBER, and TO_DATE.
--------------------------------------------------------------------------------
DECLARE
  v_number   NUMBER      := 12345;
  v_text     VARCHAR2(30);
  v_date     DATE;
BEGIN
  -- Implicit conversion: NUMBER to VARCHAR2 when concatenated with a string.
  v_text := 'Value as text = ' || v_number;
  DBMS_OUTPUT.PUT_LINE('Demo 4: ' || v_text);

  -- Explicit conversion NUMBER -> VARCHAR2 with a format (via TO_CHAR).
  DBMS_OUTPUT.PUT_LINE('Demo 4: Number formatted = ' || TO_CHAR(v_number, '999,999'));

  -- Explicit conversion STRING -> DATE.
  v_date := TO_DATE('2024-11-15', 'YYYY-MM-DD');
  DBMS_OUTPUT.PUT_LINE('Demo 4: Date value = ' || TO_CHAR(v_date, 'DD-MON-YYYY'));

  -- Explicit conversion DATE -> VARCHAR2 to build custom display strings.
  v_text := 'Today is ' || TO_CHAR(SYSDATE, 'Day, DD-Mon-YYYY');
  DBMS_OUTPUT.PUT_LINE('Demo 4: ' || v_text);
END;
/
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Demo 5: Using Variables Inside SQL Statements
-- Goal:
--   Show how variables can be used in SQL statements inside PL/SQL blocks
--   and how data flows between SQL and PL/SQL using SELECT INTO and DML.
--------------------------------------------------------------------------------
DECLARE
  v_emp_id      s012_demo_employees.emp_id%TYPE      := 1;
  v_increase    NUMBER                                := 5000;
  v_old_salary  s012_demo_employees.salary%TYPE;
  v_new_salary  s012_demo_employees.salary%TYPE;
BEGIN
  -- Get current salary into a PL/SQL variable.
  SELECT salary
    INTO v_old_salary
    FROM s012_demo_employees
   WHERE emp_id = v_emp_id;

  v_new_salary := v_old_salary + v_increase;

  -- Use PL/SQL variables in an UPDATE statement.
  UPDATE s012_demo_employees
     SET salary = v_new_salary
   WHERE emp_id = v_emp_id;

  DBMS_OUTPUT.PUT_LINE('Demo 5: Using variables inside SQL');
  DBMS_OUTPUT.PUT_LINE('  Emp ID        = ' || v_emp_id);
  DBMS_OUTPUT.PUT_LINE('  Old Salary    = ' || v_old_salary);
  DBMS_OUTPUT.PUT_LINE('  Increase By   = ' || v_increase);
  DBMS_OUTPUT.PUT_LINE('  New Salary    = ' || v_new_salary);
END;
/
--------------------------------------------------------------------------------
