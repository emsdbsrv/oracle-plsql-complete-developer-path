-- Script: plsql_data_insertion_techniques.sql
-- Session: 031 - Data Insertion Techniques (Production Patterns)
-- Purpose:
--   Demonstrate robust INSERT patterns in PL/SQL with line-by-line commentary:
--   (1) Single-row INSERT + RETURNING INTO
--   (2) INSERT with DEFAULT VALUES / generated columns
--   (3) INSERT...SELECT (subquery insert)
--   (4) INSERT ALL (fan-out to multiple tables)
--   (5) INSERT FIRST (conditional routing)
--   (6) INSERT using sequence.NEXTVAL
--   (7) INSERT with validation and exception handling
--   (8) FORALL bulk INSERT with SAVE EXCEPTIONS (bonus)
-- How to run:
--   SET SERVEROUTPUT ON; Execute each block separately (terminated by '/').
-- Notes:
--   • Avoid 'SELECT then INSERT' round-trips; prefer RETURNING INTO where possible.
--   • Use anchored types to follow schema evolution.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Setup (idempotent) – base tables for this session
--------------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'DROP TABLE dept_ins PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE emp_ins PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE emp_audit PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE emp_ins_seq'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE dept_ins (
  dept_id    NUMBER       PRIMARY KEY,
  dept_name  VARCHAR2(50) NOT NULL
);
CREATE TABLE emp_ins (
  emp_id     NUMBER       PRIMARY KEY,
  emp_name   VARCHAR2(50) NOT NULL,
  dept_id    NUMBER       REFERENCES dept_ins(dept_id),
  salary     NUMBER(10,2) DEFAULT 50000,
  email      VARCHAR2(120),
  created_on DATE         DEFAULT SYSDATE
);
CREATE TABLE emp_audit (
  audit_id   NUMBER PRIMARY KEY,
  emp_id     NUMBER,
  action     VARCHAR2(20),
  note       VARCHAR2(200),
  created_on DATE DEFAULT SYSDATE
);
CREATE SEQUENCE emp_ins_seq START WITH 100 INCREMENT BY 1 NOCACHE;
INSERT INTO dept_ins VALUES (10,'Engineering');
INSERT INTO dept_ins VALUES (20,'Finance');
COMMIT;
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 1: Single-row INSERT with RETURNING INTO
-- Scenario:
--   Insert one employee and capture generated fields in one round-trip.
-- Drivers: anchored variables + RETURNING INTO.
-- Expected Output: 'inserted emp_id=... created_on=...'
--------------------------------------------------------------------------------
DECLARE
  v_emp_id   emp_ins.emp_id%TYPE := 1;
  v_name     emp_ins.emp_name%TYPE := 'Avi';
  v_dept     emp_ins.dept_id%TYPE := 10;
  v_created  emp_ins.created_on%TYPE;
BEGIN
  INSERT INTO emp_ins(emp_id, emp_name, dept_id, email)
  VALUES (v_emp_id, v_name, v_dept, 'avi@example.com')
  RETURNING created_on INTO v_created;

  DBMS_OUTPUT.PUT_LINE('inserted emp_id='||v_emp_id||' created_on='||TO_CHAR(v_created,'YYYY-MM-DD'));
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 2: INSERT with DEFAULT VALUES / generated columns
-- Scenario:
--   Rely on DEFAULT for salary and created_on; supply only required fields.
-- Expected Output: salary defaults to 50000, created_on ~ SYSDATE.
--------------------------------------------------------------------------------
DECLARE
  v_emp_id emp_ins.emp_id%TYPE := 2;
BEGIN
  INSERT INTO emp_ins(emp_id, emp_name, dept_id)
  VALUES (v_emp_id, 'Raj', 10);
  DBMS_OUTPUT.PUT_LINE('rows='||SQL%ROWCOUNT);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 3: INSERT...SELECT (subquery insert)
-- Scenario:
--   Insert 'ghost' employee for each dept via a set-based statement.
-- Expected Output: one new row per dept.
--------------------------------------------------------------------------------
BEGIN
  INSERT INTO emp_ins(emp_id, emp_name, dept_id, email)
  SELECT emp_ins_seq.NEXTVAL, 'Dept-Ghost-'||d.dept_id, d.dept_id, 'ghost'||d.dept_id||'@example.com'
  FROM   dept_ins d;
  DBMS_OUTPUT.PUT_LINE('inserted via subquery rows='||SQL%ROWCOUNT);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 4: INSERT ALL (fan-out into multiple tables)
-- Scenario:
--   From a single source row, insert into emp_ins and an audit table.
-- Expected Output: two target tables receive rows.
--------------------------------------------------------------------------------
DECLARE
  v_id  emp_ins.emp_id%TYPE := 3;
  v_nm  emp_ins.emp_name%TYPE := 'Mani';
  v_dp  emp_ins.dept_id%TYPE := 20;
BEGIN
  INSERT ALL
    INTO emp_ins(emp_id, emp_name, dept_id, email) VALUES (v_id, v_nm, v_dp, 'mani@example.com')
    INTO emp_audit(audit_id, emp_id, action, note)  VALUES (emp_ins_seq.NEXTVAL, v_id, 'INSERT', 'Onboarded')
  SELECT 1 FROM dual;

  DBMS_OUTPUT.PUT_LINE('multi-target insert rows='||SQL%ROWCOUNT);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 5: INSERT FIRST (conditional routing)
-- Scenario:
--   Route to Finance vs Engineering welcome audit based on dept_id.
-- Expected Output: Only first matching WHEN executes per source row.
--------------------------------------------------------------------------------
DECLARE
  v_emp_id emp_ins.emp_id%TYPE := 4;
  v_dept   emp_ins.dept_id%TYPE := 20; -- change to 10 to see other branch
BEGIN
  INSERT FIRST
    WHEN v_dept = 20 THEN
      INTO emp_audit(audit_id, emp_id, action, note) VALUES (emp_ins_seq.NEXTVAL, v_emp_id, 'WELCOME', 'Finance flow')
    WHEN v_dept = 10 THEN
      INTO emp_audit(audit_id, emp_id, action, note) VALUES (emp_ins_seq.NEXTVAL, v_emp_id, 'WELCOME', 'Engineering flow')
  SELECT 1 FROM dual;

  DBMS_OUTPUT.PUT_LINE('conditional audit rows='||SQL%ROWCOUNT);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 6: INSERT using sequence.NEXTVAL
-- Scenario:
--   Generate surrogate keys using a sequence; capture the value with RETURNING INTO.
-- Expected Output: prints new emp_id and email.
--------------------------------------------------------------------------------
DECLARE
  v_new_id emp_ins.emp_id%TYPE;
  v_email  emp_ins.email%TYPE;
BEGIN
  v_new_id := emp_ins_seq.NEXTVAL;
  INSERT INTO emp_ins(emp_id, emp_name, dept_id, email)
  VALUES (v_new_id, 'Neha', 20, 'neha@example.com')
  RETURNING email INTO v_email;

  DBMS_OUTPUT.PUT_LINE('inserted id='||v_new_id||' email='||v_email);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 7: INSERT with validation and exception handling
-- Scenario:
--   Validate dept exists before INSERT; handle foreign key/unique violations gracefully.
-- Expected Output: Friendly messages instead of unhandled errors.
--------------------------------------------------------------------------------
DECLARE
  v_emp_id emp_ins.emp_id%TYPE := 2; -- duplicate on purpose to show unique handling
  v_dept   emp_ins.dept_id%TYPE := 99; -- non-existent to show validation
  v_exists PLS_INTEGER;
BEGIN
  -- Validate department (prevent FK error later)
  SELECT COUNT(*) INTO v_exists FROM dept_ins WHERE dept_id = v_dept;
  IF v_exists = 0 THEN
    DBMS_OUTPUT.PUT_LINE('Abort: dept_id '||v_dept||' does not exist');
    RETURN;
  END IF;

  INSERT INTO emp_ins(emp_id, emp_name, dept_id) VALUES (v_emp_id, 'Duplicate', v_dept);
  DBMS_OUTPUT.PUT_LINE('insert ok');
EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN
    DBMS_OUTPUT.PUT_LINE('Handled: duplicate emp_id='||v_emp_id);
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Unhandled insert error: '||SQLERRM);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 8: FORALL bulk INSERT with SAVE EXCEPTIONS (bonus)
-- Scenario:
--   Bulk insert 4 rows; catch per-row failures without aborting entire batch.
-- Expected Output: Report failures; commit successes.
--------------------------------------------------------------------------------
DECLARE
  TYPE t_emp IS TABLE OF emp_ins%ROWTYPE;
  v_rows t_emp := t_emp();
  errors EXCEPTION; PRAGMA EXCEPTION_INIT(errors, -24381); -- ORA-24381: errors in array DML
  v_success PLS_INTEGER := 0;
BEGIN
  -- NOTE: We must populate required columns; emp_id unique will cause one failure.
  v_rows.EXTEND(4);
  v_rows(1).emp_id := 5; v_rows(1).emp_name := 'Kavya'; v_rows(1).dept_id := 10; v_rows(1).email := 'kavya@example.com';
  v_rows(2).emp_id := 6; v_rows(2).emp_name := 'Isha';  v_rows(2).dept_id := 20; v_rows(2).email := 'isha@example.com';
  v_rows(3).emp_id := 2; v_rows(3).emp_name := 'DupID'; v_rows(3).dept_id := 10; v_rows(3).email := 'dup@example.com'; -- duplicate
  v_rows(4).emp_id := 7; v_rows(4).emp_name := 'Om';    v_rows(4).dept_id := 10; v_rows(4).email := 'om@example.com';

  SAVEPOINT bulk_start;
  BEGIN
    FORALL i IN 1..v_rows.COUNT SAVE EXCEPTIONS
      INSERT INTO emp_ins(emp_id, emp_name, dept_id, email)
      VALUES (v_rows(i).emp_id, v_rows(i).emp_name, v_rows(i).dept_id, v_rows(i).email);

    v_success := SQL%ROWCOUNT; -- rows affected (may not include failed)
    DBMS_OUTPUT.PUT_LINE('bulk insert attempted; reported success count='||v_success);
  EXCEPTION
    WHEN errors THEN
      DBMS_OUTPUT.PUT_LINE('Bulk exceptions count='||SQL%BULK_EXCEPTIONS.COUNT);
      FOR j IN 1..SQL%BULK_EXCEPTIONS.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE('  idx='||SQL%BULK_EXCEPTIONS(j).ERROR_INDEX||' err='||SQL%BULK_EXCEPTIONS(j).ERROR_CODE);
      END LOOP;
  END;

  COMMIT; -- commit successes
END;
/
--------------------------------------------------------------------------------
-- End of File
--------------------------------------------------------------------------------
