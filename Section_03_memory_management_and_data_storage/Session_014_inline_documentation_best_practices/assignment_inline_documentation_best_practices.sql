-- assignment_inline_documentation_best_practices.sql
-- Session : 014_inline_documentation_best_practices
-- Topic   : Practice - Writing Useful Comments in PL/SQL

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Assignment 1: Add header comments describing purpose and variables
--------------------------------------------------------------------------------
DECLARE
  -- v_customer_count: total number of customers in current report.
  v_customer_count NUMBER := 150;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Assignment 1: Customer Count = ' || v_customer_count);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 2: Comment each step of a discount calculation
--------------------------------------------------------------------------------
DECLARE
  v_price    NUMBER := 2000;
  v_discount NUMBER;
  v_net      NUMBER;
BEGIN
  -- Compute discount as 15% of price.
  v_discount := v_price * 0.15;

  -- Net amount = price minus discount.
  v_net := v_price - v_discount;

  DBMS_OUTPUT.PUT_LINE('Assignment 2: Net Amount = ' || v_net);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 3: Use block comment to explain a business rule
--------------------------------------------------------------------------------
DECLARE
  v_score NUMBER := 68;
BEGIN
  /*
    Business Rule:
    - 70 and above   : Distinction
    - 50 to 69       : Pass
    - Below 50       : Fail
  */
  IF v_score >= 70 THEN
    DBMS_OUTPUT.PUT_LINE('Assignment 3: Distinction');
  ELSIF v_score >= 50 THEN
    DBMS_OUTPUT.PUT_LINE('Assignment 3: Pass');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Assignment 3: Fail');
  END IF;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 4: Comment on assumptions for tax calculation
--------------------------------------------------------------------------------
DECLARE
  v_income   NUMBER := 900000;
  v_tax_rate NUMBER;
BEGIN
  -- Assumption:
  --   For income up to 500000, tax rate is 5%.
  --   For income between 500001 and 1000000, tax rate is 20%.
  --   For income above 1000000, tax rate is 30%.
  IF v_income <= 500000 THEN
    v_tax_rate := 0.05;
  ELSIF v_income <= 1000000 THEN
    v_tax_rate := 0.20;
  ELSE
    v_tax_rate := 0.30;
  END IF;

  DBMS_OUTPUT.PUT_LINE('Assignment 4: Tax Rate = ' || v_tax_rate);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 5: Use comments to clarify a loop’s purpose
--------------------------------------------------------------------------------
DECLARE
  v_sum NUMBER := 0;
BEGIN
  -- Loop from 1 to 10 and calculate the total sum of integers.
  FOR i IN 1 .. 10 LOOP
    v_sum := v_sum + i;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('Assignment 5: Sum 1..10 = ' || v_sum);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 6: Explain why a particular literal value is used
--------------------------------------------------------------------------------
DECLARE
  v_retry_limit NUMBER := 3; -- maximum number of login attempts allowed
BEGIN
  DBMS_OUTPUT.PUT_LINE('Assignment 6: Retry limit = ' || v_retry_limit);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 7: Comment nested block behavior for clarity
--------------------------------------------------------------------------------
DECLARE
  v_message VARCHAR2(50) := 'Outer block message';
BEGIN
  DBMS_OUTPUT.PUT_LINE('Assignment 7: ' || v_message);

  -- Inner block overrides v_message for local use.
  DECLARE
    v_message VARCHAR2(50) := 'Inner block message';
  BEGIN
    DBMS_OUTPUT.PUT_LINE('Assignment 7 (inner): ' || v_message);
  END;

  DBMS_OUTPUT.PUT_LINE('Assignment 7 (outer again): ' || v_message);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 8: Document possible error conditions using comments
--------------------------------------------------------------------------------
DECLARE
  v_denominator NUMBER := 0;
  v_result      NUMBER;
BEGIN
  -- Potential error:
  --   If v_denominator is zero, division would fail.
  --   This example avoids division when value is zero.
  IF v_denominator = 0 THEN
    DBMS_OUTPUT.PUT_LINE('Assignment 8: Cannot divide by zero.');
  ELSE
    v_result := 100 / v_denominator;
    DBMS_OUTPUT.PUT_LINE('Assignment 8: Result = ' || v_result);
  END IF;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 9: Use comments to indicate units and meaning
--------------------------------------------------------------------------------
DECLARE
  v_distance_km NUMBER := 120; -- distance in kilometers
  v_time_hr     NUMBER := 2;   -- time in hours
  v_speed       NUMBER;
BEGIN
  v_speed := v_distance_km / v_time_hr; -- km per hour

  DBMS_OUTPUT.PUT_LINE('Assignment 9: Speed = ' || v_speed || ' km/hr');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 10: Combine header, block, and line comments in one example
--------------------------------------------------------------------------------
DECLARE
  -- v_order_amount: total amount of customer order before discount.
  v_order_amount NUMBER := 5000;
  v_final_amount NUMBER;
BEGIN
  /*
    Business Logic:
    - If order_amount >= 4000 then apply 10% discount.
    - Otherwise, no discount.
  */
  IF v_order_amount >= 4000 THEN
    v_final_amount := v_order_amount * 0.90; -- apply 10% discount
  ELSE
    v_final_amount := v_order_amount;
  END IF;

  DBMS_OUTPUT.PUT_LINE('Assignment 10: Final Amount = ' || v_final_amount);
END;
/
--------------------------------------------------------------------------------
