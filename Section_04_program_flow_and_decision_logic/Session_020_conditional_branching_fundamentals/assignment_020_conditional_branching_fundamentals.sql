-- assignment_020_conditional_branching_fundamentals.sql
-- Session : 020_conditional_branching_fundamentals
-- Topic   : Practice - Conditional Branching Fundamentals
-- Purpose : 10 assignment-style examples using IF, IF-ELSE, IF-ELSIF.
-- Note    : Each block is self-contained and can be executed independently.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Assignment 1: Pass / Fail based on marks
--------------------------------------------------------------------------------
DECLARE
  v_marks NUMBER := 48;
BEGIN
  DBMS_OUTPUT.PUT_LINE('A1: Checking Pass/Fail for marks = ' || v_marks);

  IF v_marks >= 50 THEN
    DBMS_OUTPUT.PUT_LINE('A1 Result: PASS');
  ELSE
    DBMS_OUTPUT.PUT_LINE('A1 Result: FAIL');
  END IF;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 2: Determine if a number is even or odd
--------------------------------------------------------------------------------
DECLARE
  v_num NUMBER := 17;
BEGIN
  DBMS_OUTPUT.PUT_LINE('A2: Checking even/odd for number = ' || v_num);

  IF MOD(v_num, 2) = 0 THEN
    DBMS_OUTPUT.PUT_LINE('A2 Result: EVEN');
  ELSE
    DBMS_OUTPUT.PUT_LINE('A2 Result: ODD');
  END IF;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 3: Determine discount category using IF-ELSIF-ELSE
--------------------------------------------------------------------------------
DECLARE
  v_purchase_amount NUMBER := 3200;
  v_discount_label  VARCHAR2(20);
BEGIN
  DBMS_OUTPUT.PUT_LINE('A3: Purchase amount = ' || v_purchase_amount);

  IF v_purchase_amount >= 5000 THEN
    v_discount_label := 'High Discount';
  ELSIF v_purchase_amount >= 3000 THEN
    v_discount_label := 'Medium Discount';
  ELSIF v_purchase_amount >= 1000 THEN
    v_discount_label := 'Low Discount';
  ELSE
    v_discount_label := 'No Discount';
  END IF;

  DBMS_OUTPUT.PUT_LINE('A3 Result: ' || v_discount_label);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 4: Age-based ticket pricing
--------------------------------------------------------------------------------
DECLARE
  v_age       NUMBER := 65;
  v_ticket_fee NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('A4: Age = ' || v_age);

  IF v_age < 12 THEN
    v_ticket_fee := 100;
  ELSIF v_age BETWEEN 12 AND 59 THEN
    v_ticket_fee := 200;
  ELSE
    v_ticket_fee := 120; -- senior citizen concession
  END IF;

  DBMS_OUTPUT.PUT_LINE('A4 Ticket Fee = ' || v_ticket_fee);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 5: Check if entered year is a leap year (simplified rule)
--------------------------------------------------------------------------------
DECLARE
  v_year NUMBER := 2028;
BEGIN
  DBMS_OUTPUT.PUT_LINE('A5: Year = ' || v_year);

  IF MOD(v_year, 400) = 0 THEN
    DBMS_OUTPUT.PUT_LINE('A5 Result: Leap year (divisible by 400).');
  ELSIF MOD(v_year, 100) = 0 THEN
    DBMS_OUTPUT.PUT_LINE('A5 Result: Not a leap year (century not divisible by 400).');
  ELSIF MOD(v_year, 4) = 0 THEN
    DBMS_OUTPUT.PUT_LINE('A5 Result: Leap year (divisible by 4).');
  ELSE
    DBMS_OUTPUT.PUT_LINE('A5 Result: Not a leap year.');
  END IF;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 6: Validate login attempt count
--------------------------------------------------------------------------------
DECLARE
  v_failed_attempts NUMBER := 3;
BEGIN
  DBMS_OUTPUT.PUT_LINE('A6: Failed attempts = ' || v_failed_attempts);

  IF v_failed_attempts >= 3 THEN
    DBMS_OUTPUT.PUT_LINE('A6: Account locked due to multiple failures.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('A6: Account still active.');
  END IF;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 7: Determine meal type from time of day
--------------------------------------------------------------------------------
DECLARE
  v_hour NUMBER := 14; -- 24-hour format
BEGIN
  DBMS_OUTPUT.PUT_LINE('A7: Hour of day = ' || v_hour);

  IF v_hour BETWEEN 6 AND 11 THEN
    DBMS_OUTPUT.PUT_LINE('A7: It is breakfast time.');
  ELSIF v_hour BETWEEN 12 AND 15 THEN
    DBMS_OUTPUT.PUT_LINE('A7: It is lunch time.');
  ELSIF v_hour BETWEEN 19 AND 22 THEN
    DBMS_OUTPUT.PUT_LINE('A7: It is dinner time.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('A7: Snack / off-meal time.');
  END IF;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 8: Determine working / weekend day
--------------------------------------------------------------------------------
DECLARE
  v_day VARCHAR2(10) := 'Sunday';
BEGIN
  DBMS_OUTPUT.PUT_LINE('A8: Day = ' || v_day);

  IF v_day IN ('Saturday', 'Sunday') THEN
    DBMS_OUTPUT.PUT_LINE('A8: It is a weekend.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('A8: It is a working day.');
  END IF;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 9: Shipping charge based on weight
--------------------------------------------------------------------------------
DECLARE
  v_weight_kg     NUMBER := 2.8;
  v_shipping_cost NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('A9: Weight = ' || v_weight_kg || ' kg');

  IF v_weight_kg <= 1 THEN
    v_shipping_cost := 50;
  ELSIF v_weight_kg <= 3 THEN
    v_shipping_cost := 80;
  ELSE
    v_shipping_cost := 120;
  END IF;

  DBMS_OUTPUT.PUT_LINE('A9 Shipping cost = ' || v_shipping_cost);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 10: Inclusive / exclusive range checks
--------------------------------------------------------------------------------
DECLARE
  v_value NUMBER := 25;
BEGIN
  DBMS_OUTPUT.PUT_LINE('A10: Value = ' || v_value);

  IF v_value < 0 THEN
    DBMS_OUTPUT.PUT_LINE('A10: Negative value.');
  ELSIF v_value BETWEEN 0 AND 10 THEN
    DBMS_OUTPUT.PUT_LINE('A10: Between 0 and 10.');
  ELSIF v_value BETWEEN 11 AND 20 THEN
    DBMS_OUTPUT.PUT_LINE('A10: Between 11 and 20.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('A10: Greater than 20.');
  END IF;
END;
/
--------------------------------------------------------------------------------
