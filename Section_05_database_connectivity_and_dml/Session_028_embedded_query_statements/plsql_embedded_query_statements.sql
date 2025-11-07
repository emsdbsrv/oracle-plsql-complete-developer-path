-- Script: plsql_embedded_query_statements.sql
-- Session: 028 - Embedded Query Statements (Production Patterns)
-- Purpose:
--   Demonstrate embedding SQL within PL/SQL with full commentary:
--   (1) SELECT INTO single-row, (2) Exception handling (NDF/TMR),
--   (3) %ROWTYPE record load, (4) JOIN + SELECT INTO,
--   (5) Aggregates + NVL + SQL%%ROWCOUNT, (6) BULK COLLECT + LIMIT,
--   (7) Cursor FOR LOOP, (8) DML with RETURNING INTO.
-- How to run:
--   SET SERVEROUTPUT ON; Execute each block separately (terminated by '/').
-- Notes:
--   • Anchor variables with %TYPE and %ROWTYPE where possible.
--   • Use exception handlers for single-row SELECT INTO safety.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Setup (idempotent): small demo tables
--------------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'DROP TABLE emp_demo PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE dept_demo PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE dept_demo (
  dept_id   NUMBER PRIMARY KEY,
  dept_name VARCHAR2(50)
);
CREATE TABLE emp_demo (
  emp_id     NUMBER PRIMARY KEY,
  emp_name   VARCHAR2(50),
  dept_id    NUMBER REFERENCES dept_demo(dept_id),
  salary     NUMBER,
  hire_date  DATE
);
INSERT INTO dept_demo VALUES (10, 'Engineering');
INSERT INTO dept_demo VALUES (20, 'Finance');
INSERT INTO emp_demo VALUES (1, 'Avi',   10, 90000, DATE '2022-01-10');
INSERT INTO emp_demo VALUES (2, 'Raj',   10, 80000, DATE '2022-06-15');
INSERT INTO emp_demo VALUES (3, 'Mani',  20, 75000, DATE '2023-02-01');
COMMIT;
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 1: SELECT INTO single-row (by PK)
-- Scenario: Load a single scalar column into a variable using a PK lookup.
-- Drivers: v_name anchored to emp_demo.emp_name.
-- Expected Output: 'Employee #1 name = Avi'
--------------------------------------------------------------------------------
DECLARE
  v_name emp_demo.emp_name%TYPE;
BEGIN
  SELECT emp_name INTO v_name FROM emp_demo WHERE emp_id = 1;
  DBMS_OUTPUT.PUT_LINE('Employee #1 name = '||v_name);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 2: SELECT INTO with NO_DATA_FOUND and TOO_MANY_ROWS
-- Scenario: Show safe handling around single-row SELECT INTO.
-- Expected Output: 'No data found for emp_id=999' then 'Too many rows for name=Avi'
--------------------------------------------------------------------------------
BEGIN
  -- NO_DATA_FOUND branch
  DECLARE v_name emp_demo.emp_name%TYPE; BEGIN
    SELECT emp_name INTO v_name FROM emp_demo WHERE emp_id = 999;
  EXCEPTION WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('No data found for emp_id=999');
  END;

  -- Create duplicate name to trigger TOO_MANY_ROWS
  INSERT INTO emp_demo VALUES (4, 'Avi', 10, 70000, SYSDATE);
  COMMIT;

  DECLARE v_id emp_demo.emp_id%TYPE; BEGIN
    SELECT emp_id INTO v_id FROM emp_demo WHERE emp_name = 'Avi';
  EXCEPTION WHEN TOO_MANY_ROWS THEN
    DBMS_OUTPUT.PUT_LINE('Too many rows for name=Avi');
  END;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 3: %ROWTYPE record load
-- Scenario: Fetch an entire row into a table-anchored record.
-- Expected Output: 'Row: id=2, name=Raj, dept=10, salary=80000'
--------------------------------------------------------------------------------
DECLARE
  r emp_demo%ROWTYPE;
BEGIN
  SELECT * INTO r FROM emp_demo WHERE emp_id = 2;
  DBMS_OUTPUT.PUT_LINE('Row: id='||r.emp_id||', name='||r.emp_name||', dept='||r.dept_id||', salary='||r.salary);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 4: JOIN + SELECT INTO (multi-column)
-- Scenario: Retrieve employee with department name via inner join.
-- Expected Output: 'Mani works in Finance'
--------------------------------------------------------------------------------
DECLARE
  v_emp  emp_demo.emp_name%TYPE;
  v_dept dept_demo.dept_name%TYPE;
BEGIN
  SELECT e.emp_name, d.dept_name
  INTO   v_emp,     v_dept
  FROM   emp_demo e
  JOIN   dept_demo d ON d.dept_id = e.dept_id
  WHERE  e.emp_id = 3;
  DBMS_OUTPUT.PUT_LINE(v_emp||' works in '||v_dept);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 5: Aggregates + NVL + SQL%%ROWCOUNT
-- Scenario: Aggregate salary by dept; show AVG and report rows with SQL%%ROWCOUNT.
-- Expected Output: 'Dept 10 average salary = 85000' and 'Rows scanned = 1'
--------------------------------------------------------------------------------
DECLARE
  v_avg NUMBER;
BEGIN
  SELECT NVL(AVG(salary),0) INTO v_avg FROM emp_demo WHERE dept_id = 10;
  DBMS_OUTPUT.PUT_LINE('Dept 10 average salary = '||ROUND(v_avg));
  DBMS_OUTPUT.PUT_LINE('Rows scanned = '||SQL%ROWCOUNT); -- for SELECT INTO, this is 1
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 6: BULK COLLECT + LIMIT (efficient multi-row retrieval)
-- Scenario: Fetch employee names in batches of 2 and print.
-- Expected Output: Names printed in batches.
--------------------------------------------------------------------------------
DECLARE
  TYPE t_vc IS TABLE OF VARCHAR2(50);
  t t_vc;
  c_limit CONSTANT PLS_INTEGER := 2;
  v_offset NUMBER := 0;
BEGIN
  LOOP
    SELECT emp_name
    BULK COLLECT INTO t
    FROM emp_demo
    ORDER BY emp_id
    OFFSET v_offset ROWS FETCH NEXT c_limit ROWS ONLY;
    EXIT WHEN t.COUNT = 0;
    FOR i IN 1..t.COUNT LOOP
      DBMS_OUTPUT.PUT_LINE('name='||t(i));
    END LOOP;
    v_offset := v_offset + c_limit;
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 7: Cursor FOR LOOP (implicit open/fetch/close)
-- Scenario: Iterate rows for dept 10 without manual cursor management.
-- Expected Output: 'emp=..., dept=...' per row.
--------------------------------------------------------------------------------
BEGIN
  FOR r IN (
    SELECT e.emp_name AS emp, d.dept_name AS dept
    FROM   emp_demo e
    JOIN   dept_demo d ON d.dept_id = e.dept_id
    WHERE  e.dept_id = 10
    ORDER BY e.emp_id
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('emp='||r.emp||', dept='||r.dept);
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 8: DML with RETURNING INTO (avoid extra SELECT)
-- Scenario: Raise salary for emp_id=2 and capture new value immediately.
-- Expected Output: 'Updated rows = 1; New salary = 81000'
--------------------------------------------------------------------------------
DECLARE
  v_new emp_demo.salary%TYPE;
BEGIN
  UPDATE emp_demo
  SET    salary = salary + 1000
  WHERE  emp_id = 2
  RETURNING salary INTO v_new;
  DBMS_OUTPUT.PUT_LINE('Updated rows = '||SQL%ROWCOUNT||'; New salary = '||v_new);
END;
/
--------------------------------------------------------------------------------
-- End of File
--------------------------------------------------------------------------------
