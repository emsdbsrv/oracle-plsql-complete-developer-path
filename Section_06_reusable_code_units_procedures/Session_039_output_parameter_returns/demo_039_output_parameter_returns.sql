-- demo_039_output_parameter_returns.sql
-- Session 039: Output Parameter Returns (OUT Parameters)
-- Objective:
--   Learn how procedures can return data to the caller through OUT parameters.
--   OUT parameters are useful for:
--     - Returning lookup values (names, amounts, statuses)
--     - Returning multiple values without using a SELECT in the caller
--     - Returning both result and error information in a single call.


SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- COMMON EMS BUSINESS SCHEMA
-- This schema is shared across all demos and assignments in Sessions 035–041.
--
-- It simulates a simplified Enterprise Management System (EMS) with:
--   1) EMS_DEPARTMENTS   : List of departments (HR, IT, FIN, OPS)
--   2) EMS_EMPLOYEES     : Employees, salaries, status, and department references
--   3) EMS_AUDIT_LOG     : Central audit log for actions and batch runs
--   4) EMS_PAYROLL_RUNS  : History of payroll calculations per employee
--
-- Each demo and assignment focuses on PL/SQL techniques, but uses this same
-- schema so that business scenarios feel realistic and connected.
--------------------------------------------------------------------------------

-- Drop existing objects so the script is re-runnable during practice.
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE ems_payroll_runs';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE ems_audit_log';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE ems_employees';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE ems_departments';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- Core master data: departments
BEGIN
  EXECUTE IMMEDIATE 'CREATE TABLE ems_departments (
    dept_id     NUMBER        CONSTRAINT pk_ems_departments PRIMARY KEY,
    dept_code   VARCHAR2(10)  CONSTRAINT uq_ems_departments_code UNIQUE,
    dept_name   VARCHAR2(100) NOT NULL,
    active_flag CHAR(1)       DEFAULT ''Y'' CHECK (active_flag IN (''Y'',''N''))
  )';
END;
/

-- Employee master: references departments and holds base salary and status
BEGIN
  EXECUTE IMMEDIATE 'CREATE TABLE ems_employees (
    emp_id      NUMBER        CONSTRAINT pk_ems_employees PRIMARY KEY,
    emp_no      VARCHAR2(20)  CONSTRAINT uq_ems_employees_no UNIQUE,
    first_name  VARCHAR2(50)  NOT NULL,
    last_name   VARCHAR2(50)  NOT NULL,
    dept_id     NUMBER        CONSTRAINT fk_ems_emp_dept
                               REFERENCES ems_departments(dept_id),
    salary      NUMBER(12,2)  CHECK (salary >= 0),
    hire_date   DATE          DEFAULT SYSDATE,
    status      VARCHAR2(20)  DEFAULT ''ACTIVE''
  )';
END;
/

-- Central audit log table: each row is a small audit event
BEGIN
  EXECUTE IMMEDIATE 'CREATE TABLE ems_audit_log (
    audit_id    NUMBER        CONSTRAINT pk_ems_audit_log PRIMARY KEY,
    module_name VARCHAR2(50)  NOT NULL,
    action_desc VARCHAR2(200) NOT NULL,
    created_at  DATE          DEFAULT SYSDATE
  )';
END;
/

-- Payroll history table: stores each payroll run per employee
BEGIN
  EXECUTE IMMEDIATE 'CREATE TABLE ems_payroll_runs (
    run_id       NUMBER        CONSTRAINT pk_ems_payroll_runs PRIMARY KEY,
    emp_id       NUMBER        CONSTRAINT fk_ems_payroll_emp
                                REFERENCES ems_employees(emp_id),
    run_month    NUMBER(2)     CHECK (run_month BETWEEN 1 AND 12),
    run_year     NUMBER(4),
    gross_salary NUMBER(12,2),
    bonus_amount NUMBER(12,2),
    net_salary   NUMBER(12,2),
    run_at       DATE          DEFAULT SYSDATE
  )';
END;
/

-- Sequences for synthetic keys
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_ems_dept_id';   EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_ems_emp_id';    EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_ems_audit_id';  EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_ems_run_id';    EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN
  EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_ems_dept_id  START WITH 10 INCREMENT BY 10';
  EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_ems_emp_id   START WITH 100 INCREMENT BY 1';
  EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_ems_audit_id START WITH 1   INCREMENT BY 1';
  EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_ems_run_id   START WITH 1   INCREMENT BY 1';
END;
/

-- Seed realistic department data
BEGIN
  INSERT INTO ems_departments (dept_id, dept_code, dept_name, active_flag)
  VALUES (seq_ems_dept_id.NEXTVAL, 'HR',  'Human Resources',          'Y');

  INSERT INTO ems_departments (dept_id, dept_code, dept_name, active_flag)
  VALUES (seq_ems_dept_id.NEXTVAL, 'IT',  'Information Technology',   'Y');

  INSERT INTO ems_departments (dept_id, dept_code, dept_name, active_flag)
  VALUES (seq_ems_dept_id.NEXTVAL, 'FIN', 'Finance',                  'Y');

  INSERT INTO ems_departments (dept_id, dept_code, dept_name, active_flag)
  VALUES (seq_ems_dept_id.NEXTVAL, 'OPS', 'Operations',               'Y');

  COMMIT;
END;
/

-- Seed a few employees in different departments
BEGIN
  INSERT INTO ems_employees (emp_id, emp_no, first_name, last_name,
                             dept_id, salary, hire_date, status)
  SELECT seq_ems_emp_id.NEXTVAL, 'E1001', 'Amit',  'Sharma',
         d.dept_id, 60000, ADD_MONTHS(TRUNC(SYSDATE), -24), 'ACTIVE'
    FROM ems_departments d
   WHERE d.dept_code = 'IT';

  INSERT INTO ems_employees (emp_id, emp_no, first_name, last_name,
                             dept_id, salary, hire_date, status)
  SELECT seq_ems_emp_id.NEXTVAL, 'E1002', 'Bhavna', 'Kumar',
         d.dept_id, 75000, ADD_MONTHS(TRUNC(SYSDATE), -36), 'ACTIVE'
    FROM ems_departments d
   WHERE d.dept_code = 'FIN';

  INSERT INTO ems_employees (emp_id, emp_no, first_name, last_name,
                             dept_id, salary, hire_date, status)
  SELECT seq_ems_emp_id.NEXTVAL, 'E1003', 'Chirag', 'Patel',
         d.dept_id, 50000, ADD_MONTHS(TRUNC(SYSDATE), -12), 'ACTIVE'
    FROM ems_departments d
   WHERE d.dept_code = 'HR';

  COMMIT;
END;
/

--------------------------------------------------------------------------------
-- End of COMMON EMS SCHEMA
--------------------------------------------------------------------------------


SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Demo 1: OUT parameter returning full name for a given emp_no
-- Pattern:
--   IN  : p_emp_no  (request)
--   OUT : p_fullname (response)
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE demo39_get_emp_name (
  p_emp_no   IN  ems_employees.emp_no%TYPE,
  p_fullname OUT VARCHAR2
)
IS
BEGIN
  SELECT first_name || ' ' || last_name
    INTO p_fullname
    FROM ems_employees
   WHERE emp_no = p_emp_no;
END demo39_get_emp_name;
/
DECLARE
  v_name VARCHAR2(120);
BEGIN
  demo39_get_emp_name('E1001', v_name);
  DBMS_OUTPUT.PUT_LINE('Demo 1: Name for E1001 = ' || v_name);
END;
/
--------------------------------------------------------------------------------
-- Demo 2: OUT parameters returning salary and department name
-- Pattern:
--   IN  : p_emp_no
--   OUT : p_salary, p_deptname
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE demo39_get_emp_details (
  p_emp_no   IN  ems_employees.emp_no%TYPE,
  p_salary   OUT ems_employees.salary%TYPE,
  p_deptname OUT ems_departments.dept_name%TYPE
)
IS
BEGIN
  SELECT e.salary, d.dept_name
    INTO p_salary, p_deptname
    FROM ems_employees e
    JOIN ems_departments d
      ON d.dept_id = e.dept_id
   WHERE e.emp_no = p_emp_no;
END demo39_get_emp_details;
/
DECLARE
  v_sal   ems_employees.salary%TYPE;
  v_dept  ems_departments.dept_name%TYPE;
BEGIN
  demo39_get_emp_details('E1002', v_sal, v_dept);
  DBMS_OUTPUT.PUT_LINE(
    'Demo 2: Salary = ' || v_sal || ', Department = ' || v_dept
  );
END;
/
--------------------------------------------------------------------------------
-- Demo 3: OUT parameters used as an error channel
-- Business Scenario:
--   Instead of raising an exception for "employee not found", we want a
--   procedure that fills OUT parameters with an error code and message, while
--   still using OUT to return the full name when successful.
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE demo39_try_get_emp (
  p_emp_no    IN  ems_employees.emp_no%TYPE,
  p_fullname  OUT VARCHAR2,
  p_err_code  OUT NUMBER,
  p_err_msg   OUT VARCHAR2
)
IS
BEGIN
  -- Clear any old error from caller
  p_err_code := NULL;
  p_err_msg  := NULL;

  SELECT first_name || ' ' || last_name
    INTO p_fullname
    FROM ems_employees
   WHERE emp_no = p_emp_no;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    p_fullname := NULL;
    p_err_code := 1;
    p_err_msg  := 'Employee not found';
  WHEN OTHERS THEN
    p_fullname := NULL;
    p_err_code := SQLCODE;
    p_err_msg  := SQLERRM;
END demo39_try_get_emp;
/
DECLARE
  v_name VARCHAR2(120);
  v_code NUMBER;
  v_msg  VARCHAR2(4000);
BEGIN
  demo39_try_get_emp('E9999', v_name, v_code, v_msg);

  DBMS_OUTPUT.PUT_LINE(
    'Demo 3: code=' || NVL(TO_CHAR(v_code), 'NULL') ||
    ', msg=' || NVL(v_msg, 'NULL') ||
    ', name=' || NVL(v_name, 'NULL')
  );
END;
/
--------------------------------------------------------------------------------
-- Demo 4: OUT parameter returning total payroll for a year
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE demo39_get_total_payroll (
  p_year     IN  NUMBER,
  p_total    OUT NUMBER
)
IS
BEGIN
  -- If there are no rows, NVL ensures we return 0 instead of NULL.
  SELECT NVL(SUM(net_salary), 0)
    INTO p_total
    FROM ems_payroll_runs
   WHERE run_year = p_year;
END demo39_get_total_payroll;
/
DECLARE
  v_total NUMBER;
BEGIN
  demo39_get_total_payroll(EXTRACT(YEAR FROM SYSDATE), v_total);
  DBMS_OUTPUT.PUT_LINE(
    'Demo 4: Total payroll for current year = ' || v_total
  );
END;
/
--------------------------------------------------------------------------------
-- Demo 5: OUT parameter for department-level summary (headcount + avg salary)
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE demo39_get_dept_summary (
  p_dept_code IN  ems_departments.dept_code%TYPE,
  p_headcount OUT NUMBER,
  p_avg_sal   OUT NUMBER
)
IS
BEGIN
  SELECT COUNT(e.emp_id),
         NVL(AVG(e.salary), 0)
    INTO p_headcount, p_avg_sal
    FROM ems_departments d
    LEFT JOIN ems_employees e
      ON e.dept_id = d.dept_id
   WHERE d.dept_code = p_dept_code;
END demo39_get_dept_summary;
/
DECLARE
  v_cnt NUMBER;
  v_avg NUMBER;
BEGIN
  demo39_get_dept_summary('IT', v_cnt, v_avg);
  DBMS_OUTPUT.PUT_LINE(
    'Demo 5: IT headcount = ' || v_cnt ||
    ', average salary = ' || v_avg
  );
END;
/
--------------------------------------------------------------------------------
-- End of demo_039_output_parameter_returns.sql
--------------------------------------------------------------------------------
