-- assignment_035_unnamed_execution_blocks.sql
-- Session 035: Assignments - Unnamed (Anonymous) Execution Blocks
-- 10 practice tasks using the EMS business schema.

SET SERVEROUTPUT ON;

-------------------------------------------------------------------------------
-- A1: Give a one-time joining bonus of 15% to E1003 and log it.
-------------------------------------------------------------------------------
DECLARE
  v_emp_no  ems_employees.emp_no%TYPE := 'E1003';
  v_salary  ems_employees.salary%TYPE;
  v_bonus   NUMBER(12,2);
BEGIN
  SELECT salary INTO v_salary
    FROM ems_employees
   WHERE emp_no = v_emp_no;

  v_bonus := v_salary * 0.15;

  UPDATE ems_employees
     SET salary = salary + v_bonus
   WHERE emp_no = v_emp_no;

  INSERT INTO ems_audit_log (audit_id, module_name, action_desc)
  VALUES (seq_ems_audit_id.NEXTVAL,
          'A35',
          'Joining bonus ' || v_bonus || ' applied to ' || v_emp_no);
  COMMIT;

  DBMS_OUTPUT.PUT_LINE('A1: Joining bonus applied for ' || v_emp_no);
END;
/
-------------------------------------------------------------------------------
-- A2: Soft-terminate an employee by setting status = ''INACTIVE'' and auditing.
-------------------------------------------------------------------------------
DECLARE
  v_emp_no ems_employees.emp_no%TYPE := 'E1001';
BEGIN
  UPDATE ems_employees
     SET status = 'INACTIVE'
   WHERE emp_no = v_emp_no;

  INSERT INTO ems_audit_log (audit_id, module_name, action_desc)
  VALUES (seq_ems_audit_id.NEXTVAL,
          'A35',
          'Employee ' || v_emp_no || ' marked INACTIVE');

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('A2: ' || v_emp_no || ' marked INACTIVE.');
END;
/
-------------------------------------------------------------------------------
-- A3: For all IT employees, increase salary by 5% in a single anonymous block.
-------------------------------------------------------------------------------
BEGIN
  UPDATE ems_employees e
     SET salary = salary * 1.05
   WHERE dept_id = (SELECT dept_id FROM ems_departments WHERE dept_code = 'IT');

  INSERT INTO ems_audit_log (audit_id, module_name, action_desc)
  VALUES (seq_ems_audit_id.NEXTVAL,
          'A35',
          'IT department salary increased by 5%');
  COMMIT;

  DBMS_OUTPUT.PUT_LINE('A3: IT salaries increased by 5%.');
END;
/
-------------------------------------------------------------------------------
-- A4: Generate a payroll run for all ACTIVE employees for the current month.
-------------------------------------------------------------------------------
DECLARE
  v_month NUMBER := EXTRACT(MONTH FROM SYSDATE);
  v_year  NUMBER := EXTRACT(YEAR FROM SYSDATE);
BEGIN
  FOR r_emp IN (
    SELECT emp_id, salary FROM ems_employees WHERE status = 'ACTIVE'
  ) LOOP
    INSERT INTO ems_payroll_runs (run_id, emp_id, run_month, run_year,
                                  gross_salary, bonus_amount, net_salary)
    VALUES (seq_ems_run_id.NEXTVAL,
            r_emp.emp_id,
            v_month,
            v_year,
            r_emp.salary,
            r_emp.salary * 0.10,
            r_emp.salary * 1.10);
  END LOOP;

  INSERT INTO ems_audit_log (audit_id, module_name, action_desc)
  VALUES (seq_ems_audit_id.NEXTVAL,
          'A35',
          'Monthly payroll generated for all ACTIVE employees');
  COMMIT;

  DBMS_OUTPUT.PUT_LINE('A4: Payroll generated for ACTIVE employees.');
END;
/
-------------------------------------------------------------------------------
-- A5: Handle NO_DATA_FOUND for an invalid employee number input.
-------------------------------------------------------------------------------
DECLARE
  v_emp_no ems_employees.emp_no%TYPE := 'E9999';
  v_salary ems_employees.salary%TYPE;
BEGIN
  BEGIN
    SELECT salary INTO v_salary
      FROM ems_employees
     WHERE emp_no = v_emp_no;

    DBMS_OUTPUT.PUT_LINE('A5: Salary for ' || v_emp_no || ' = ' || v_salary);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('A5: No employee found with emp_no ' || v_emp_no);
  END;
END;
/
-------------------------------------------------------------------------------
-- A6: Print headcount for each department without writing to audit.
-------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('A6: Headcount by department (display only)');
  FOR r IN (
    SELECT d.dept_code, d.dept_name, COUNT(e.emp_id) AS headcount
      FROM ems_departments d
      LEFT JOIN ems_employees e ON e.dept_id = d.dept_id
     GROUP BY d.dept_code, d.dept_name
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('  ' || r.dept_code || ' - ' || r.dept_name ||
                         ' -> ' || r.headcount);
  END LOOP;
END;
/
-------------------------------------------------------------------------------
-- A7: Identify employees with salary above 70000 and log them.
-------------------------------------------------------------------------------
BEGIN
  FOR r IN (
    SELECT emp_no, first_name, last_name, salary
      FROM ems_employees
     WHERE salary > 70000
  ) LOOP
    INSERT INTO ems_audit_log (audit_id, module_name, action_desc)
    VALUES (seq_ems_audit_id.NEXTVAL,
            'A35',
            'High earner ' || r.emp_no || ' (' || r.first_name || ' ' ||
            r.last_name || '), salary=' || r.salary);
  END LOOP;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('A7: High earners logged to EMS_AUDIT_LOG.');
END;
/
-------------------------------------------------------------------------------
-- A8: Reset salary for an employee to a given fixed value.
-------------------------------------------------------------------------------
DECLARE
  v_emp_no ems_employees.emp_no%TYPE := 'E1002';
  v_new_sal NUMBER := 65000;
BEGIN
  UPDATE ems_employees
     SET salary = v_new_sal
   WHERE emp_no = v_emp_no;

  INSERT INTO ems_audit_log (audit_id, module_name, action_desc)
  VALUES (seq_ems_audit_id.NEXTVAL,
          'A35',
          'Salary reset to ' || v_new_sal || ' for ' || v_emp_no);

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('A8: Salary reset for ' || v_emp_no);
END;
/
-------------------------------------------------------------------------------
-- A9: Show total payroll (sum of latest net_salary) for each employee.
-------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('A9: Total payroll paid per employee (all runs)');
  FOR r IN (
    SELECT e.emp_no,
           e.first_name,
           e.last_name,
           SUM(p.net_salary) AS total_net
      FROM ems_employees e
      JOIN ems_payroll_runs p ON p.emp_id = e.emp_id
     GROUP BY e.emp_no, e.first_name, e.last_name
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('  ' || r.emp_no || ' - ' ||
                         r.first_name || ' ' || r.last_name ||
                         ' -> ' || r.total_net);
  END LOOP;
END;
/
-------------------------------------------------------------------------------
-- A10: Delete all payroll runs for the previous year (cleanup).
-------------------------------------------------------------------------------
DECLARE
  v_last_year NUMBER := EXTRACT(YEAR FROM SYSDATE) - 1;
BEGIN
  DELETE FROM ems_payroll_runs
   WHERE run_year = v_last_year;

  INSERT INTO ems_audit_log (audit_id, module_name, action_desc)
  VALUES (seq_ems_audit_id.NEXTVAL,
          'A35',
          'Old payroll runs for year ' || v_last_year || ' removed');
  COMMIT;

  DBMS_OUTPUT.PUT_LINE('A10: Cleanup of previous year payroll completed.');
END;
/
-------------------------------------------------------------------------------
-- End of assignment_035_unnamed_execution_blocks.sql
-------------------------------------------------------------------------------
