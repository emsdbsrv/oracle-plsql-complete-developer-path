
SET SERVEROUTPUT ON;
--------------------------------------------------------------------------------
-- Session 091 – BEFORE Trigger Timing
-- Purpose:
--   Demonstrate BEFORE INSERT/UPDATE/DELETE behavior with detailed examples.
--------------------------------------------------------------------------------

/******************************************************************************
EX1: BEFORE INSERT – Standardize names to uppercase
******************************************************************************/
CREATE OR REPLACE TRIGGER tg_emp_bi_upper
BEFORE INSERT ON tg_employees
FOR EACH ROW
BEGIN
  :NEW.emp_name := UPPER(:NEW.emp_name);
END;
/
--------------------------------------------------------------------------------

/******************************************************************************
EX2: BEFORE INSERT – Enforce minimum salary
******************************************************************************/
CREATE OR REPLACE TRIGGER tg_emp_bi_minsal
BEFORE INSERT ON tg_employees
FOR EACH ROW
BEGIN
  IF :NEW.salary < 20000 THEN
    RAISE_APPLICATION_ERROR(-30001,'Minimum salary is 20000');
  END IF;
END;
/
--------------------------------------------------------------------------------

/******************************************************************************
EX3: BEFORE UPDATE – Prevent department change for executives
******************************************************************************/
CREATE OR REPLACE TRIGGER tg_emp_bu_nodeptchange
BEFORE UPDATE OF dept_id ON tg_employees
FOR EACH ROW
BEGIN
  IF :OLD.dept_id = 99 THEN
    RAISE_APPLICATION_ERROR(-30002,'Executive department cannot be changed');
  END IF;
END;
/
--------------------------------------------------------------------------------

/******************************************************************************
EX4: BEFORE UPDATE – Auto-adjust salary (business rule)
******************************************************************************/
CREATE OR REPLACE TRIGGER tg_emp_bu_autosalary
BEFORE UPDATE OF salary ON tg_employees
FOR EACH ROW
BEGIN
  IF :NEW.salary < :OLD.salary THEN
    :NEW.salary := :OLD.salary;  -- enforce no salary reduction
  END IF;
END;
/
--------------------------------------------------------------------------------

/******************************************************************************
EX5: BEFORE DELETE – Block deletion during business hours
******************************************************************************/
CREATE OR REPLACE TRIGGER tg_emp_bd_businessblock
BEFORE DELETE ON tg_employees
FOR EACH ROW
BEGIN
  IF TO_CHAR(SYSDATE,'HH24') BETWEEN '09' AND '18' THEN
    RAISE_APPLICATION_ERROR(-30003,'Deletion not allowed during business hours');
  END IF;
END;
/
--------------------------------------------------------------------------------

-- End Lesson
--------------------------------------------------------------------------------
