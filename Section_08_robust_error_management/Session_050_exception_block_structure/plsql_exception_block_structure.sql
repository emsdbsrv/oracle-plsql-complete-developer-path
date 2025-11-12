-- Script: plsql_exception_block_structure.sql
-- Session: 050 - Exception Block Structure
-- Purpose:
--   Show the structure of PL/SQL blocks and exception sections with detailed, line-by-line commentary.
--   Includes: basic block, specific handlers, OTHERS with diagnostics, nested blocks with re-raise,
--   local recovery, translation, and commit/rollback patterns.
-- How to run:
--   SET SERVEROUTPUT ON; Execute each block separately (terminated by '/').
-- Notes:
--   • Use specific handlers first, THEN a final WHEN OTHERS for safety.
--   • Include SQLCODE and SQLERRM in logs to aid troubleshooting.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Setup (idempotent)
--------------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'DROP TABLE xb_orders PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE TABLE xb_orders (
  order_id NUMBER CONSTRAINT xb_orders_pk PRIMARY KEY,
  amount   NUMBER(12,2) NOT NULL,
  status   VARCHAR2(20) DEFAULT 'NEW'
);

INSERT INTO xb_orders VALUES (1, 1000,  'NEW');
INSERT INTO xb_orders VALUES (2,  250,  'PAID');
COMMIT;
/

--------------------------------------------------------------------------------
-- Example 1: Minimal block with no exceptions raised
-- Intention: Show DECLARE/BEGIN/EXCEPTION/END skeleton, with EXCEPTION unused.
--------------------------------------------------------------------------------
DECLARE
  v_msg VARCHAR2(50) := 'Hello block';
BEGIN
  DBMS_OUTPUT.PUT_LINE(v_msg);
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('unexpected: '||SQLCODE||' '||SQLERRM);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 2: Specific handlers before WHEN OTHERS
-- Intention: Trigger ZERO_DIVIDE and show it is caught by specific handler.
--------------------------------------------------------------------------------
DECLARE
  a NUMBER := 10;
  b NUMBER := 0;
  c NUMBER;
BEGIN
  c := a / b; -- raises ZERO_DIVIDE
  DBMS_OUTPUT.PUT_LINE('c='||c);
EXCEPTION
  WHEN ZERO_DIVIDE THEN
    DBMS_OUTPUT.PUT_LINE('Handled ZERO_DIVIDE specifically');
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Fallback: code='||SQLCODE||' err='||SQLERRM);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 3: WHEN OTHERS for diagnostics and optional re-raise
-- Intention: Final guard that logs code/message; comment shows where to re-raise.
--------------------------------------------------------------------------------
BEGIN
  RAISE_APPLICATION_ERROR(-20050, 'Domain failure');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('[diag] code='||SQLCODE||' msg='||SQLERRM);
    -- RAISE; -- uncomment to propagate
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 4: Nested blocks with local handling and re-raise
-- Intention: Inner block logs and re-raises; outer block handles final outcome.
--------------------------------------------------------------------------------
DECLARE
  PROCEDURE inner_op(p_id IN xb_orders.order_id%TYPE) IS
    v_amt xb_orders.amount%TYPE;
  BEGIN
    BEGIN
      SELECT amount INTO v_amt FROM xb_orders WHERE order_id = p_id;
      v_amt := v_amt / 0; -- force ZERO_DIVIDE
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[inner] code='||SQLCODE||' err='||SQLERRM||' id='||p_id);
        RAISE; -- re-raise to outer
    END;
  END;
BEGIN
  inner_op(1);
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('[outer] code='||SQLCODE||' err='||SQLERRM);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 5: Local recovery inside a nested block (no re-raise)
-- Intention: Inner block recovers gracefully; outer sees success path.
--------------------------------------------------------------------------------
DECLARE
  v_ok BOOLEAN := FALSE;
BEGIN
  BEGIN
    UPDATE xb_orders SET status='PAID' WHERE order_id=999; -- affects 0 rows
    IF SQL%ROWCOUNT=0 THEN
      -- recover locally by inserting a placeholder, then continue
      INSERT INTO xb_orders(order_id, amount, status) VALUES(999, 0, 'PAID');
      v_ok := TRUE;
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      v_ok := TRUE; -- already exists, proceed
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('[local] unexpected: '||SQLCODE||' '||SQLERRM);
      RAISE; -- cannot recover
  END;

  DBMS_OUTPUT.PUT_LINE('Recovery result v_ok='||CASE WHEN v_ok THEN 'Y' ELSE 'N' END);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 6: Translate to application error with parameters
-- Intention: Use RAISE_APPLICATION_ERROR to present domain-specific messages.
--------------------------------------------------------------------------------
DECLARE
  v_id   xb_orders.order_id%TYPE := 2;
  v_amt  NUMBER := -10; -- invalid
BEGIN
  IF v_amt <= 0 THEN
    RAISE_APPLICATION_ERROR(-20060, 'Amount must be positive. id='||v_id||', amt='||v_amt);
  END IF;
  UPDATE xb_orders SET amount = amount + v_amt WHERE order_id=v_id;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('[translate] code='||SQLCODE||' msg='||SQLERRM);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 7: Commit/rollback pattern with defensive exception block
-- Intention: Do work; commit on success; rollback and log on failure.
--------------------------------------------------------------------------------
DECLARE
  v_id xb_orders.order_id%TYPE := 1;
BEGIN
  SAVEPOINT before_update;
  UPDATE xb_orders SET amount = amount + 100 WHERE order_id = v_id;
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Committed for id='||v_id);
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK TO before_update;
    DBMS_OUTPUT.PUT_LINE('[rolled back] code='||SQLCODE||' msg='||SQLERRM);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 8: PRAGMA EXCEPTION_INIT usage inside structured block
-- Intention: Map ORA-00001 to a named exception; show specific catch within structure.
--------------------------------------------------------------------------------
DECLARE
  e_dup EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_dup, -1); -- ORA-00001
BEGIN
  INSERT INTO xb_orders(order_id, amount, status) VALUES(1, 0, 'NEW'); -- duplicate key
EXCEPTION
  WHEN e_dup THEN
    DBMS_OUTPUT.PUT_LINE('Caught e_dup (ORA-00001) via PRAGMA mapping');
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('[fallback] '||SQLCODE||' '||SQLERRM);
END;
/
--------------------------------------------------------------------------------
-- End of File
--------------------------------------------------------------------------------
