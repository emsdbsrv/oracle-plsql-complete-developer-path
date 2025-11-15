-- assignment_practical_workshop_1.sql
-- Session : 019_practical_workshop_1
-- Topic   : Practice - Mini Scenarios Combining Multiple Concepts

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Assignment 1: Simple loan EMI-style calculation (approximate)
--------------------------------------------------------------------------------
DECLARE
  v_principal NUMBER := 500000;
  v_rate      NUMBER := 8.0;   -- annual percent
  v_years     NUMBER := 5;
  v_simple_interest NUMBER;
BEGIN
  v_simple_interest := (v_principal * v_rate * v_years) / 100;

  DBMS_OUTPUT.PUT_LINE('A1: Principal        = ' || v_principal);
  DBMS_OUTPUT.PUT_LINE('A1: Total Interest   = ' || v_simple_interest);
  DBMS_OUTPUT.PUT_LINE('A1: Amount Payable   = ' || (v_principal + v_simple_interest));
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 2: Student result with grade decision
--------------------------------------------------------------------------------
DECLARE
  v_student_name VARCHAR2(50) := 'Avi';
  v_marks        NUMBER       := 72;
  v_grade        VARCHAR2(2);
BEGIN
  IF v_marks >= 80 THEN
    v_grade := 'A';
  ELSIF v_marks >= 60 THEN
    v_grade := 'B';
  ELSIF v_marks >= 50 THEN
    v_grade := 'C';
  ELSE
    v_grade := 'D';
  END IF;

  DBMS_OUTPUT.PUT_LINE('A2: ' || v_student_name || ' scored ' || v_marks ||
                       ' and grade is ' || v_grade);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 3: Inventory adjustment scenario
--------------------------------------------------------------------------------
DECLARE
  v_item_name      VARCHAR2(50) := 'Keyboard';
  v_current_stock  NUMBER := 20;
  v_new_shipment   NUMBER := 15;
  v_sold_units     NUMBER := 5;
BEGIN
  v_current_stock := v_current_stock + v_new_shipment - v_sold_units;

  DBMS_OUTPUT.PUT_LINE('A3: Item        = ' || v_item_name);
  DBMS_OUTPUT.PUT_LINE('A3: Final stock = ' || v_current_stock);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 4: Travel distance and time calculation
--------------------------------------------------------------------------------
DECLARE
  v_distance_km NUMBER := 350;
  v_speed_kmph  NUMBER := 70;
  v_time_hours  NUMBER;
BEGIN
  v_time_hours := v_distance_km / v_speed_kmph;

  DBMS_OUTPUT.PUT_LINE('A4: Travel time = ' ||
                       TO_CHAR(v_time_hours, '999.99') || ' hours');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 5: Email notification scenario (simulated with DBMS_OUTPUT)
--------------------------------------------------------------------------------
DECLARE
  v_to_email   VARCHAR2(100) := 'user@example.com';
  v_subject    VARCHAR2(100) := 'Welcome to PL/SQL Course';
  v_body       VARCHAR2(200) := 'Your registration is successful.';
BEGIN
  DBMS_OUTPUT.PUT_LINE('A5: Sending email...');
  DBMS_OUTPUT.PUT_LINE('  To      : ' || v_to_email);
  DBMS_OUTPUT.PUT_LINE('  Subject : ' || v_subject);
  DBMS_OUTPUT.PUT_LINE('  Body    : ' || v_body);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 6: Basic timesheet calculation
--------------------------------------------------------------------------------
DECLARE
  v_hours_mon NUMBER := 8;
  v_hours_tue NUMBER := 7.5;
  v_hours_wed NUMBER := 8;
  v_hours_thu NUMBER := 6.5;
  v_hours_fri NUMBER := 8;
  v_total     NUMBER;
BEGIN
  v_total := v_hours_mon + v_hours_tue + v_hours_wed +
             v_hours_thu + v_hours_fri;

  DBMS_OUTPUT.PUT_LINE('A6: Total hours worked this week = ' || v_total);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 7: Simple expense tracker
--------------------------------------------------------------------------------
DECLARE
  v_rent     NUMBER := 15000;
  v_food     NUMBER := 8000;
  v_travel   NUMBER := 3000;
  v_misc     NUMBER := 2000;
  v_total    NUMBER;
BEGIN
  v_total := v_rent + v_food + v_travel + v_misc;

  DBMS_OUTPUT.PUT_LINE('A7: Monthly expenses = ' || v_total);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 8: Data conversion plus reporting in one scenario
--------------------------------------------------------------------------------
DECLARE
  v_amount_text VARCHAR2(20) := '9876.50';
  v_amount      NUMBER;
  v_report_date DATE := SYSDATE;
BEGIN
  v_amount := TO_NUMBER(v_amount_text);

  DBMS_OUTPUT.PUT_LINE('A8: Amount = ' || TO_CHAR(v_amount, '9,999.99') ||
                       ' on ' || TO_CHAR(v_report_date, 'DD-MON-YYYY'));
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 9: Mini eligibility calculator
--------------------------------------------------------------------------------
DECLARE
  v_age        NUMBER := 21;
  v_income     NUMBER := 450000;
  v_is_eligible BOOLEAN;
BEGIN
  IF v_age >= 18 AND v_income >= 300000 THEN
    v_is_eligible := TRUE;
  ELSE
    v_is_eligible := FALSE;
  END IF;

  IF v_is_eligible THEN
    DBMS_OUTPUT.PUT_LINE('A9: Eligible for the scheme.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('A9: Not eligible for the scheme.');
  END IF;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 10: Combined scenario using constants, conversion and IF logic
--------------------------------------------------------------------------------
DECLARE
  c_min_balance CONSTANT NUMBER := 1000;
  v_account_no  VARCHAR2(20) := 'ACCT123';
  v_balance_txt VARCHAR2(20) := '850.75';
  v_balance     NUMBER;
BEGIN
  v_balance := TO_NUMBER(v_balance_txt);

  DBMS_OUTPUT.PUT_LINE('A10: Account ' || v_account_no ||
                       ' has balance ' || v_balance);

  IF v_balance < c_min_balance THEN
    DBMS_OUTPUT.PUT_LINE('A10: Alert - Balance below minimum threshold.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('A10: Balance is healthy.');
  END IF;
END;
/
--------------------------------------------------------------------------------
