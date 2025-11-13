SET SERVEROUTPUT ON SIZE UNLIMITED;
--------------------------------------------------------------------------------
-- Session 094 – Row-Level Execution
-- Purpose:
--   Row-level triggers fire once for each affected row. They are ideal for:
--     • Validations
--     • Row-by-row auditing
--     • History tracking
--     • Conditional constraints
--------------------------------------------------------------------------------

/******************************************************************************
EX1: BEFORE INSERT (row-level) – enforce uppercase name
******************************************************************************/
CREATE OR REPLACE TRIGGER tg_emp_bi_row_upper
BEFORE INSERT ON tg_employees
FOR EACH ROW
BEGIN
  :NEW.emp_name := UPPER(:NEW.emp_name);
END;
/
--------------------------------------------------------------------------------

/******************************************************************************
EX2: BEFORE UPDATE (row-level) – prevent lowering salary
******************************************************************************/
CREATE OR REPLACE TRIGGER tg_emp_bu_row_salary
BEFORE UPDATE OF salary ON tg_employees
FOR EACH ROW
BEGIN
  IF :NEW.salary < :OLD.salary THEN
    RAISE_APPLICATION_ERROR(-34001,'Salary cannot be decreased.');
  END IF;
END;
/
--------------------------------------------------------------------------------

/******************************************************************************
EX3: AFTER UPDATE (row-level) – audit salary change into audit table
******************************************************************************/
CREATE OR REPLACE TRIGGER tg_emp_au_row_salary_audit
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
    'SALARY_UPDATE',
    USER,
    SYSDATE
  );
END;
/
--------------------------------------------------------------------------------

/******************************************************************************
EX4: BEFORE DELETE (row-level) – archive row into history table
******************************************************************************/
CREATE OR REPLACE TRIGGER tg_emp_bd_row_history
BEFORE DELETE ON tg_employees
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
EX5: AFTER INSERT (row-level) – notification trigger
******************************************************************************/
CREATE OR REPLACE TRIGGER tg_emp_ai_row_notify
AFTER INSERT ON tg_employees
FOR EACH ROW
WHEN (NEW.dept_id = 10)
BEGIN
  DBMS_OUTPUT.PUT_LINE('New Dept 10 hire: '||:NEW.emp_name);
END;
/
--------------------------------------------------------------------------------

-- End Lesson
--------------------------------------------------------------------------------
