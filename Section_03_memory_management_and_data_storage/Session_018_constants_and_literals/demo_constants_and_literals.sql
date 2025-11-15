-- demo_constants_and_literals.sql
-- Session : 018_constants_and_literals
-- Topic   : Constants and Literal Values in PL/SQL.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Demo 1: Declaring Numeric and String Constants
--------------------------------------------------------------------------------
DECLARE
  c_app_name CONSTANT VARCHAR2(50) := 'PL/SQL Training App';
  c_tax_rate CONSTANT NUMBER       := 0.18;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 1: Application Name = ' || c_app_name);
  DBMS_OUTPUT.PUT_LINE('Demo 1: Tax Rate        = ' || c_tax_rate);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 2: Using Date Literals and Interval Literals
--------------------------------------------------------------------------------
DECLARE
  c_start_date CONSTANT DATE := DATE '2025-01-01';
  v_end_date   DATE;
BEGIN
  v_end_date := c_start_date + 30; -- add 30 days

  DBMS_OUTPUT.PUT_LINE('Demo 2: Start Date = ' ||
                       TO_CHAR(c_start_date, 'YYYY-MM-DD'));
  DBMS_OUTPUT.PUT_LINE('Demo 2: End Date   = ' ||
                       TO_CHAR(v_end_date, 'YYYY-MM-DD'));
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 3: Using Constants in Formulas
--------------------------------------------------------------------------------
DECLARE
  c_pi CONSTANT NUMBER := 3.14159;
  v_radius NUMBER := 7;
  v_area   NUMBER;
BEGIN
  v_area := c_pi * v_radius * v_radius;
  DBMS_OUTPUT.PUT_LINE('Demo 3: Radius = ' || v_radius);
  DBMS_OUTPUT.PUT_LINE('Demo 3: Area   = ' || v_area);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 4: Literal Notation for Strings and Escaping Quotes
--------------------------------------------------------------------------------
DECLARE
  v_msg1 VARCHAR2(100) := 'It''s a literal with single quote.';
  v_msg2 VARCHAR2(100) := q'[Using q-quote syntax: it's simpler]';
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 4: ' || v_msg1);
  DBMS_OUTPUT.PUT_LINE('Demo 4: ' || v_msg2);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 5: Using Constants to Avoid Magic Numbers
--------------------------------------------------------------------------------
DECLARE
  c_min_pass   CONSTANT NUMBER := 40;
  c_max_marks  CONSTANT NUMBER := 100;
  v_obtained   NUMBER := 78;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 5: Max marks = ' || c_max_marks);

  IF v_obtained >= c_min_pass THEN
    DBMS_OUTPUT.PUT_LINE('Demo 5: Result = Pass (' || v_obtained || ')');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Demo 5: Result = Fail (' || v_obtained || ')');
  END IF;
END;
/
--------------------------------------------------------------------------------
