-- Script: plsql_user_defined_error_codes.sql
-- Session: 051 - User-Defined Error Codes
-- Purpose:
--   Demonstrate designing, declaring, and using user-defined error codes in PL/SQL.
--   Covers: named exceptions, RAISE vs RAISE_APPLICATION_ERROR, central package of codes,
--   translation strategies, propagation, and logging with SQLCODE/SQLERRM.
-- How to run:
--   SET SERVEROUTPUT ON; Execute each example separately (terminated by '/').
-- Notes:
--   • Application error codes typically use -20000..-20999.
--   • Keep messages actionable and include identifiers.
--   • This script is idempotent and can be re-run safely.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Setup: sample table
--------------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'DROP TABLE udec_accounts PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE udec_accounts (
  acct_id    NUMBER CONSTRAINT udec_accounts_pk PRIMARY KEY,
  cust_name  VARCHAR2(80) NOT NULL,
  balance    NUMBER(12,2) NOT NULL,
  status     VARCHAR2(20) DEFAULT 'ACTIVE' NOT NULL
);
INSERT INTO udec_accounts VALUES (1,'Avi',  1000,'ACTIVE');
INSERT INTO udec_accounts VALUES (2,'Neha',  250,'ACTIVE');
COMMIT;
/

--------------------------------------------------------------------------------
-- Package: centralized codes and helpers
--------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE pkg_errors AS
  -- Code constants (document meaning)
  c_neg_amount      CONSTANT PLS_INTEGER := -20001; -- negative or zero amount
  c_low_balance     CONSTANT PLS_INTEGER := -20002; -- insufficient funds
  c_inactive_acct   CONSTANT PLS_INTEGER := -20003; -- status not ACTIVE
  c_duplicate_txn   CONSTANT PLS_INTEGER := -20004; -- business duplicate
  c_domain_generic  CONSTANT PLS_INTEGER := -20010; -- catch-all translation

  -- Helper to raise with consistent formatting
  PROCEDURE raise_err(p_code IN PLS_INTEGER, p_msg IN VARCHAR2);

  -- Optional mapping from system errors to domain codes (example)
  FUNCTION translate_system(p_code IN PLS_INTEGER, p_msg IN VARCHAR2)
    RETURN PLS_INTEGER;
END pkg_errors;
/

CREATE OR REPLACE PACKAGE BODY pkg_errors AS
  PROCEDURE raise_err(p_code IN PLS_INTEGER, p_msg IN VARCHAR2) IS
  BEGIN
    RAISE_APPLICATION_ERROR(p_code, p_msg);
  END;

  FUNCTION translate_system(p_code IN PLS_INTEGER, p_msg IN VARCHAR2)
    RETURN PLS_INTEGER
  IS
  BEGIN
    -- Sample: map unique constraint to a business duplicate
    IF p_code = -1 THEN
      RETURN c_duplicate_txn;
    END IF;
    RETURN c_domain_generic;
  END;
END pkg_errors;
/

--------------------------------------------------------------------------------
-- Example 1: RAISE a named exception (no code) vs RAISE_APPLICATION_ERROR (code)
--------------------------------------------------------------------------------
DECLARE
  ex_neg_amount EXCEPTION;
  v_amt NUMBER := -5;
BEGIN
  IF v_amt <= 0 THEN
    -- Option A: named exception inside the module (no externally visible code)
    -- RAISE ex_neg_amount;

    -- Option B: translate to a standard -20xxx code for callers
    pkg_errors.raise_err(pkg_errors.c_neg_amount,
      'Amount must be positive. amt='||v_amt);
  END IF;
EXCEPTION
  WHEN ex_neg_amount THEN
    DBMS_OUTPUT.PUT_LINE('named exception caught (internal only)');
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('code='||SQLCODE||' msg='||SQLERRM);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 2: Withdraw with user-defined codes and domain checks
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE udec_withdraw(p_acct_id IN NUMBER, p_amt IN NUMBER) IS
  v_bal udec_accounts.balance%TYPE;
  v_st  udec_accounts.status%TYPE;
BEGIN
  -- Input validation
  IF p_amt <= 0 THEN
    pkg_errors.raise_err(pkg_errors.c_neg_amount,
      'Amount must be positive. acct='||p_acct_id||' amt='||p_amt);
  END IF;

  SELECT balance, status INTO v_bal, v_st FROM udec_accounts WHERE acct_id=p_acct_id;

  IF v_st <> 'ACTIVE' THEN
    pkg_errors.raise_err(pkg_errors.c_inactive_acct,
      'Account is not ACTIVE. acct='||p_acct_id||' status='||v_st);
  END IF;

  IF v_bal < p_amt THEN
    pkg_errors.raise_err(pkg_errors.c_low_balance,
      'Insufficient funds. acct='||p_acct_id||' bal='||v_bal||' need='||p_amt);
  END IF;

  UPDATE udec_accounts
     SET balance = balance - p_amt
   WHERE acct_id = p_acct_id;

  DBMS_OUTPUT.PUT_LINE('Withdrawal OK. acct='||p_acct_id||' new_bal='||(v_bal - p_amt));
EXCEPTION
  WHEN OTHERS THEN
    -- Log and re-raise for upper layer to decide commit/rollback
    DBMS_OUTPUT.PUT_LINE('[udec_withdraw] code='||SQLCODE||' err='||SQLERRM);
    RAISE;
END;
/

BEGIN
  -- Try valid
  udec_withdraw(1, 100);
  -- Try invalid amount
  BEGIN udec_withdraw(1, 0); EXCEPTION WHEN OTHERS THEN NULL; END;
  -- Try low balance
  BEGIN udec_withdraw(2, 1000); EXCEPTION WHEN OTHERS THEN NULL; END;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 3: Translate system error to domain code at boundary
--------------------------------------------------------------------------------
DECLARE
  PROCEDURE create_duplicate IS
  BEGIN
    INSERT INTO udec_accounts VALUES (1,'Dup',0,'ACTIVE'); -- ORA-00001
  END;
BEGIN
  BEGIN
    create_duplicate;
  EXCEPTION
    WHEN OTHERS THEN
      -- Translate ORA to domain code and re-raise with domain message
      pkg_errors.raise_err(pkg_errors.translate_system(SQLCODE, SQLERRM),
        'Duplicate business key while creating account. detail='||SQLERRM);
  END;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('[translated] code='||SQLCODE||' msg='||SQLERRM);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 4: Package-scoped named exceptions + re-raise
--------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE udec_ops AS
  ex_inactive EXCEPTION; -- internal named exception
  PROCEDURE activate(p_acct_id IN NUMBER);
END udec_ops;
/

CREATE OR REPLACE PACKAGE BODY udec_ops AS
  PROCEDURE activate(p_acct_id IN NUMBER) IS
    v_st udec_accounts.status%TYPE;
  BEGIN
    SELECT status INTO v_st FROM udec_accounts WHERE acct_id=p_acct_id;
    IF v_st='ACTIVE' THEN
      RETURN; -- idempotent
    ELSIF v_st<>'INACTIVE' THEN
      RAISE ex_inactive;
    END IF;
    UPDATE udec_accounts SET status='ACTIVE' WHERE acct_id=p_acct_id;
  EXCEPTION
    WHEN ex_inactive THEN
      -- translate to domain code for callers
      pkg_errors.raise_err(pkg_errors.c_inactive_acct,
        'Cannot activate from status='||v_st||' acct='||p_acct_id);
  END;
END udec_ops;
/

BEGIN
  -- Create an INACTIVE row and then activate
  MERGE INTO udec_accounts d
  USING (SELECT 3 acct_id, 'Rita' cust_name, 500 balance, 'INACTIVE' status FROM dual) s
  ON (d.acct_id=s.acct_id)
  WHEN NOT MATCHED THEN
    INSERT (acct_id, cust_name, balance, status)
    VALUES (s.acct_id, s.cust_name, s.balance, s.status);
  udec_ops.activate(3);
  DBMS_OUTPUT.PUT_LINE('Activation attempted.');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 5: Boundary guideline — where to translate vs where to preserve
--------------------------------------------------------------------------------
DECLARE
  PROCEDURE deeper IS
  BEGIN
    -- low-level failure: division by zero (simulating any system error)
    DECLARE a NUMBER:=1; b NUMBER:=0; c NUMBER; BEGIN c:=a/b; END;
  END;
  PROCEDURE mid IS
  BEGIN
    deeper; -- do not translate here; preserve for boundary
  END;
  PROCEDURE boundary IS
  BEGIN
    BEGIN
      mid;
    EXCEPTION
      WHEN OTHERS THEN
        pkg_errors.raise_err(pkg_errors.c_domain_generic,
          'Boundary translation. cause='||SQLERRM);
    END;
  END;
BEGIN
  BEGIN boundary; EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('[boundary] code='||SQLCODE||' msg='||SQLERRM); END;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 6: Logging pattern with SQLCODE/SQLERRM and identifiers
--------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE udec_log AS
  PROCEDURE write(p_where IN VARCHAR2, p_detail IN VARCHAR2);
END udec_log;
/

CREATE OR REPLACE PACKAGE BODY udec_log AS
  PROCEDURE write(p_where IN VARCHAR2, p_detail IN VARCHAR2) IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE('[LOG]['||p_where||'] '||p_detail);
  END;
END udec_log;
/

DECLARE
  PROCEDURE do_work(p_acct_id IN NUMBER) IS
    v_bal NUMBER;
  BEGIN
    SELECT balance INTO v_bal FROM udec_accounts WHERE acct_id=p_acct_id;
    IF v_bal < 100 THEN
      pkg_errors.raise_err(pkg_errors.c_low_balance,
        'Low balance. acct='||p_acct_id||' bal='||v_bal);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      udec_log.write('do_work', 'acct='||p_acct_id||' code='||SQLCODE||' err='||SQLERRM);
      RAISE;
  END;
BEGIN
  BEGIN do_work(2); EXCEPTION WHEN OTHERS THEN udec_log.write('caller','caught code='||SQLCODE||' err='||SQLERRM); END;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 7: Consistent message format helper
--------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE udec_fmt AS
  FUNCTION msg(p_key VARCHAR2, p_msg VARCHAR2) RETURN VARCHAR2;
END udec_fmt;
/

CREATE OR REPLACE PACKAGE BODY udec_fmt AS
  FUNCTION msg(p_key VARCHAR2, p_msg VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN '['||p_key||'] '||p_msg;
  END;
END udec_fmt;
/

BEGIN
  pkg_errors.raise_err(pkg_errors.c_neg_amount,
    udec_fmt.msg('WITHDRAW-001','Amount must be positive for acct=1 amt=-10'));
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('[fmt] code='||SQLCODE||' msg='||SQLERRM);
END;
/
--------------------------------------------------------------------------------
-- End of File
--------------------------------------------------------------------------------
