-- demo_practical_workshop_1.sql
-- Session : 019_practical_workshop_1
-- Topic   : Practical Workshop 1 - Bringing Concepts Together
-- Purpose : Combine variables, constants, scope, data types, and conversions
--           into small end-to-end PL/SQL mini-scenarios.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Demo 1: Simple Order Pricing Workflow
--------------------------------------------------------------------------------
DECLARE
  c_tax_rate   CONSTANT NUMBER := 0.18;
  v_order_id   NUMBER := 1001;
  v_item_price NUMBER := 2500;
  v_quantity   NUMBER := 3;
  v_subtotal   NUMBER;
  v_tax_amount NUMBER;
  v_total      NUMBER;
BEGIN
  v_subtotal   := v_item_price * v_quantity;
  v_tax_amount := v_subtotal * c_tax_rate;
  v_total      := v_subtotal + v_tax_amount;

  DBMS_OUTPUT.PUT_LINE('Demo 1: Order ' || v_order_id);
  DBMS_OUTPUT.PUT_LINE('  Subtotal   = ' || v_subtotal);
  DBMS_OUTPUT.PUT_LINE('  Tax Amount = ' || v_tax_amount);
  DBMS_OUTPUT.PUT_LINE('  Total      = ' || v_total);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 2: Attendance Summary Using Variables and IF Logic
--------------------------------------------------------------------------------
DECLARE
  v_total_students NUMBER := 40;
  v_present        NUMBER := 36;
  v_absent         NUMBER;
  v_attendance_pct NUMBER;
BEGIN
  v_absent         := v_total_students - v_present;
  v_attendance_pct := (v_present / v_total_students) * 100;

  DBMS_OUTPUT.PUT_LINE('Demo 2: Attendance Summary');
  DBMS_OUTPUT.PUT_LINE('  Total   = ' || v_total_students);
  DBMS_OUTPUT.PUT_LINE('  Present = ' || v_present);
  DBMS_OUTPUT.PUT_LINE('  Absent  = ' || v_absent);
  DBMS_OUTPUT.PUT_LINE('  Percent = ' ||
                       TO_CHAR(v_attendance_pct, '999.99') || '%');

  IF v_attendance_pct < 75 THEN
    DBMS_OUTPUT.PUT_LINE('  Status  = Below required threshold.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('  Status  = Meets requirement.');
  END IF;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 3: Mini Salary Revision Workflow with RECORD Type
--------------------------------------------------------------------------------
DECLARE
  TYPE t_emp IS RECORD
  (
    emp_id   NUMBER,
    emp_name VARCHAR2(50),
    salary   NUMBER
  );

  r_emp t_emp;
  v_increment_rate NUMBER := 0.08;
BEGIN
  r_emp.emp_id   := 1;
  r_emp.emp_name := 'Workshop Employee';
  r_emp.salary   := 60000;

  DBMS_OUTPUT.PUT_LINE('Demo 3: Before increment salary = ' || r_emp.salary);

  r_emp.salary := r_emp.salary * (1 + v_increment_rate);

  DBMS_OUTPUT.PUT_LINE('Demo 3: After 8% increment salary = ' || r_emp.salary);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 4: Basic Error Handling and Debugging in One Flow
--------------------------------------------------------------------------------
DECLARE
  v_dividend NUMBER := 100;
  v_divisor  NUMBER := 0;
  v_result   NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 4: Starting division workflow');

  BEGIN
    v_result := v_dividend / v_divisor;
    DBMS_OUTPUT.PUT_LINE('Demo 4: Result = ' || v_result);
  EXCEPTION
    WHEN ZERO_DIVIDE THEN
      DBMS_OUTPUT.PUT_LINE('Demo 4: Division by zero detected, using fallback divisor = 1.');
      v_divisor := 1;
      v_result  := v_dividend / v_divisor;
      DBMS_OUTPUT.PUT_LINE('Demo 4: New result = ' || v_result);
  END;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 5: End-to-End Enrollment Scenario Using Multiple Concepts
--------------------------------------------------------------------------------
DECLARE
  c_min_age   CONSTANT NUMBER := 18;
  c_max_seats CONSTANT NUMBER := 30;

  v_student_name VARCHAR2(50) := 'Sample Learner';
  v_age          NUMBER       := 19;
  v_requested_seats NUMBER    := 2;
  v_current_enrolled NUMBER   := 25;
  v_enrollment_allowed BOOLEAN;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 5: Enrollment scenario for ' || v_student_name);

  IF v_age < c_min_age THEN
    DBMS_OUTPUT.PUT_LINE('  Rejected: Age below minimum requirement.');
    v_enrollment_allowed := FALSE;
  ELSIF v_current_enrolled + v_requested_seats > c_max_seats THEN
    DBMS_OUTPUT.PUT_LINE('  Rejected: Not enough seats available.');
    v_enrollment_allowed := FALSE;
  ELSE
    v_current_enrolled   := v_current_enrolled + v_requested_seats;
    v_enrollment_allowed := TRUE;
    DBMS_OUTPUT.PUT_LINE('  Accepted: Seats booked successfully.');
  END IF;

  IF v_enrollment_allowed THEN
    DBMS_OUTPUT.PUT_LINE('  New enrolled count = ' || v_current_enrolled);
  END IF;
END;
/
--------------------------------------------------------------------------------
