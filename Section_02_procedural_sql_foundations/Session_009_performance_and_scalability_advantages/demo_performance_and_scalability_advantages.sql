-- demo_performance_and_scalability_advantages.sql
-- Session : 009_performance_and_scalability_advantages
-- Topic   : Why PL/SQL can offer performance and scalability benefits
-- Purpose : Show how moving logic closer to the data and reducing
--           round-trips can improve efficiency.
-- Focus   : Anonymous blocks, loops, simple inserts, variable reuse,
--           encapsulating logic in procedures.

SET SERVEROUTPUT ON;



--------------------------------------------------------------------------------
-- Demo 1: Concept of Reducing Network Round-Trips
-- Idea:
--   Instead of sending three separate SQL statements from the client,
--   we can send one PL/SQL block that executes all three operations
--   inside the database server. This reduces network chatter and can
--   improve response time when many calls are involved.
--------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 1: Simulating three related operations in one block.');

  -- Imagine these are three separate SQL calls from a client application.
  -- Here they all run in a single anonymous PL/SQL block on the server.
  DBMS_OUTPUT.PUT_LINE('  Step 1: Validate input data.');
  DBMS_OUTPUT.PUT_LINE('  Step 2: Perform main database operation.');
  DBMS_OUTPUT.PUT_LINE('  Step 3: Write audit / log information.');

  DBMS_OUTPUT.PUT_LINE('Demo 1 result: All steps completed in one server round-trip.');
END;
/
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Setup: Small Demo Table for Remaining Examples
-- We create a simple table to demonstrate batch inserts and updates.
-- This setup section is intentionally verbose so learners understand
-- what is being created and why.
--------------------------------------------------------------------------------
BEGIN
  -- Try to drop the table if it already exists.
  EXECUTE IMMEDIATE 'DROP TABLE s009_perf_employees';
EXCEPTION
  WHEN OTHERS THEN
    -- ORA-00942 = table or view does not exist. We ignore this specific error
    -- so the script can be rerun safely.
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
/
CREATE TABLE s009_perf_employees
(
  emp_id      NUMBER        PRIMARY KEY,
  emp_name    VARCHAR2(50),
  base_salary NUMBER
);
/
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Demo 2: Batch INSERT Using a LOOP (Single Block)
-- Idea:
--   Insert multiple rows using a single anonymous block and a FOR loop.
--   This demonstrates how PL/SQL can push a series of related operations
--   to the database server instead of issuing them one by one from a client.
--------------------------------------------------------------------------------
DECLARE
  v_counter NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 2: Inserting 5 employees using a FOR loop.');

  FOR v_counter IN 1 .. 5 LOOP
    INSERT INTO s009_perf_employees (emp_id, emp_name, base_salary)
    VALUES (
      v_counter,
      'Employee-' || TO_CHAR(v_counter),
      30000 + (v_counter * 1000)
    );
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('Demo 2 result: 5 rows inserted in a single PL/SQL block.');
END;
/
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Demo 3: Reusing Computed Values Instead of Repeating Expressions
-- Idea:
--   Compute a value once, store it in a variable, and reuse it.
--   This avoids repeating the same expression or query multiple times.
--------------------------------------------------------------------------------
DECLARE
  v_raise_percent NUMBER := 0.10;  -- 10 percent raise
  v_employee_id   NUMBER := 1;
  v_old_salary    NUMBER;
  v_new_salary    NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 3: Applying a 10% raise to employee 1.');

  -- Get current salary once and reuse the value.
  SELECT base_salary
    INTO v_old_salary
    FROM s009_perf_employees
   WHERE emp_id = v_employee_id;

  v_new_salary := v_old_salary * (1 + v_raise_percent);

  UPDATE s009_perf_employees
     SET base_salary = v_new_salary
   WHERE emp_id = v_employee_id;

  DBMS_OUTPUT.PUT_LINE('  Old salary = ' || v_old_salary);
  DBMS_OUTPUT.PUT_LINE('  New salary = ' || v_new_salary);
  DBMS_OUTPUT.PUT_LINE('Demo 3 result: Salary updated using a single read and one update.');
END;
/
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Demo 4: Simple Stored Procedure for Reusable Operations
-- Idea:
--   Encapsulate frequently used logic in a stored procedure. This allows
--   multiple clients and sessions to reuse the same tested code, reducing
--   duplication and improving maintainability and scalability.
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE s009_grant_bonus
(
  p_emp_id        IN NUMBER,
  p_bonus_percent IN NUMBER
)
AS
  v_old_salary NUMBER;
  v_new_salary NUMBER;
BEGIN
  -- Fetch existing salary.
  SELECT base_salary
    INTO v_old_salary
    FROM s009_perf_employees
   WHERE emp_id = p_emp_id;

  -- Apply bonus as a percentage on top of existing salary.
  v_new_salary := v_old_salary * (1 + (p_bonus_percent / 100));

  UPDATE s009_perf_employees
     SET base_salary = v_new_salary
   WHERE emp_id = p_emp_id;

  DBMS_OUTPUT.PUT_LINE(
    'Procedure s009_grant_bonus: Employee ' || p_emp_id ||
    ' salary changed from ' || v_old_salary ||
    ' to ' || v_new_salary ||
    ' using bonus ' || p_bonus_percent || '%.'
  );
END s009_grant_bonus;
/
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Demo 4 (Execution): Calling the Procedure Multiple Times
-- Idea:
--   Invoke the stored procedure from a PL/SQL block. We still send just one
--   PL/SQL block from the client while the procedure runs entirely on the
--   database server, which scales better for large applications.
--------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 4 execution: Granting bonus using stored procedure.');

  s009_grant_bonus(p_emp_id => 2, p_bonus_percent => 5);
  s009_grant_bonus(p_emp_id => 3, p_bonus_percent => 7.5);
END;
/
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Demo 5: Simple Aggregation and Reporting in PL/SQL
-- Idea:
--   Use PL/SQL to compute summary information (aggregate values) and present
--   a small report directly from the database side.
--------------------------------------------------------------------------------
DECLARE
  v_total_employees   NUMBER;
  v_total_salary      NUMBER;
  v_average_salary    NUMBER;
BEGIN
  -- Aggregate query calculated once, then results are reused in PL/SQL.
  SELECT COUNT(*), SUM(base_salary), AVG(base_salary)
    INTO v_total_employees, v_total_salary, v_average_salary
    FROM s009_perf_employees;

  DBMS_OUTPUT.PUT_LINE('Demo 5: Salary summary for s009_perf_employees');
  DBMS_OUTPUT.PUT_LINE('  Total employees  = ' || v_total_employees);
  DBMS_OUTPUT.PUT_LINE('  Total salary sum = ' || v_total_salary);
  DBMS_OUTPUT.PUT_LINE('  Average salary   = ' || v_average_salary);
END;
/
--------------------------------------------------------------------------------
