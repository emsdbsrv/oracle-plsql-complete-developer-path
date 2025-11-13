
SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Assignment – Session 089: DML Trigger Classification
-- 10 questions with fully commented solutions.
--------------------------------------------------------------------------------

/*********************************
Q1 Create BEFORE INSERT trigger to prevent NULL names.
*********************************/
-- SOLUTION:
-- CREATE OR REPLACE TRIGGER tg_emp_bi_chkname
-- BEFORE INSERT ON tg_employees
-- FOR EACH ROW
-- BEGIN
--   IF :NEW.emp_name IS NULL THEN
--     RAISE_APPLICATION_ERROR(-20010,'Name cannot be NULL');
--   END IF;
-- END;
-- /

/*********************************
Q2 AFTER INSERT statement-level trigger: print message.
*********************************/
-- SOLUTION:
-- CREATE OR REPLACE TRIGGER tg_emp_ai_stmt_msg
-- AFTER INSERT ON tg_employees
-- BEGIN
--   DBMS_OUTPUT.PUT_LINE('Insert completed.');
-- END;
-- /

/*********************************
Q3 BEFORE UPDATE row-level: prevent salary decrease.
*********************************/
-- SOLUTION:
-- CREATE OR REPLACE TRIGGER tg_emp_no_salary_cut
-- BEFORE UPDATE OF salary ON tg_employees
-- FOR EACH ROW
-- BEGIN
--   IF :NEW.salary < :OLD.salary THEN
--     RAISE_APPLICATION_ERROR(-20020,'Salary cannot be reduced.');
--   END IF;
-- END;
-- /

/*********************************
Q4 AFTER DELETE row-level: log employee id to audit table.
*********************************/
-- SOLUTION:
-- CREATE OR REPLACE TRIGGER tg_emp_del_audit
-- AFTER DELETE ON tg_employees
-- FOR EACH ROW
-- BEGIN
--   INSERT INTO tg_employees_audit(
--     audit_id,emp_id,old_salary,new_salary,action_type,action_by,action_date)
--   VALUES(
--     tg_emp_audit_seq.NEXTVAL,
--     :OLD.emp_id,
--     :OLD.salary,
--     NULL,
--     'DELETE',
--     USER,
--     SYSDATE
--   );
-- END;
-- /

/*********************************
Q5 BEFORE UPDATE statement trigger: print old vs new salary count.
*********************************/
-- SOLUTION:
-- CREATE OR REPLACE TRIGGER tg_emp_upd_stmt_msg
-- BEFORE UPDATE ON tg_employees
-- BEGIN
--   DBMS_OUTPUT.PUT_LINE('Employees are being updated...');
-- END;
-- /

/*********************************
Q6 Conditional trigger: fire only when NEW salary > 100000.
*********************************/
-- SOLUTION:
-- CREATE OR REPLACE TRIGGER tg_emp_highpay
-- AFTER UPDATE ON tg_employees
-- FOR EACH ROW
-- WHEN (NEW.salary > 100000)
-- BEGIN
--   DBMS_OUTPUT.PUT_LINE('High salary threshold reached.');
-- END;
-- /

/*********************************
Q7 BEFORE DELETE statement trigger: prevent deletion on weekends.
*********************************/
-- SOLUTION:
-- CREATE OR REPLACE TRIGGER tg_emp_nodelete_weekend
-- BEFORE DELETE ON tg_employees
-- BEGIN
--   IF TO_CHAR(SYSDATE,'DY') IN ('SAT','SUN') THEN
--     RAISE_APPLICATION_ERROR(-20030,'Deletion not allowed on weekends.');
--   END IF;
-- END;
-- /

/*********************************
Q8 AFTER UPDATE: write to history table for dept changes.
*********************************/
-- SOLUTION:
-- CREATE OR REPLACE TRIGGER tg_emp_hist_dept
-- AFTER UPDATE OF dept_id ON tg_employees
-- FOR EACH ROW
-- BEGIN
--   INSERT INTO tg_employees_history(hist_id,emp_id,old_name,old_salary,old_dept,modified_on)
--   VALUES(
--     tg_emp_audit_seq.NEXTVAL,
--     :OLD.emp_id,
--     :OLD.emp_name,
--     :OLD.salary,
--     :OLD.dept_id,
--     SYSDATE
--   );
-- END;
-- /

/*********************************
Q9 BEFORE INSERT: enforce unique dept + emp_name combination.
*********************************/
-- SOLUTION:
-- CREATE OR REPLACE TRIGGER tg_emp_unique_name_dept
-- BEFORE INSERT ON tg_employees
-- FOR EACH ROW
-- DECLARE
--   v_cnt NUMBER;
-- BEGIN
--   SELECT COUNT(*) INTO v_cnt
--   FROM tg_employees
--   WHERE emp_name=:NEW.emp_name AND dept_id=:NEW.dept_id;
--
--   IF v_cnt>0 THEN
--     RAISE_APPLICATION_ERROR(-20040,'Duplicate employee in department.');
--   END IF;
-- END;
-- /

/*********************************
Q10 AFTER INSERT: write to history table with created record snapshot.
*********************************/
-- SOLUTION:
-- CREATE OR REPLACE TRIGGER tg_emp_hist_snapshot
-- AFTER INSERT ON tg_employees
-- FOR EACH ROW
-- BEGIN
--   INSERT INTO tg_employees_history(hist_id,emp_id,old_name,old_salary,old_dept,modified_on)
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

--------------------------------------------------------------------------------
-- End Assignment
--------------------------------------------------------------------------------
