-- demo_020_conditional_branching_fundamentals.sql
-- Session : 020_conditional_branching_fundamentals
-- Topic   : Conditional Branching Fundamentals (IF, IF-ELSE, IF-ELSIF)
-- Purpose : Learn how to control execution flow based on simple conditions.
-- Style   : 5 demo examples with detailed explanations and comments.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Demo 1: Basic IF condition (single branch)
-- Concept:
--   Execute a block of statements only when a condition is TRUE.
--------------------------------------------------------------------------------
DECLARE
  v_score NUMBER := 85;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 1: Basic IF condition');
  DBMS_OUTPUT.PUT_LINE('  Input score = ' || v_score);

  IF v_score >= 80 THEN
    DBMS_OUTPUT.PUT_LINE('  Result      = High performer (>= 80).');
  END IF;

  DBMS_OUTPUT.PUT_LINE('  End of Demo 1 block.');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 2: IF ... ELSE (two-way decision)
-- Concept:
--   Choose between two mutually exclusive paths:
--   - TRUE branch (condition met)
--   - ELSE branch (condition not met)
--------------------------------------------------------------------------------
DECLARE
  v_attendance_pct NUMBER := 68;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 2: IF ... ELSE');
  DBMS_OUTPUT.PUT_LINE('  Attendance = ' || v_attendance_pct || '%');

  IF v_attendance_pct >= 75 THEN
    DBMS_OUTPUT.PUT_LINE('  Status     = Eligible for exam.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('  Status     = Not eligible (attendance < 75%).');
  END IF;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 3: IF ... ELSIF ... ELSE (multi-level decision)
-- Concept:
--   Support more than two outcomes using ELSIF.
--   First TRUE condition wins and remaining branches are skipped.
--------------------------------------------------------------------------------
DECLARE
  v_marks NUMBER := 56;
  v_grade VARCHAR2(2);
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 3: IF ... ELSIF ... ELSE (grading)');
  DBMS_OUTPUT.PUT_LINE('  Marks = ' || v_marks);

  IF v_marks >= 80 THEN
    v_grade := 'A';
  ELSIF v_marks >= 60 THEN
    v_grade := 'B';
  ELSIF v_marks >= 50 THEN
    v_grade := 'C';
  ELSE
    v_grade := 'D';
  END IF;

  DBMS_OUTPUT.PUT_LINE('  Derived Grade = ' || v_grade);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 4: Nested IF statements (IF inside IF)
-- Concept:
--   Combine multiple related checks by nesting IF blocks.
--------------------------------------------------------------------------------
DECLARE
  v_country   VARCHAR2(20) := 'India';
  v_age       NUMBER       := 19;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 4: Nested IF');
  DBMS_OUTPUT.PUT_LINE('  Country = ' || v_country);
  DBMS_OUTPUT.PUT_LINE('  Age     = ' || v_age);

  IF v_country = 'India' THEN
    DBMS_OUTPUT.PUT_LINE('  Inside first IF: Country is India.');

    IF v_age >= 18 THEN
      DBMS_OUTPUT.PUT_LINE('  Nested IF: Eligible to vote in India.');
    ELSE
      DBMS_OUTPUT.PUT_LINE('  Nested IF: Not eligible to vote (age < 18).');
    END IF;
  ELSE
    DBMS_OUTPUT.PUT_LINE('  Country is not India, using different rules.');
  END IF;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 5: Using Boolean expressions and BETWEEN/IN operators
-- Concept:
--   Combine comparison operators and use BETWEEN / IN for cleaner conditions.
--------------------------------------------------------------------------------
DECLARE
  v_experience_years NUMBER := 4;
  v_role             VARCHAR2(20) := 'Developer';
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 5: Boolean expressions with BETWEEN / IN');
  DBMS_OUTPUT.PUT_LINE('  Experience (years) = ' || v_experience_years);
  DBMS_OUTPUT.PUT_LINE('  Role               = ' || v_role);

  IF v_experience_years BETWEEN 0 AND 2 THEN
    DBMS_OUTPUT.PUT_LINE('  Level = Junior');
  ELSIF v_experience_years BETWEEN 3 AND 6 THEN
    DBMS_OUTPUT.PUT_LINE('  Level = Mid-level');
  ELSE
    DBMS_OUTPUT.PUT_LINE('  Level = Senior');
  END IF;

  IF v_role IN ('Developer', 'DBA', 'Tester') THEN
    DBMS_OUTPUT.PUT_LINE('  Category = Technical contributor');
  ELSE
    DBMS_OUTPUT.PUT_LINE('  Category = Non-technical / Other');
  END IF;
END;
/
--------------------------------------------------------------------------------
