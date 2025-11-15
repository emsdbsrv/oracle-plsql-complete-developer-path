-- demo_035_unnamed_execution_blocks.sql
-- Session 035: Unnamed (Anonymous) Execution Blocks
-- Topic   : Practical use of anonymous PL/SQL blocks in an EMS system
-- Focus   : Direct DML, auditing, payroll adjustment, and error handling.


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
-- Demo 1: One-time salary correction as an anonymous block
-------------------------------------------------------------------------------
DECLARE
  v_emp_no   ems_employees.emp_no%TYPE := 'E1001';
  v_increment NUMBER := 5000;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 1: One-time salary correction for ' || v_emp_no);

  UPDATE ems_employees
     SET salary = salary + v_increment
   WHERE emp_no = v_emp_no;

  INSERT INTO ems_audit_log (audit_id, module_name, action_desc)
  VALUES (seq_ems_audit_id.NEXTVAL,
          'DEMO035',
          'Salary increased by ' || v_increment || ' for ' || v_emp_no);

  COMMIT;

  DBMS_OUTPUT.PUT_LINE('  Salary updated and audit row written.');
END;
/
-------------------------------------------------------------------------------
-- Demo 2: Mark long-tenure employees as ELIGIBLE_FOR_PROMO
-------------------------------------------------------------------------------
DECLARE
  v_cutoff_date DATE := ADD_MONTHS(TRUNC(SYSDATE), -24);
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 2: Mark long-tenure employees as ELIGIBLE_FOR_PROMO');

  UPDATE ems_employees
     SET status = 'ELIGIBLE_FOR_PROMO'
   WHERE hire_date <= v_cutoff_date
     AND status = 'ACTIVE';

  INSERT INTO ems_audit_log (audit_id, module_name, action_desc)
  VALUES (seq_ems_audit_id.NEXTVAL,
          'DEMO035',
          'Status ELIGIBLE_FOR_PROMO applied to employees hired before ' ||
          TO_CHAR(v_cutoff_date, 'YYYY-MM-DD'));

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('  Employee status updated based on hire_date.');
END;
/
-------------------------------------------------------------------------------
-- Demo 3: Generate a single payroll run for one employee
-------------------------------------------------------------------------------
DECLARE
  v_emp_no       ems_employees.emp_no%TYPE := 'E1002';
  v_emp_id       ems_employees.emp_id%TYPE;
  v_salary       ems_employees.salary%TYPE;
  v_bonus        NUMBER(12,2);
  v_net          NUMBER(12,2);
  v_month        NUMBER := EXTRACT(MONTH FROM SYSDATE);
  v_year         NUMBER := EXTRACT(YEAR FROM SYSDATE);
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 3: Generate payroll run for ' || v_emp_no);

  SELECT emp_id, salary
    INTO v_emp_id, v_salary
    FROM ems_employees
   WHERE emp_no = v_emp_no;

  v_bonus := v_salary * 0.10;
  v_net   := v_salary + v_bonus;

  INSERT INTO ems_payroll_runs (run_id, emp_id, run_month, run_year,
                                gross_salary, bonus_amount, net_salary)
  VALUES (seq_ems_run_id.NEXTVAL, v_emp_id, v_month, v_year,
          v_salary, v_bonus, v_net);

  INSERT INTO ems_audit_log (audit_id, module_name, action_desc)
  VALUES (seq_ems_audit_id.NEXTVAL,
          'DEMO035',
          'Payroll generated for ' || v_emp_no ||
          ' net=' || v_net);

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('  Payroll run created with net salary ' || v_net);
END;
/
-------------------------------------------------------------------------------
-- Demo 4: Anonymous block with error handling (invalid department)
-------------------------------------------------------------------------------
DECLARE
  v_dept_code ems_departments.dept_code%TYPE := 'XXX';
  v_count     NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 4: Try to count employees in invalid department ' || v_dept_code);

  BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM ems_employees e
      JOIN ems_departments d ON d.dept_id = e.dept_id
     WHERE d.dept_code = v_dept_code;

    DBMS_OUTPUT.PUT_LINE('  Employees found: ' || v_count);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('  No data found for department ' || v_dept_code);
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('  Unexpected error: ' || SQLERRM);
  END;
END;
/
-------------------------------------------------------------------------------
-- Demo 5: Batch audit of current headcount by department
-------------------------------------------------------------------------------
DECLARE
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 5: Headcount by department');

  FOR r IN (
    SELECT d.dept_code,
           d.dept_name,
           COUNT(e.emp_id) AS headcount
      FROM ems_departments d
      LEFT JOIN ems_employees e ON e.dept_id = d.dept_id
     GROUP BY d.dept_code, d.dept_name
     ORDER BY d.dept_code
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('  ' || r.dept_code || ' - ' || r.dept_name ||
                         ' -> ' || r.headcount || ' employees');

    INSERT INTO ems_audit_log (audit_id, module_name, action_desc)
    VALUES (seq_ems_audit_id.NEXTVAL,
            'DEMO035',
            'Headcount report: ' || r.dept_code ||
            ' has ' || r.headcount || ' employees');
  END LOOP;

  COMMIT;
END;
/
-------------------------------------------------------------------------------
-- End of demo_035_unnamed_execution_blocks.sql
-------------------------------------------------------------------------------
