-- Script: plsql_first_application.sql
-- Session: 011 - Building Your First Application
-- Purpose : Step-by-step PL/SQL progression from basic to intermediate applications

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Example 1: The Simplest PL/SQL Program
-- Concept : Minimal BEGIN–END block with DBMS_OUTPUT.
--------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('Hello, PL/SQL World!');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 2: Declaring Variables and Performing Arithmetic
-- Concept : Introduces DECLARE and variable operations.
--------------------------------------------------------------------------------
DECLARE
  v_a NUMBER := 25;
  v_b NUMBER := 40;
  v_total NUMBER;
BEGIN
  v_total := v_a + v_b;
  DBMS_OUTPUT.PUT_LINE('Sum of ' || v_a || ' and ' || v_b || ' = ' || v_total);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 3: Using IF–ELSE Conditions for Logic
-- Concept : Shows how PL/SQL handles decision making.
--------------------------------------------------------------------------------
DECLARE
  v_score NUMBER := 83;
  v_result VARCHAR2(10);
BEGIN
  IF v_score >= 90 THEN
    v_result := 'Excellent';
  ELSIF v_score >= 70 THEN
    v_result := 'Good';
  ELSIF v_score >= 50 THEN
    v_result := 'Average';
  ELSE
    v_result := 'Fail';
  END IF;

  DBMS_OUTPUT.PUT_LINE('Score: ' || v_score || ' → Result: ' || v_result);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 4: Using FOR Loop
-- Concept : Looping construct that repeats logic n times.
--------------------------------------------------------------------------------
BEGIN
  FOR i IN 1..5 LOOP
    DBMS_OUTPUT.PUT_LINE('Processing record number: ' || i);
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 5: Integrating SQL Operations with PL/SQL
-- Concept : Create, insert, and update data dynamically.
--------------------------------------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE IF EXISTS student_info';
EXCEPTION
  WHEN OTHERS THEN
    NULL;
END;
/
CREATE TABLE student_info (
  id NUMBER PRIMARY KEY,
  name VARCHAR2(50),
  marks NUMBER,
  grade VARCHAR2(5)
);
BEGIN
  INSERT INTO student_info VALUES (1, 'John', 91, NULL);
  INSERT INTO student_info VALUES (2, 'Mary', 68, NULL);
  INSERT INTO student_info VALUES (3, 'Raj', 47, NULL);

  FOR rec IN (SELECT id, marks FROM student_info) LOOP
    UPDATE student_info
       SET grade = CASE
                     WHEN rec.marks >= 90 THEN 'A'
                     WHEN rec.marks >= 70 THEN 'B'
                     WHEN rec.marks >= 50 THEN 'C'
                     ELSE 'F'
                   END
     WHERE id = rec.id;
  END LOOP;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Grades assigned successfully.');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 6: Exception Handling with NO_DATA_FOUND
-- Concept : Catch errors gracefully and provide user feedback.
--------------------------------------------------------------------------------
DECLARE
  v_student_name VARCHAR2(50);
BEGIN
  SELECT name INTO v_student_name FROM student_info WHERE id = 10;
  DBMS_OUTPUT.PUT_LINE('Found: ' || v_student_name);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('No record found for the given ID.');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 7: Nested Blocks and Scope
-- Concept : Demonstrates how nested BEGIN–END sections work.
--------------------------------------------------------------------------------
DECLARE
  v_text VARCHAR2(30) := 'Outer Scope';
BEGIN
  DBMS_OUTPUT.PUT_LINE(v_text);
  DECLARE
    v_text VARCHAR2(30) := 'Inner Scope';
  BEGIN
    DBMS_OUTPUT.PUT_LINE(v_text);
  END;
  DBMS_OUTPUT.PUT_LINE('Returning to → ' || v_text);
END;
/
--------------------------------------------------------------------------------
-- End of File
--------------------------------------------------------------------------------
