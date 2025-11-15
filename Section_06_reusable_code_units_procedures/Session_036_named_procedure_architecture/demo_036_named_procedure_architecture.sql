-- demo_036_named_procedure_architecture.sql
-- Session 036: Named Procedure Architecture
-- Focus   : Building reusable procedures on top of EMS business schema.


SET SERVEROUTPUT ON;

-------------------------------------------------------------------------------
-- BUSINESS SCHEMA SETUP (COMMON ACROSS SESSIONS)
-- This section creates a small but realistic enterprise schema:
--   * EMS_DEPARTMENTS     - master data for departments
--   * EMS_EMPLOYEES       - employee master
--   * EMS_AUDIT_LOG       - generic audit log
--   * EMS_PAYROLL_RUNS    - payroll history
--   * Sequences for synthetic keys
-------------------------------------------------------------------------------
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

BEGIN
  EXECUTE IMMEDIATE 'CREATE TABLE ems_departments (
    dept_id     NUMBER       CONSTRAINT pk_ems_departments PRIMARY KEY,
    dept_code   VARCHAR2(10) CONSTRAINT uq_ems_departments_code UNIQUE,
    dept_name   VARCHAR2(100) NOT NULL,
    active_flag CHAR(1)       DEFAULT ''Y'' CHECK (active_flag IN (''Y'',''N''))
  )';
END;
/

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

BEGIN
  EXECUTE IMMEDIATE 'CREATE TABLE ems_audit_log (
    audit_id    NUMBER        CONSTRAINT pk_ems_audit_log PRIMARY KEY,
    module_name VARCHAR2(50)  NOT NULL,
    action_desc VARCHAR2(200) NOT NULL,
    created_at  DATE          DEFAULT SYSDATE
  )';
END;
/

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

-- Sequences
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_ems_dept_id'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_ems_emp_id';  EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_ems_audit_id'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_ems_run_id';   EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN
  EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_ems_dept_id START WITH 10 INCREMENT BY 10';
  EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_ems_emp_id  START WITH 100 INCREMENT BY 1';
  EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_ems_audit_id START WITH 1 INCREMENT BY 1';
  EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_ems_run_id   START WITH 1 INCREMENT BY 1';
END;
/

-- Seed reference data
BEGIN
  INSERT INTO ems_departments (dept_id, dept_code, dept_name, active_flag)
  VALUES (seq_ems_dept_id.NEXTVAL, 'HR',   'Human Resources', 'Y');

  INSERT INTO ems_departments (dept_id, dept_code, dept_name, active_flag)
  VALUES (seq_ems_dept_id.NEXTVAL, 'IT',   'Information Technology', 'Y');

  INSERT INTO ems_departments (dept_id, dept_code, dept_name, active_flag)
  VALUES (seq_ems_dept_id.NEXTVAL, 'FIN',  'Finance', 'Y');

  INSERT INTO ems_departments (dept_id, dept_code, dept_name, active_flag)
  VALUES (seq_ems_dept_id.NEXTVAL, 'OPS',  'Operations', 'Y');

  COMMIT;
END;
/

-- Seed a few employees
BEGIN
  INSERT INTO ems_employees (emp_id, emp_no, first_name, last_name, dept_id, salary, hire_date, status)
  SELECT seq_ems_emp_id.NEXTVAL, 'E1001', 'Amit',  'Sharma', d.dept_id, 60000, ADD_MONTHS(TRUNC(SYSDATE), -24), 'ACTIVE'
    FROM ems_departments d WHERE d.dept_code = 'IT';

  INSERT INTO ems_employees (emp_id, emp_no, first_name, last_name, dept_id, salary, hire_date, status)
  SELECT seq_ems_emp_id.NEXTVAL, 'E1002', 'Bhavna','Kumar',  d.dept_id, 75000, ADD_MONTHS(TRUNC(SYSDATE), -36), 'ACTIVE'
    FROM ems_departments d WHERE d.dept_code = 'FIN';

  INSERT INTO ems_employees (emp_id, emp_no, first_name, last_name, dept_id, salary, hire_date, status)
  SELECT seq_ems_emp_id.NEXTVAL, 'E1003', 'Chirag','Patel',  d.dept_id, 50000, ADD_MONTHS(TRUNC(SYSDATE), -12), 'ACTIVE'
    FROM ems_departments d WHERE d.dept_code = 'HR';

  COMMIT;
END;
/

-------------------------------------------------------------------------------
-- End of COMMON BUSINESS SCHEMA
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
-- Demo 1: Core audit procedure - prc_ems_write_audit
-------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE prc_ems_write_audit (
  p_module_name IN ems_audit_log.module_name%TYPE,
  p_action_desc IN ems_audit_log.action_desc%TYPE
)
IS
BEGIN
  INSERT INTO ems_audit_log (audit_id, module_name, action_desc)
  VALUES (seq_ems_audit_id.NEXTVAL, p_module_name, p_action_desc);
END prc_ems_write_audit;
/
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 1: Calling prc_ems_write_audit');
  prc_ems_write_audit('DEMO036', 'Audit procedure tested successfully');
  COMMIT;
END;
/
-------------------------------------------------------------------------------
-- Demo 2: Procedure to hire a new employee
-------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE prc_ems_hire_employee (
  p_emp_no     IN ems_employees.emp_no%TYPE,
  p_first_name IN ems_employees.first_name%TYPE,
  p_last_name  IN ems_employees.last_name%TYPE,
  p_dept_code  IN ems_departments.dept_code%TYPE,
  p_salary     IN ems_employees.salary%TYPE
)
IS
  v_dept_id ems_departments.dept_id%TYPE;
  v_emp_id  ems_employees.emp_id%TYPE;
BEGIN
  SELECT dept_id INTO v_dept_id
    FROM ems_departments
   WHERE dept_code = p_dept_code
     AND active_flag = 'Y';

  v_emp_id := seq_ems_emp_id.NEXTVAL;

  INSERT INTO ems_employees (emp_id, emp_no, first_name, last_name,
                             dept_id, salary, hire_date, status)
  VALUES (v_emp_id, p_emp_no, p_first_name, p_last_name,
          v_dept_id, p_salary, TRUNC(SYSDATE), 'ACTIVE');

  prc_ems_write_audit('DEMO036',
                      'Hired ' || p_emp_no || ' into ' || p_dept_code);

  DBMS_OUTPUT.PUT_LINE('Demo 2: Employee hired with emp_id = ' || v_emp_id);
END prc_ems_hire_employee;
/
BEGIN
  prc_ems_hire_employee('E2001', 'New', 'Joiner', 'IT', 55000);
  COMMIT;
END;
/
-------------------------------------------------------------------------------
-- Demo 3: Procedure to adjust department salaries by percentage
-------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE prc_ems_adjust_dept_salary (
  p_dept_code IN ems_departments.dept_code%TYPE,
  p_percent   IN NUMBER
)
IS
  v_rows NUMBER;
BEGIN
  UPDATE ems_employees
     SET salary = salary * (1 + p_percent/100)
   WHERE dept_id = (SELECT dept_id
                      FROM ems_departments
                     WHERE dept_code = p_dept_code);
  v_rows := SQL%ROWCOUNT;

  prc_ems_write_audit('DEMO036',
                      'Adjusted salaries by ' || p_percent ||
                      '% for dept ' || p_dept_code ||
                      ' rows=' || v_rows);

  DBMS_OUTPUT.PUT_LINE('Demo 3: ' || v_rows ||
                       ' rows updated for department ' || p_dept_code);
END prc_ems_adjust_dept_salary;
/
BEGIN
  prc_ems_adjust_dept_salary('IT', 5);
  COMMIT;
END;
/
-------------------------------------------------------------------------------
-- Demo 4: Procedure to generate payroll for one employee
-------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE prc_ems_generate_payroll (
  p_emp_no IN ems_employees.emp_no%TYPE
)
IS
  v_emp_id ems_employees.emp_id%TYPE;
  v_salary ems_employees.salary%TYPE;
  v_bonus  NUMBER(12,2);
  v_net    NUMBER(12,2);
  v_month  NUMBER := EXTRACT(MONTH FROM SYSDATE);
  v_year   NUMBER := EXTRACT(YEAR  FROM SYSDATE);
BEGIN
  SELECT emp_id, salary
    INTO v_emp_id, v_salary
    FROM ems_employees
   WHERE emp_no = p_emp_no;

  v_bonus := v_salary * 0.10;
  v_net   := v_salary + v_bonus;

  INSERT INTO ems_payroll_runs (run_id, emp_id, run_month, run_year,
                                gross_salary, bonus_amount, net_salary)
  VALUES (seq_ems_run_id.NEXTVAL, v_emp_id, v_month, v_year,
          v_salary, v_bonus, v_net);

  prc_ems_write_audit('DEMO036',
                      'Payroll generated for ' || p_emp_no ||
                      ' net=' || v_net);

  DBMS_OUTPUT.PUT_LINE('Demo 4: Payroll generated for ' || p_emp_no);
END prc_ems_generate_payroll;
/
BEGIN
  prc_ems_generate_payroll('E1001');
  COMMIT;
END;
/
-------------------------------------------------------------------------------
-- Demo 5: Controller procedure to orchestrate daily batch tasks
-------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE prc_ems_daily_batch
IS
BEGIN
  prc_ems_write_audit('DEMO036', 'Daily batch started');

  prc_ems_adjust_dept_salary('HR', 3);
  prc_ems_generate_payroll('E1002');

  prc_ems_write_audit('DEMO036', 'Daily batch completed');
END prc_ems_daily_batch;
/
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 5: Running prc_ems_daily_batch...');
  prc_ems_daily_batch;
  COMMIT;
END;
/
-------------------------------------------------------------------------------
-- End of demo_036_named_procedure_architecture.sql
-------------------------------------------------------------------------------
