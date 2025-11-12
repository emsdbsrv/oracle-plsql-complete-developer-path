-- Script: assignment_practical_workshop_robust_error_management.sql
-- Session: 054 - Practical Workshop #5 (Robust Error Management)
-- Format:
--   • 10 scenario tasks with fully commented solutions. Copy a solution block, remove '--', run.
-- Guidance:
--   • Use -20xxx codes at boundaries; log STACK/BACKTRACE/CALL_STACK internally.
--   • Prefer RAISE to preserve diagnostics; translate only at API interfaces.
SET SERVEROUTPUT ON SIZE UNLIMITED;

--------------------------------------------------------------------------------
-- Q1 (Central policy): Add new code c_over_limit=-20091 to pw5_errors and raise it from a stub.
-- Answer (commented):
-- CREATE OR REPLACE PACKAGE BODY pw5_errors AS
--   FUNCTION fmt(p_key VARCHAR2, p_msg VARCHAR2) RETURN VARCHAR2 IS BEGIN RETURN '['||p_key||'] '||p_msg; END;
--   PROCEDURE raise_err(p_code IN PLS_INTEGER, p_msg IN VARCHAR2) IS BEGIN RAISE_APPLICATION_ERROR(p_code,p_msg); END;
-- END pw5_errors; /
-- -- Then:
-- BEGIN pw5_errors.raise_err(-20091, pw5_errors.fmt('PW5-LIMIT','Exceeded limit for id=1')); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q2 (Guarded DML): Write a block that SAVEPOINTs then updates a nonexistent id and raises c_not_found.
-- Answer (commented):
-- DECLARE v_id NUMBER:=999; BEGIN SAVEPOINT sp; UPDATE pw5_orders SET amount=amount+1 WHERE order_id=v_id;
-- IF SQL%ROWCOUNT=0 THEN pw5_errors.raise_err(pw5_errors.c_not_found, pw5_errors.fmt('PW5-UPD-404','Order not found id='||v_id)); END IF; COMMIT; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q3 (Inner→boundary): Create inner that does TO_NUMBER('abc'); boundary logs & translates to c_generic.
-- Answer (commented):
-- CREATE OR REPLACE PROCEDURE q3_inner IS BEGIN EXECUTE IMMEDIATE 'BEGIN :x := TO_NUMBER(''abc''); END;' USING OUT NULL; END; /
-- BEGIN BEGIN q3_inner; EXCEPTION WHEN OTHERS THEN pw5_print_diag('Q3'); pw5_log_diag('Q3'); pw5_errors.raise_err(pw5_errors.c_generic, pw5_errors.fmt('PW5-Q3','Translated: '||SQLERRM)); END; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q4 (PRAGMA mapping): Map ORA-01476 to e_zero via EXCEPTION_INIT and catch by name; print stacks.
-- Answer (commented):
-- DECLARE e_zero EXCEPTION; PRAGMA EXCEPTION_INIT(e_zero,-1476); a NUMBER:=1; b NUMBER:=0; c NUMBER;
-- BEGIN c:=a/b; EXCEPTION WHEN e_zero THEN pw5_print_diag('Q4'); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q5 (Package boundary): Create pkg with local ex_bad_state; translate to c_invalid_status at boundary.
-- Answer (commented):
-- CREATE OR REPLACE PACKAGE q5_pkg AS ex_bad_state EXCEPTION; PROCEDURE step(p_id NUMBER); END; /
-- CREATE OR REPLACE PACKAGE BODY q5_pkg AS PROCEDURE step(p_id NUMBER) IS s VARCHAR2(20); BEGIN SELECT status INTO s FROM pw5_orders WHERE order_id=p_id; IF s NOT IN ('NEW','PAID') THEN RAISE ex_bad_state; END IF; EXCEPTION WHEN ex_bad_state THEN pw5_errors.raise_err(pw5_errors.c_invalid_status, pw5_errors.fmt('PW5-Q5','state='||s||' id='||p_id)); END; END; /
-- BEGIN UPDATE pw5_orders SET status='HOLD' WHERE order_id=2; COMMIT; BEGIN q5_pkg.step(2); EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE(SQLCODE||' '||SQLERRM); END; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q6 (Rethrow preserves code): Raise -20092 inside inner, log, then RAISE; outer prints code.
-- Answer (commented):
-- BEGIN BEGIN RAISE_APPLICATION_ERROR(-20092,'inner boom'); EXCEPTION WHEN OTHERS THEN pw5_print_diag('Q6-INNER'); RAISE; END;
-- EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('[Q6-OUTER] code='||SQLCODE||' err='||SQLERRM); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q7 (Autonomous logger): Write a tiny autonomous logger to insert into pw5_error_log from handler.
-- Answer (commented):
-- CREATE OR REPLACE PACKAGE q7_log AS PROCEDURE now(p_tag VARCHAR2); END; /
-- CREATE OR REPLACE PACKAGE BODY q7_log AS PROCEDURE now(p_tag VARCHAR2) IS PRAGMA AUTONOMOUS_TRANSACTION; BEGIN INSERT INTO pw5_error_log(tag,err_code,err_stack,err_backtrace,call_stack) VALUES (p_tag,SQLCODE,DBMS_UTILITY.FORMAT_ERROR_STACK,DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,DBMS_UTILITY.FORMAT_CALL_STACK); COMMIT; EXCEPTION WHEN OTHERS THEN NULL; END; END; /
-- BEGIN BEGIN EXECUTE IMMEDIATE 'BEGIN :x := TO_NUMBER(''abc''); END;' USING OUT NULL; EXCEPTION WHEN OTHERS THEN q7_log.now('Q7'); END; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q8 (Bulk test harness): Loop through a set of invalid ids and collect codes/messages into a temp table.
-- Answer (commented):
-- BEGIN EXECUTE IMMEDIATE 'DROP TABLE q8_runs PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END; /
-- CREATE TABLE q8_runs(id NUMBER, code NUMBER, msg VARCHAR2(200)); /
-- DECLARE PROCEDURE one(p_id NUMBER) IS BEGIN pw5_boundary.api_set_amount(p_id,100); EXCEPTION WHEN OTHERS THEN INSERT INTO q8_runs VALUES (p_id, SQLCODE, SUBSTR(SQLERRM,1,200)); END; BEGIN FOR i IN 900..904 LOOP one(i); END LOOP; COMMIT; END; /
-- SELECT * FROM q8_runs ORDER BY id;
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q9 (Savepoint demo): Show that a failed unit (0 rows) is rolled back while unrelated changes persist.
-- Answer (commented):
-- DECLARE v_id NUMBER:=999; BEGIN SAVEPOINT sp; UPDATE pw5_orders SET amount=amount+5 WHERE order_id=v_id; IF SQL%ROWCOUNT=0 THEN ROLLBACK TO sp; END IF; UPDATE pw5_orders SET amount=amount+5 WHERE order_id=1; COMMIT; END; /
-- SELECT * FROM pw5_orders WHERE order_id IN (1,999) ORDER BY order_id;
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q10 (Policy audit): Print all pw5_errors constants via an anonymous block.
-- Answer (commented):
-- BEGIN DBMS_OUTPUT.PUT_LINE('codes: neg='||pw5_errors.c_neg_amount||', nf='||pw5_errors.c_not_found||', paid='||pw5_errors.c_already_paid||', invalid='||pw5_errors.c_invalid_status||', gen='||pw5_errors.c_generic); END; /
--------------------------------------------------------------------------------
-- End of Assignment
--------------------------------------------------------------------------------
