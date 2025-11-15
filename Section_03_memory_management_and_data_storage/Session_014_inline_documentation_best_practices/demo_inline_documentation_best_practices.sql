-- demo_inline_documentation_best_practices.sql
-- Session : 014_inline_documentation_best_practices
-- Topic   : Inline Documentation and Commenting in PL/SQL
-- Purpose : Demonstrate how to use comments to explain intent, assumptions,
--           parameters, and logic steps without cluttering code.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Demo 1: Header Comments Explaining Module Purpose
--------------------------------------------------------------------------------
DECLARE
  -- v_month_sales:
  --   Represents total sales in the current month for a given store.
  v_month_sales NUMBER := 125000;

  -- v_target_sales:
  --   Goal set by management for this month.
  v_target_sales NUMBER := 100000;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 1: Using clear header comments for variables.');

  IF v_month_sales >= v_target_sales THEN
    DBMS_OUTPUT.PUT_LINE('  Target achieved.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('  Target not achieved.');
  END IF;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 2: Line Comments for Critical Logic Steps
--------------------------------------------------------------------------------
DECLARE
  v_basic_salary NUMBER := 60000;
  v_bonus        NUMBER;
  v_total_pay    NUMBER;
BEGIN
  -- Step 1: Calculate bonus as 20 percent of basic salary.
  v_bonus := v_basic_salary * 0.20;

  -- Step 2: Add bonus to basic salary to get total pay.
  v_total_pay := v_basic_salary + v_bonus;

  DBMS_OUTPUT.PUT_LINE('Demo 2: Total Pay = ' || v_total_pay);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 3: Block Comments to Document Business Rules
--------------------------------------------------------------------------------
DECLARE
  v_age NUMBER := 17;
BEGIN
  /*
    Business Rule:
    - A person is eligible for this program only if age is 18 or above.
    - This block checks the age and prints eligibility status.
  */
  IF v_age >= 18 THEN
    DBMS_OUTPUT.PUT_LINE('Demo 3: Eligible for program.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Demo 3: Not eligible for program (age < 18).');
  END IF;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 4: Commenting Assumptions and Edge Cases
--------------------------------------------------------------------------------
DECLARE
  v_items_count NUMBER := 0;
  v_discount    NUMBER;
BEGIN
  -- Assumption:
  --   If no items are purchased (v_items_count = 0), discount is zero.
  --   If items are more than 5, apply 10% discount.
  IF v_items_count = 0 THEN
    v_discount := 0;
  ELSIF v_items_count > 5 THEN
    v_discount := 0.10;
  ELSE
    v_discount := 0.05;
  END IF;

  DBMS_OUTPUT.PUT_LINE('Demo 4: Calculated discount rate = ' || v_discount);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 5: Self-Documenting Code with Good Names and Minimal Comments
--------------------------------------------------------------------------------
DECLARE
  v_total_students NUMBER := 40;
  v_present_count  NUMBER := 35;
  v_attendance_pct NUMBER;
BEGIN
  -- Compute attendance percentage using present_count / total_students.
  v_attendance_pct := (v_present_count / v_total_students) * 100;

  DBMS_OUTPUT.PUT_LINE('Demo 5: Attendance Percentage = ' ||
                       TO_CHAR(v_attendance_pct, '999.99') || '%');
END;
/
--------------------------------------------------------------------------------
