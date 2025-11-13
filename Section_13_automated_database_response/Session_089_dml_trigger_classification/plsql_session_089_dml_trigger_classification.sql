
SET SERVEROUTPUT ON;
--------------------------------------------------------------------------------
-- Session 089 – DML Trigger Classification
-- This script explains trigger categories and provides 7 detailed examples.
--------------------------------------------------------------------------------

/******************************************************************************
EX1: BEFORE INSERT row-level trigger – validate salary
******************************************************************************/
CREATE OR REPLACE TRIGGER tg_emp_bi_row
BEFORE INSERT ON tg_employees
FOR EACH ROW
BEGIN
  IF :NEW.salary < 0 THEN
    RAISE_APPLICATION_ERROR(-20001,'Salary cannot be negative.');
  END IF;
END;
/
--------------------------------------------------------------------------------

/******************************************************************************
EX2: BEFORE UPDATE statement-level trigger – log event
******************************************************************************/
CREATE OR REPLACE TRIGGER tg_emp_bu_stmt
BEFORE UPDATE ON tg_employees
BEGIN
  DBMS_OUTPUT.PUT_LINE('Update statement detected on employees table.');
END;
/
--------------------------------------------------------------------------------

/******************************************************************************
EX3: AFTER INSERT row-level trigger – write audit record
******************************************************************************/
CREATE OR REPLACE TRIGGER tg_emp_ai_row
AFTER INSERT ON tg_employees
FOR EACH ROW
BEGIN
  INSERT INTO tg_employees_audit(
    audit_id,emp_id,old_salary,new_salary,action_type,action_by,action_date)
  VALUES(
    tg_emp_audit_seq.NEXTVAL,
    :NEW.emp_id,
    NULL,
    :NEW.salary,
    'INSERT',
    USER,
    SYSDATE
  );
END;
/
--------------------------------------------------------------------------------

/******************************************************************************
EX4: AFTER UPDATE row-level trigger – salary change logging
******************************************************************************/
CREATE OR REPLACE TRIGGER tg_emp_au_row
AFTER UPDATE OF salary ON tg_employees
FOR EACH ROW
BEGIN
  INSERT INTO tg_employees_audit(
    audit_id,emp_id,old_salary,new_salary,action_type,action_by,action_date)
  VALUES(
    tg_emp_audit_seq.NEXTVAL,
    :OLD.emp_id,
    :OLD.salary,
    :NEW.salary,
    'UPDATE',
    USER,
    SYSDATE
  );
END;
/
--------------------------------------------------------------------------------

/******************************************************************************
EX5: BEFORE DELETE row-level trigger – archive to history
******************************************************************************/
CREATE OR REPLACE TRIGGER tg_emp_bd_row
BEFORE DELETE ON tg_employees
FOR EACH ROW
BEGIN
  INSERT INTO tg_employees_history(hist_id,emp_id,old_name,old_salary,old_dept,modified_on)
  VALUES(
    tg_emp_audit_seq.NEXTVAL,
    :OLD.emp_id,
    :OLD.emp_name,
    :OLD.salary,
    :OLD.dept_id,
    SYSDATE
  );
END;
/
--------------------------------------------------------------------------------

/******************************************************************************
EX6: Statement-level DELETE trigger – log message
******************************************************************************/
CREATE OR REPLACE TRIGGER tg_emp_bd_stmt
BEFORE DELETE ON tg_employees
BEGIN
  DBMS_OUTPUT.PUT_LINE('DELETE operation started');
END;
/
--------------------------------------------------------------------------------

/******************************************************************************
EX7: Conditional trigger – fire only for specific department
******************************************************************************/
CREATE OR REPLACE TRIGGER tg_emp_cond_row
AFTER UPDATE ON tg_employees
FOR EACH ROW
WHEN (OLD.dept_id = 10)
BEGIN
  DBMS_OUTPUT.PUT_LINE('Employee from dept 10 updated.');
END;
/
--------------------------------------------------------------------------------
-- End of Lesson
--------------------------------------------------------------------------------
