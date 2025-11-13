SET SERVEROUTPUT ON SIZE UNLIMITED;

--------------------------------------------------------------------------------
-- Assignment – Session 094: Row-Level Execution
-- 10 questions – all include fully commented solutions.
--------------------------------------------------------------------------------

/*********************************
Q1 BEFORE INSERT – Default salary if NULL
*********************************/
-- SOLUTION:
-- CREATE OR REPLACE TRIGGER tg_bi_row_default_salary
-- BEFORE INSERT ON tg_employees
-- FOR EACH ROW
-- BEGIN
--   IF :NEW.salary IS NULL THEN
--     :NEW.salary := 30000;
--   END IF;
-- END;
-- /
--------------------------------------------------------------------------------

/*********************************
Q2 BEFORE UPDATE – Block name change
*********************************/
-- SOLUTION:
-- CREATE OR REPLACE TRIGGER tg_bu_row_no_name_change
-- BEFORE UPDATE OF emp_name ON tg_employees
-- FOR EACH ROW
-- BEGIN
--   RAISE_APPLICATION_ERROR(-34002,'Name change not allowed.');
-- END;
-- /
--------------------------------------------------------------------------------

/*********************************
Q3 BEFORE DELETE – Prevent deletion of executives
*********************************/
-- SOLUTION:
-- CREATE OR REPLACE TRIGGER tg_bd_row_protect_exec
-- BEFORE DELETE ON tg_employees
-- FOR EACH ROW
-- BEGIN
--   IF :OLD.dept_id = 99 THEN
--     RAISE_APPLICATION_ERROR(-34003,'Executive record protected.');
--   END IF;
-- END;
-- /
--------------------------------------------------------------------------------

/*********************************
Q4 AFTER INSERT – Audit insert into custom audit table
*********************************/
-- SOLUTION:
-- INSERT INTO tg_employees_audit(
--   audit_id,emp_id,old_salary,new_salary,action_type,action_by,action_date)
-- VALUES(
--   tg_emp_audit_seq.NEXTVAL,
--   :NEW.emp_id,
--   NULL,
--   :NEW.salary,
--   'INSERT',
--   USER,
--   SYSDATE
-- );
--------------------------------------------------------------------------------

/*********************************
Q5 AFTER UPDATE – Log dept change only
*********************************/
-- SOLUTION:
-- IF :OLD.dept_id <> :NEW.dept_id THEN
--   DBMS_OUTPUT.PUT_LINE(
--     'Dept changed for ID '||:OLD.emp_id||
--     ' from '||:OLD.dept_id||' to '||:NEW.dept_id
--   );
-- END IF;
--------------------------------------------------------------------------------

/*********************************
Q6 BEFORE INSERT – Ensure dept_id not NULL
*********************************/
-- SOLUTION:
-- IF :NEW.dept_id IS NULL THEN
--   :NEW.dept_id := 1;
-- END IF;
--------------------------------------------------------------------------------

/*********************************
Q7 AFTER DELETE – Add deletion snapshot to history
*********************************/
-- SOLUTION:
-- INSERT INTO tg_employees_history(
--   hist_id,emp_id,old_name,old_salary,old_dept,modified_on)
-- VALUES(
--   tg_emp_audit_seq.NEXTVAL,
--   :OLD.emp_id,
--   :OLD.emp_name,
--   :OLD.salary,
--   :OLD.dept_id,
--   SYSDATE
-- );
--------------------------------------------------------------------------------

/*********************************
Q8 BEFORE UPDATE – Prevent salary > 200000
*********************************/
-- SOLUTION:
-- IF :NEW.salary > 200000 THEN
--   RAISE_APPLICATION_ERROR(-34004,'Salary too high.');
-- END IF;
--------------------------------------------------------------------------------

/*********************************
Q9 AFTER INSERT – Notify if emp_id < 5
*********************************/
-- SOLUTION:
-- IF :NEW.emp_id < 5 THEN
--   DBMS_OUTPUT.PUT_LINE('Special early ID: '||:NEW.emp_id);
-- END IF;
--------------------------------------------------------------------------------

/*********************************
Q10 BEFORE DELETE – Block delete on Mondays
*********************************/
-- SOLUTION:
-- IF TO_CHAR(SYSDATE,'DY') = 'MON' THEN
--   RAISE_APPLICATION_ERROR(-34005,'No deletes allowed on Monday.');
-- END IF;
--------------------------------------------------------------------------------

-- End Assignment
--------------------------------------------------------------------------------
