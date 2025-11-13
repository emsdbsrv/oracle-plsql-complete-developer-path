SET SERVEROUTPUT ON SIZE UNLIMITED;

--------------------------------------------------------------------------------
-- Session 096 – Conditional and Column Triggers
-- Purpose:
--   Demonstrates WHEN clause filtering and column-specific triggers.
--   These reduce trigger overhead and enforce precise business rules.
--------------------------------------------------------------------------------

/******************************************************************************
EX1: Column-Specific Trigger – Fires only when SALARY column is updated
******************************************************************************/
CREATE OR REPLACE TRIGGER tg_emp_au_salary_only
AFTER UPDATE OF salary ON tg_employees
FOR EACH ROW
BEGIN
  DBMS_OUTPUT.PUT_LINE('Salary updated for Emp ID='||:OLD.emp_id);
END;
/
--------------------------------------------------------------------------------

/******************************************************************************
EX2: Conditional Trigger – Fires only when raise exceeds 20%
******************************************************************************/
CREATE OR REPLACE TRIGGER tg_emp_bu_high_raise
BEFORE UPDATE OF salary ON tg_employees
FOR EACH ROW
WHEN (NEW.salary > OLD.salary * 1.2)
BEGIN
  DBMS_OUTPUT.PUT_LINE('High raise detected for ID='||:OLD.emp_id);
END;
/
--------------------------------------------------------------------------------

/******************************************************************************
EX3: Department Change Trigger – WHEN OLD <> NEW
******************************************************************************/
CREATE OR REPLACE TRIGGER tg_emp_au_dept_change
AFTER UPDATE ON tg_employees
FOR EACH ROW
WHEN (OLD.dept_id <> NEW.dept_id)
BEGIN
  DBMS_OUTPUT.PUT_LINE('Dept changed: '||:OLD.dept_id||' -> '||:NEW.dept_id);
END;
/
--------------------------------------------------------------------------------

/******************************************************************************
EX4: Combined Conditional + Column Trigger
******************************************************************************/
CREATE OR REPLACE TRIGGER tg_emp_bu_salary_limit
BEFORE UPDATE OF salary ON tg_employees
FOR EACH ROW
WHEN (NEW.salary > 200000)
BEGIN
  RAISE_APPLICATION_ERROR(-36001,'Salary exceeds permitted max.');
END;
/
--------------------------------------------------------------------------------

/******************************************************************************
EX5: Conditional INSERT – Only dept 10 hires get notification
******************************************************************************/
CREATE OR REPLACE TRIGGER tg_emp_ai_dept10_notify
AFTER INSERT ON tg_employees
FOR EACH ROW
WHEN (NEW.dept_id = 10)
BEGIN
  DBMS_OUTPUT.PUT_LINE('Dept 10 hire: '||:NEW.emp_name);
END;
/
--------------------------------------------------------------------------------

-- End of Lesson
--------------------------------------------------------------------------------
