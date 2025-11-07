-- Script: plsql_rowtype_anchoring_with_percent_rowtype.sql
-- Session: 030 - Row Type Anchoring with %ROWTYPE (Production Patterns)
-- Purpose:
--   Demonstrate robust patterns for using %ROWTYPE with tables and cursors:
--   (1) Table%ROWTYPE single-row fetch
--   (2) Partial assignment & field updates
--   (3) INSERT using record + RETURNING INTO fields
--   (4) UPDATE with RETURNING INTO record fields
--   (5) Cursor %ROWTYPE with join shape
--   (6) Cursor FOR LOOP implicit record
--   (7) Function returning table%ROWTYPE
--   (8) Defensive initialization & NULL handling
-- How to run:
--   SET SERVEROUTPUT ON; Execute each block separately (terminated by '/').
-- Notes:
--   • %ROWTYPE mirrors all columns of a table or cursor at compile time.
--   • Prefer cursor%ROWTYPE for SELECTs that don't match a base table shape.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Setup (idempotent): small schema
--------------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'DROP TABLE emp_row_demo PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE dept_row_demo PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE dept_row_demo (
  dept_id   NUMBER PRIMARY KEY,
  dept_name VARCHAR2(50)
);
CREATE TABLE emp_row_demo (
  emp_id     NUMBER PRIMARY KEY,
  emp_name   VARCHAR2(50) NOT NULL,
  dept_id    NUMBER REFERENCES dept_row_demo(dept_id),
  salary     NUMBER(10,2),
  email      VARCHAR2(120),
  hired_on   DATE
);
INSERT INTO dept_row_demo VALUES (10,'Engineering');
INSERT INTO dept_row_demo VALUES (20,'Finance');
INSERT INTO emp_row_demo VALUES (1,'Avi', 10, 90000,'avi@example.com', DATE '2022-01-10');
INSERT INTO emp_row_demo VALUES (2,'Raj', 10, 80000,'raj@example.com', DATE '2022-06-15');
INSERT INTO emp_row_demo VALUES (3,'Mani',20, 75000,'mani@example.com',DATE '2023-02-01');
COMMIT;
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 1: Table%ROWTYPE single-row fetch
-- Scenario:
--   Load the entire employee row into a record variable.
-- Expected Output:
--   Prints id, name, dept, salary from the record.
--------------------------------------------------------------------------------
DECLARE
  r emp_row_demo%ROWTYPE;  -- mirrors emp_row_demo columns
BEGIN
  SELECT * INTO r FROM emp_row_demo WHERE emp_id = 1;
  DBMS_OUTPUT.PUT_LINE('Row: id='||r.emp_id||', name='||r.emp_name||', dept='||r.dept_id||', salary='||r.salary);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 2: Partial assignment & field updates
-- Scenario:
--   Fetch row, update a few fields in the record, then push changes back.
-- Expected Output:
--   'rows=1 new_email=... new_salary=...'
--------------------------------------------------------------------------------
DECLARE
  r emp_row_demo%ROWTYPE;
BEGIN
  SELECT * INTO r FROM emp_row_demo WHERE emp_id = 2;
  r.email := 'raj.updated@example.com';
  r.salary := NVL(r.salary,0) + 1200;
  UPDATE emp_row_demo
  SET    email  = r.email,
         salary = r.salary
  WHERE  emp_id = r.emp_id;
  DBMS_OUTPUT.PUT_LINE('rows='||SQL%ROWCOUNT||' new_email='||r.email||' new_salary='||r.salary);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 3: INSERT using record + RETURNING INTO fields
-- Scenario:
--   Build a record and insert a new employee; capture generated values.
-- Expected Output:
--   'inserted id=4 name=Neha salary=70000'
--------------------------------------------------------------------------------
DECLARE
  r emp_row_demo%ROWTYPE;
BEGIN
  -- initialize needed fields
  r.emp_id   := 4;
  r.emp_name := 'Neha';
  r.dept_id  := 20;
  r.salary   := 70000;
  r.email    := 'neha@example.com';
  r.hired_on := SYSDATE;

  INSERT INTO emp_row_demo(emp_id, emp_name, dept_id, salary, email, hired_on)
  VALUES(r.emp_id, r.emp_name, r.dept_id, r.salary, r.email, r.hired_on)
  RETURNING emp_id, emp_name, salary
  INTO      r.emp_id, r.emp_name, r.salary;

  DBMS_OUTPUT.PUT_LINE('inserted id='||r.emp_id||' name='||r.emp_name||' salary='||r.salary);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 4: UPDATE with RETURNING INTO record fields
-- Scenario:
--   Give emp_id=3 a raise and capture the new row values into fields of a record.
-- Expected Output:
--   'updated rows=1 new_salary=... new_email=...'
--------------------------------------------------------------------------------
DECLARE
  r emp_row_demo%ROWTYPE;
BEGIN
  UPDATE emp_row_demo
  SET    salary = salary + 500,
         email  = 'mani.updated@example.com'
  WHERE  emp_id = 3
  RETURNING emp_id, emp_name, dept_id, salary, email, hired_on
  INTO      r.emp_id, r.emp_name, r.dept_id, r.salary, r.email, r.hired_on;

  DBMS_OUTPUT.PUT_LINE('updated rows='||SQL%ROWCOUNT||' new_salary='||r.salary||' new_email='||r.email);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 5: Cursor %ROWTYPE with join shape
-- Scenario:
--   Use a cursor selecting a join projection; declare r as cursor%ROWTYPE.
-- Expected Output:
--   'Avi (Engineering)', 'Raj (Engineering)'
--------------------------------------------------------------------------------
DECLARE
  CURSOR c_emp IS
    SELECT e.emp_id, e.emp_name, d.dept_name
    FROM   emp_row_demo e
    JOIN   dept_row_demo d ON d.dept_id = e.dept_id
    WHERE  e.dept_id = 10
    ORDER  BY e.emp_id;
  r c_emp%ROWTYPE;  -- shaped like the cursor projection
BEGIN
  OPEN c_emp;
  LOOP
    FETCH c_emp INTO r;
    EXIT WHEN c_emp%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE(r.emp_name||' ('||r.dept_name||')');
  END LOOP;
  CLOSE c_emp;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 6: Cursor FOR LOOP implicit record
-- Scenario:
--   Iterate join results without explicit open/fetch/close; implicit record 'rec' used per row.
-- Expected Output:
--   Prints 'id=..., name=..., dept=...'
--------------------------------------------------------------------------------
BEGIN
  FOR rec IN (
    SELECT e.emp_id AS id, e.emp_name AS name, d.dept_name AS dept
    FROM   emp_row_demo e
    JOIN   dept_row_demo d ON d.dept_id = e.dept_id
    ORDER  BY e.emp_id
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('id='||rec.id||', name='||rec.name||', dept='||rec.dept);
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 7: Function returning table%ROWTYPE
-- Scenario:
--   Return full employee row as emp_row_demo%ROWTYPE; consume in caller.
-- Expected Output:
--   'F(1) => Avi, Engineering'
--------------------------------------------------------------------------------
DECLARE
  FUNCTION get_emp(p_id IN emp_row_demo.emp_id%TYPE)
    RETURN emp_row_demo%ROWTYPE
  IS
    r emp_row_demo%ROWTYPE;
  BEGIN
    SELECT * INTO r FROM emp_row_demo WHERE emp_id = p_id;
    RETURN r;
  END;
  r emp_row_demo%ROWTYPE;
  v_dept dept_row_demo.dept_name%TYPE;
BEGIN
  r := get_emp(1);
  SELECT dept_name INTO v_dept FROM dept_row_demo WHERE dept_id = r.dept_id;
  DBMS_OUTPUT.PUT_LINE('F(1) => '||r.emp_name||', '||v_dept);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 8: Defensive initialization & NULL handling
-- Scenario:
--   Show how to safely initialize a record and guard against NULL fields before DML.
-- Expected Output:
--   'safe update rows=1'
--------------------------------------------------------------------------------
DECLARE
  r emp_row_demo%ROWTYPE;
BEGIN
  -- Initialize from an existing row to ensure non-null defaults
  SELECT * INTO r FROM emp_row_demo WHERE emp_id = 2;

  -- Guard modifications
  r.salary := NVL(r.salary,0) + 100;
  r.email  := COALESCE(r.email, r.emp_name||'@example.com');

  UPDATE emp_row_demo
  SET    salary = r.salary,
         email  = r.email
  WHERE  emp_id = r.emp_id;

  DBMS_OUTPUT.PUT_LINE('safe update rows='||SQL%ROWCOUNT);
END;
/
--------------------------------------------------------------------------------
-- End of File
--------------------------------------------------------------------------------
