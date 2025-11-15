-- assignment_constants_and_literals.sql
-- Session : 018_constants_and_literals
-- Topic   : Practice - Constants and Literals

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Assignment 1: Define constant for application version
--------------------------------------------------------------------------------
DECLARE
  c_app_version CONSTANT VARCHAR2(10) := 'v1.0';
BEGIN
  DBMS_OUTPUT.PUT_LINE('A1: Application Version = ' || c_app_version);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 2: Use numeric constants in a pricing formula
--------------------------------------------------------------------------------
DECLARE
  c_discount_rate CONSTANT NUMBER := 0.10;
  v_price         NUMBER := 2500;
  v_final_price   NUMBER;
BEGIN
  v_final_price := v_price - (v_price * c_discount_rate);
  DBMS_OUTPUT.PUT_LINE('A2: Final Price = ' || v_final_price);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 3: Use date literal for financial year start
--------------------------------------------------------------------------------
DECLARE
  c_fy_start CONSTANT DATE := DATE '2025-04-01';
BEGIN
  DBMS_OUTPUT.PUT_LINE('A3: Financial Year starts on ' ||
                       TO_CHAR(c_fy_start, 'DD-MON-YYYY'));
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 4: Constant for maximum login attempts
--------------------------------------------------------------------------------
DECLARE
  c_max_attempts CONSTANT NUMBER := 3;
  v_used_attempts NUMBER := 2;
BEGIN
  DBMS_OUTPUT.PUT_LINE('A4: Max attempts = ' || c_max_attempts);
  DBMS_OUTPUT.PUT_LINE('A4: Used attempts= ' || v_used_attempts);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 5: String literal with single quotes using q-quote
--------------------------------------------------------------------------------
DECLARE
  v_msg VARCHAR2(100) := q'[Today's session is on constants and literals]';
BEGIN
  DBMS_OUTPUT.PUT_LINE('A5: ' || v_msg);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 6: Use PI constant for circumference calculation
--------------------------------------------------------------------------------
DECLARE
  c_pi      CONSTANT NUMBER := 3.14159;
  v_radius  NUMBER := 5;
  v_circum NUMBER;
BEGIN
  v_circum := 2 * c_pi * v_radius;
  DBMS_OUTPUT.PUT_LINE('A6: Circumference = ' || v_circum);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 7: Avoid magic numbers by naming tax rates
--------------------------------------------------------------------------------
DECLARE
  c_tax_low   CONSTANT NUMBER := 0.05;
  c_tax_high  CONSTANT NUMBER := 0.18;
  v_amount    NUMBER := 800;
  v_tax       NUMBER;
BEGIN
  IF v_amount <= 1000 THEN
    v_tax := v_amount * c_tax_low;
  ELSE
    v_tax := v_amount * c_tax_high;
  END IF;

  DBMS_OUTPUT.PUT_LINE('A7: Tax = ' || v_tax);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 8: Use boolean constants for feature flags
--------------------------------------------------------------------------------
DECLARE
  c_feature_x_enabled CONSTANT BOOLEAN := TRUE;
BEGIN
  IF c_feature_x_enabled THEN
    DBMS_OUTPUT.PUT_LINE('A8: Feature X is enabled.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('A8: Feature X is disabled.');
  END IF;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 9: Use multiple literals in a formatted summary line
--------------------------------------------------------------------------------
DECLARE
  c_label CONSTANT VARCHAR2(30) := 'Order Total';
  v_total NUMBER := 4520.75;
BEGIN
  DBMS_OUTPUT.PUT_LINE('A9: ' || c_label || ' = ' || v_total);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 10: Combine numeric, date, and string constants
--------------------------------------------------------------------------------
DECLARE
  c_project_name CONSTANT VARCHAR2(50) := 'Migration Phase 1';
  c_start_date   CONSTANT DATE         := DATE '2025-02-01';
  c_budget       CONSTANT NUMBER       := 500000;
BEGIN
  DBMS_OUTPUT.PUT_LINE(
    'A10: Project "' || c_project_name ||
    '" starting ' || TO_CHAR(c_start_date, 'DD-MON-YYYY') ||
    ' with budget ' || c_budget
  );
END;
/
--------------------------------------------------------------------------------
