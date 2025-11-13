SET SERVEROUTPUT ON SIZE UNLIMITED;

--------------------------------------------------------------------------------
-- Session 095 – Pseudo-Record Access (:OLD and :NEW)
-- Purpose:
--   Demonstrate how :OLD and :NEW provide row context inside row-level triggers.
--   Used for:
--     • Value comparisons
--     • Auditing
--     • Validation
--     • History tracking
--------------------------------------------------------------------------------

/******************************************************************************
EX1: INSERT – :NEW available, :OLD is NULL
******************************************************************************/
CREATE OR REPLACE TRIGGER tg_emp_ai_show_new
AFTER INSERT ON tg_employees
FOR EACH ROW
BEGIN
  DBMS_OUTPUT.PUT_LINE('Inserted Emp Name = '||:NEW.emp_name);
END;
/
--------------------------------------------------------------------------------

/******************************************************************************
EX2: DELETE – :OLD available, :NEW is NULL
******************************************************************************/
CREATE OR REPLACE TRIGGER tg_emp_ad_show_old
AFTER DELETE ON tg_employees
FOR EACH ROW
BEGIN
  DBMS_OUTPUT.PUT_LINE('Deleted Emp Name = '||:OLD.emp_name);
END;
/
--------------------------------------------------------------------------------

/******************************************************************************
EX3: UPDATE – compare :OLD and :NEW values
******************************************************************************/
CREATE OR REPLACE TRIGGER tg_emp_au_compare
AFTER UPDATE ON tg_employees
FOR EACH ROW
BEGIN
  DBMS_OUTPUT.PUT_LINE(
    'Name changed from '||:OLD.emp_name||' to '||:NEW.emp_name
  );
END;
/
--------------------------------------------------------------------------------

/******************************************************************************
EX4: UPDATE salary validation using pseudo-records
******************************************************************************/
CREATE OR REPLACE TRIGGER tg_emp_bu_salary_validate
BEFORE UPDATE OF salary ON tg_employees
FOR EACH ROW
BEGIN
  IF :NEW.salary < :OLD.salary THEN
    RAISE_APPLICATION_ERROR(-35001,'Salary cannot be reduced.');
  END IF;
END;
/
--------------------------------------------------------------------------------

/******************************************************************************
EX5: History archive example using :OLD
******************************************************************************/
CREATE OR REPLACE TRIGGER tg_emp_ad_hist_archive
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

-- End Lesson
--------------------------------------------------------------------------------
