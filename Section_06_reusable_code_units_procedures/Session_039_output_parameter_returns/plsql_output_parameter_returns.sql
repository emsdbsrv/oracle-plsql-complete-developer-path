-- Script: plsql_output_parameter_returns.sql
-- Session: 039 - Output Parameter Returns
-- Purpose:
--   Demonstrate robust patterns for returning values from procedures using OUT parameters.
--   Each example contains line-by-line commentary explaining the steps, decisions, and numeric/text handling.
-- How to run:
--   SET SERVEROUTPUT ON; Execute each example separately (terminated by '/').
-- Notes:
--   • OUT parameters must be assigned before normal exit; initialize defensively in EXCEPTION blocks.
--   • Anchor to table columns using %TYPE, or to rows using %ROWTYPE, to prevent datatype drift.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Setup: reference table for examples (idempotent)
--------------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'DROP TABLE opr_accounts PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE TABLE opr_accounts (
  acct_id     NUMBER CONSTRAINT opr_accounts_pk PRIMARY KEY,   -- numeric identifier
  acct_name   VARCHAR2(80) NOT NULL,                           -- account friendly name
  balance     NUMBER(12,2) DEFAULT 0,                          -- money-like numeric (2 decimals)
  opened_on   DATE DEFAULT SYSDATE,                            -- date the account was opened
  status      VARCHAR2(20) DEFAULT 'ACTIVE'                    -- lifecycle state
);

INSERT INTO opr_accounts VALUES (1,'Primary', 2500.00, SYSDATE-10, 'ACTIVE');
INSERT INTO opr_accounts VALUES (2,'Savings', 12000.00, SYSDATE-30, 'ACTIVE');
COMMIT;

--------------------------------------------------------------------------------
-- Example 1: OUT scalar return (get balance by acct_id)
--------------------------------------------------------------------------------
-- Goal:
--   Return a single NUMBER(12,2) balance through an OUT parameter.
-- Highlights:
--   1) Anchor OUT to underlying column type for safety.
--   2) Handle NO_DATA_FOUND and set OUT to 0 on error for deterministic behavior.
CREATE OR REPLACE PROCEDURE opr_get_balance(
  p_acct_id IN  opr_accounts.acct_id%TYPE,
  p_balance OUT opr_accounts.balance%TYPE
) IS
BEGIN
  SELECT balance
    INTO p_balance
    FROM opr_accounts
   WHERE acct_id = p_acct_id;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    p_balance := 0;  -- defensive default on error path
    DBMS_OUTPUT.PUT_LINE('No account with id='||p_acct_id);
END opr_get_balance;
/
-- Test
DECLARE v NUMBER; BEGIN opr_get_balance(1, v); DBMS_OUTPUT.PUT_LINE('balance='||TO_CHAR(v,'FM9999999990.00')); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 2: Multiple OUTs: status code, message, and value
--------------------------------------------------------------------------------
-- Goal:
--   Provide structured feedback via OUT parameters:
--     p_ok:    BOOLEAN-like NUMBER (1=success, 0=failure)
--     p_msg:   human-readable message
--     p_value: resulting numeric (new balance)
-- Steps:
--   1) Validate input amount (must be > 0).
--   2) Update balance and return the new value.
CREATE OR REPLACE PROCEDURE opr_add_funds(
  p_acct_id IN  opr_accounts.acct_id%TYPE,
  p_amount  IN  NUMBER,                         -- caller may pass any NUMBER; we round to 2 decimals
  p_ok      OUT NUMBER,                         -- 1 or 0
  p_msg     OUT VARCHAR2,                       -- explanation
  p_value   OUT NUMBER                          -- resulting balance
) IS
  v_amt   NUMBER(12,2);                         -- normalized money value
BEGIN
  p_ok    := 0;                                 -- initialize OUTs early
  p_msg   := NULL;
  p_value := NULL;

  v_amt := ROUND(p_amount, 2);
  IF v_amt IS NULL OR v_amt <= 0 THEN
    p_msg := 'Amount must be positive';
    RETURN;                                     -- early return with p_ok=0
  END IF;

  UPDATE opr_accounts
     SET balance = NVL(balance,0) + v_amt
   WHERE acct_id = p_acct_id;

  IF SQL%ROWCOUNT = 0 THEN
    p_msg := 'Account not found';
    RETURN;
  END IF;

  SELECT balance INTO p_value FROM opr_accounts WHERE acct_id=p_acct_id;
  p_ok  := 1;
  p_msg := 'Funds added';
EXCEPTION
  WHEN OTHERS THEN
    p_ok    := 0;
    p_msg   := 'Unexpected: '||SQLERRM;
    p_value := NULL;
END opr_add_funds;
/
-- Test
DECLARE ok NUMBER; msg VARCHAR2(200); val NUMBER;
BEGIN opr_add_funds(1, 500.456, ok, msg, val);
  DBMS_OUTPUT.PUT_LINE('ok='||ok||' msg='||msg||' new_balance='||TO_CHAR(val,'FM9999999990.00'));
END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 3: OUT %ROWTYPE (return an entire row)
--------------------------------------------------------------------------------
-- Goal:
--   Return a whole row using a %ROWTYPE OUT parameter.
-- Steps:
--   1) Caller declares a variable of table%ROWTYPE.
--   2) Procedure fills the OUT record via SELECT ... INTO.
CREATE OR REPLACE PROCEDURE opr_get_account_row(
  p_acct_id IN  opr_accounts.acct_id%TYPE,
  p_row     OUT opr_accounts%ROWTYPE          -- composite OUT (record of the table)
) IS
BEGIN
  SELECT *
    INTO p_row
    FROM opr_accounts
   WHERE acct_id=p_acct_id;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    -- Initialize a safe default row (only primary key set; others NULL)
    p_row.acct_id   := p_acct_id;
    p_row.acct_name := NULL;
    p_row.balance   := NULL;
    p_row.opened_on := NULL;
    p_row.status    := NULL;
END opr_get_account_row;
/
-- Test
DECLARE r opr_accounts%ROWTYPE;
BEGIN
  opr_get_account_row(2, r);
  DBMS_OUTPUT.PUT_LINE('acct_id='||r.acct_id||' name='||r.acct_name||' bal='||TO_CHAR(r.balance,'FM9999999990.00'));
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 4: OUT SYS_REFCURSOR (return a result set)
--------------------------------------------------------------------------------
-- Goal:
--   Return a multi-row result set filtered by status using a SYS_REFCURSOR OUT parameter.
-- Steps:
--   1) OPEN the cursor FOR a query.
--   2) Caller FETCHes rows from the cursor.
CREATE OR REPLACE PROCEDURE opr_get_active_accounts(
  p_status   IN  opr_accounts.status%TYPE,
  p_rc       OUT SYS_REFCURSOR
) IS
BEGIN
  OPEN p_rc FOR
    SELECT acct_id, acct_name, balance, opened_on, status
      FROM opr_accounts
     WHERE status = p_status
     ORDER BY acct_id;
END opr_get_active_accounts;
/
-- Test
DECLARE c SYS_REFCURSOR; v_id NUMBER; v_name VARCHAR2(80); v_bal NUMBER; v_dt DATE; v_st VARCHAR2(20);
BEGIN
  opr_get_active_accounts('ACTIVE', c);
  LOOP
    FETCH c INTO v_id, v_name, v_bal, v_dt, v_st;
    EXIT WHEN c%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('id='||v_id||' name='||v_name||' bal='||TO_CHAR(v_bal,'FM9999999990.00'));
  END LOOP;
  CLOSE c;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 5: Defensive OUT initialization in EXCEPTION paths
--------------------------------------------------------------------------------
-- Goal:
--   Guarantee OUT parameters are assigned even when unexpected errors occur.
-- Steps:
--   1) Initialize OUTs at the top.
--   2) In EXCEPTION block set OUTs to safe defaults and return a meaningful message.
CREATE OR REPLACE PROCEDURE opr_transfer(
  p_from    IN  opr_accounts.acct_id%TYPE,
  p_to      IN  opr_accounts.acct_id%TYPE,
  p_amount  IN  NUMBER,
  p_ok      OUT NUMBER,
  p_msg     OUT VARCHAR2,
  p_from_bal OUT NUMBER,
  p_to_bal   OUT NUMBER
) IS
  v_amt NUMBER(12,2);
BEGIN
  p_ok := 0; p_msg := NULL; p_from_bal := NULL; p_to_bal := NULL;

  v_amt := ROUND(p_amount,2);
  IF v_amt IS NULL OR v_amt <= 0 THEN
    p_msg := 'Amount must be positive';
    RETURN;
  END IF;

  UPDATE opr_accounts SET balance = balance - v_amt WHERE acct_id=p_from;
  IF SQL%ROWCOUNT=0 THEN p_msg := 'Source account not found'; RETURN; END IF;

  UPDATE opr_accounts SET balance = balance + v_amt WHERE acct_id=p_to;
  IF SQL%ROWCOUNT=0 THEN p_msg := 'Target account not found'; ROLLBACK; RETURN; END IF;

  SELECT balance INTO p_from_bal FROM opr_accounts WHERE acct_id=p_from;
  SELECT balance INTO p_to_bal   FROM opr_accounts WHERE acct_id=p_to;

  p_ok := 1; p_msg := 'Transfer complete';
EXCEPTION
  WHEN OTHERS THEN
    -- Set safe defaults so caller is never left with NULLs unknowingly
    IF p_from_bal IS NULL THEN p_from_bal := 0; END IF;
    IF p_to_bal   IS NULL THEN p_to_bal   := 0; END IF;
    p_ok := 0; p_msg := 'Transfer failed: '||SQLERRM;
END opr_transfer;
/
-- Test
DECLARE ok NUMBER; msg VARCHAR2(200); b1 NUMBER; b2 NUMBER;
BEGIN
  opr_transfer(1, 2, 300.25, ok, msg, b1, b2);
  DBMS_OUTPUT.PUT_LINE('ok='||ok||' msg='||msg||' from='||TO_CHAR(b1,'FM9999999990.00')||' to='||TO_CHAR(b2,'FM9999999990.00'));
END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 6: OUT with derived metrics (date difference and formatted text)
--------------------------------------------------------------------------------
-- Goal:
--   Compute derived values and return them via OUT: account age in days and a message.
CREATE OR REPLACE PROCEDURE opr_account_age(
  p_acct_id  IN  opr_accounts.acct_id%TYPE,
  p_days_out OUT NUMBER,
  p_msg_out  OUT VARCHAR2
) IS
  v_opened DATE;
BEGIN
  p_days_out := NULL; p_msg_out := NULL;

  SELECT opened_on INTO v_opened FROM opr_accounts WHERE acct_id=p_acct_id;
  p_days_out := TRUNC(SYSDATE) - TRUNC(v_opened);
  p_msg_out  := 'Account has been open for '||p_days_out||' days';
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    p_days_out := 0;
    p_msg_out  := 'Account not found';
END opr_account_age;
/
-- Test
DECLARE d NUMBER; m VARCHAR2(200);
BEGIN opr_account_age(1,d,m); DBMS_OUTPUT.PUT_LINE(m); END; /
--------------------------------------------------------------------------------
-- End of File
--------------------------------------------------------------------------------
