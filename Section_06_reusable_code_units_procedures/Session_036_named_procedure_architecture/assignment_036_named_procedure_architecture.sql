-- assignment_036_named_procedure_architecture.sql
-- Session 036: Assignments - Named Procedure Architecture
-- 10 tasks using EMS procedures (create/call/extend).

SET SERVEROUTPUT ON;

-------------------------------------------------------------------------------
-- A1: Call prc_ems_write_audit with a custom message
-------------------------------------------------------------------------------
BEGIN
  prc_ems_write_audit('A36', 'Assignment A1 custom audit message');
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('A1: Audit written.');
END;
/
-------------------------------------------------------------------------------
-- A2: Use prc_ems_hire_employee to add a Finance employee
-------------------------------------------------------------------------------
BEGIN
  prc_ems_hire_employee('E2002', 'Finance', 'User', 'FIN', 80000);
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('A2: Finance employee hired.');
END;
/
-------------------------------------------------------------------------------
-- A3: Adjust Finance salaries by 2.5%
-------------------------------------------------------------------------------
BEGIN
  prc_ems_adjust_dept_salary('FIN', 2.5);
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('A3: Finance salaries adjusted.');
END;
/
-------------------------------------------------------------------------------
-- A4: Generate payroll for employee E1003
-------------------------------------------------------------------------------
BEGIN
  prc_ems_generate_payroll('E1003');
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('A4: Payroll generated for E1003.');
END;
/
-------------------------------------------------------------------------------
-- A5: Create a wrapper procedure a36_run_hr_cycle that calls audit + adjust
-------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE a36_run_hr_cycle
IS
BEGIN
  prc_ems_write_audit('A36', 'HR cycle started');
  prc_ems_adjust_dept_salary('HR', 4);
  prc_ems_write_audit('A36', 'HR cycle completed');
END a36_run_hr_cycle;
/
BEGIN
  a36_run_hr_cycle;
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('A5: HR cycle executed.');
END;
/
-------------------------------------------------------------------------------
-- A6: Create procedure a36_mark_inactive that sets status to INACTIVE by emp_no
-------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE a36_mark_inactive (
  p_emp_no IN ems_employees.emp_no%TYPE
)
IS
BEGIN
  UPDATE ems_employees
     SET status = 'INACTIVE'
   WHERE emp_no = p_emp_no;

  prc_ems_write_audit('A36', 'Employee ' || p_emp_no || ' marked INACTIVE');
END a36_mark_inactive;
/
BEGIN
  a36_mark_inactive('E1001');
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('A6: Employee E1001 marked INACTIVE.');
END;
/
-------------------------------------------------------------------------------
-- A7: Write a controller that hires one IT employee and generates payroll
-------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE a36_hire_and_pay_it
IS
BEGIN
  prc_ems_hire_employee('E3001', 'Batch', 'ITUser', 'IT', 62000);
  prc_ems_generate_payroll('E3001');
  prc_ems_write_audit('A36', 'IT hire and pay workflow completed for E3001');
END a36_hire_and_pay_it;
/
BEGIN
  a36_hire_and_pay_it;
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('A7: a36_hire_and_pay_it executed.');
END;
/
-------------------------------------------------------------------------------
-- A8: Procedure to log total headcount to audit
-------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE a36_log_headcount
IS
  v_cnt NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_cnt FROM ems_employees;
  prc_ems_write_audit('A36', 'Current headcount = ' || v_cnt);
  DBMS_OUTPUT.PUT_LINE('A8: Headcount logged: ' || v_cnt);
END a36_log_headcount;
/
BEGIN
  a36_log_headcount;
  COMMIT;
END;
/
-------------------------------------------------------------------------------
-- A9: Create procedure a36_clear_payroll(year) to delete runs for a given year
-------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE a36_clear_payroll (
  p_year IN NUMBER
)
IS
  v_rows NUMBER;
BEGIN
  DELETE FROM ems_payroll_runs WHERE run_year = p_year;
  v_rows := SQL%ROWCOUNT;
  prc_ems_write_audit('A36', 'Cleared ' || v_rows ||
                               ' payroll rows for year ' || p_year);
END a36_clear_payroll;
/
BEGIN
  a36_clear_payroll(EXTRACT(YEAR FROM SYSDATE));
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('A9: Cleared current-year payroll (if any).');
END;
/
-------------------------------------------------------------------------------
-- A10: Use prc_ems_daily_batch created in demo as a scheduled-style call
-------------------------------------------------------------------------------
BEGIN
  prc_ems_daily_batch;
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('A10: prc_ems_daily_batch executed from assignment.');
END;
/
-------------------------------------------------------------------------------
-- End of assignment_036_named_procedure_architecture.sql
-------------------------------------------------------------------------------
