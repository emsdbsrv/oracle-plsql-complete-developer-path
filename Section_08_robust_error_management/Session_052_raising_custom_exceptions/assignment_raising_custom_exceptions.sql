-- Script: assignment_raising_custom_exceptions.sql
-- Session: 052 - Raising Custom Exceptions
-- Format:
--   • 10 detailed tasks with complete solutions provided as COMMENTED answers.
--   • To run a solution: copy the commented block and remove leading '--'.
-- Guidance:
--   • Prefer -20xxx codes at module boundaries; keep named exceptions inside.
--   • Log SQLCODE/SQLERRM before translation; guard writes with SAVEPOINT.
SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Q1 (Named internal): Raise a local named exception when amount<=0 and catch it.
-- Answer (commented):
-- DECLARE ex_neg EXCEPTION; v NUMBER:=-1; BEGIN IF v<=0 THEN RAISE ex_neg; END IF; EXCEPTION WHEN ex_neg THEN DBMS_OUTPUT.PUT_LINE('caught named'); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q2 (Boundary code): Raise -20081 '[RCE-Q2] bad amount=...' when amount<=0.
-- Answer (commented):
-- DECLARE v NUMBER:=0; BEGIN IF v<=0 THEN RAISE_APPLICATION_ERROR(-20081,'[RCE-Q2] bad amount='||v); END IF; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q3 (Escalation): Inner logs ZERO_DIVIDE, RAISE; boundary translates to -20082.
-- Answer (commented):
-- BEGIN BEGIN DECLARE a NUMBER:=1; b NUMBER:=0; c NUMBER; BEGIN c:=a/b; END; EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('[inner] '||SQLCODE||' '||SQLERRM); RAISE; END; EXCEPTION WHEN OTHERS THEN RAISE_APPLICATION_ERROR(-20082,'Translated: '||SQLERRM); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q4 (Central package): Create rce2(c_neg, raise_err) and use it when amt<=0.
-- Answer (commented):
-- CREATE OR REPLACE PACKAGE rce2 AS c_neg CONSTANT PLS_INTEGER := -20083; PROCEDURE raise_err(p_code IN PLS_INTEGER,p_msg IN VARCHAR2); END; /
-- CREATE OR REPLACE PACKAGE BODY rce2 AS PROCEDURE raise_err(p_code IN PLS_INTEGER,p_msg IN VARCHAR2) IS BEGIN RAISE_APPLICATION_ERROR(p_code,p_msg); END; END; /
-- DECLARE v NUMBER:=-5; BEGIN IF v<=0 THEN rce2.raise_err(rce2.c_neg,'neg amount '||v); END IF; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q5 (Already paid): Create rce_pay that raises -20084 if status='PAID'; test it.
-- Answer (commented):
-- BEGIN EXECUTE IMMEDIATE 'CREATE TABLE rce_pay_t(id NUMBER PRIMARY KEY, status VARCHAR2(10))'; EXCEPTION WHEN OTHERS THEN NULL; END; /
-- BEGIN MERGE INTO rce_pay_t d USING (SELECT 1 id,'PAID' status FROM dual) s ON (d.id=s.id) WHEN NOT MATCHED THEN INSERT (id,status) VALUES (s.id,s.status); END; /
-- CREATE OR REPLACE PROCEDURE rce_pay(p_id IN NUMBER) IS v VARCHAR2(10); BEGIN SELECT status INTO v FROM rce_pay_t WHERE id=p_id; IF v='PAID' THEN RAISE_APPLICATION_ERROR(-20084,'already paid id='||p_id); END IF; UPDATE rce_pay_t SET status='PAID' WHERE id=p_id; END; /
-- BEGIN BEGIN rce_pay(1); EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE(SQLCODE||' '||SQLERRM); END; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q6 (Rethrow preserves code): Raise -20085; inner prints then RAISE; outer prints.
-- Answer (commented):
-- BEGIN BEGIN RAISE_APPLICATION_ERROR(-20085,'boom'); EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('[inner] '||SQLCODE||' '||SQLERRM); RAISE; END; EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('[outer] '||SQLCODE||' '||SQLERRM); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q7 (Guarded update): SAVEPOINT; if 0 rows updated raise -20086; ROLLBACK TO sp.
-- Answer (commented):
-- BEGIN SAVEPOINT sp; UPDATE rce_orders SET amount=amount+1 WHERE order_id=999; IF SQL%ROWCOUNT=0 THEN RAISE_APPLICATION_ERROR(-20086,'no such order'); END IF; COMMIT; EXCEPTION WHEN OTHERS THEN ROLLBACK TO sp; DBMS_OUTPUT.PUT_LINE('rolled back: '||SQLCODE||' '||SQLERRM); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q8 (Boundary translation): Preserve low-level error; boundary raises -20087 with context.
-- Answer (commented):
-- DECLARE PROCEDURE low IS BEGIN EXECUTE IMMEDIATE 'BEGIN :x := TO_NUMBER(''abc''); END;' USING OUT NULL; END; BEGIN BEGIN low; EXCEPTION WHEN OTHERS THEN RAISE_APPLICATION_ERROR(-20087,'Boundary: '||SQLERRM); END; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q9 (Formatter helper): Create function fmt('[KEY] msg') and raise -20088 using it.
-- Answer (commented):
-- CREATE OR REPLACE FUNCTION q9_fmt(p_key VARCHAR2,p_msg VARCHAR2) RETURN VARCHAR2 IS BEGIN RETURN '['||p_key||'] '||p_msg; END; /
-- BEGIN RAISE_APPLICATION_ERROR(-20088, q9_fmt('RCE-Q9','Custom formatted message')); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q10 (Policy package): Document a -20xxx constant and raise it.
-- Answer (commented):
-- CREATE OR REPLACE PACKAGE q10_policy AS c_rule CONSTANT PLS_INTEGER := -20099; END; /
-- BEGIN RAISE_APPLICATION_ERROR(q10_policy.c_rule, 'Policy demonstration'); END; /
--------------------------------------------------------------------------------
-- End of Assignment
--------------------------------------------------------------------------------
