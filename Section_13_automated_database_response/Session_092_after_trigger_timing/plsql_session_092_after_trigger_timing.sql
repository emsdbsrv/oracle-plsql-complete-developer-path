
SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Session 092 – AFTER Trigger Timing
-- AFTER triggers fire only after successful DML completion.
-- Ideal for audit, history, notifications, asynchronous logic.
--------------------------------------------------------------------------------

/******************************************************************************
EX1: AFTER INSERT – Write audit row
******************************************************************************/
CREATE OR REPLACE TRIGGER tg_emp_ai_audit
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
EX2: AFTER UPDATE – Track all salary updates
******************************************************************************/
CREATE OR REPLACE TRIGGER tg_emp_au_salary
AFTER UPDATE OF salary ON tg_employees
FOR EACH ROW
BEGIN
  DBMS_OUTPUT.PUT_LINE('Salary changed from '||:OLD.salary||' to '||:NEW.salary);
END;
/
--------------------------------------------------------------------------------

/******************************************************************************
EX3: AFTER DELETE – Archive deleted rows to history
******************************************************************************/
CREATE OR REPLACE TRIGGER tg_emp_ad_hist
AFTER DELETE ON tg_employees
FOR EACH ROW
BEGIN
  INSERT INTO tg_employees_history(
    hist_id,emp_id,old_name,old_salary,old_dept,modified_on)
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
EX4: AFTER UPDATE – Log department changes
******************************************************************************/
CREATE OR REPLACE TRIGGER tg_emp_au_dept
AFTER UPDATE OF dept_id ON tg_employees
FOR EACH ROW
BEGIN
  DBMS_OUTPUT.PUT_LINE('Dept changed from '||:OLD.dept_id||' to '||:NEW.dept_id);
END;
/
--------------------------------------------------------------------------------

/******************************************************************************
EX5: AFTER INSERT – Notify when executive added
******************************************************************************/
CREATE OR REPLACE TRIGGER tg_emp_ai_exec
AFTER INSERT ON tg_employees
FOR EACH ROW
WHEN (:NEW.dept_id = 99)
BEGIN
  DBMS_OUTPUT.PUT_LINE('Executive added: '||:NEW.emp_name);
END;
/
--------------------------------------------------------------------------------
-- End Lesson
--------------------------------------------------------------------------------
