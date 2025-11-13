SET SERVEROUTPUT ON SIZE UNLIMITED;

--------------------------------------------------------------------------------
-- Assignment – Session 088: Event-Driven Programming Model
-- 10 tasks with fully commented solutions.
-- Each solution block is commented; copy, uncomment, and run to practice.
--------------------------------------------------------------------------------


/**********************************
 Q1 – BEFORE INSERT trigger defaulting
 Task:
   For tg_employees, write a BEFORE INSERT row trigger that:
     • Sets dept_id to 99 when caller passes NULL.
**********************************/
-- Solution:
-- CREATE OR REPLACE TRIGGER trg_emp_bi_default_dept
-- BEFORE INSERT ON tg_employees
-- FOR EACH ROW
-- BEGIN
--   IF :NEW.dept_id IS NULL THEN
--     :NEW.dept_id := 99;
--   END IF;
-- END;
-- /
--------------------------------------------------------------------------------


/**********************************
 Q2 – AFTER INSERT audit trigger for new employees
 Task:
   Insert a row into tg_employees_audit with action_type = 'INSERT'
   whenever a new employee is inserted.
**********************************/
-- Solution:
-- CREATE OR REPLACE TRIGGER trg_emp_ai_audit_insert
-- AFTER INSERT ON tg_employees
-- FOR EACH ROW
-- BEGIN
--   INSERT INTO tg_employees_audit (
--     audit_id, emp_id, old_salary, new_salary,
--     action_type, action_by, action_date
--   )
--   VALUES (
--     tg_emp_audit_seq.NEXTVAL,
--     :NEW.emp_id,
--     NULL,
--     :NEW.salary,
--     'INSERT',
--     USER,
--     SYSDATE
--   );
-- END;
-- /
--------------------------------------------------------------------------------


/**********************************
 Q3 – BEFORE UPDATE validate salary increase
 Task:
   Prevent an UPDATE that increases salary by more than 50 percent.
   If violated, raise an application error.
**********************************/
-- Solution:
-- CREATE OR REPLACE TRIGGER trg_emp_bu_limit_raise
-- BEFORE UPDATE OF salary ON tg_employees
-- FOR EACH ROW
-- BEGIN
--   IF :OLD.salary IS NOT NULL
--      AND :NEW.salary > :OLD.salary * 1.5 THEN
--     RAISE_APPLICATION_ERROR(-20001,'Raise exceeds 50 percent limit');
--   END IF;
-- END;
-- /
--------------------------------------------------------------------------------


/**********************************
 Q4 – AFTER DELETE history trigger
 Task:
   On DELETE from tg_employees, store old row in tg_employees_history.
**********************************/
-- Solution:
-- CREATE OR REPLACE TRIGGER trg_emp_ad_history
-- AFTER DELETE ON tg_employees
-- FOR EACH ROW
-- BEGIN
--   INSERT INTO tg_employees_history(
--     hist_id, emp_id, old_name, old_salary, old_dept, modified_on
--   )
--   VALUES(
--     :OLD.emp_id,
--     :OLD.emp_id,
--     :OLD.emp_name,
--     :OLD.salary,
--     :OLD.dept_id,
--     SYSDATE
--   );
-- END;
-- /
--------------------------------------------------------------------------------


/**********************************
 Q5 – Statement-level UPDATE trigger
 Task:
   Log one row into tg_error_log (or a logging table) every time an UPDATE
   statement touches tg_employees, regardless of number of rows affected.
**********************************/
-- Solution:
-- CREATE OR REPLACE TRIGGER trg_emp_au_stmt_log
-- AFTER UPDATE ON tg_employees
-- DECLARE
--   v_ts DATE := SYSDATE;
-- BEGIN
--   INSERT INTO tg_error_log (err_id, emp_id, err_message, created_on)
--   VALUES (0, NULL, 'Employees table updated', v_ts);
-- END;
-- /
--------------------------------------------------------------------------------


/**********************************
 Q6 – DDL trigger for DROP on schema
 Task:
   When any object is DROPPED in the schema, record an entry in ddl_event_log.
**********************************/
-- Solution:
-- CREATE OR REPLACE TRIGGER trg_ddl_after_drop
-- AFTER DROP ON SCHEMA
-- BEGIN
--   INSERT INTO ddl_event_log(username, object_name, object_type, event_date)
--   VALUES(SYS.LOGIN_USER, ORA_DICT_OBJ_NAME, ORA_DICT_OBJ_TYPE, SYSDATE);
-- END;
-- /
--------------------------------------------------------------------------------


/**********************************
 Q7 – LOGOFF system trigger
 Task:
   Create a trigger that logs username and logoff time into logon_event_log
   when a user logs off. (Use a separate column or reuse existing one.)
**********************************/
-- Solution (conceptual example):
-- ALTER TABLE logon_event_log ADD (logoff_ts DATE);
-- /
-- CREATE OR REPLACE TRIGGER trg_sys_after_logoff
-- AFTER LOGOFF ON DATABASE
-- BEGIN
--   INSERT INTO logon_event_log(username, logon_ts, logoff_ts)
--   VALUES(SYS.LOGIN_USER, NULL, SYSDATE);
-- END;
-- /
--------------------------------------------------------------------------------


/**********************************
 Q8 – Error capture inside trigger
 Task:
   Modify a trigger to wrap risky logic in a BEGIN..EXCEPTION..END block
   and store SQLERRM in tg_error_log instead of propagating the error.
**********************************/
-- Solution pattern:
-- CREATE OR REPLACE TRIGGER trg_emp_au_safe_demo
-- AFTER UPDATE ON tg_employees
-- FOR EACH ROW
-- DECLARE
--   v_dummy NUMBER;
-- BEGIN
--   BEGIN
--     v_dummy := 10 / 0; -- risky
--   EXCEPTION
--     WHEN OTHERS THEN
--       INSERT INTO tg_error_log(err_id, emp_id, err_message, created_on)
--       VALUES(:NEW.emp_id, :NEW.emp_id, SQLERRM, SYSDATE);
--   END;
-- END;
-- /
--------------------------------------------------------------------------------


/**********************************
 Q9 – Conditional firing using WHEN clause
 Task:
   Create an AFTER UPDATE OF salary trigger that fires only when
   NEW.salary > OLD.salary (salary increase).
**********************************/
-- Solution:
-- CREATE OR REPLACE TRIGGER trg_emp_au_raise_only
-- AFTER UPDATE OF salary ON tg_employees
-- FOR EACH ROW
-- WHEN (NEW.salary > OLD.salary)
-- BEGIN
--   INSERT INTO tg_employees_audit(
--     audit_id, emp_id, old_salary, new_salary, action_type, action_by, action_date
--   )
--   VALUES(
--     tg_emp_audit_seq.NEXTVAL,
--     :NEW.emp_id,
--     :OLD.salary,
--     :NEW.salary,
--     'RAISE',
--     USER,
--     SYSDATE
--   );
-- END;
-- /
--------------------------------------------------------------------------------


/**********************************
 Q10 – Combined event understanding
 Task:
   Explain (in comments) how event-driven triggers differ from:
--   • Stored procedures called manually
--   • Scheduled jobs (DBMS_SCHEDULER)
   Then create a simple trigger that prints a DBMS_OUTPUT message
   every time an employee row is updated.
**********************************/
-- Explanation notes (idea):
--   • Stored procedures are invoked explicitly by code or user.
--   • DBMS_SCHEDULER jobs are invoked by time-based or job-based schedules.
--   • Triggers are invoked implicitly by database events (DML, DDL, system).
--
-- Simple trigger:
-- CREATE OR REPLACE TRIGGER trg_emp_au_msg
-- AFTER UPDATE ON tg_employees
-- FOR EACH ROW
-- BEGIN
--   DBMS_OUTPUT.PUT_LINE('Row for emp_id='||:NEW.emp_id||' has been updated.');
-- END;
-- /
--------------------------------------------------------------------------------

-- End of Assignment
--------------------------------------------------------------------------------
