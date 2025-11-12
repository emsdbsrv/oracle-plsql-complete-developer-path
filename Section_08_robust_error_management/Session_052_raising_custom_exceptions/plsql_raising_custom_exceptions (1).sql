-- Script: plsql_raising_custom_exceptions.sql
-- Session: 052 - Raising Custom Exceptions
-- Purpose:
--   Complete, production-style reference showing how to raise custom exceptions in PL/SQL.
--   Coverage: RAISE vs RAISE_APPLICATION_ERROR, centralized -20xxx codes, inner→outer
--   escalation with logging and translation, transaction guards, and policy consistency.
-- How to run:
--   SET SERVEROUTPUT ON; Execute each example block separately (terminated by '/').
-- Notes:
--   • Use -20000..-20999 for application-visible error codes.
--   • Keep error text actionable: include identifiers, parameters, and context.
--   • Prefer rethrowing (RAISE) over swallowing to preserve diagnostics.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Setup (idempotent)
--------------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'DROP TABLE rce_orders PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE rce_orders (
  order_id   NUMBER CONSTRAINT rce_orders_pk PRIMARY KEY,
  customer   VARCHAR2(80) NOT NULL,
  amount     NUMBER(12,2) NOT NULL,
  status     VARCHAR2(20) DEFAULT 'NEW' NOT NULL
);
INSERT INTO rce_orders VALUES (1,'Avi',  500,'NEW');
INSERT INTO rce_orders VALUES (2,'Neha', 1000,'PAID');
COMMIT;
/

--------------------------------------------------------------------------------
-- Central error package: codes and helpers (single source of truth)
--------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE rce_errors AS
  -- -20xxx domain codes
  c_neg_amount       CONSTANT PLS_INTEGER := -20071; -- invalid amount <= 0
  c_not_found        CONSTANT PLS_INTEGER := -20072; -- entity not found
  c_already_paid     CONSTANT PLS_INTEGER := -20073; -- illegal state transition
  c_invalid_status   CONSTANT PLS_INTEGER := -20074; -- unknown/unsupported state
  c_domain_generic   CONSTANT PLS_INTEGER := -20079; -- generic boundary translation
  -- Helpers
  FUNCTION fmt(p_key VARCHAR2, p_msg VARCHAR2) RETURN VARCHAR2;
  PROCEDURE raise_err(p_code IN PLS_INTEGER, p_msg IN VARCHAR2);
END rce_errors;
/
CREATE OR REPLACE PACKAGE BODY rce_errors AS
  FUNCTION fmt(p_key VARCHAR2, p_msg VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN '['||p_key||'] '||p_msg;
  END;
  PROCEDURE raise_err(p_code IN PLS_INTEGER, p_msg IN VARCHAR2) IS
  BEGIN
    RAISE_APPLICATION_ERROR(p_code, p_msg);
  END;
END rce_errors;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 1: Local named exception + RAISE (internal control only)
-- Scenario:
--   Use a local exception to signal a rule violation (amount <= 0) inside a module.
-- Why:
--   Avoid exposing -20xxx codes deep inside; keep boundary translation centralized.
--------------------------------------------------------------------------------
DECLARE
  ex_neg_amt EXCEPTION;    -- local signal
  v_amt NUMBER := -10;     -- driver
BEGIN
  IF v_amt <= 0 THEN
    RAISE ex_neg_amt;      -- throw named exception
  END IF;
  DBMS_OUTPUT.PUT_LINE('OK');
EXCEPTION
  WHEN ex_neg_amt THEN
    DBMS_OUTPUT.PUT_LINE('Caught ex_neg_amt (internal only)');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 2: Boundary translation to -20xxx using helper
-- Scenario:
--   Convert the internal rule to a standardized application code for callers.
-- Pattern:
--   rce_errors.raise_err(code, rce_errors.fmt('KEY','message with context'))
--------------------------------------------------------------------------------
DECLARE
  v_amt NUMBER := -15;
BEGIN
  IF v_amt <= 0 THEN
    rce_errors.raise_err(rce_errors.c_neg_amount,
      rce_errors.fmt('RCE-NEG-001','Amount must be positive. amt='||v_amt));
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Translated: code='||SQLCODE||' msg='||SQLERRM);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 3: Inner→outer escalation with logging; boundary translation
-- Scenario:
--   Inner block logs ZERO_DIVIDE and re-raises; boundary adds domain code + context.
--------------------------------------------------------------------------------
DECLARE
  PROCEDURE inner_calc(p_id IN NUMBER) IS
    v_amt NUMBER;
  BEGIN
    SELECT amount INTO v_amt FROM rce_orders WHERE order_id=p_id;
    v_amt := v_amt / 0;  -- trigger ZERO_DIVIDE
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('[inner_calc] id='||p_id||' code='||SQLCODE||' err='||SQLERRM);
      RAISE; -- escalate upward
  END;
BEGIN
  BEGIN
    inner_calc(1);
  EXCEPTION
    WHEN OTHERS THEN
      rce_errors.raise_err(rce_errors.c_domain_generic,
        rce_errors.fmt('RCE-ESC-001','Computation failed for order='||1||' cause='||SQLERRM));
  END;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('[caller] code='||SQLCODE||' msg='||SQLERRM);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 4: Business rule procedure raises user codes (already PAID / not found)
-- Notes:
--   • Use NO_DATA_FOUND to detect missing id and translate to c_not_found.
--   • Use c_already_paid to block duplicate transitions.
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE rce_mark_paid(p_order_id IN NUMBER) IS
  v_status rce_orders.status%TYPE;
BEGIN
  SELECT status INTO v_status FROM rce_orders WHERE order_id=p_order_id;
  IF v_status='PAID' THEN
    rce_errors.raise_err(rce_errors.c_already_paid,
      rce_errors.fmt('RCE-PAY-001','Order already PAID. id='||p_order_id));
  END IF;
  UPDATE rce_orders SET status='PAID' WHERE order_id=p_order_id;
  DBMS_OUTPUT.PUT_LINE('Order marked PAID: '||p_order_id);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    rce_errors.raise_err(rce_errors.c_not_found,
      rce_errors.fmt('RCE-PAY-404','Order not found. id='||p_order_id));
END;
/
BEGIN
  -- 1) success
  rce_mark_paid(1);
  -- 2) duplicate
  BEGIN rce_mark_paid(1); EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('[dup] '||SQLCODE||' '||SQLERRM); END;
  -- 3) not found
  BEGIN rce_mark_paid(999); EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('[nf] '||SQLCODE||' '||SQLERRM); END;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 5: Package-scoped named exception; translated at package boundary
-- Why:
--   Internal control uses RAISE; consumers receive consistent -20xxx codes.
--------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE rce_pkg AS
  ex_bad_state EXCEPTION;
  PROCEDURE step(p_order_id IN NUMBER);
END rce_pkg;
/
CREATE OR REPLACE PACKAGE BODY rce_pkg AS
  PROCEDURE step(p_order_id IN NUMBER) IS
    v_s rce_orders.status%TYPE;
  BEGIN
    SELECT status INTO v_s FROM rce_orders WHERE order_id=p_order_id;
    IF v_s NOT IN ('NEW','PAID') THEN
      RAISE ex_bad_state; -- internal signal
    END IF;
  EXCEPTION
    WHEN ex_bad_state THEN
      rce_errors.raise_err(rce_errors.c_invalid_status,
        rce_errors.fmt('RCE-STEP-STATE','Unsupported state='||v_s||' id='||p_order_id));
  END;
END rce_pkg;
/
BEGIN
  UPDATE rce_orders SET status='HOLD' WHERE order_id=2; COMMIT;
  BEGIN rce_pkg.step(2); EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('[pkg] '||SQLCODE||' '||SQLERRM); END;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 6: Guarded transaction with SAVEPOINT and rollback
-- Pattern:
--   SAVEPOINT → DML → check SQL%ROWCOUNT → raise custom code if 0 → COMMIT else ROLLBACK TO sp.
--------------------------------------------------------------------------------
DECLARE
  v_id NUMBER := 777; -- nonexistent id for demonstration
BEGIN
  SAVEPOINT sp;
  UPDATE rce_orders SET amount = amount + 50 WHERE order_id=v_id;
  IF SQL%ROWCOUNT = 0 THEN
    rce_errors.raise_err(rce_errors.c_not_found,
      rce_errors.fmt('RCE-GUARD-404','No order for guarded update. id='||v_id));
  END IF;
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Committed guarded update for id='||v_id);
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK TO sp;
    DBMS_OUTPUT.PUT_LINE('[rolled back] code='||SQLCODE||' msg='||SQLERRM);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 7: Preserve low-level system error; translate only at API boundary
-- Why:
--   Separation of concerns—keep system diagnostics intact until boundary.
--------------------------------------------------------------------------------
DECLARE
  PROCEDURE low IS
  BEGIN
    EXECUTE IMMEDIATE 'BEGIN :x := TO_NUMBER(''abc''); END;' USING OUT NULL;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE; -- preserve original
  END;
BEGIN
  BEGIN
    low;
  EXCEPTION
    WHEN OTHERS THEN
      rce_errors.raise_err(rce_errors.c_domain_generic,
        rce_errors.fmt('RCE-API-TRANS','Invalid numeric input. cause='||SQLERRM));
  END;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('[api] code='||SQLCODE||' msg='||SQLERRM);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 8: Unified code policy — list constants for discoverability
--------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE(
    'Codes: neg='||rce_errors.c_neg_amount||', nf='||rce_errors.c_not_found||
    ', paid='||rce_errors.c_already_paid||', invalid='||rce_errors.c_invalid_status||
    ', generic='||rce_errors.c_domain_generic
  );
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 9: Re-raise after partial handling (logging) to preserve SQLCODE
--------------------------------------------------------------------------------
BEGIN
  BEGIN
    RAISE_APPLICATION_ERROR(-20090,'Intermediate failure');
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('[partial] captured: code='||SQLCODE||' msg='||SQLERRM);
      RAISE; -- rethrow preserves code and message
  END;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('[caller] final: code='||SQLCODE||' msg='||SQLERRM);
END;
/
--------------------------------------------------------------------------------
-- End of File
--------------------------------------------------------------------------------
