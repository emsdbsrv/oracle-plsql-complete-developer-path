-- Script: plsql_default_parameter_values.sql
-- Session: 041 - DEFAULT Parameter Values
-- Purpose:
--   Demonstrate robust patterns for specifying default parameter values in PL/SQL procedures.
--   Each example includes step-by-step commentary and explains numeric/text choices.
-- How to run:
--   SET SERVEROUTPUT ON; Execute each example separately (terminated by '/').
-- Notes:
--   • Defaults are typically declared for IN parameters using either 'DEFAULT expr' or ':= expr' syntax.
--   • OUT parameters cannot have default values. IN OUT defaults are not idiomatic and should be avoided.
--   • Use named notation to skip optional parameters safely.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Setup: reference table and package constants (idempotent)
--------------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'DROP TABLE dp_orders PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE TABLE dp_orders (
  order_id    NUMBER CONSTRAINT dp_orders_pk PRIMARY KEY,
  cust_name   VARCHAR2(100) NOT NULL,
  amount      NUMBER(12,2)   NOT NULL,
  status      VARCHAR2(20)   DEFAULT 'NEW',
  created_on  DATE           DEFAULT SYSDATE
);

INSERT INTO dp_orders VALUES (1,'Avi',  999.00, 'NEW', SYSDATE-3);
INSERT INTO dp_orders VALUES (2,'Neha', 499.50, 'NEW', SYSDATE-1);
COMMIT;
/

-- Package to hold constants used as defaults
CREATE OR REPLACE PACKAGE dp_consts IS
  c_default_status CONSTANT VARCHAR2(20) := 'PENDING';
  c_currency       CONSTANT CHAR(3)      := 'INR';
END dp_consts;
/

--------------------------------------------------------------------------------
-- Example 1: Basic DEFAULT for optional IN parameter
--------------------------------------------------------------------------------
-- Scenario:
--   Optional status defaults to dp_consts.c_default_status when caller omits it.
-- Highlights:
--   1) Defaults declared using ':='.
--   2) Use named notation to skip optional argument.
CREATE OR REPLACE PROCEDURE dp_set_status(
  p_order_id IN dp_orders.order_id%TYPE,
  p_status   IN dp_orders.status%TYPE := dp_consts.c_default_status  -- default expression from package constant
) IS
BEGIN
  UPDATE dp_orders SET status = p_status WHERE order_id = p_order_id;
  DBMS_OUTPUT.PUT_LINE('rows='||SQL%ROWCOUNT||' status='||p_status);
END dp_set_status;
/
-- Test: omit p_status -> uses default; then explicit override via named notation
BEGIN
  dp_set_status(1);                                 -- default PENDING
  dp_set_status(p_order_id=>2, p_status=>'APPROVED'); -- explicit
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 2: Multiple defaults (amount step and flag)
--------------------------------------------------------------------------------
-- Scenario:
--   Increase amount by a step with defaults: step defaults to 100.00, and flag toggles rounding behavior.
-- Notes:
--   1) Use NUMBER(12,2) for money-like arithmetic.
--   2) BOOLEAN defaults enable feature toggles.
CREATE OR REPLACE PROCEDURE dp_add_amount(
  p_order_id IN dp_orders.order_id%TYPE,
  p_step     IN NUMBER := 100.00,   -- default increase step
  p_round    IN BOOLEAN := TRUE     -- default behavior toggles ROUND()
) IS
  v_old NUMBER(12,2);
  v_new NUMBER(12,2);
BEGIN
  SELECT amount INTO v_old FROM dp_orders WHERE order_id=p_order_id;
  v_new := v_old + p_step;
  IF p_round THEN
    v_new := ROUND(v_new, 2);
  END IF;

  UPDATE dp_orders SET amount = v_new WHERE order_id=p_order_id;
  DBMS_OUTPUT.PUT_LINE('old='||TO_CHAR(v_old,'FM9999999990.00')||' new='||TO_CHAR(v_new,'FM9999999990.00'));
END dp_add_amount;
/
-- Test calls showing positional and named notation
BEGIN
  dp_add_amount(1);                                  -- uses defaults (step 100, round TRUE)
  dp_add_amount(p_order_id=>2, p_step=>12.345, p_round=>FALSE);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 3: Default timestamp using SYSDATE and optional currency code
--------------------------------------------------------------------------------
-- Scenario:
--   Log an audit message with optional currency defaulting to dp_consts.c_currency and
--   a timestamp defaulting to SYSDATE. Demonstrates function/constant defaults.
CREATE OR REPLACE PROCEDURE dp_audit(
  p_order_id IN dp_orders.order_id%TYPE,
  p_currency IN CHAR    := dp_consts.c_currency,
  p_when     IN DATE    := SYSDATE,
  p_note     IN VARCHAR2 := 'no-note'
) IS
BEGIN
  DBMS_OUTPUT.PUT_LINE('AUDIT order='||p_order_id||' curr='||p_currency||' when='||TO_CHAR(p_when,'YYYY-MM-DD HH24:MI:SS')||' note='||p_note);
END dp_audit;
/
-- Test with various omissions via named notation
BEGIN
  dp_audit(1);                                                 -- all defaults
  dp_audit(p_order_id=>2, p_note=>'manual adjustment');        -- override note only
  dp_audit(p_order_id=>2, p_currency=>'USD', p_when=>SYSDATE); -- override currency and time
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 4: Mix required + optional, skipping via named notation safely
--------------------------------------------------------------------------------
-- Scenario:
--   Recompute amount with optional tax_rate and discount_pct. Both default to 0.
--   Demonstrates skipping parameters using names while keeping required first.
CREATE OR REPLACE PROCEDURE dp_reprice(
  p_order_id    IN dp_orders.order_id%TYPE,
  p_tax_rate    IN NUMBER := 0,     -- e.g., 0.18 for 18%
  p_discount_pc IN NUMBER := 0      -- e.g., 5 for 5%
) IS
  v_base NUMBER(12,2);
  v_tmp  NUMBER(12,2);
  v_new  NUMBER(12,2);
BEGIN
  SELECT amount INTO v_base FROM dp_orders WHERE order_id=p_order_id;

  v_tmp := v_base * (1 + NVL(p_tax_rate,0));            -- tax
  v_new := v_tmp  * (1 - NVL(p_discount_pc,0)/100);     -- discount in percent
  v_new := ROUND(v_new, 2);

  UPDATE dp_orders SET amount=v_new WHERE order_id=p_order_id;
  DBMS_OUTPUT.PUT_LINE('base='||v_base||' tax='||NVL(p_tax_rate,0)||' disc%='||NVL(p_discount_pc,0)||' new='||v_new);
END dp_reprice;
/
-- Test: skip tax_rate but set discount using named notation
BEGIN
  dp_reprice(p_order_id=>1, p_discount_pc=>10); -- only discount
  dp_reprice(p_order_id=>2, p_tax_rate=>0.18);  -- only tax
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 5: Overloads + defaults (avoid ambiguous calls)
--------------------------------------------------------------------------------
-- Scenario:
--   Provide two overloads: one accepts a numeric step, another accepts a percentage.
--   Use defaults so callers can omit the optional argument, but ensure no ambiguity.
CREATE OR REPLACE PACKAGE dp_over AS
  PROCEDURE bump_amount(p_order_id IN NUMBER, p_step IN NUMBER := 50.00);
  PROCEDURE bump_amount(p_order_id IN NUMBER, p_percent IN NUMBER, p_is_percent IN BOOLEAN);
END dp_over;
/
CREATE OR REPLACE PACKAGE BODY dp_over AS
  PROCEDURE bump_amount(p_order_id IN NUMBER, p_step IN NUMBER) IS
    v NUMBER(12,2);
  BEGIN
    SELECT amount INTO v FROM dp_orders WHERE order_id=p_order_id;
    v := ROUND(v + NVL(p_step,50), 2);
    UPDATE dp_orders SET amount=v WHERE order_id=p_order_id;
    DBMS_OUTPUT.PUT_LINE('bump by step -> '||v);
  END;

  PROCEDURE bump_amount(p_order_id IN NUMBER, p_percent IN NUMBER, p_is_percent IN BOOLEAN) IS
    v NUMBER(12,2);
  BEGIN
    SELECT amount INTO v FROM dp_orders WHERE order_id=p_order_id;
    IF p_is_percent THEN
      v := ROUND(v * (1 + NVL(p_percent,0)/100), 2);
      UPDATE dp_orders SET amount=v WHERE order_id=p_order_id;
      DBMS_OUTPUT.PUT_LINE('bump by percent -> '||v);
    ELSE
      -- If called with p_is_percent=FALSE, treat p_percent as absolute step
      v := ROUND(v + NVL(p_percent,0), 2);
      UPDATE dp_orders SET amount=v WHERE order_id=p_order_id;
      DBMS_OUTPUT.PUT_LINE('bump by absolute -> '||v);
    END IF;
  END;
END dp_over;
/
-- Test: explicit second param for the overload that requires the boolean to avoid ambiguity
BEGIN
  dp_over.bump_amount(1);                        -- uses default step 50.00
  dp_over.bump_amount(2, p_percent=>10, p_is_percent=>TRUE);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 6: Named notation skipping middle arguments
--------------------------------------------------------------------------------
-- Scenario:
--   Optional middle args can be skipped with named notation. The last argument remains defaulted.
CREATE OR REPLACE PROCEDURE dp_notify(
  p_order_id IN dp_orders.order_id%TYPE,
  p_channel  IN VARCHAR2 := 'EMAIL',
  p_retries  IN PLS_INTEGER := 3,
  p_timeout  IN PLS_INTEGER := 30
) IS
BEGIN
  DBMS_OUTPUT.PUT_LINE('notify id='||p_order_id||' via '||p_channel||' retries='||p_retries||' timeout='||p_timeout);
END dp_notify;
/
-- Test: set p_retries only; skip p_channel and p_timeout (both default)
BEGIN
  dp_notify(p_order_id=>1, p_retries=>5);
END;
/
--------------------------------------------------------------------------------
-- End of File
--------------------------------------------------------------------------------
