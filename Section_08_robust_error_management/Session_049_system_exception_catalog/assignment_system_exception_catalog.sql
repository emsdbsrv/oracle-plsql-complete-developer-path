-- Script: assignment_system_exception_catalog.sql
-- Session: 049 - System Exception Catalog — Detailed Guide
-- Format:
--   • 10 tasks with fully commented solutions. Copy a block, remove '--', and execute.
-- Guidance:
--   • Trigger exceptions intentionally and observe handler behavior.
--   • Always log SQLCODE and SQLERRM in catch-all blocks.
SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Q1 NO_DATA_FOUND: Missing key in se_demo.
-- Answer (commented):
-- DECLARE v VARCHAR2(10); BEGIN SELECT val INTO v FROM se_demo WHERE id=-1; EXCEPTION WHEN NO_DATA_FOUND THEN DBMS_OUTPUT.PUT_LINE('no row'); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q2 TOO_MANY_ROWS: Create two rows with same val, then SELECT scalar.
-- Answer (commented):
-- BEGIN INSERT INTO se_demo VALUES (100,'Z'); INSERT INTO se_demo VALUES (101,'Z'); COMMIT; END; /
-- DECLARE v NUMBER; BEGIN SELECT id INTO v FROM se_demo WHERE val='Z'; EXCEPTION WHEN TOO_MANY_ROWS THEN DBMS_OUTPUT.PUT_LINE('too many rows'); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q3 ZERO_DIVIDE: Division by zero in PL/SQL.
-- Answer (commented):
-- DECLARE a NUMBER:=1; b NUMBER:=0; c NUMBER; BEGIN c:=a/b; EXCEPTION WHEN ZERO_DIVIDE THEN DBMS_OUTPUT.PUT_LINE('zero divide handled'); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q4 VALUE_ERROR: Numeric overflow for NUMBER(2,0).
-- Answer (commented):
-- DECLARE v NUMBER(2,0); BEGIN v:=999; EXCEPTION WHEN VALUE_ERROR THEN DBMS_OUTPUT.PUT_LINE('overflow handled'); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q5 INVALID_NUMBER: Use TO_NUMBER('abc') via EXECUTE IMMEDIATE; catch in OTHERS.
-- Answer (commented):
-- DECLARE x NUMBER; BEGIN BEGIN EXECUTE IMMEDIATE 'BEGIN :y := TO_NUMBER(''abc''); END;' USING OUT x; EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('invalid: '||SQLCODE||' '||SQLERRM); END; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q6 DUP_VAL_ON_INDEX: Insert duplicate PK into se_demo; handle.
-- Answer (commented):
-- BEGIN INSERT INTO se_demo VALUES (1,'X'); EXCEPTION WHEN DUP_VAL_ON_INDEX THEN DBMS_OUTPUT.PUT_LINE('dup handled'); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q7 CURSOR_ALREADY_OPEN: Open twice; handle specific exception.
-- Answer (commented):
-- DECLARE CURSOR c IS SELECT * FROM se_demo; BEGIN OPEN c; OPEN c; CLOSE c; EXCEPTION WHEN CURSOR_ALREADY_OPEN THEN DBMS_OUTPUT.PUT_LINE('cursor handled'); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q8 CASE_NOT_FOUND: No ELSE; unmatched value; handle.
-- Answer (commented):
-- DECLARE n NUMBER:=9; txt VARCHAR2(10); BEGIN CASE n WHEN 1 THEN txt:='one'; WHEN 2 THEN txt:='two'; END CASE; EXCEPTION WHEN CASE_NOT_FOUND THEN DBMS_OUTPUT.PUT_LINE('case handled'); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q9 Collections: null nested table, beyond count, outside limit.
-- Answer (commented):
-- DECLARE TYPE nt IS TABLE OF NUMBER; v nt; n NUMBER; BEGIN BEGIN n:=v(1); EXCEPTION WHEN COLLECTION_IS_NULL THEN DBMS_OUTPUT.PUT_LINE('null'); END; v:=nt(10,20); BEGIN n:=v(3); EXCEPTION WHEN SUBSCRIPT_BEYOND_COUNT THEN DBMS_OUTPUT.PUT_LINE('beyond'); END; BEGIN n:=v(0); EXCEPTION WHEN SUBSCRIPT_OUTSIDE_LIMIT THEN DBMS_OUTPUT.PUT_LINE('outside'); END; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q10 PRAGMA EXCEPTION_INIT: Map -30006 to e_timeout and handle after raising same code.
-- Answer (commented):
-- DECLARE e_timeout EXCEPTION; PRAGMA EXCEPTION_INIT(e_timeout,-30006); BEGIN RAISE_APPLICATION_ERROR(-30006,'busy/timeout'); EXCEPTION WHEN e_timeout THEN DBMS_OUTPUT.PUT_LINE('timeout handled'); END; /
--------------------------------------------------------------------------------
-- End of Assignment
--------------------------------------------------------------------------------
