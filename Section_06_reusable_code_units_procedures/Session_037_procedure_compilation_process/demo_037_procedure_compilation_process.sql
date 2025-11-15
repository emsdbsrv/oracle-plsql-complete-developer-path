-- demo_037_procedure_compilation_process.sql
-- Session 037: Procedure Compilation Process
-- Focus: How procedures compile, how to detect errors, and recompile.


SET SERVEROUTPUT ON;

-------------------------------------------------------------------------------
-- COMMON BUSINESS SCHEMA (EMS) - USED BY ALL PROCEDURE DEMOS
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
-- END COMMON EMS SCHEMA
-------------------------------------------------------------------------------


SET SERVEROUTPUT ON;

-------------------------------------------------------------------------------
-- Demo 1: Create a valid procedure and show it compiles without errors
-------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE demo37_valid_proc
IS
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 1: demo37_valid_proc compiled and executed.');
END demo37_valid_proc;
/
BEGIN
  demo37_valid_proc;
END;
/
-------------------------------------------------------------------------------
-- Demo 2: Intentionally create an invalid procedure and query USER_ERRORS
-------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 2: Creating an invalid procedure demo37_invalid_proc');
END;
/
CREATE OR REPLACE PROCEDURE demo37_invalid_proc
IS
BEGIN
  -- This will fail because table name is wrong (ems_employeez vs ems_employees)
  UPDATE ems_employeez
     SET salary = salary * 1.10;
END demo37_invalid_proc;
/
-- Compile-time errors are now stored in USER_ERRORS
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 2: Listing USER_ERRORS for demo37_INVALID_PROC');
  FOR r IN (
    SELECT name, type, line, position, text
      FROM user_errors
     WHERE name = 'DEMO37_INVALID_PROC'
     ORDER BY sequence
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('  ' || r.type || ' ' || r.name ||
                         ' line ' || r.line || ':' || r.position ||
                         ' -> ' || r.text);
  END LOOP;
END;
/
-------------------------------------------------------------------------------
-- Demo 3: Correct the procedure and recompile successfully
-------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE demo37_invalid_proc
IS
BEGIN
  UPDATE ems_employees
     SET salary = salary * 1.10;
END demo37_invalid_proc;
/
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 3: After fix, calling demo37_invalid_proc');
  demo37_invalid_proc;
END;
/
-------------------------------------------------------------------------------
-- Demo 4: Procedure depending on another procedure (dependency chain)
-------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE demo37_base_proc
IS
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 4: demo37_base_proc called.');
END demo37_base_proc;
/
CREATE OR REPLACE PROCEDURE demo37_wrapper_proc
IS
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 4: demo37_wrapper_proc calling base...');
  demo37_base_proc;
END demo37_wrapper_proc;
/
BEGIN
  demo37_wrapper_proc;
END;
/
-------------------------------------------------------------------------------
-- Demo 5: Force recompile using ALTER PROCEDURE
-------------------------------------------------------------------------------
ALTER PROCEDURE demo37_base_proc COMPILE;
ALTER PROCEDURE demo37_wrapper_proc COMPILE;

BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 5: After ALTER COMPILE, calling wrapper again.');
  demo37_wrapper_proc;
END;
/
-------------------------------------------------------------------------------
-- End of demo_037_procedure_compilation_process.sql
-------------------------------------------------------------------------------
