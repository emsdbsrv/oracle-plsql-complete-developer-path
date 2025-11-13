
SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Assignment – Session 092 AFTER Trigger Timing
-- 10 Questions – All with fully commented solutions
--------------------------------------------------------------------------------

/*********************************
Q1 AFTER INSERT – Log new employee name
*********************************/
-- SOLUTION:
-- CREATE OR REPLACE TRIGGER tg_ai_logname
-- AFTER INSERT ON tg_employees
-- FOR EACH ROW
-- BEGIN
--   DBMS_OUTPUT.PUT_LINE('New employee: '||:NEW.emp_name);
-- END;
-- /

/*********************************
Q2 AFTER UPDATE – Audit salary raise only if increase > 10000
*********************************/
-- SOLUTION:
-- CREATE OR REPLACE TRIGGER tg_au_bigraise
-- AFTER UPDATE OF salary ON tg_employees
-- FOR EACH ROW
-- BEGIN
--   IF :NEW.salary - :OLD.salary > 10000 THEN
--     INSERT INTO tg_employees_audit(
--       audit_id,emp_id,old_salary,new_salary,action_type,action_by,action_date)
--     VALUES(
--       tg_emp_audit_seq.NEXTVAL,
--       :OLD.emp_id,
--       :OLD.salary,
--       :NEW.salary,
--       'BIG_RAISE',
--       USER,
--       SYSDATE
--     );
--   END IF;
-- END;
-- /

/*********************************
Q3 AFTER DELETE – Log deleted ID
*********************************/
-- SOLUTION:
-- CREATE OR REPLACE TRIGGER tg_ad_id
-- AFTER DELETE ON tg_employees
-- FOR EACH ROW
-- BEGIN
--   DBMS_OUTPUT.PUT_LINE('Deleted ID: '||:OLD.emp_id);
-- END;
-- /

/*********************************
Q4 AFTER INSERT – Add snapshot to history
*********************************/
-- SOLUTION:
-- CREATE OR REPLACE TRIGGER tg_ai_snapshot
-- AFTER INSERT ON tg_employees
-- FOR EACH ROW
-- BEGIN
--   INSERT INTO tg_employees_history(
--     hist_id,emp_id,old_name,old_salary,old_dept,modified_on)
--   VALUES(
--     tg_emp_audit_seq.NEXTVAL,
--     :NEW.emp_id,
--     :NEW.emp_name,
--     :NEW.salary,
--     :NEW.dept_id,
--     SYSDATE
--   );
-- END;
-- /

/*********************************
Q5 AFTER UPDATE – Prevent silent department drift (log to DB)
*********************************/
-- SOLUTION:
-- INSERT INTO tg_employees_audit(
--   audit_id,emp_id,old_salary,new_salary,action_type,action_by,action_date)
-- VALUES(
--   tg_emp_audit_seq.NEXTVAL,
--   :OLD.emp_id,
--   NULL,
--   NULL,
--   'DEPT_CHANGE',
--   USER,
--   SYSDATE
-- );

/*********************************
Q6 AFTER INSERT – Send welcome message for salary > 100000
*********************************/
-- SOLUTION:
-- IF :NEW.salary > 100000 THEN
--   DBMS_OUTPUT.PUT_LINE('Welcome high-value employee: '||:NEW.emp_name);
-- END IF;

/*********************************
Q7 AFTER DELETE – Add to special delete_log table
*********************************/
-- SOLUTION:
-- INSERT INTO delete_log(emp_id,deleted_on)
-- VALUES(:OLD.emp_id,SYSDATE);

/*********************************
Q8 AFTER UPDATE – Notify if dept changed to 10
*********************************/
-- SOLUTION:
-- IF :NEW.dept_id = 10 AND :OLD.dept_id <> 10 THEN
--   DBMS_OUTPUT.PUT_LINE('Moved to dept 10: '||:OLD.emp_id);
-- END IF;

/*********************************
Q9 AFTER INSERT – Prevent negative salary (should not happen)
*********************************/
-- SOLUTION:
-- IF :NEW.salary < 0 THEN
--   RAISE_APPLICATION_ERROR(-32010,'Negative salary detected.');
-- END IF;

/*********************************
Q10 AFTER UPDATE – Create audit entry for ANY non-null attribute update
*********************************/
-- SOLUTION:
-- INSERT INTO tg_employees_audit(
--   audit_id,emp_id,old_salary,new_salary,action_type,action_by,action_date)
-- VALUES(
--   tg_emp_audit_seq.NEXTVAL,
--   :OLD.emp_id,
--   :OLD.salary,
--   :NEW.salary,
--   'GENERIC_UPDATE',
--   USER,
--   SYSDATE
-- );

--------------------------------------------------------------------------------
-- End Assignment
--------------------------------------------------------------------------------
