-- demo_041_default_parameter_values.sql
-- Session 041: Default Parameter Values
-- Objective:
--   Show how default values in parameter lists simplify procedure calls and
--   reduce duplication, while still allowing the caller to override defaults.


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
-- Demo 1: Default bonus percentage parameter
-- Pattern:
--   p_bonus_pct has a default of 10 percent.
--   Caller can omit it or pass a custom value.
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE demo41_calculate_bonus (
  p_salary    IN  ems_employees.salary%TYPE,
  p_bonus_pct IN  NUMBER DEFAULT 10,
  p_bonus_out OUT NUMBER
)
IS
BEGIN
  p_bonus_out := p_salary * (p_bonus_pct / 100);
END demo41_calculate_bonus;
/
DECLARE
  v_bonus NUMBER;
BEGIN
  -- Use default 10 percent
  demo41_calculate_bonus(60000, p_bonus_out => v_bonus);
  DBMS_OUTPUT.PUT_LINE(
    'Demo 1: Default 10 percent bonus for 60000 = ' || v_bonus
  );

  -- Override default to 20 percent
  demo41_calculate_bonus(60000, 20, v_bonus);
  DBMS_OUTPUT.PUT_LINE(
    'Demo 1: 20 percent bonus for 60000 = ' || v_bonus
  );
END;
/
--------------------------------------------------------------------------------
-- Demo 2: Default department code parameter
-- Pattern:
--   p_dept_code defaults to 'IT', so the caller can just call the procedure
--   without arguments to see IT employees.
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE demo41_list_dept_emps (
  p_dept_code IN ems_departments.dept_code%TYPE DEFAULT 'IT'
)
IS
BEGIN
  DBMS_OUTPUT.PUT_LINE(
    'Demo 2: Employees for department ' || p_dept_code
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
  ) LOOP
    DBMS_OUTPUT.PUT_LINE(
      '  ' || r.emp_no || ' - ' ||
      r.first_name || ' ' || r.last_name ||
      ' salary=' || r.salary
    );
  END LOOP;
END demo41_list_dept_emps;
/
BEGIN
  demo41_list_dept_emps;        -- uses default IT
  demo41_list_dept_emps('FIN'); -- override with Finance
END;
/
--------------------------------------------------------------------------------
-- Demo 3: Multiple default parameters for payroll run
-- Defaults:
--   p_month     = current month
--   p_year      = current year
--   p_bonus_pct = 10 percent
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE demo41_run_payroll (
  p_month     IN NUMBER DEFAULT EXTRACT(MONTH FROM SYSDATE),
  p_year      IN NUMBER DEFAULT EXTRACT(YEAR  FROM SYSDATE),
  p_bonus_pct IN NUMBER DEFAULT 10
)
IS
BEGIN
  DBMS_OUTPUT.PUT_LINE(
    'Demo 3: Running payroll for ' ||
    p_month || '/' || p_year ||
    ' with bonus percent ' || p_bonus_pct
  );

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
      r.emp_id, p_month, p_year,
      r.salary,
      r.salary * (p_bonus_pct/100),
      r.salary * (1 + p_bonus_pct/100)
    );
  END LOOP;
END demo41_run_payroll;
/
BEGIN
  demo41_run_payroll;               -- all defaults
  demo41_run_payroll(1, 2025, 15);  -- explicit arguments
END;
/
--------------------------------------------------------------------------------
-- Demo 4: Default parameter controlling audit module name
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE demo41_log_action (
  p_module_name IN ems_audit_log.module_name%TYPE DEFAULT 'DEMO041',
  p_action_desc IN ems_audit_log.action_desc%TYPE
)
IS
BEGIN
  INSERT INTO ems_audit_log (audit_id, module_name, action_desc)
  VALUES (seq_ems_audit_id.NEXTVAL, p_module_name, p_action_desc);
END demo41_log_action;
/
BEGIN
  demo41_log_action(p_action_desc => 'Default module used');
  demo41_log_action('CUSTOMMOD',  'Custom module used');
END;
/
--------------------------------------------------------------------------------
-- Demo 5: Default parameter for reporting minimum net salary threshold
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE demo41_report_payroll (
  p_year      IN NUMBER DEFAULT EXTRACT(YEAR FROM SYSDATE),
  p_min_net   IN NUMBER DEFAULT 0
)
IS
BEGIN
  DBMS_OUTPUT.PUT_LINE(
    'Demo 5: Payroll report for year ' || p_year ||
    ', minimum net salary = ' || p_min_net
  );

  FOR r IN (
    SELECT e.emp_no,
           e.first_name,
           e.last_name,
           p.net_salary,
           p.run_month
      FROM ems_payroll_runs p
      JOIN ems_employees    e
        ON e.emp_id = p.emp_id
     WHERE p.run_year = p_year
       AND p.net_salary >= p_min_net
     ORDER BY p.net_salary DESC
  ) LOOP
    DBMS_OUTPUT.PUT_LINE(
      '  ' || r.emp_no ||
      ' ' || r.first_name || ' ' || r.last_name ||
      ' month=' || r.run_month ||
      ' net=' || r.net_salary
    );
  END LOOP;
END demo41_report_payroll;
/
BEGIN
  demo41_report_payroll;                 -- default year and minimum
  demo41_report_payroll(p_min_net => 70000); -- show only higher salaries
END;
/
--------------------------------------------------------------------------------
-- End of demo_041_default_parameter_values.sql
--------------------------------------------------------------------------------
