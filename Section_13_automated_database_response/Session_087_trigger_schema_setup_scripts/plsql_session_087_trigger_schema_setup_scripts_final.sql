SET SERVEROUTPUT ON SIZE UNLIMITED;
--------------------------------------------------------------------------------
-- Session 087 – Trigger Schema Setup Scripts (Final Full Version)
-- Purpose:
--   Provide all schema objects required for building and testing triggers,
--   including base tables, audit tables, history tables, error log tables,
--   and sequences.
--------------------------------------------------------------------------------

/******************************************************************************
 EXAMPLE 1 – Base Table
******************************************************************************/
CREATE TABLE tg_employees(
  emp_id     NUMBER PRIMARY KEY,
  emp_name   VARCHAR2(50),
  salary     NUMBER,
  dept_id    NUMBER,
  created_on DATE DEFAULT SYSDATE
);
--------------------------------------------------------------------------------

/******************************************************************************
 EXAMPLE 2 – Audit Table
******************************************************************************/
CREATE TABLE tg_employees_audit(
  audit_id     NUMBER,
  emp_id       NUMBER,
  old_salary   NUMBER,
  new_salary   NUMBER,
  action_type  VARCHAR2(20),
  action_by    VARCHAR2(50),
  action_date  DATE
);
--------------------------------------------------------------------------------

/******************************************************************************
 EXAMPLE 3 – Audit Table Sequence
******************************************************************************/
CREATE SEQUENCE tg_emp_audit_seq START WITH 1 INCREMENT BY 1;
--------------------------------------------------------------------------------

/******************************************************************************
 EXAMPLE 4 – History Table (Archival)
******************************************************************************/
CREATE TABLE tg_employees_history(
  hist_id     NUMBER,
  emp_id      NUMBER,
  old_name    VARCHAR2(50),
  old_salary  NUMBER,
  old_dept    NUMBER,
  modified_on DATE
);
--------------------------------------------------------------------------------

/******************************************************************************
 EXAMPLE 5 – Error Log Table
******************************************************************************/
CREATE TABLE tg_error_log(
  err_id      NUMBER,
  emp_id      NUMBER,
  err_message VARCHAR2(4000),
  created_on  DATE
);
--------------------------------------------------------------------------------

/******************************************************************************
 EXAMPLE 6 – Insert Seed Data
******************************************************************************/
INSERT INTO tg_employees VALUES (1,'Avi',50000,10,SYSDATE);
INSERT INTO tg_employees VALUES (2,'Raj',60000,20,SYSDATE);
COMMIT;
--------------------------------------------------------------------------------

/******************************************************************************
 EXAMPLE 7 – Validate Setup
******************************************************************************/
BEGIN
  DBMS_OUTPUT.PUT_LINE('Employees Count='||(SELECT COUNT(*) FROM tg_employees));
END;
/
--------------------------------------------------------------------------------
-- End Lesson
--------------------------------------------------------------------------------
