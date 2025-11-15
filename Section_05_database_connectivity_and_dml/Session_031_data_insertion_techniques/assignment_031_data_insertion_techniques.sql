-- assignment_031_data_insertion_techniques.sql
-- Session : 031_data_insertion_techniques
-- Topic   : Practice - Data Insertion Techniques
-- Purpose : 10 tasks covering VALUES, variables, loops, INSERT-SELECT
--           and RETURNING clause.

SET SERVEROUTPUT ON;

BEGIN
  BEGIN EXECUTE IMMEDIATE 'DROP TABLE demo31_emp_assign'; EXCEPTION WHEN OTHERS THEN NULL; END;
END;
/
CREATE TABLE demo31_emp_assign (
  emp_id     NUMBER PRIMARY KEY,
  emp_name   VARCHAR2(100),
  hire_date  DATE,
  salary     NUMBER
);
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 1: Insert one row with literal values
--------------------------------------------------------------------------------
BEGIN
  INSERT INTO demo31_emp_assign (emp_id, emp_name, hire_date, salary)
  VALUES (1, 'Alpha User', SYSDATE, 50000);
  DBMS_OUTPUT.PUT_LINE('A1: Row inserted.');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 2: Insert row using variables
--------------------------------------------------------------------------------
DECLARE
  v_id   demo31_emp_assign.emp_id%TYPE   := 2;
  v_name demo31_emp_assign.emp_name%TYPE := 'Beta User';
  v_sal  demo31_emp_assign.salary%TYPE   := 52000;
BEGIN
  INSERT INTO demo31_emp_assign (emp_id, emp_name, hire_date, salary)
  VALUES (v_id, v_name, SYSDATE, v_sal);
  DBMS_OUTPUT.PUT_LINE('A2: Row inserted using variables.');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 3: Insert row using INSERT-SELECT
--------------------------------------------------------------------------------
BEGIN
  INSERT INTO demo31_emp_assign (emp_id, emp_name, hire_date, salary)
  SELECT 3, 'Gamma User', SYSDATE, 53000 FROM dual;
  DBMS_OUTPUT.PUT_LINE('A3: Row inserted using SELECT.');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 4: Use FOR loop to insert 5 employees
--------------------------------------------------------------------------------
DECLARE
  v_start NUMBER := 10;
BEGIN
  FOR i IN 1 .. 5 LOOP
    INSERT INTO demo31_emp_assign (emp_id, emp_name, hire_date, salary)
    VALUES (v_start + i, 'LoopUser ' || i, SYSDATE, 45000 + i * 500);
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('A4: 5 rows inserted using loop.');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 5: INSERT with RETURNING into variable
--------------------------------------------------------------------------------
DECLARE
  v_new_id demo31_emp_assign.emp_id%TYPE;
BEGIN
  INSERT INTO demo31_emp_assign (emp_id, emp_name, hire_date, salary)
  VALUES (99, 'ReturnedUser', SYSDATE, 65000)
  RETURNING emp_id INTO v_new_id;

  DBMS_OUTPUT.PUT_LINE('A5: New emp_id = ' || v_new_id);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 6: Insert with missing hire_date to observe default
--------------------------------------------------------------------------------
BEGIN
  INSERT INTO demo31_emp_assign (emp_id, emp_name, salary)
  VALUES (4, 'NoDateUser', 48000);
  DBMS_OUTPUT.PUT_LINE('A6: Row inserted with hire_date left NULL (unless default).');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 7: Insert multiple records using UNION ALL
--------------------------------------------------------------------------------
BEGIN
  INSERT INTO demo31_emp_assign (emp_id, emp_name, hire_date, salary)
  SELECT 5, 'UnionUser1', SYSDATE, 51000 FROM dual
  UNION ALL
  SELECT 6, 'UnionUser2', SYSDATE, 52000 FROM dual;

  DBMS_OUTPUT.PUT_LINE('A7: 2 rows inserted with UNION ALL.');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 8: Prevent duplicate insert using COUNT check
--------------------------------------------------------------------------------
DECLARE
  v_cnt NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_cnt FROM demo31_emp_assign WHERE emp_id = 1;

  IF v_cnt = 0 THEN
    INSERT INTO demo31_emp_assign (emp_id, emp_name, hire_date, salary)
    VALUES (1, 'Alpha User', SYSDATE, 50000);
    DBMS_OUTPUT.PUT_LINE('A8: Inserted as id not present.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('A8: Skipped insert, id already exists.');
  END IF;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 9: Procedure to insert a new employee
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE a31_add_emp (
  p_id   IN demo31_emp_assign.emp_id%TYPE,
  p_name IN demo31_emp_assign.emp_name%TYPE,
  p_sal  IN demo31_emp_assign.salary%TYPE
) IS
BEGIN
  INSERT INTO demo31_emp_assign (emp_id, emp_name, hire_date, salary)
  VALUES (p_id, p_name, SYSDATE, p_sal);
END;
/
BEGIN
  a31_add_emp(20, 'Proc User', 70000);
  DBMS_OUTPUT.PUT_LINE('A9: Row inserted via procedure.');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 10: Show all inserted rows
--------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('A10: Final data in demo31_emp_assign');
  FOR r IN (SELECT * FROM demo31_emp_assign ORDER BY emp_id) LOOP
    DBMS_OUTPUT.PUT_LINE('  ' || r.emp_id || ' - ' || r.emp_name ||
                         ' - ' || r.salary);
  END LOOP;
END;
/
--------------------------------------------------------------------------------
