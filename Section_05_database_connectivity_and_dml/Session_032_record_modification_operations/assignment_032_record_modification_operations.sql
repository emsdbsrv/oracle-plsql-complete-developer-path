-- assignment_032_record_modification_operations.sql
-- Session : 032_record_modification_operations
-- Topic   : Practice - Record Modification Operations
-- Purpose : 10 tasks focusing on UPDATE variations.

SET SERVEROUTPUT ON;

BEGIN
  BEGIN EXECUTE IMMEDIATE 'DROP TABLE demo32_emp_assign'; EXCEPTION WHEN OTHERS THEN NULL; END;
END;
/
CREATE TABLE demo32_emp_assign (
  emp_id     NUMBER PRIMARY KEY,
  emp_name   VARCHAR2(100),
  dept       VARCHAR2(50),
  salary     NUMBER
);
/
INSERT INTO demo32_emp_assign VALUES (1, 'Alpha', 'IT',      55000);
INSERT INTO demo32_emp_assign VALUES (2, 'Beta',  'HR',      45000);
INSERT INTO demo32_emp_assign VALUES (3, 'Gamma', 'Finance', 60000);
INSERT INTO demo32_emp_assign VALUES (4, 'Delta', 'IT',      65000);
INSERT INTO demo32_emp_assign VALUES (5, 'Epsilon', 'Sales', 40000);
COMMIT;
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 1: Give Alpha a 5000 raise
--------------------------------------------------------------------------------
BEGIN
  UPDATE demo32_emp_assign
     SET salary = salary + 5000
   WHERE emp_id = 1;
  DBMS_OUTPUT.PUT_LINE('A1: Rows updated = ' || SQL%ROWCOUNT);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 2: Increase salary by 10 percent for IT department
--------------------------------------------------------------------------------
BEGIN
  UPDATE demo32_emp_assign
     SET salary = salary * 1.10
   WHERE dept = 'IT';
  DBMS_OUTPUT.PUT_LINE('A2: Rows updated = ' || SQL%ROWCOUNT);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 3: Set HR salary to Finance department maximum
--------------------------------------------------------------------------------
BEGIN
  UPDATE demo32_emp_assign hr
     SET salary = (SELECT MAX(salary)
                     FROM demo32_emp_assign
                    WHERE dept = 'Finance')
   WHERE hr.dept = 'HR';
  DBMS_OUTPUT.PUT_LINE('A3: Rows updated = ' || SQL%ROWCOUNT);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 4: Reduce Sales salaries by 5 percent
--------------------------------------------------------------------------------
BEGIN
  UPDATE demo32_emp_assign
     SET salary = salary * 0.95
   WHERE dept = 'Sales';
  DBMS_OUTPUT.PUT_LINE('A4: Rows updated = ' || SQL%ROWCOUNT);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 5: Use cursor loop to add a fixed bonus of 2000 to all employees
--------------------------------------------------------------------------------
DECLARE
  CURSOR c_all IS
    SELECT emp_id, salary FROM demo32_emp_assign;
BEGIN
  FOR r IN c_all LOOP
    UPDATE demo32_emp_assign
       SET salary = r.salary + 2000
     WHERE emp_id = r.emp_id;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('A5: Bonus added for all employees.');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 6: UPDATE with RETURNING clause to capture old and new salary
--------------------------------------------------------------------------------
DECLARE
  v_old NUMBER;
  v_new NUMBER;
BEGIN
  UPDATE demo32_emp_assign
     SET salary = salary + 1000
   WHERE emp_id = 2
  RETURNING salary - 1000, salary
       INTO v_old, v_new;

  DBMS_OUTPUT.PUT_LINE('A6: Old = ' || v_old || ', New = ' || v_new);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 7: Set IT salaries to a minimum of 60000 using CASE
--------------------------------------------------------------------------------
BEGIN
  UPDATE demo32_emp_assign
     SET salary = CASE
                    WHEN salary < 60000 THEN 60000
                    ELSE salary
                  END
   WHERE dept = 'IT';
  DBMS_OUTPUT.PUT_LINE('A7: Rows updated = ' || SQL%ROWCOUNT);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 8: Swap salaries of two employees using intermediate variable
--------------------------------------------------------------------------------
DECLARE
  v_sal1 NUMBER;
  v_sal2 NUMBER;
BEGIN
  SELECT salary INTO v_sal1 FROM demo32_emp_assign WHERE emp_id = 3;
  SELECT salary INTO v_sal2 FROM demo32_emp_assign WHERE emp_id = 4;

  UPDATE demo32_emp_assign SET salary = v_sal2 WHERE emp_id = 3;
  UPDATE demo32_emp_assign SET salary = v_sal1 WHERE emp_id = 4;

  DBMS_OUTPUT.PUT_LINE('A8: Swapped salaries of emp_id 3 and 4.');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 9: Promote all employees to new department 'Corporate' if salary > 65000
--------------------------------------------------------------------------------
BEGIN
  UPDATE demo32_emp_assign
     SET dept = 'Corporate'
   WHERE salary > 65000;
  DBMS_OUTPUT.PUT_LINE('A9: Rows updated = ' || SQL%ROWCOUNT);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 10: Display final rows
--------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('A10: Final state of demo32_emp_assign');
  FOR r IN (SELECT * FROM demo32_emp_assign ORDER BY emp_id) LOOP
    DBMS_OUTPUT.PUT_LINE('  ' || r.emp_id || ' - ' || r.emp_name ||
                         ' - ' || r.dept || ' - ' || r.salary);
  END LOOP;
END;
/
--------------------------------------------------------------------------------
