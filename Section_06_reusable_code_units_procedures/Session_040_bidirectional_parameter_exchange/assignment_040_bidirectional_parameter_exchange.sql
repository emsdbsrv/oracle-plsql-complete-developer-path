-- assignment_040_bidirectional_parameter_exchange.sql
-- Session 040: Assignments - IN OUT Parameters

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- A1: Use demo40_increment_counter inside a loop of 5 iterations.
--------------------------------------------------------------------------------
DECLARE
  v_cnt NUMBER := 0;
BEGIN
  FOR i IN 1..5 LOOP
    demo40_increment_counter(v_cnt);
  END LOOP;

  DBMS_OUTPUT.PUT_LINE(
    'A1: Counter after 5 increments = ' || v_cnt
  );
END;
/
--------------------------------------------------------------------------------
-- A2: Use demo40_adjust_salary for multiple adjustments.
--------------------------------------------------------------------------------
DECLARE
  v_sal ems_employees.salary%TYPE := 30000;
BEGIN
  demo40_adjust_salary(v_sal, 7000);
  DBMS_OUTPUT.PUT_LINE('A2: After +7000, v_sal = ' || v_sal);

  demo40_adjust_salary(v_sal, -10000);
  DBMS_OUTPUT.PUT_LINE('A2: After -10000, v_sal = ' || v_sal);
END;
/
--------------------------------------------------------------------------------
-- A3: Use demo40_accumulate_total to sum only IT salaries.
--------------------------------------------------------------------------------
DECLARE
  v_total NUMBER := 0;
BEGIN
  FOR r IN (
    SELECT e.salary
      FROM ems_employees e
      JOIN ems_departments d
        ON d.dept_id = e.dept_id
     WHERE d.dept_code = 'IT'
  ) LOOP
    demo40_accumulate_total(r.salary, v_total);
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('A3: Total IT salary = ' || v_total);
END;
/
--------------------------------------------------------------------------------
-- A4: Use demo40_raise_emp_salary to raise E1002 salary by 3000.
--------------------------------------------------------------------------------
DECLARE
  v_final ems_employees.salary%TYPE := 0;
BEGIN
  demo40_raise_emp_salary('E1002', 3000, v_final);
  DBMS_OUTPUT.PUT_LINE(
    'A4: New salary for E1002 = ' || v_final
  );
END;
/
--------------------------------------------------------------------------------
-- A5: Attempt to raise salary for a non-existing employee E9999 and handle error.
--------------------------------------------------------------------------------
DECLARE
  v_final ems_employees.salary%TYPE := 0;
BEGIN
  BEGIN
    demo40_raise_emp_salary('E9999', 3000, v_final);
    DBMS_OUTPUT.PUT_LINE(
      'A5: Unexpected success, new salary = ' || v_final
    );
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE(
        'A5: No employee found for E9999 (NO_DATA_FOUND).'
      );
  END;
END;
/
--------------------------------------------------------------------------------
-- A6: Use demo40_append_log to build a simple user activity trace.
--------------------------------------------------------------------------------
DECLARE
  v_log VARCHAR2(4000);
BEGIN
  demo40_append_log(v_log, 'Login');
  demo40_append_log(v_log, 'View dashboard');
  demo40_append_log(v_log, 'Download report');

  DBMS_OUTPUT.PUT_LINE('A6: User activity log = ' || v_log);
END;
/
--------------------------------------------------------------------------------
-- A7: Use demo40_accumulate_total to build a bonus pool of 10 percent of salary.
--------------------------------------------------------------------------------
DECLARE
  v_bonus_total NUMBER := 0;
BEGIN
  FOR r IN (SELECT salary FROM ems_employees) LOOP
    demo40_accumulate_total(r.salary * 0.10, v_bonus_total);
  END LOOP;

  DBMS_OUTPUT.PUT_LINE(
    'A7: Total bonus pool (10 percent) = ' || v_bonus_total
  );
END;
/
--------------------------------------------------------------------------------
-- A8: Use demo40_increment_counter as a sequence for labeling steps.
--------------------------------------------------------------------------------
DECLARE
  v_seq NUMBER := 0;
BEGIN
  FOR i IN 1..3 LOOP
    demo40_increment_counter(v_seq);
    DBMS_OUTPUT.PUT_LINE(
      'A8: Step ' || v_seq || ' completed'
    );
  END LOOP;
END;
/
--------------------------------------------------------------------------------
-- A9: Combine demo40_raise_emp_salary and demo40_append_log.
--------------------------------------------------------------------------------
DECLARE
  v_final ems_employees.salary%TYPE := 0;
  v_log   VARCHAR2(4000);
BEGIN
  demo40_raise_emp_salary('E1003', 2000, v_final);
  demo40_append_log(v_log, 'Raised E1003 salary to ' || v_final);

  demo40_raise_emp_salary('E1003', 1000, v_final);
  demo40_append_log(v_log, 'Raised E1003 salary again to ' || v_final);

  DBMS_OUTPUT.PUT_LINE('A9: ' || v_log);
END;
/
--------------------------------------------------------------------------------
-- A10: Use demo40_accumulate_total to sum net payroll for the current year.
--------------------------------------------------------------------------------
DECLARE
  v_total NUMBER := 0;
BEGIN
  FOR r IN (
    SELECT net_salary
      FROM ems_payroll_runs
     WHERE run_year = EXTRACT(YEAR FROM SYSDATE)
  ) LOOP
    demo40_accumulate_total(r.net_salary, v_total);
  END LOOP;

  DBMS_OUTPUT.PUT_LINE(
    'A10: Accumulated net payroll for current year = ' || v_total
  );
END;
/
--------------------------------------------------------------------------------
-- End of assignment_040_bidirectional_parameter_exchange.sql
--------------------------------------------------------------------------------
