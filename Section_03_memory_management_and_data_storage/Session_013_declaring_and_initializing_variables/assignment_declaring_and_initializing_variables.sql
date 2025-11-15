-- assignment_declaring_and_initializing_variables.sql
-- Session : 013_declaring_and_initializing_variables
-- Topic   : Practice - Declaring and Initializing Variables
-- Purpose : 10 detailed exercises with full solutions and comments.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Assignment 1: Simple Declarations and Output
--------------------------------------------------------------------------------
DECLARE
  v_id    NUMBER       := 101;
  v_title VARCHAR2(50) := 'Declaring Variables';
BEGIN
  DBMS_OUTPUT.PUT_LINE('Assignment 1: v_id    = ' || v_id);
  DBMS_OUTPUT.PUT_LINE('Assignment 1: v_title = ' || v_title);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 2: Two-Step Initialization with Business Meaning
--------------------------------------------------------------------------------
DECLARE
  v_employee_name VARCHAR2(50);
  v_basic_pay     NUMBER;
BEGIN
  v_employee_name := 'Avi Jha';
  v_basic_pay     := 55000;

  DBMS_OUTPUT.PUT_LINE('Assignment 2: Employee Name = ' || v_employee_name);
  DBMS_OUTPUT.PUT_LINE('Assignment 2: Basic Pay     = ' || v_basic_pay);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 3: NOT NULL Variable for Control Flags
--------------------------------------------------------------------------------
DECLARE
  v_is_enabled BOOLEAN NOT NULL := TRUE;
BEGIN
  IF v_is_enabled THEN
    DBMS_OUTPUT.PUT_LINE('Assignment 3: Feature is enabled.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Assignment 3: Feature is disabled.');
  END IF;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 4: Default Value Versus Explicit Assignment
--------------------------------------------------------------------------------
DECLARE
  v_region      VARCHAR2(20) := 'APAC';  -- default region
  v_current_reg VARCHAR2(20);
BEGIN
  DBMS_OUTPUT.PUT_LINE('Assignment 4: Default region = ' || v_region);

  v_current_reg := 'EMEA'; -- explicit update, simulating user selection
  DBMS_OUTPUT.PUT_LINE('Assignment 4: Updated region = ' || v_current_reg);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 5: Using %TYPE with a supporting table
--------------------------------------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE s013_assign_departments';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN RAISE; END IF;
END;
/
CREATE TABLE s013_assign_departments
(
  dept_id   NUMBER PRIMARY KEY,
  dept_name VARCHAR2(50)
);
/
INSERT INTO s013_assign_departments VALUES (10, 'IT');
INSERT INTO s013_assign_departments VALUES (20, 'HR');
COMMIT;
--------------------------------------------------------------------------------
DECLARE
  v_dept_id   s013_assign_departments.dept_id%TYPE;
  v_dept_name s013_assign_departments.dept_name%TYPE;
BEGIN
  SELECT dept_id, dept_name
    INTO v_dept_id, v_dept_name
    FROM s013_assign_departments
   WHERE dept_id = 10;

  DBMS_OUTPUT.PUT_LINE('Assignment 5: Department ID   = ' || v_dept_id);
  DBMS_OUTPUT.PUT_LINE('Assignment 5: Department Name = ' || v_dept_name);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 6: Numeric Variables for Simple Finance Formula
--------------------------------------------------------------------------------
DECLARE
  v_principal NUMBER := 100000;
  v_rate      NUMBER := 8.5;
  v_time      NUMBER := 2;
  v_interest  NUMBER;
BEGIN
  v_interest := (v_principal * v_rate * v_time) / 100;

  DBMS_OUTPUT.PUT_LINE('Assignment 6: Principal = ' || v_principal);
  DBMS_OUTPUT.PUT_LINE('Assignment 6: Rate      = ' || v_rate);
  DBMS_OUTPUT.PUT_LINE('Assignment 6: Time      = ' || v_time);
  DBMS_OUTPUT.PUT_LINE('Assignment 6: Interest  = ' || v_interest);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 7: Reusing Variables to Track Progress
--------------------------------------------------------------------------------
DECLARE
  v_step  NUMBER := 0;
  v_label VARCHAR2(50);
BEGIN
  v_step  := v_step + 1;
  v_label := 'Step ' || v_step || ': Initialization complete.';
  DBMS_OUTPUT.PUT_LINE('Assignment 7: ' || v_label);

  v_step  := v_step + 1;
  v_label := 'Step ' || v_step || ': Validation complete.';
  DBMS_OUTPUT.PUT_LINE('Assignment 7: ' || v_label);

  v_step  := v_step + 1;
  v_label := 'Step ' || v_step || ': Processing complete.';
  DBMS_OUTPUT.PUT_LINE('Assignment 7: ' || v_label);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 8: Using BOOLEAN Flags for Conditional Messages
--------------------------------------------------------------------------------
DECLARE
  v_is_admin   BOOLEAN := TRUE;
  v_is_active  BOOLEAN := FALSE;
BEGIN
  IF v_is_admin THEN
    DBMS_OUTPUT.PUT_LINE('Assignment 8: User has admin rights.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Assignment 8: User is a normal user.');
  END IF;

  IF v_is_active THEN
    DBMS_OUTPUT.PUT_LINE('Assignment 8: User account is active.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Assignment 8: User account is inactive.');
  END IF;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 9: Combining String Variables into Messages
--------------------------------------------------------------------------------
DECLARE
  v_first_name VARCHAR2(30) := 'Avi';
  v_last_name  VARCHAR2(30) := 'Jha';
  v_full_name  VARCHAR2(60);
BEGIN
  v_full_name := v_first_name || ' ' || v_last_name;

  DBMS_OUTPUT.PUT_LINE('Assignment 9: Full Name = ' || v_full_name);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 10: Tracking Start and End Time in Variables
--------------------------------------------------------------------------------
DECLARE
  v_start_time DATE := SYSDATE;
  v_end_time   DATE;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Assignment 10: Process started at ' ||
                       TO_CHAR(v_start_time, 'HH24:MI:SS'));

  -- simulate some work by assigning end time to current SYSDATE again
  v_end_time := SYSDATE;

  DBMS_OUTPUT.PUT_LINE('Assignment 10: Process ended at   ' ||
                       TO_CHAR(v_end_time, 'HH24:MI:SS'));
END;
/
--------------------------------------------------------------------------------
