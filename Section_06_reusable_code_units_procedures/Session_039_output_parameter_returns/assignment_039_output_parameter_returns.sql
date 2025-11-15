-- assignment_039_output_parameter_returns.sql
-- Session 039: Assignments - Output Parameter Returns

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- A1: Use demo39_get_emp_name to print names for all employees.
--------------------------------------------------------------------------------
DECLARE
  v_name VARCHAR2(120);
BEGIN
  FOR r IN (SELECT emp_no FROM ems_employees ORDER BY emp_no) LOOP
    demo39_get_emp_name(r.emp_no, v_name);
    DBMS_OUTPUT.PUT_LINE(
      'A1: ' || r.emp_no || ' -> ' || v_name
    );
  END LOOP;
END;
/
--------------------------------------------------------------------------------
-- A2: Use demo39_get_emp_details for E1001 and print a formatted string.
--------------------------------------------------------------------------------
DECLARE
  v_sal  ems_employees.salary%TYPE;
  v_dept ems_departments.dept_name%TYPE;
BEGIN
  demo39_get_emp_details('E1001', v_sal, v_dept);
  DBMS_OUTPUT.PUT_LINE(
    'A2: Employee E1001 works in ' || v_dept ||
    ' with salary ' || v_sal
  );
END;
/
--------------------------------------------------------------------------------
-- A3: Call demo39_try_get_emp for both existing and non-existing employees.
--------------------------------------------------------------------------------
DECLARE
  v_name VARCHAR2(120);
  v_code NUMBER;
  v_msg  VARCHAR2(4000);
BEGIN
  demo39_try_get_emp('E1002', v_name, v_code, v_msg);
  DBMS_OUTPUT.PUT_LINE(
    'A3: valid E1002 -> code=' || NVL(TO_CHAR(v_code),'NULL') ||
    ', msg=' || NVL(v_msg,'NULL') ||
    ', name=' || NVL(v_name,'NULL')
  );

  demo39_try_get_emp('E9999', v_name, v_code, v_msg);
  DBMS_OUTPUT.PUT_LINE(
    'A3: invalid E9999 -> code=' || NVL(TO_CHAR(v_code),'NULL') ||
    ', msg=' || NVL(v_msg,'NULL') ||
    ', name=' || NVL(v_name,'NULL')
  );
END;
/
--------------------------------------------------------------------------------
-- A4: Use demo39_get_total_payroll for a year with no data (e.g. 1999).
--------------------------------------------------------------------------------
DECLARE
  v_total NUMBER;
BEGIN
  demo39_get_total_payroll(1999, v_total);
  DBMS_OUTPUT.PUT_LINE(
    'A4: Total payroll for 1999 = ' || v_total
  );
END;
/
--------------------------------------------------------------------------------
-- A5: Use demo39_get_total_payroll for the current year.
--------------------------------------------------------------------------------
DECLARE
  v_total NUMBER;
BEGIN
  demo39_get_total_payroll(EXTRACT(YEAR FROM SYSDATE), v_total);
  DBMS_OUTPUT.PUT_LINE(
    'A5: Total payroll for the current year = ' || v_total
  );
END;
/
--------------------------------------------------------------------------------
-- A6: Use demo39_get_dept_summary for HR and display headcount and avg salary.
--------------------------------------------------------------------------------
DECLARE
  v_cnt NUMBER;
  v_avg NUMBER;
BEGIN
  demo39_get_dept_summary('HR', v_cnt, v_avg);
  DBMS_OUTPUT.PUT_LINE(
    'A6: HR headcount = ' || v_cnt || ', average salary = ' || v_avg
  );
END;
/
--------------------------------------------------------------------------------
-- A7: Loop through all departments and call demo39_get_dept_summary.
--------------------------------------------------------------------------------
DECLARE
  v_cnt NUMBER;
  v_avg NUMBER;
BEGIN
  FOR r IN (SELECT dept_code, dept_name FROM ems_departments) LOOP
    demo39_get_dept_summary(r.dept_code, v_cnt, v_avg);
    DBMS_OUTPUT.PUT_LINE(
      'A7: ' || r.dept_code || ' - ' || r.dept_name ||
      ' -> headcount=' || v_cnt ||
      ', average salary=' || v_avg
    );
  END LOOP;
END;
/
--------------------------------------------------------------------------------
-- A8: Build a mini employee report using demo39_get_emp_details.
--------------------------------------------------------------------------------
DECLARE
  v_sal  ems_employees.salary%TYPE;
  v_dept ems_departments.dept_name%TYPE;
BEGIN
  FOR r IN (SELECT emp_no FROM ems_employees ORDER BY emp_no) LOOP
    demo39_get_emp_details(r.emp_no, v_sal, v_dept);
    DBMS_OUTPUT.PUT_LINE(
      'A8: ' || r.emp_no ||
      ' -> ' || v_dept ||
      ', salary = ' || v_sal
    );
  END LOOP;
END;
/
--------------------------------------------------------------------------------
-- A9: Use demo39_try_get_emp as a search helper for E1003.
--------------------------------------------------------------------------------
DECLARE
  v_name VARCHAR2(120);
  v_code NUMBER;
  v_msg  VARCHAR2(4000);
BEGIN
  demo39_try_get_emp('E1003', v_name, v_code, v_msg);
  IF v_code IS NULL THEN
    DBMS_OUTPUT.PUT_LINE('A9: Found employee: ' || v_name);
  ELSE
    DBMS_OUTPUT.PUT_LINE('A9: Error: ' || v_msg);
  END IF;
END;
/
--------------------------------------------------------------------------------
-- A10: Use demo39_get_dept_summary to decide if IT is high paying or not.
--------------------------------------------------------------------------------
DECLARE
  v_cnt NUMBER;
  v_avg NUMBER;
BEGIN
  demo39_get_dept_summary('IT', v_cnt, v_avg);
  IF v_avg > 65000 THEN
    DBMS_OUTPUT.PUT_LINE('A10: IT is currently a high-paying department.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('A10: IT salary level is moderate.');
  END IF;
END;
/
--------------------------------------------------------------------------------
-- End of assignment_039_output_parameter_returns.sql
--------------------------------------------------------------------------------
