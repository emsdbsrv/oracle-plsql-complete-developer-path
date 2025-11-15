-- assignment_041_default_parameter_values.sql
-- Session 041: Assignments - Default Parameter Values

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- A1: Call demo41_calculate_bonus using the default bonus percent.
--------------------------------------------------------------------------------
DECLARE
  v_bonus NUMBER;
BEGIN
  demo41_calculate_bonus(50000, p_bonus_out => v_bonus);
  DBMS_OUTPUT.PUT_LINE(
    'A1: Default bonus for 50000 = ' || v_bonus
  );
END;
/
--------------------------------------------------------------------------------
-- A2: Call demo41_calculate_bonus with a custom 25 percent bonus.
--------------------------------------------------------------------------------
DECLARE
  v_bonus NUMBER;
BEGIN
  demo41_calculate_bonus(50000, 25, v_bonus);
  DBMS_OUTPUT.PUT_LINE(
    'A2: 25 percent bonus for 50000 = ' || v_bonus
  );
END;
/
--------------------------------------------------------------------------------
-- A3: Use demo41_list_dept_emps only with the default department.
--------------------------------------------------------------------------------
BEGIN
  demo41_list_dept_emps;
END;
/
--------------------------------------------------------------------------------
-- A4: Loop through all departments and call demo41_list_dept_emps explicitly.
--------------------------------------------------------------------------------
BEGIN
  FOR r IN (SELECT dept_code FROM ems_departments) LOOP
    demo41_list_dept_emps(r.dept_code);
  END LOOP;
END;
/
--------------------------------------------------------------------------------
-- A5: Run demo41_run_payroll with all defaults.
--------------------------------------------------------------------------------
BEGIN
  demo41_run_payroll;
END;
/
--------------------------------------------------------------------------------
-- A6: Run demo41_run_payroll for a specific historical period.
--------------------------------------------------------------------------------
BEGIN
  demo41_run_payroll(12, 2024, 12);
END;
/
--------------------------------------------------------------------------------
-- A7: Use demo41_log_action with default module name.
--------------------------------------------------------------------------------
BEGIN
  demo41_log_action(p_action_desc => 'A7 default module test');
END;
/
--------------------------------------------------------------------------------
-- A8: Use demo41_log_action with explicit module and description.
--------------------------------------------------------------------------------
BEGIN
  demo41_log_action('A41', 'A8 explicit module test');
END;
/
--------------------------------------------------------------------------------
-- A9: Use demo41_report_payroll with default minimum net salary.
--------------------------------------------------------------------------------
BEGIN
  demo41_report_payroll;
END;
/
--------------------------------------------------------------------------------
-- A10: Use demo41_report_payroll with a high minimum net salary to filter rows.
--------------------------------------------------------------------------------
BEGIN
  demo41_report_payroll(p_min_net => 80000);
END;
/
--------------------------------------------------------------------------------
-- End of assignment_041_default_parameter_values.sql
--------------------------------------------------------------------------------
