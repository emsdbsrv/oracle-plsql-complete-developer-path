-- demo_plsql_language_overview.sql
-- Topic   : PL/SQL Language Overview
-- Purpose : Demonstrate the basic structure and syntax of PL/SQL blocks
--           using small, focused examples.
-- Focus   : DECLARE section, variables, constants, expressions, BOOLEAN,
--           IF condition and DBMS_OUTPUT usage.

SET SERVEROUTPUT ON;



--------------------------------------------------------------------------------
-- Demo 1: Minimal Anonymous PL/SQL Block
-- Goal:
--   Understand the basic structure of a PL/SQL block:
--   [DECLARE] (optional)
--   BEGIN
--      executable statements
--   EXCEPTION (optional)
--      exception-handling statements
--   END;
--------------------------------------------------------------------------------
BEGIN
  -- DBMS_OUTPUT.PUT_LINE prints text to the output buffer so we can see it
  -- in tools like SQL*Plus, SQLcl or SQL Developer when SERVEROUTPUT is ON.
  DBMS_OUTPUT.PUT_LINE('Demo 1: Basic PL/SQL block executed successfully.');
  DBMS_OUTPUT.PUT_LINE('This is the simplest possible PL/SQL block.');
END;
/
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Demo 2: DECLARE Section and Simple VARCHAR2 Variable
-- Goal:
--   Learn how to:
--   1. Declare a variable in the DECLARE section.
--   2. Initialize the variable with a default value.
--   3. Concatenate strings and print them.
--------------------------------------------------------------------------------
DECLARE
  -- v_student_name is a VARCHAR2 variable that can hold a string up to 50 chars.
  v_student_name VARCHAR2(50) := 'Avi Jha';
BEGIN
  -- Here we are concatenating the label text with the variable using || operator.
  DBMS_OUTPUT.PUT_LINE('Demo 2: Student Name = ' || v_student_name);

  -- You can also assign a new value to the same variable later in the block.
  v_student_name := 'Oracle PL/SQL Learner';
  DBMS_OUTPUT.PUT_LINE('Demo 2 (updated): Student Name = ' || v_student_name);
END;
/
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Demo 3: Numeric Variables and Arithmetic Expressions
-- Goal:
--   Learn how to:
--   1. Declare NUMBER variables.
--   2. Perform arithmetic operations (multiplication, addition).
--   3. Store intermediate results in another variable.
--------------------------------------------------------------------------------
DECLARE
  v_price  NUMBER := 1200;   -- base price of a product
  v_tax    NUMBER := 0.18;   -- 18% tax rate
  v_total  NUMBER;           -- to store final price including tax
BEGIN
  -- First calculate tax amount: v_price * v_tax
  -- Then add this tax to the original price.
  v_total := v_price + (v_price * v_tax);

  DBMS_OUTPUT.PUT_LINE('Demo 3: Base Price             = ' || v_price);
  DBMS_OUTPUT.PUT_LINE('Demo 3: Tax Rate               = ' || v_tax);
  DBMS_OUTPUT.PUT_LINE('Demo 3: Total Price (Incl Tax) = ' || v_total);
END;
/
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Demo 4: CONSTANT Keyword and Using It in a Formula
-- Goal:
--   Learn how to:
--   1. Declare a constant using CONSTANT.
--   2. Use the constant in multiple expressions.
--   3. Understand why constants are useful (value cannot be changed).
--------------------------------------------------------------------------------
DECLARE
  -- c_pi is a constant. Once assigned, its value cannot be changed.
  c_pi CONSTANT NUMBER := 3.14159;

  v_radius NUMBER := 5;  -- radius of a circle
  v_area   NUMBER;       -- to store the computed area
BEGIN
  -- Formula for area of a circle = π * r^2
  v_area := c_pi * v_radius * v_radius;

  DBMS_OUTPUT.PUT_LINE('Demo 4: Radius of Circle   = ' || v_radius);
  DBMS_OUTPUT.PUT_LINE('Demo 4: PI (Constant)      = ' || c_pi);
  DBMS_OUTPUT.PUT_LINE('Demo 4: Area of Circle     = ' || v_area);
END;
/
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Demo 5: BOOLEAN Variables and IF Condition
-- Goal:
--   Learn how to:
--   1. Declare a BOOLEAN variable.
--   2. Use IF-THEN-ELSE in PL/SQL.
-- Note:
--   - BOOLEAN is only available inside PL/SQL (not in SQL).
--------------------------------------------------------------------------------
DECLARE
  v_is_active BOOLEAN := TRUE;    -- This can be TRUE, FALSE, or NULL.
BEGIN
  -- IF condition checks the BOOLEAN variable.
  IF v_is_active THEN
    DBMS_OUTPUT.PUT_LINE('Demo 5: Status = Active');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Demo 5: Status = Inactive');
  END IF;

  -- We can change the BOOLEAN value and check again.
  v_is_active := FALSE;

  IF v_is_active THEN
    DBMS_OUTPUT.PUT_LINE('Demo 5 (after change): Status = Active');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Demo 5 (after change): Status = Inactive');
  END IF;
END;
/
--------------------------------------------------------------------------------
