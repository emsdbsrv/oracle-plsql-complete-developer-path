-- assignment_038_input_parameter_handling.sql
-- Session 038: Assignments - Input Parameter Handling
-- Objective:
--   Practice calling procedures with IN parameters and observe how changing
--   inputs changes the behavior and output for realistic EMS scenarios.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- A1: Call demo38_show_emp_name for all seeded employees.
-- Goal:
--   Understand that the same procedure can be reused for multiple inputs.
--------------------------------------------------------------------------------
DECLARE
  CURSOR c_emp IS
    SELECT emp_no
      FROM ems_employees
     ORDER BY emp_no;
BEGIN
  FOR r IN c_emp LOOP
    demo38_show_emp_name(r.emp_no);
  END LOOP;
END;
/
--------------------------------------------------------------------------------
-- A2: Use demo38_list_by_dept_and_status for Finance ACTIVE employees.
--------------------------------------------------------------------------------
BEGIN
  demo38_list_by_dept_and_status('FIN', 'ACTIVE');
END;
/
--------------------------------------------------------------------------------
-- A3: Negative salary test on demo38_update_salary (should raise -20001).
--------------------------------------------------------------------------------
BEGIN
  BEGIN
    demo38_update_salary('E1001', -500);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        'A3: Caught error while setting negative salary: ' || SQLERRM
      );
  END;
END;
/
--------------------------------------------------------------------------------
-- A4: Valid salary update using demo38_update_salary.
--------------------------------------------------------------------------------
BEGIN
  demo38_update_salary('E1001', 65000);
END;
/
--------------------------------------------------------------------------------
-- A5: Call demo38_update_salary with non-existing emp_no (should raise -20002).
--------------------------------------------------------------------------------
BEGIN
  BEGIN
    demo38_update_salary('E9999', 50000);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        'A5: Caught error for non-existing employee: ' || SQLERRM
      );
  END;
END;
/
--------------------------------------------------------------------------------
-- A6: Apply FIN_HIGH promotion rule using demo38_apply_promo_rule.
--------------------------------------------------------------------------------
BEGIN
  demo38_apply_promo_rule('FIN_HIGH');
END;
/
--------------------------------------------------------------------------------
-- A7: Call demo38_apply_promo_rule with an unknown rule code.
--------------------------------------------------------------------------------
BEGIN
  demo38_apply_promo_rule('UNKNOWN_RULE');
END;
/
--------------------------------------------------------------------------------
-- A8: Generate payroll for January of the current year.
--------------------------------------------------------------------------------
BEGIN
  demo38_generate_payroll_for_period(
    1,
    EXTRACT(YEAR FROM SYSDATE)
  );
END;
/
--------------------------------------------------------------------------------
-- A9: Call demo38_list_by_dept_and_status twice for IT:
--     one for ACTIVE, one for INACTIVE (even if none exist).
--------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('A9: ACTIVE IT employees');
  demo38_list_by_dept_and_status('IT', 'ACTIVE');

  DBMS_OUTPUT.PUT_LINE('A9: INACTIVE IT employees');
  demo38_list_by_dept_and_status('IT', 'INACTIVE');
END;
/
--------------------------------------------------------------------------------
-- A10: Combine multiple calls to simulate a small HR operation:
--      1) Update salary for E1003
--      2) Apply SENIOR_IT rule
--      3) Generate payroll for current month/year
--------------------------------------------------------------------------------
BEGIN
  demo38_update_salary('E1003', 52000);
  demo38_apply_promo_rule('SENIOR_IT');

  demo38_generate_payroll_for_period(
    EXTRACT(MONTH FROM SYSDATE),
    EXTRACT(YEAR  FROM SYSDATE)
  );
END;
/
--------------------------------------------------------------------------------
-- End of assignment_038_input_parameter_handling.sql
--------------------------------------------------------------------------------
