-- assignment_027_practical_workshop_2.sql
-- Session : 027_practical_workshop_2
-- Topic   : Practice - Combined Control Structure Scenarios
-- Purpose : 10 hands-on tasks mixing IF, CASE, loops, and flags.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Assignment 1: Generate monthly EMI-like schedule for 6 months
--------------------------------------------------------------------------------
DECLARE
  v_month     NUMBER := 1;
  v_tenor     NUMBER := 6;
  v_emi       NUMBER := 5000;
  v_balance   NUMBER := 30000;
BEGIN
  WHILE v_month <= v_tenor LOOP
    v_balance := v_balance - v_emi;
    DBMS_OUTPUT.PUT_LINE('A1: Month ' || v_month ||
                         ', EMI=' || v_emi ||
                         ', Balance=' || v_balance);
    v_month := v_month + 1;
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 2: Classification of customers by annual spend
--------------------------------------------------------------------------------
DECLARE
  TYPE t_spend_tab IS TABLE OF NUMBER;
  v_spends t_spend_tab := t_spend_tab(8000, 25000, 52000);
  v_tier   VARCHAR2(15);
BEGIN
  FOR i IN 1 .. v_spends.COUNT LOOP
    v_tier := CASE
                WHEN v_spends(i) >= 50000 THEN 'Platinum'
                WHEN v_spends(i) >= 20000 THEN 'Gold'
                WHEN v_spends(i) >= 10000 THEN 'Silver'
                ELSE 'Bronze'
              END;

    DBMS_OUTPUT.PUT_LINE('A2: Customer ' || i ||
                         ' spend=' || v_spends(i) ||
                         ' -> ' || v_tier);
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 3: Daily temperature report with labels
--------------------------------------------------------------------------------
DECLARE
  TYPE t_temp_tab IS TABLE OF NUMBER;
  v_temps t_temp_tab := t_temp_tab(28, 34, 22, 31, 29);
  v_label VARCHAR2(20);
BEGIN
  FOR i IN 1 .. v_temps.COUNT LOOP
    v_label := CASE
                 WHEN v_temps(i) <= 20 THEN 'Cold'
                 WHEN v_temps(i) <= 30 THEN 'Pleasant'
                 ELSE 'Hot'
               END;

    DBMS_OUTPUT.PUT_LINE('A3: Day ' || i ||
                         ', Temp=' || v_temps(i) ||
                         'C, Label=' || v_label);
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 4: Nested loops to compute sum of all products i*j (1..3)
--------------------------------------------------------------------------------
DECLARE
  v_sum NUMBER := 0;
BEGIN
  FOR v_i IN 1 .. 3 LOOP
    FOR v_j IN 1 .. 3 LOOP
      v_sum := v_sum + (v_i * v_j);
    END LOOP;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('A4: Sum of all i*j for i,j in 1..3 = ' || v_sum);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 5: Simple inventory reorder logic using IF and loops
--------------------------------------------------------------------------------
DECLARE
  TYPE t_stock_tab IS TABLE OF NUMBER;
  v_stock  t_stock_tab := t_stock_tab(5, 15, 2, 40);
  v_min    NUMBER := 10;
BEGIN
  FOR i IN 1 .. v_stock.COUNT LOOP
    IF v_stock(i) < v_min THEN
      DBMS_OUTPUT.PUT_LINE('A5: Item ' || i || ' needs reorder. Stock=' || v_stock(i));
    ELSE
      DBMS_OUTPUT.PUT_LINE('A5: Item ' || i || ' stock OK. Stock=' || v_stock(i));
    END IF;
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 6: Use LOOP to search for first failing test case
--------------------------------------------------------------------------------
DECLARE
  TYPE t_result_tab IS TABLE OF VARCHAR2(5);
  v_results t_result_tab := t_result_tab('PASS', 'PASS', 'FAIL', 'PASS');
  v_index NUMBER := 1;
  v_found BOOLEAN := FALSE;
BEGIN
  LOOP
    EXIT WHEN v_index > v_results.COUNT;

    IF v_results(v_index) = 'FAIL' THEN
      v_found := TRUE;
      EXIT;
    END IF;

    v_index := v_index + 1;
  END LOOP;

  IF v_found THEN
    DBMS_OUTPUT.PUT_LINE('A6: First FAIL at test ' || v_index);
  ELSE
    DBMS_OUTPUT.PUT_LINE('A6: All tests PASSED.');
  END IF;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 7: Compute overtime hours from weekly work log
--------------------------------------------------------------------------------
DECLARE
  TYPE t_hours_tab IS TABLE OF NUMBER;
  v_hours t_hours_tab := t_hours_tab(8, 9, 10, 7, 6);
  v_total NUMBER := 0;
  v_overtime NUMBER;
BEGIN
  FOR i IN 1 .. v_hours.COUNT LOOP
    v_total := v_total + v_hours(i);
  END LOOP;

  v_overtime := GREATEST(v_total - 40, 0);

  DBMS_OUTPUT.PUT_LINE('A7: Total hours = ' || v_total);
  DBMS_OUTPUT.PUT_LINE('A7: Overtime    = ' || v_overtime);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 8: Determine loan eligibility with combined conditions
--------------------------------------------------------------------------------
DECLARE
  v_age    NUMBER := 30;
  v_salary NUMBER := 60000;
  v_score  NUMBER := 750; -- credit score
BEGIN
  IF v_age BETWEEN 21 AND 60
     AND v_salary >= 40000
     AND v_score >= 700 THEN
    DBMS_OUTPUT.PUT_LINE('A8: Loan Approved.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('A8: Loan Rejected.');
  END IF;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 9: Multi-branch CASE to categorize bank balance
--------------------------------------------------------------------------------
DECLARE
  v_balance NUMBER := 8500;
  v_category VARCHAR2(20);
BEGIN
  v_category := CASE
                  WHEN v_balance < 0 THEN 'Overdrawn'
                  WHEN v_balance < 1000 THEN 'Low'
                  WHEN v_balance < 10000 THEN 'Medium'
                  ELSE 'High'
                END;

  DBMS_OUTPUT.PUT_LINE('A9: Balance=' || v_balance ||
                       ' -> Category=' || v_category);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 10: Combined scenario - ticket booking and seat allocation
--------------------------------------------------------------------------------
DECLARE
  v_required_seats NUMBER := 3;
  v_available_seats NUMBER := 5;
  v_allocated BOOLEAN := FALSE;
  v_seat_no NUMBER := 0;
BEGIN
  IF v_required_seats <= v_available_seats THEN
    DBMS_OUTPUT.PUT_LINE('A10: Booking confirmed. Allocating seats:');
    FOR i IN 1 .. v_required_seats LOOP
      v_seat_no := v_seat_no + 1;
      DBMS_OUTPUT.PUT_LINE('      Seat ' || v_seat_no);
    END LOOP;
    v_allocated := TRUE;
  ELSE
    DBMS_OUTPUT.PUT_LINE('A10: Not enough seats available.');
  END IF;

  IF v_allocated THEN
    DBMS_OUTPUT.PUT_LINE('A10: Allocation completed successfully.');
  END IF;
END;
/
--------------------------------------------------------------------------------
