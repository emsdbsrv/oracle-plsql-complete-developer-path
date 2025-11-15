-- demo_declaring_and_initializing_variables.sql
-- Session : 013_declaring_and_initializing_variables
-- Topic   : Declaring and Initializing Variables in PL/SQL
-- Purpose : Show multiple ways to declare, initialize, and use variables.
--           Style aligned with Session_010 (execution block framework).
-- Focus   : Default values, delayed assignment, NOT NULL, %TYPE, simple checks.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Demo 1: Basic Declarations with Immediate Initialization
--------------------------------------------------------------------------------
DECLARE
  v_course_name   VARCHAR2(100) := 'Oracle PL/SQL Complete Developer Path';
  v_batch_number  NUMBER        := 1;
  v_is_active     BOOLEAN       := TRUE;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 1: Basic variable declarations and initial values');
  DBMS_OUTPUT.PUT_LINE('  Course Name  = ' || v_course_name);
  DBMS_OUTPUT.PUT_LINE('  Batch Number = ' || v_batch_number);

  IF v_is_active THEN
    DBMS_OUTPUT.PUT_LINE('  Status       = Active');
  ELSE
    DBMS_OUTPUT.PUT_LINE('  Status       = Inactive');
  END IF;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 2: Declaration First, Assignment Later (Two-Step Initialization)
--------------------------------------------------------------------------------
DECLARE
  v_student_name  VARCHAR2(50);  -- declaration without initial value
  v_total_marks   NUMBER;        -- will be assigned later
BEGIN
  -- Initialization after declaration (for example, computed or fetched)
  v_student_name := 'Sample Student';
  v_total_marks  := 92;

  DBMS_OUTPUT.PUT_LINE('Demo 2: Two-step initialization');
  DBMS_OUTPUT.PUT_LINE('  Student Name = ' || v_student_name);
  DBMS_OUTPUT.PUT_LINE('  Total Marks  = ' || v_total_marks);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 3: Using NOT NULL with Default Values
--------------------------------------------------------------------------------
DECLARE
  v_min_passing_marks NUMBER NOT NULL := 40;
  v_obtained_marks    NUMBER          := 65;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 3: NOT NULL variable with default');
  DBMS_OUTPUT.PUT_LINE('  Passing Marks = ' || v_min_passing_marks);
  DBMS_OUTPUT.PUT_LINE('  Obtained      = ' || v_obtained_marks);

  IF v_obtained_marks >= v_min_passing_marks THEN
    DBMS_OUTPUT.PUT_LINE('  Result        = PASS');
  ELSE
    DBMS_OUTPUT.PUT_LINE('  Result        = FAIL');
  END IF;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 4: Anchored Declarations Using %TYPE
--------------------------------------------------------------------------------
-- Supporting object for %TYPE demonstration
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE s013_demo_scores';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN RAISE; END IF;
END;
/
CREATE TABLE s013_demo_scores
(
  student_id NUMBER       PRIMARY KEY,
  score      NUMBER(5,2),
  grade      VARCHAR2(2)
);
/
INSERT INTO s013_demo_scores VALUES (1, 88.50, 'A');
COMMIT;
--------------------------------------------------------------------------------
DECLARE
  v_student_id s013_demo_scores.student_id%TYPE;
  v_score      s013_demo_scores.score%TYPE;
  v_grade      s013_demo_scores.grade%TYPE;
BEGIN
  SELECT student_id, score, grade
    INTO v_student_id, v_score, v_grade
    FROM s013_demo_scores
   WHERE student_id = 1;

  DBMS_OUTPUT.PUT_LINE('Demo 4: Variables declared with %TYPE');
  DBMS_OUTPUT.PUT_LINE('  Student ID = ' || v_student_id);
  DBMS_OUTPUT.PUT_LINE('  Score      = ' || v_score);
  DBMS_OUTPUT.PUT_LINE('  Grade      = ' || v_grade);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 5: Reusing and Reassigning Variables in a Block
--------------------------------------------------------------------------------
DECLARE
  v_counter NUMBER := 0;
  v_message VARCHAR2(100);
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 5: Reassigning variable values');

  v_counter := v_counter + 1;
  v_message := 'Iteration ' || v_counter;
  DBMS_OUTPUT.PUT_LINE('  ' || v_message);

  v_counter := v_counter + 1;
  v_message := 'Iteration ' || v_counter;
  DBMS_OUTPUT.PUT_LINE('  ' || v_message);

  v_counter := v_counter + 1;
  v_message := 'Iteration ' || v_counter;
  DBMS_OUTPUT.PUT_LINE('  ' || v_message);
END;
/
--------------------------------------------------------------------------------
