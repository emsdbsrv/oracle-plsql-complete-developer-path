
SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Assignment – Session 090: DDL and System Triggers
-- 10 questions with full commented solutions.
--------------------------------------------------------------------------------

/*********************************
Q1 Create AFTER CREATE trigger to print object name.
*********************************/
-- SOLUTION:
-- CREATE OR REPLACE TRIGGER tg_acr_print
-- AFTER CREATE ON SCHEMA
-- BEGIN
--   DBMS_OUTPUT.PUT_LINE('Created: '||ORA_DICT_OBJ_NAME);
-- END;
-- /

/*********************************
Q2 BEFORE DROP: block dropping tables starting with 'SEC_'
*********************************/
-- SOLUTION:
-- CREATE OR REPLACE TRIGGER tg_bd_block
-- BEFORE DROP ON SCHEMA
-- BEGIN
--   IF ORA_DICT_OBJ_NAME LIKE 'SEC_%' THEN
--     RAISE_APPLICATION_ERROR(-21100,'SEC_ tables cannot be dropped.');
--   END IF;
-- END;
-- /

/*********************************
Q3 AFTER ALTER: log action to table ddl_log
*********************************/
-- SOLUTION:
-- INSERT INTO ddl_log(object_name,action_date)
-- VALUES(ORA_DICT_OBJ_NAME,SYSDATE);

/*********************************
Q4 BEFORE CREATE: enforce min length of object names
*********************************/
-- SOLUTION:
-- IF LENGTH(ORA_DICT_OBJ_NAME) < 5 THEN
--   RAISE_APPLICATION_ERROR(-21110,'Object name too short.');
-- END IF;

/*********************************
Q5 LOGON trigger: record login to login_audit table
*********************************/
-- SOLUTION:
-- INSERT INTO login_audit(username,login_time)
-- VALUES(USER,SYSDATE);

/*********************************
Q6 LOGOFF trigger: record logout
*********************************/
-- SOLUTION:
-- INSERT INTO login_audit(username,logout_time)
-- VALUES(USER,SYSDATE);

/*********************************
Q7 STARTUP trigger: log startup event to startup_log
*********************************/
-- SOLUTION:
-- INSERT INTO startup_log(event_time) VALUES(SYSDATE);

/*********************************
Q8 Create BEFORE SHUTDOWN trigger message
*********************************/
-- SOLUTION:
-- CREATE OR REPLACE TRIGGER tg_shutdown
-- BEFORE SHUTDOWN ON DATABASE
-- BEGIN
--   DBMS_OUTPUT.PUT_LINE('Database shutting down...');
-- END;
-- /

/*********************************
Q9 AFTER CREATE: allow only tables with prefix APP_
*********************************/
-- SOLUTION:
-- IF ORA_DICT_OBJ_NAME NOT LIKE 'APP_%' THEN
--   RAISE_APPLICATION_ERROR(-21200,'Only APP_ tables are allowed.');
-- END IF;

/*********************************
Q10 BEFORE ALTER: prevent ALTER on payroll table
*********************************/
-- SOLUTION:
-- IF ORA_DICT_OBJ_NAME='PAYROLL' THEN
--   RAISE_APPLICATION_ERROR(-21210,'Cannot alter PAYROLL.');
-- END IF;

--------------------------------------------------------------------------------
-- End Assignment
--------------------------------------------------------------------------------
