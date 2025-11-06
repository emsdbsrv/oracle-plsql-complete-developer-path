-- Script: plsql_inline_documentation.sql
-- Session: 014 - Inline Documentation Best Practices
-- Purpose: Demonstrate professional commenting and documentation styles.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Example 1: Single-Line Comments
-- Concept : Use '--' for short explanations.
--------------------------------------------------------------------------------
BEGIN
  -- Print welcome message
  DBMS_OUTPUT.PUT_LINE('Starting documentation demo...');
  -- Print a result
  DBMS_OUTPUT.PUT_LINE('10 * 2 = ' || (10 * 2));
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 2: Multi-Line Comments for Detailed Notes
-- Concept : Use /* ... */ for descriptive explanations.
--------------------------------------------------------------------------------
/*
  This block demonstrates multi-line comments.
  The script calculates the final price after tax.
*/
DECLARE
  v_price NUMBER := 200;
  v_tax   NUMBER := 0.18;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Final price = ' || (v_price + (v_price * v_tax)));
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 3: Header Template Example
-- Concept : Include metadata header in every PL/SQL script.
--------------------------------------------------------------------------------
/*************************************************************
 Script : calc_discount.sql
 Author : Avishesh Jha
 Purpose: Apply 10% discount on total price.
 Date   : 06-Nov-2025
*************************************************************/
DECLARE
  v_total NUMBER := 1000;
  v_discount NUMBER;
BEGIN
  -- Apply discount
  v_discount := v_total * 0.10;
  DBMS_OUTPUT.PUT_LINE('Discount = ' || v_discount);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 4: Section Markers for Readability
-- Concept : Use comments to sectionize code.
--------------------------------------------------------------------------------
DECLARE
  v_base NUMBER := 50;
  v_factor NUMBER := 3;
  v_result NUMBER;
BEGIN
  -- SECTION 1: Multiplication
  v_result := v_base * v_factor;
  DBMS_OUTPUT.PUT_LINE('Result = ' || v_result);

  -- SECTION 2: Verification
  IF v_result > 100 THEN
    DBMS_OUTPUT.PUT_LINE('Result exceeds threshold.');
  END IF;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 5: Nested Comments and Exception Notes
-- Concept : Explain both main and inner blocks clearly.
--------------------------------------------------------------------------------
DECLARE
  v_a NUMBER := 10;
  v_b NUMBER := 0;
  v_c NUMBER;
BEGIN
  -- Outer block
  DBMS_OUTPUT.PUT_LINE('Outer block started.');
  BEGIN
    -- Inner block performing risky division
    v_c := v_a / v_b;
    DBMS_OUTPUT.PUT_LINE('Result = ' || v_c);
  EXCEPTION
    WHEN ZERO_DIVIDE THEN
      DBMS_OUTPUT.PUT_LINE('Error: Division by zero in inner block.');
  END;
  DBMS_OUTPUT.PUT_LINE('Outer block completed.');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 6: Comment Template for Procedures
-- Concept : Follow enterprise documentation pattern.
--------------------------------------------------------------------------------
/***************************************************************
 Procedure : log_activity
 Purpose   : Insert activity logs for debugging
 Input     : p_action VARCHAR2
 Author    : Developer Team
 Date      : 06-Nov-2025
***************************************************************/
CREATE OR REPLACE PROCEDURE log_activity(p_action VARCHAR2) AS
BEGIN
  DBMS_OUTPUT.PUT_LINE('Activity Logged: ' || p_action);
END;
/
--------------------------------------------------------------------------------
-- End of File
--------------------------------------------------------------------------------
