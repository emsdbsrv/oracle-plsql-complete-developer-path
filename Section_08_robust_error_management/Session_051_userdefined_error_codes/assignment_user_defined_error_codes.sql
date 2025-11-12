-- Script: assignment_user_defined_error_codes.sql
-- Session: 051 - User-Defined Error Codes
-- Format:
--   • 10 tasks with fully commented answers. Copy a solution, remove '--', execute.
-- Guidance:
--   • Prefer -20xxx codes; include identifiers; keep logs with SQLCODE/SQLERRM.
--   • Translate engine errors at boundaries; preserve inside modules.
SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Q1: Create a package of codes (two constants) and a helper procedure to raise them.
-- Answer (commented):
-- CREATE OR REPLACE PACKAGE a1_codes AS c_a CONSTANT PLS_INTEGER := -20021; c_b CONSTANT PLS_INTEGER := -20022; PROCEDURE raise_err(p_code IN PLS_INTEGER, p_msg IN VARCHAR2); END; /
-- CREATE OR REPLACE PACKAGE BODY a1_codes AS PROCEDURE raise_err(p_code IN PLS_INTEGER, p_msg IN VARCHAR2) IS BEGIN RAISE_APPLICATION_ERROR(p_code, p_msg); END; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q2: Validate positive amount; on failure raise -20031 with acct id in message.
-- Answer (commented):
-- DECLARE acct NUMBER:=10; amt NUMBER:=-5; BEGIN IF amt<=0 THEN RAISE_APPLICATION_ERROR(-20031,'Amount must be positive. acct='||acct||' amt='||amt); END IF; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q3: Named exception inside module; translate to -20032 for callers.
-- Answer (commented):
-- DECLARE ex_internal EXCEPTION; BEGIN RAISE ex_internal; EXCEPTION WHEN ex_internal THEN RAISE_APPLICATION_ERROR(-20032,'Translated internal failure'); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q4: Central translation: map -1 (duplicate) to -20040; demonstrate by violating PK.
-- Answer (commented):
-- BEGIN EXECUTE IMMEDIATE 'CREATE TABLE a4_t(x NUMBER PRIMARY KEY)'; EXCEPTION WHEN OTHERS THEN NULL; END; /
-- BEGIN INSERT INTO a4_t VALUES(1); INSERT INTO a4_t VALUES(1); EXCEPTION WHEN OTHERS THEN RAISE_APPLICATION_ERROR(-20040,'Duplicate domain key: '||SQLERRM); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q5: Propagation: inner raises -20041; outer logs SQLCODE/SQLERRM and re-raises.
-- Answer (commented):
-- DECLARE PROCEDURE innerp IS BEGIN RAISE_APPLICATION_ERROR(-20041,'inner'); END; BEGIN BEGIN innerp; EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('[outer] '||SQLCODE||' '||SQLERRM); RAISE; END; EXCEPTION WHEN OTHERS THEN NULL; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q6: Logging helper package, then use it in a WHEN OTHERS handler with identifiers.
-- Answer (commented):
-- CREATE OR REPLACE PACKAGE a6_log AS PROCEDURE w(p VARCHAR2); END; /
-- CREATE OR REPLACE PACKAGE BODY a6_log AS PROCEDURE w(p VARCHAR2) IS BEGIN DBMS_OUTPUT.PUT_LINE('[LOG] '||p); END; END; /
-- BEGIN BEGIN RAISE_APPLICATION_ERROR(-20042,'boom'); EXCEPTION WHEN OTHERS THEN a6_log.w('code='||SQLCODE||' msg='||SQLERRM||' id=5'); END; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q7: Boundary demo: preserve system error inside; translate to -20050 at API boundary.
-- Answer (commented):
-- DECLARE PROCEDURE deep IS BEGIN DECLARE a NUMBER:=1; b NUMBER:=0; c NUMBER; BEGIN c:=a/b; END; END; BEGIN BEGIN deep; EXCEPTION WHEN OTHERS THEN RAISE_APPLICATION_ERROR(-20050,'Boundary translation: '||SQLERRM); END; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q8: Use a formatting helper to standardize messages.
-- Answer (commented):
-- CREATE OR REPLACE PACKAGE a8_fmt AS FUNCTION msg(p_key VARCHAR2,p_msg VARCHAR2) RETURN VARCHAR2; END; /
-- CREATE OR REPLACE PACKAGE BODY a8_fmt AS FUNCTION msg(p_key VARCHAR2,p_msg VARCHAR2) RETURN VARCHAR2 IS BEGIN RETURN '['||p_key||'] '||p_msg; END; END; /
-- BEGIN RAISE_APPLICATION_ERROR(-20055, a8_fmt.msg('AUTH-001','Access denied for user=U1')); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q9: Inactive account rule: if status<>'ACTIVE' raise -20060; include acct id and status.
-- Answer (commented):
-- BEGIN EXECUTE IMMEDIATE 'CREATE TABLE a9_acc(id NUMBER PRIMARY KEY, status VARCHAR2(10))'; EXCEPTION WHEN OTHERS THEN NULL; END; /
-- BEGIN MERGE INTO a9_acc d USING (SELECT 1 id,'HOLD' status FROM dual) s ON (d.id=s.id) WHEN NOT MATCHED THEN INSERT (id,status) VALUES (s.id,s.status); END; /
-- DECLARE v VARCHAR2(10); BEGIN SELECT status INTO v FROM a9_acc WHERE id=1; IF v<>'ACTIVE' THEN RAISE_APPLICATION_ERROR(-20060,'Inactive acct id=1 status='||v); END IF; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q10: Consistent code policy: choose -20xxx and ensure single source of truth (package).
-- Answer (commented):
-- -- Write a short package with one code constant and a raise helper as done in Q1; use it to raise an error.
--------------------------------------------------------------------------------
-- End of Assignment
--------------------------------------------------------------------------------
