-- Script: assignment_exception_block_structure.sql
-- Session: 050 - Exception Block Structure
-- Format:
--   • 10 tasks with fully commented answers. Copy a solution, remove '--', execute.
-- Guidance:
--   • Use specific handlers first; keep WHEN OTHERS as a final guard with diagnostics.
--   • Demonstrate nested blocks for localized handling, and re-raise when appropriate.
SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Q1: Write the minimal block with DECLARE/BEGIN/EXCEPTION/END and print a message.
-- Answer (commented):
-- DECLARE v VARCHAR2(20):='hi'; BEGIN DBMS_OUTPUT.PUT_LINE(v); EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('err '||SQLCODE||' '||SQLERRM); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q2: Force ZERO_DIVIDE and handle it specifically.
-- Answer (commented):
-- DECLARE a NUMBER:=1; b NUMBER:=0; c NUMBER; BEGIN c:=a/b; EXCEPTION WHEN ZERO_DIVIDE THEN DBMS_OUTPUT.PUT_LINE('zero divide handled'); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q3: Raise -20070 with RAISE_APPLICATION_ERROR and log with WHEN OTHERS.
-- Answer (commented):
-- BEGIN RAISE_APPLICATION_ERROR(-20070,'bad state'); EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('code='||SQLCODE||' msg='||SQLERRM); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q4: Nested block logs locally then re-raises to the outer block.
-- Answer (commented):
-- DECLARE BEGIN BEGIN RAISE ZERO_DIVIDE; EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('[inner]'||SQLCODE||' '||SQLERRM); RAISE; END; EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('[outer]'||SQLCODE||' '||SQLERRM); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q5: Local recovery: if UPDATE affects 0 rows, INSERT instead; no re-raise.
-- Answer (commented):
-- DECLARE cnt NUMBER; BEGIN BEGIN UPDATE xb_orders SET status='PAID' WHERE order_id=777; cnt:=SQL%ROWCOUNT; IF cnt=0 THEN INSERT INTO xb_orders VALUES(777,0,'PAID'); END IF; EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL; END; DBMS_OUTPUT.PUT_LINE('done'); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q6: Translate a negative amount error to -20061 with details.
-- Answer (commented):
-- DECLARE id NUMBER:=2; amt NUMBER:=-5; BEGIN IF amt<=0 THEN RAISE_APPLICATION_ERROR(-20061,'negative amount id='||id||' amt='||amt); END IF; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q7: Commit/rollback pattern using SAVEPOINT.
-- Answer (commented):
-- DECLARE id NUMBER:=1; BEGIN SAVEPOINT sp; UPDATE xb_orders SET amount=amount+10 WHERE order_id=id; COMMIT; EXCEPTION WHEN OTHERS THEN ROLLBACK TO sp; DBMS_OUTPUT.PUT_LINE('rolled back: '||SQLCODE||' '||SQLERRM); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q8: Map ORA-00001 using PRAGMA EXCEPTION_INIT and handle the named exception.
-- Answer (commented):
-- DECLARE e_dup EXCEPTION; PRAGMA EXCEPTION_INIT(e_dup,-1); BEGIN INSERT INTO xb_orders(order_id,amount,status) VALUES(1,0,'X'); EXCEPTION WHEN e_dup THEN DBMS_OUTPUT.PUT_LINE('dup handled'); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q9: Show handler resolution: specific handler executes even when OTHERS exists below it.
-- Answer (commented):
-- BEGIN RAISE ZERO_DIVIDE; EXCEPTION WHEN ZERO_DIVIDE THEN DBMS_OUTPUT.PUT_LINE('specific first'); WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('others'); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q10: Add a final OTHERS handler that re-raises after logging.
-- Answer (commented):
-- BEGIN RAISE_APPLICATION_ERROR(-20099,'boom'); EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('logged '||SQLCODE||' '||SQLERRM); RAISE; END; /
--------------------------------------------------------------------------------
-- End of Assignment
--------------------------------------------------------------------------------
