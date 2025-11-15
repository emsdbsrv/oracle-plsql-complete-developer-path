-- assignment_021_multicondition_selection_statements.sql
-- Session : 021_multicondition_selection_statements
-- Topic   : Practice - Multicondition Selection (CASE)
-- Purpose : 10 exercises using simple and searched CASE expressions.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Assignment 1: Map day number (1-7) to weekday name
--------------------------------------------------------------------------------
DECLARE
  v_day_num NUMBER := 3;
  v_day_name VARCHAR2(10);
BEGIN
  v_day_name := CASE v_day_num
                  WHEN 1 THEN 'Monday'
                  WHEN 2 THEN 'Tuesday'
                  WHEN 3 THEN 'Wednesday'
                  WHEN 4 THEN 'Thursday'
                  WHEN 5 THEN 'Friday'
                  WHEN 6 THEN 'Saturday'
                  WHEN 7 THEN 'Sunday'
                  ELSE 'Invalid'
                END;

  DBMS_OUTPUT.PUT_LINE('A1: Day ' || v_day_num || ' = ' || v_day_name);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 2: Classify order amount using searched CASE
--------------------------------------------------------------------------------
DECLARE
  v_amount NUMBER := 5200;
  v_category VARCHAR2(20);
BEGIN
  v_category := CASE
                  WHEN v_amount >= 5000 THEN 'Platinum'
                  WHEN v_amount >= 3000 THEN 'Gold'
                  WHEN v_amount >= 1000 THEN 'Silver'
                  ELSE 'Regular'
                END;

  DBMS_OUTPUT.PUT_LINE('A2: Amount ' || v_amount || ' -> ' || v_category);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 3: Convert month number to quarter
--------------------------------------------------------------------------------
DECLARE
  v_month NUMBER := 11;
  v_quarter VARCHAR2(5);
BEGIN
  v_quarter := CASE
                 WHEN v_month BETWEEN 1 AND 3  THEN 'Q1'
                 WHEN v_month BETWEEN 4 AND 6  THEN 'Q2'
                 WHEN v_month BETWEEN 7 AND 9  THEN 'Q3'
                 WHEN v_month BETWEEN 10 AND 12 THEN 'Q4'
                 ELSE 'NA'
               END;

  DBMS_OUTPUT.PUT_LINE('A3: Month ' || v_month || ' falls in ' || v_quarter);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 4: Use CASE to map status code to human-readable message
--------------------------------------------------------------------------------
DECLARE
  v_status_code VARCHAR2(1) := 'P';
  v_status_text VARCHAR2(30);
BEGIN
  v_status_text := CASE v_status_code
                     WHEN 'N' THEN 'New'
                     WHEN 'P' THEN 'Processing'
                     WHEN 'C' THEN 'Completed'
                     WHEN 'X' THEN 'Cancelled'
                     ELSE 'Unknown'
                   END;

  DBMS_OUTPUT.PUT_LINE('A4: Status code ' || v_status_code ||
                       ' -> ' || v_status_text);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 5: CASE to decide travel mode based on distance
--------------------------------------------------------------------------------
DECLARE
  v_distance_km NUMBER := 650;
  v_mode        VARCHAR2(20);
BEGIN
  v_mode := CASE
              WHEN v_distance_km <= 5   THEN 'Walk'
              WHEN v_distance_km <= 30  THEN 'Car/Taxi'
              WHEN v_distance_km <= 300 THEN 'Train/Bus'
              ELSE 'Flight'
            END;

  DBMS_OUTPUT.PUT_LINE('A5: Distance ' || v_distance_km ||
                       ' km -> Mode = ' || v_mode);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 6: Map performance rating (1-5) to text
--------------------------------------------------------------------------------
DECLARE
  v_rating NUMBER := 4;
  v_text   VARCHAR2(20);
BEGIN
  v_text := CASE v_rating
              WHEN 5 THEN 'Outstanding'
              WHEN 4 THEN 'Exceeds Expectation'
              WHEN 3 THEN 'Meets Expectation'
              WHEN 2 THEN 'Needs Improvement'
              WHEN 1 THEN 'Unsatisfactory'
              ELSE 'Invalid'
            END;

  DBMS_OUTPUT.PUT_LINE('A6: Rating ' || v_rating || ' -> ' || v_text);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 7: CASE inside arithmetic expression
--------------------------------------------------------------------------------
DECLARE
  v_country VARCHAR2(2) := 'IN';
  v_base_price NUMBER := 1000;
  v_tax_rate   NUMBER;
  v_final_price NUMBER;
BEGIN
  v_tax_rate := CASE v_country
                  WHEN 'IN' THEN 0.18
                  WHEN 'US' THEN 0.07
                  WHEN 'UK' THEN 0.20
                  ELSE 0.10
                END;

  v_final_price := v_base_price + (v_base_price * v_tax_rate);

  DBMS_OUTPUT.PUT_LINE('A7: Country ' || v_country ||
                       ', Tax rate=' || v_tax_rate ||
                       ', Final price=' || v_final_price);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 8: Searched CASE with overlapping conditions (order matters)
--------------------------------------------------------------------------------
DECLARE
  v_temp_c NUMBER := 32;
  v_label  VARCHAR2(20);
BEGIN
  v_label := CASE
               WHEN v_temp_c <= 0 THEN 'Freezing'
               WHEN v_temp_c <= 15 THEN 'Cold'
               WHEN v_temp_c <= 30 THEN 'Pleasant'
               WHEN v_temp_c > 30 THEN 'Hot'
             END;

  DBMS_OUTPUT.PUT_LINE('A8: Temperature ' || v_temp_c || 'C -> ' || v_label);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 9: Map hour of day to greeting
--------------------------------------------------------------------------------
DECLARE
  v_hour NUMBER := 21;
  v_greeting VARCHAR2(20);
BEGIN
  v_greeting := CASE
                  WHEN v_hour BETWEEN 5  AND 11 THEN 'Good Morning'
                  WHEN v_hour BETWEEN 12 AND 16 THEN 'Good Afternoon'
                  WHEN v_hour BETWEEN 17 AND 21 THEN 'Good Evening'
                  ELSE 'Good Night'
                END;

  DBMS_OUTPUT.PUT_LINE('A9: Hour ' || v_hour || ' -> ' || v_greeting);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 10: CASE to compute bonus percentage
--------------------------------------------------------------------------------
DECLARE
  v_years_service NUMBER := 9;
  v_bonus_pct     NUMBER;
BEGIN
  v_bonus_pct := CASE
                   WHEN v_years_service >= 10 THEN 0.20
                   WHEN v_years_service >= 5  THEN 0.15
                   WHEN v_years_service >= 2  THEN 0.10
                   ELSE 0.05
                 END;

  DBMS_OUTPUT.PUT_LINE('A10: Years of service = ' || v_years_service);
  DBMS_OUTPUT.PUT_LINE('A10: Bonus percentage = ' || (v_bonus_pct * 100) || '%');
END;
/
--------------------------------------------------------------------------------
