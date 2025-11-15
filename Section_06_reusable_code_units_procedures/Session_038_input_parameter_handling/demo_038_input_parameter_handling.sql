-- demo_038_input_parameter_handling.sql
-- Session 038: Input Parameter Handling (IN Parameters)
-- Objective:
--   Understand how IN parameters allow a caller to control procedure behavior,
--   filter data, and pass business values into reusable PL/SQL code.


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


--------------------------------------------------------------------------------
-- Demo 1: Simple IN parameter to fetch employee full name
-- Business Scenario:
--   A reporting screen asks for an employee number and shows the full name.
--   Instead of duplicating SELECT logic in many places, we centralize it in a
--   procedure that accepts emp_no as input and prints the full name.
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE demo38_show_emp_name (
  p_emp_no IN ems_employees.emp_no%TYPE  -- Employee number to look up
)
IS
  v_full_name VARCHAR2(120);             -- Local variable to hold "First Last"
BEGIN
  SELECT first_name || ' ' || last_name
    INTO v_full_name
    FROM ems_employees
   WHERE emp_no = p_emp_no;

  DBMS_OUTPUT.PUT_LINE(
    'Demo 1: Employee ' || p_emp_no || ' is ' || v_full_name
  );
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE(
      'Demo 1: No employee found for emp_no = ' || p_emp_no
    );
END demo38_show_emp_name;
/
BEGIN
  -- Call with a valid employee number to see the expected full name.
  demo38_show_emp_name('E1001');
END;
/
--------------------------------------------------------------------------------
-- Demo 2: Multiple IN parameters that behave like filters
-- Business Scenario:
--   HR wants a list of employees per department and status (ACTIVE/INACTIVE).
--   Instead of writing many different queries, we create one reusable procedure
--   that accepts both dept_code and status as input parameters.
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE demo38_list_by_dept_and_status (
  p_dept_code IN ems_departments.dept_code%TYPE,  -- HR, IT, FIN, OPS
  p_status    IN ems_employees.status%TYPE        -- Typically ACTIVE/INACTIVE
)
IS
BEGIN
  DBMS_OUTPUT.PUT_LINE(
    'Demo 2: Employees in department ' || p_dept_code ||
    ' with status ' || p_status
  );

  FOR r IN (
    SELECT e.emp_no,
           e.first_name,
           e.last_name,
           e.salary
      FROM ems_employees e
      JOIN ems_departments d
        ON d.dept_id = e.dept_id
     WHERE d.dept_code = p_dept_code
       AND e.status    = p_status
  ) LOOP
    DBMS_OUTPUT.PUT_LINE(
      '  ' || r.emp_no || ' - ' ||
      r.first_name || ' ' || r.last_name ||
      ' (salary = ' || r.salary || ')'
    );
  END LOOP;
END demo38_list_by_dept_and_status;
/
BEGIN
  -- Example call: list all ACTIVE employees in IT.
  demo38_list_by_dept_and_status('IT', 'ACTIVE');
END;
/
--------------------------------------------------------------------------------
-- Demo 3: Validating IN parameters and using RAISE_APPLICATION_ERROR
-- Business Scenario:
--   HR wants a procedure to directly set an employee salary. This should:
--     1) Reject negative salary values
--     2) Error out if the employee does not exist
--   These validations are implemented using input checks and
--   RAISE_APPLICATION_ERROR with custom error codes.
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE demo38_update_salary (
  p_emp_no      IN ems_employees.emp_no%TYPE,     -- Employee identifier
  p_new_salary  IN ems_employees.salary%TYPE      -- New salary to assign
)
IS
BEGIN
  -- Input validation 1: salary cannot be negative
  IF p_new_salary < 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'New salary cannot be negative');
  END IF;

  -- Apply the update
  UPDATE ems_employees
     SET salary = p_new_salary
   WHERE emp_no = p_emp_no;

  -- Input validation 2: ensure a row was actually updated
  IF SQL%ROWCOUNT = 0 THEN
    RAISE_APPLICATION_ERROR(
      -20002, 'No employee found with emp_no = ' || p_emp_no
    );
  END IF;

  DBMS_OUTPUT.PUT_LINE(
    'Demo 3: Salary updated for ' || p_emp_no ||
    ' to ' || p_new_salary
  );
END demo38_update_salary;
/
BEGIN
  -- Valid case: existing employee with a positive salary value
  demo38_update_salary('E1002', 82000);
END;
/
--------------------------------------------------------------------------------
-- Demo 4: Rule-based behavior controlled by a string IN parameter
-- Business Scenario:
--   Compensation team defines named rules like "SENIOR_IT" or "FIN_HIGH"
--   that encode complex raise logic. Here we show how an IN parameter
--   p_rule_code can control which branch of logic executes inside the body.
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE demo38_apply_promo_rule (
  p_rule_code IN VARCHAR2    -- Example: 'SENIOR_IT', 'FIN_HIGH', etc.
)
IS
BEGIN
  IF p_rule_code = 'SENIOR_IT' THEN
    UPDATE ems_employees e
       SET salary = salary * 1.20
     WHERE e.dept_id = (
             SELECT dept_id
               FROM ems_departments
              WHERE dept_code = 'IT'
           )
       AND e.salary < 70000;

    DBMS_OUTPUT.PUT_LINE(
      'Demo 4: Applied SENIOR_IT rule for IT employees below 70k'
    );

  ELSIF p_rule_code = 'FIN_HIGH' THEN
    UPDATE ems_employees e
       SET salary = salary * 1.15
     WHERE e.dept_id = (
             SELECT dept_id
               FROM ems_departments
              WHERE dept_code = 'FIN'
           )
       AND e.salary >= 70000;

    DBMS_OUTPUT.PUT_LINE(
      'Demo 4: Applied FIN_HIGH rule for Finance employees above or equal to 70k'
    );

  ELSE
    DBMS_OUTPUT.PUT_LINE(
      'Demo 4: Unknown rule code ' || p_rule_code ||
      ' (no changes applied)'
    );
  END IF;
END demo38_apply_promo_rule;
/
BEGIN
  -- Call with a known rule code
  demo38_apply_promo_rule('SENIOR_IT');
END;
/
--------------------------------------------------------------------------------
-- Demo 5: Numeric IN parameters for ad hoc payroll generation for a period
-- Business Scenario:
--   Payroll team wants the flexibility to run payroll for any month/year
--   combination. This procedure accepts month/year as IN parameters and
--   calculates payroll for all ACTIVE employees for that period.
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE demo38_generate_payroll_for_period (
  p_month IN NUMBER,   -- Payroll month (1-12)
  p_year  IN NUMBER    -- Payroll year (for example 2025)
)
IS
BEGIN
  FOR r IN (
    SELECT emp_id, salary
      FROM ems_employees
     WHERE status = 'ACTIVE'
  ) LOOP
    INSERT INTO ems_payroll_runs (
      run_id, emp_id, run_month, run_year,
      gross_salary, bonus_amount, net_salary
    )
    VALUES (
      seq_ems_run_id.NEXTVAL,
      r.emp_id,
      p_month,
      p_year,
      r.salary,
      r.salary * 0.10,       -- 10 percent bonus
      r.salary * 1.10        -- net = salary + bonus
    );
  END LOOP;

  DBMS_OUTPUT.PUT_LINE(
    'Demo 5: Payroll generated for period ' ||
    p_month || '/' || p_year
  );
END demo38_generate_payroll_for_period;
/
BEGIN
  -- Example call for the current calendar month and year.
  demo38_generate_payroll_for_period(
    EXTRACT(MONTH FROM SYSDATE),
    EXTRACT(YEAR  FROM SYSDATE)
  );
END;
/
--------------------------------------------------------------------------------
-- End of demo_038_input_parameter_handling.sql
--------------------------------------------------------------------------------
