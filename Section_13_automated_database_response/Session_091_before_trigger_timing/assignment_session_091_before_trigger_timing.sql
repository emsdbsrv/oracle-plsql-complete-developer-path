
SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Assignment – Session 091: BEFORE Trigger Timing
-- 10 Questions with FULLY COMMENTED SOLUTIONS
--------------------------------------------------------------------------------

/*********************************
Q1 BEFORE INSERT – Ensure emp_name is not NULL
*********************************/
-- SOLUTION:
-- CREATE OR REPLACE TRIGGER tg_bi_nonullname
-- BEFORE INSERT ON tg_employees
-- FOR EACH ROW
-- BEGIN
--   IF :NEW.emp_name IS NULL THEN
--     RAISE_APPLICATION_ERROR(-31001,'Name cannot be NULL');
--   END IF;
-- END;
-- /

/*********************************
Q2 BEFORE UPDATE – Block salary decrease
*********************************/
-- SOLUTION:
-- CREATE OR REPLACE TRIGGER tg_bu_nocut
-- BEFORE UPDATE OF salary ON tg_employees
-- FOR EACH ROW
-- BEGIN
--   IF :NEW.salary < :OLD.salary THEN
--     RAISE_APPLICATION_ERROR(-31002,'Salary cannot be reduced');
--   END IF;
-- END;
-- /

/*********************************
Q3 BEFORE INSERT – Auto-fill dept_id if NULL
*********************************/
-- SOLUTION:
-- CREATE OR REPLACE TRIGGER tg_bi_defaultdept
-- BEFORE INSERT ON tg_employees
-- FOR EACH ROW
-- BEGIN
--   IF :NEW.dept_id IS NULL THEN
--     :NEW.dept_id := 10;
--   END IF;
-- END;
-- /

/*********************************
Q4 BEFORE UPDATE – Prevent updating emp_name
*********************************/
-- SOLUTION:
-- CREATE OR REPLACE TRIGGER tg_bu_nonamechange
-- BEFORE UPDATE OF emp_name ON tg_employees
-- FOR EACH ROW
-- BEGIN
--   RAISE_APPLICATION_ERROR(-31003,'Name change is not permitted');
-- END;
-- /

/*********************************
Q5 BEFORE DELETE – Deny delete for emp_id < 5
*********************************/
-- SOLUTION:
-- CREATE OR REPLACE TRIGGER tg_bd_protect
-- BEFORE DELETE ON tg_employees
-- FOR EACH ROW
-- BEGIN
--   IF :OLD.emp_id < 5 THEN
--     RAISE_APPLICATION_ERROR(-31004,'Protected record cannot be deleted');
--   END IF;
-- END;
-- /

/*********************************
Q6 BEFORE INSERT – Convert salary NULL to 0
*********************************/
-- SOLUTION:
-- CREATE OR REPLACE TRIGGER tg_bi_salarynull
-- BEFORE INSERT ON tg_employees
-- FOR EACH ROW
-- BEGIN
--   IF :NEW.salary IS NULL THEN
--     :NEW.salary := 0;
--   END IF;
-- END;
-- /

/*********************************
Q7 BEFORE UPDATE – Log old/new salary difference
*********************************/
-- SOLUTION:
-- DBMS_OUTPUT.PUT_LINE('Old='||:OLD.salary||' New='||:NEW.salary);

/*********************************
Q8 BEFORE INSERT – Assign created_on manually if needed
*********************************/
-- SOLUTION:
-- IF :NEW.created_on IS NULL THEN
--   :NEW.created_on := SYSDATE;
-- END IF;

/*********************************
Q9 BEFORE UPDATE – Prevent updating executives
*********************************/
-- SOLUTION:
-- IF :OLD.dept_id = 99 THEN
--   RAISE_APPLICATION_ERROR(-31005,'Executives are locked from updates');
-- END IF;

/*********************************
Q10 BEFORE DELETE – Prevent deletion on Mondays
*********************************/
-- SOLUTION:
-- IF TO_CHAR(SYSDATE,'DY') = 'MON' THEN
--   RAISE_APPLICATION_ERROR(-31006,'Deletion not allowed on Monday');
-- END IF;

--------------------------------------------------------------------------------
-- End Assignment
--------------------------------------------------------------------------------
