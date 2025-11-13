
SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Session 090 – DDL and System Triggers
-- This lesson contains 7 detailed examples explaining DDL and system triggers.
--------------------------------------------------------------------------------

/******************************************************************************
EX1: AFTER CREATE trigger – log object creation
******************************************************************************/
CREATE OR REPLACE TRIGGER tg_ddl_after_create
AFTER CREATE ON SCHEMA
BEGIN
  DBMS_OUTPUT.PUT_LINE('Object created in schema.');
END;
/
--------------------------------------------------------------------------------

/******************************************************************************
EX2: BEFORE DROP trigger – block DROP on sensitive tables
******************************************************************************/
CREATE OR REPLACE TRIGGER tg_ddl_before_drop
BEFORE DROP ON SCHEMA
BEGIN
  IF ORA_DICT_OBJ_NAME = 'TG_EMPLOYEES' THEN
    RAISE_APPLICATION_ERROR(-21000,'Drop not allowed for TG_EMPLOYEES.');
  END IF;
END;
/
--------------------------------------------------------------------------------

/******************************************************************************
EX3: AFTER ALTER trigger – audit structure changes
******************************************************************************/
CREATE OR REPLACE TRIGGER tg_ddl_after_alter
AFTER ALTER ON SCHEMA
BEGIN
  DBMS_OUTPUT.PUT_LINE('Object altered: '||ORA_DICT_OBJ_NAME);
END;
/
--------------------------------------------------------------------------------

/******************************************************************************
EX4: BEFORE CREATE trigger – enforce naming conventions
******************************************************************************/
CREATE OR REPLACE TRIGGER tg_ddl_before_create
BEFORE CREATE ON SCHEMA
BEGIN
  IF NOT REGEXP_LIKE(ORA_DICT_OBJ_NAME,'^[A-Z0-9_]+$') THEN
    RAISE_APPLICATION_ERROR(-21010,'Object name must be uppercase.');
  END IF;
END;
/
--------------------------------------------------------------------------------

/******************************************************************************
EX5: LOGON trigger – log every session login
******************************************************************************/
CREATE OR REPLACE TRIGGER tg_logon
AFTER LOGON ON DATABASE
BEGIN
  DBMS_OUTPUT.PUT_LINE('User logged in: '||USER);
END;
/
--------------------------------------------------------------------------------

/******************************************************************************
EX6: LOGOFF trigger – notify on logout
******************************************************************************/
CREATE OR REPLACE TRIGGER tg_logoff
BEFORE LOGOFF ON DATABASE
BEGIN
  DBMS_OUTPUT.PUT_LINE('User logged off: '||USER);
END;
/
--------------------------------------------------------------------------------

/******************************************************************************
EX7: STARTUP trigger – initialize environment
******************************************************************************/
CREATE OR REPLACE TRIGGER tg_startup
AFTER STARTUP ON DATABASE
BEGIN
  DBMS_OUTPUT.PUT_LINE('Database Startup Completed');
END;
/
--------------------------------------------------------------------------------

-- End Lesson
--------------------------------------------------------------------------------
