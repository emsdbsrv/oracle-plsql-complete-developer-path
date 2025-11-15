-- demo_040_bidirectional_parameter_exchange.sql
-- Session 040: Bidirectional Parameter Exchange (IN OUT parameters)
-- Objective:
--   Explore scenarios where the caller provides an initial value and expects the
--   procedure to modify and return the updated value through the same argument.


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
-- Demo 1: Simple IN OUT numeric counter
-- Scenario:
--   A workflow engine maintains a step counter. Each time the procedure is
--   called, it increments the counter and returns the new value.
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE demo40_increment_counter (
  p_counter IN OUT NUMBER   -- Holds running count across calls
)
IS
BEGIN
  p_counter := p_counter + 1;
END demo40_increment_counter;
/
DECLARE
  v_cnt NUMBER := 0;
BEGIN
  demo40_increment_counter(v_cnt);  -- v_cnt becomes 1
  demo40_increment_counter(v_cnt);  -- v_cnt becomes 2
  DBMS_OUTPUT.PUT_LINE(
    'Demo 1: Counter after two calls = ' || v_cnt
  );
END;
/
--------------------------------------------------------------------------------
-- Demo 2: IN OUT salary adjustment with safety floor
-- Scenario:
--   Compensation system passes a salary value to be adjusted by a delta.
--   The procedure returns the adjusted salary and ensures it never goes below 0.
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE demo40_adjust_salary (
  p_salary IN OUT ems_employees.salary%TYPE,  -- salary being adjusted
  p_delta  IN     NUMBER                      -- positive or negative adjustment
)
IS
BEGIN
  p_salary := p_salary + p_delta;

  IF p_salary < 0 THEN
    p_salary := 0;
  END IF;
END demo40_adjust_salary;
/
DECLARE
  v_sal ems_employees.salary%TYPE := 50000;
BEGIN
  demo40_adjust_salary(v_sal, 5000);
  DBMS_OUTPUT.PUT_LINE('Demo 2: After +5000, salary = ' || v_sal);

  demo40_adjust_salary(v_sal, -60000);
  DBMS_OUTPUT.PUT_LINE('Demo 2: After -60000, salary floored at ' || v_sal);
END;
/
--------------------------------------------------------------------------------
-- Demo 3: IN OUT used as a running accumulator
-- Scenario:
--   We want to accumulate the total salary bill for all employees. The caller
--   passes p_total starting at 0, and each call adds the passed p_amount.
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE demo40_accumulate_total (
  p_amount IN     NUMBER,   -- amount to add for this call
  p_total  IN OUT NUMBER    -- running total maintained by caller
)
IS
BEGIN
  p_total := p_total + NVL(p_amount, 0);
END demo40_accumulate_total;
/
DECLARE
  v_total NUMBER := 0;
BEGIN
  FOR r IN (SELECT salary FROM ems_employees) LOOP
    demo40_accumulate_total(r.salary, v_total);
  END LOOP;

  DBMS_OUTPUT.PUT_LINE(
    'Demo 3: Total salary for all employees = ' || v_total
  );
END;
/
--------------------------------------------------------------------------------
-- Demo 4: IN OUT used with table update using RETURNING
-- Scenario:
--   The caller wants to both update the salary in the table and know the new
--   salary value after the change, using a single IN OUT parameter.
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE demo40_raise_emp_salary (
  p_emp_no IN  ems_employees.emp_no%TYPE,
  p_delta  IN  NUMBER,
  p_final  IN OUT ems_employees.salary%TYPE  -- new salary returned
)
IS
BEGIN
  UPDATE ems_employees
     SET salary = salary + p_delta
   WHERE emp_no = p_emp_no
  RETURNING salary INTO p_final;
END demo40_raise_emp_salary;
/
DECLARE
  v_final ems_employees.salary%TYPE := 0;
BEGIN
  demo40_raise_emp_salary('E1001', 4000, v_final);
  DBMS_OUTPUT.PUT_LINE(
    'Demo 4: New salary for E1001 = ' || v_final
  );
END;
/
--------------------------------------------------------------------------------
-- Demo 5: IN OUT for building a log string step by step
-- Scenario:
--   A batch process wants to keep a single log message that is gradually
--   appended to as different steps complete.
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE demo40_append_log (
  p_log     IN OUT VARCHAR2,  -- accumulated log text
  p_message IN     VARCHAR2   -- message to append
)
IS
BEGIN
  IF p_log IS NULL THEN
    p_log := p_message;
  ELSE
    p_log := p_log || ' | ' || p_message;
  END IF;
END demo40_append_log;
/
DECLARE
  v_log VARCHAR2(4000);
BEGIN
  demo40_append_log(v_log, 'Start batch');
  demo40_append_log(v_log, 'Adjusted IT salaries');
  demo40_append_log(v_log, 'Generated payroll');

  DBMS_OUTPUT.PUT_LINE('Demo 5: Log chain = ' || v_log);
END;
/
--------------------------------------------------------------------------------
-- End of demo_040_bidirectional_parameter_exchange.sql
--------------------------------------------------------------------------------
