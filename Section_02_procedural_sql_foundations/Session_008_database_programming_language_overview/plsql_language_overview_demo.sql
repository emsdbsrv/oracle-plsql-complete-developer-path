-- Demo Script: plsql_language_overview_demo.sql
-- Objective: Understand PL/SQL structure and syntax basics

SET SERVEROUTPUT ON;

BEGIN
  DBMS_OUTPUT.PUT_LINE('Welcome to the Oracle PL/SQL Developer Path!');
  DBMS_OUTPUT.PUT_LINE('This block demonstrates basic PL/SQL execution.');
END;
/

-- Example with variable declaration
DECLARE
  v_course_name VARCHAR2(50) := 'PL/SQL Complete Developer Path';
BEGIN
  DBMS_OUTPUT.PUT_LINE('Current Course: ' || v_course_name);
END;
/

-- Example with simple calculation
DECLARE
  v_salary NUMBER := 60000;
  v_bonus  NUMBER;
BEGIN
  v_bonus := v_salary * 0.10;
  DBMS_OUTPUT.PUT_LINE('Calculated Bonus: ' || v_bonus);
END;
/