-- demo_032_record_modification_operations.sql
-- Session : 032_record_modification_operations
-- Topic   : Record Modification (UPDATE) Operations in PL/SQL
-- Purpose : Show how to update rows using WHERE, loops and RETURNING.

SET SERVEROUTPUT ON;

BEGIN
  BEGIN EXECUTE IMMEDIATE 'DROP TABLE demo32_emp'; EXCEPTION WHEN OTHERS THEN NULL; END;
END;
/
CREATE TABLE demo32_emp (
  emp_id     NUMBER PRIMARY KEY,
  emp_name   VARCHAR2(100),
  dept       VARCHAR2(50),
  salary     NUMBER
);
/
INSERT INTO demo32_emp VALUES (1, 'Amit',   'IT',      55000);
INSERT INTO demo32_emp VALUES (2, 'Bhavna', 'HR',      45000);
INSERT INTO demo32_emp VALUES (3, 'Chirag', 'Finance', 60000);
INSERT INTO demo32_emp VALUES (4, 'Divya',  'IT',      65000);
COMMIT;
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 1: Simple UPDATE for single row
--------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 1: Increase Amit salary by 5000');

  UPDATE demo32_emp
     SET salary = salary + 5000
   WHERE emp_id = 1;

  DBMS_OUTPUT.PUT_LINE('  Rows updated = ' || SQL%ROWCOUNT);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 2: Conditional UPDATE with WHERE clause
--------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 2: Give 10 percent raise to IT employees');

  UPDATE demo32_emp
     SET salary = salary * 1.10
   WHERE dept = 'IT';

  DBMS_OUTPUT.PUT_LINE('  Rows updated = ' || SQL%ROWCOUNT);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 3: UPDATE using data from another row (self-join style)
--------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 3: Set HR salary to match Finance max salary');

  UPDATE demo32_emp e_hr
     SET salary = (
          SELECT MAX(salary) FROM demo32_emp WHERE dept = 'Finance'
        )
   WHERE e_hr.dept = 'HR';

  DBMS_OUTPUT.PUT_LINE('  Rows updated = ' || SQL%ROWCOUNT);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 4: Row-by-row UPDATE using cursor loop
--------------------------------------------------------------------------------
DECLARE
  CURSOR c_emp IS
    SELECT emp_id, salary
      FROM demo32_emp
     WHERE dept = 'IT';
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 4: Add 1000 bonus using cursor loop for IT');

  FOR r IN c_emp LOOP
    UPDATE demo32_emp
       SET salary = r.salary + 1000
     WHERE emp_id = r.emp_id;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('  Rows updated (check table to verify).');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 5: UPDATE with RETURNING clause
--------------------------------------------------------------------------------
DECLARE
  v_old_sal NUMBER;
  v_new_sal NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 5: Update one row and capture old/new salary');

  UPDATE demo32_emp
     SET salary = salary + 2000
   WHERE emp_id = 2
  RETURNING salary - 2000, salary
       INTO v_old_sal, v_new_sal;

  DBMS_OUTPUT.PUT_LINE('  Old salary = ' || v_old_sal);
  DBMS_OUTPUT.PUT_LINE('  New salary = ' || v_new_sal);
END;
/
--------------------------------------------------------------------------------
