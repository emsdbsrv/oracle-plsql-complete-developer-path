-- assignment_033_data_removal_and_cleanup.sql
-- Session : 033_data_removal_and_cleanup
-- Topic   : Practice - Data Removal and Cleanup

SET SERVEROUTPUT ON;

BEGIN
  BEGIN EXECUTE IMMEDIATE 'DROP TABLE demo33_emp_assign'; EXCEPTION WHEN OTHERS THEN NULL; END;
END;
/
CREATE TABLE demo33_emp_assign (
  emp_id      NUMBER PRIMARY KEY,
  emp_name    VARCHAR2(100),
  dept        VARCHAR2(50),
  active_flag CHAR(1) DEFAULT 'Y'
);
/
INSERT INTO demo33_emp_assign VALUES (1, 'Alpha', 'IT',      'Y');
INSERT INTO demo33_emp_assign VALUES (2, 'Beta',  'HR',      'Y');
INSERT INTO demo33_emp_assign VALUES (3, 'Gamma', 'Finance', 'Y');
INSERT INTO demo33_emp_assign VALUES (4, 'Delta', 'IT',      'Y');
INSERT INTO demo33_emp_assign VALUES (5, 'Epsilon', 'Sales', 'Y');
COMMIT;
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 1: Delete one employee by emp_id
--------------------------------------------------------------------------------
BEGIN
  DELETE FROM demo33_emp_assign
   WHERE emp_id = 5;
  DBMS_OUTPUT.PUT_LINE('A1: Rows deleted = ' || SQL%ROWCOUNT);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 2: Delete all employees from HR
--------------------------------------------------------------------------------
BEGIN
  DELETE FROM demo33_emp_assign
   WHERE dept = 'HR';
  DBMS_OUTPUT.PUT_LINE('A2: Rows deleted = ' || SQL%ROWCOUNT);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 3: Soft delete Finance department (set active_flag to N)
--------------------------------------------------------------------------------
BEGIN
  UPDATE demo33_emp_assign
     SET active_flag = 'N'
   WHERE dept = 'Finance';
  DBMS_OUTPUT.PUT_LINE('A3: Rows updated (soft-deleted) = ' || SQL%ROWCOUNT);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 4: Soft delete IT employees with emp_id > 2
--------------------------------------------------------------------------------
BEGIN
  UPDATE demo33_emp_assign
     SET active_flag = 'N'
   WHERE dept = 'IT'
     AND emp_id > 2;
  DBMS_OUTPUT.PUT_LINE('A4: Rows updated = ' || SQL%ROWCOUNT);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 5: TRUNCATE the table and repopulate
--------------------------------------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE demo33_emp_assign';

  INSERT INTO demo33_emp_assign VALUES (1, 'Alpha', 'IT',      'Y');
  INSERT INTO demo33_emp_assign VALUES (2, 'Beta',  'HR',      'Y');
  INSERT INTO demo33_emp_assign VALUES (3, 'Gamma', 'Finance', 'Y');
  INSERT INTO demo33_emp_assign VALUES (4, 'Delta', 'IT',      'Y');
  INSERT INTO demo33_emp_assign VALUES (5, 'Epsilon', 'Sales', 'Y');
  COMMIT;

  DBMS_OUTPUT.PUT_LINE('A5: Table truncated and repopulated.');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 6: Delete inactive employees (active_flag = N)
--------------------------------------------------------------------------------
BEGIN
  DELETE FROM demo33_emp_assign
   WHERE active_flag = 'N';
  DBMS_OUTPUT.PUT_LINE('A6: Rows deleted = ' || SQL%ROWCOUNT);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 7: Mark Sales employees inactive instead of deleting
--------------------------------------------------------------------------------
BEGIN
  UPDATE demo33_emp_assign
     SET active_flag = 'N'
   WHERE dept = 'Sales';
  DBMS_OUTPUT.PUT_LINE('A7: Rows updated (soft-deleted) = ' || SQL%ROWCOUNT);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 8: Delete all employees where dept = 'IT' and active_flag = 'Y'
--------------------------------------------------------------------------------
BEGIN
  DELETE FROM demo33_emp_assign
   WHERE dept = 'IT'
     AND active_flag = 'Y';
  DBMS_OUTPUT.PUT_LINE('A8: Rows deleted = ' || SQL%ROWCOUNT);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 9: Show only active employees
--------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('A9: Active employees');
  FOR r IN (SELECT * FROM demo33_emp_assign WHERE active_flag = 'Y') LOOP
    DBMS_OUTPUT.PUT_LINE('  ' || r.emp_id || ' - ' || r.emp_name ||
                         ' - ' || r.dept || ' - active_flag=' || r.active_flag);
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 10: Show all rows for final verification
--------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('A10: Final data in demo33_emp_assign');
  FOR r IN (SELECT * FROM demo33_emp_assign ORDER BY emp_id) LOOP
    DBMS_OUTPUT.PUT_LINE('  ' || r.emp_id || ' - ' || r.emp_name ||
                         ' - ' || r.dept || ' - ' || r.active_flag);
  END LOOP;
END;
/
--------------------------------------------------------------------------------
