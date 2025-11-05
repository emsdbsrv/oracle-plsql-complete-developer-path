-- Demo Script: plsql_performance_demo.sql
-- Objective: Compare SQL and PL/SQL performance efficiency

SET SERVEROUTPUT ON;
DECLARE
  v_start_time TIMESTAMP;
  v_end_time   TIMESTAMP;
BEGIN
  v_start_time := SYSTIMESTAMP;

  -- Inefficient loop with context switching
  FOR i IN 1..500 LOOP
    INSERT INTO employees (emp_id, emp_name, hire_date, salary)
    VALUES (emp_seq.NEXTVAL, 'Emp_' || i, SYSDATE, 50000 + i);
  END LOOP;
  COMMIT;

  v_end_time := SYSTIMESTAMP;
  DBMS_OUTPUT.PUT_LINE('Execution time (row-by-row): ' || TO_CHAR(v_end_time - v_start_time));

  -- Optimized bulk operation
  v_start_time := SYSTIMESTAMP;

  FORALL i IN 1..500
    INSERT INTO employees (emp_id, emp_name, hire_date, salary)
    VALUES (emp_seq.NEXTVAL, 'Bulk_' || i, SYSDATE, 60000 + i);

  COMMIT;

  v_end_time := SYSTIMESTAMP;
  DBMS_OUTPUT.PUT_LINE('Execution time (bulk insert): ' || TO_CHAR(v_end_time - v_start_time));
END;
/