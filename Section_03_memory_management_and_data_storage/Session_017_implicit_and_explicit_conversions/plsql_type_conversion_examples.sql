-- Script: plsql_type_conversion_examples.sql
-- Session: 017 - Implicit and Explicit Conversions
-- Purpose: Show safe and predictable type conversions in PL/SQL & SQL

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Example 1: Implicit conversion (NUMBER -> VARCHAR2) and why to avoid relying on it
--------------------------------------------------------------------------------
DECLARE
  v_num NUMBER := 1234.5;
  v_txt VARCHAR2(50);
BEGIN
  -- Implicit conversion (allowed but NLS-dependent)
  v_txt := v_num;
  DBMS_OUTPUT.PUT_LINE('Implicit NUMBER->VARCHAR2: ' || v_txt);

  -- Preferred: Explicit control with TO_CHAR and format
  DBMS_OUTPUT.PUT_LINE('Explicit NUMBER->VARCHAR2: ' || TO_CHAR(v_num, 'FM9990D00'));
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 2: TO_CHAR for NUMBER and DATE with format models
--------------------------------------------------------------------------------
DECLARE
  v_num NUMBER := 98765.432;
  v_dt  DATE   := DATE '2025-11-06';
BEGIN
  DBMS_OUTPUT.PUT_LINE('TO_CHAR(NUMBER): ' || TO_CHAR(v_num, 'FM999G999D000'));
  DBMS_OUTPUT.PUT_LINE('TO_CHAR(DATE)  : ' || TO_CHAR(v_dt, 'DD-MON-YYYY HH24:MI:SS'));
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 3: TO_NUMBER with format and NLS parameter string
--------------------------------------------------------------------------------
DECLARE
  v_txt_en VARCHAR2(20) := '1,234.50'; -- US style
  v_txt_eu VARCHAR2(20) := '1.234,50'; -- EU style
  n1 NUMBER;
  n2 NUMBER;
BEGIN
  n1 := TO_NUMBER(v_txt_en, '9G999D99', 'NLS_NUMERIC_CHARACTERS=.,');
  n2 := TO_NUMBER(v_txt_eu, '9G999D99', 'NLS_NUMERIC_CHARACTERS=,.');
  DBMS_OUTPUT.PUT_LINE('US parsed  : ' || n1);
  DBMS_OUTPUT.PUT_LINE('EU parsed  : ' || n2);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 4: TO_DATE with varying formats and validation
--------------------------------------------------------------------------------
DECLARE
  v_txt1 VARCHAR2(20) := '06-11-2025';
  v_txt2 VARCHAR2(20) := '2025/11/06 17:30:00';
  d1 DATE;
  d2 DATE;
BEGIN
  d1 := TO_DATE(v_txt1, 'DD-MM-YYYY');
  d2 := TO_DATE(v_txt2, 'YYYY/MM/DD HH24:MI:SS');
  DBMS_OUTPUT.PUT_LINE('d1: ' || TO_CHAR(d1, 'DD-MON-YYYY'));
  DBMS_OUTPUT.PUT_LINE('d2: ' || TO_CHAR(d2, 'DD-MON-YYYY HH24:MI:SS'));
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 5: Handling invalid conversions with EXCEPTION blocks
--------------------------------------------------------------------------------
DECLARE
  v_bad_txt VARCHAR2(20) := 'NOT_A_NUMBER';
  n NUMBER;
BEGIN
  BEGIN
    n := TO_NUMBER(v_bad_txt);
    DBMS_OUTPUT.PUT_LINE('Converted: ' || n);
  EXCEPTION
    WHEN VALUE_ERROR THEN
      DBMS_OUTPUT.PUT_LINE('Handled VALUE_ERROR: invalid numeric text -> ' || v_bad_txt);
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Unhandled conversion error: ' || SQLERRM);
  END;

  BEGIN
    -- Bad date text versus expected format
    DBMS_OUTPUT.PUT_LINE( TO_CHAR( TO_DATE('31/02/2025', 'DD/MM/YYYY'), 'DD-MON-YYYY') );
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Date conversion failed: ' || SQLERRM);
  END;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 6: Predicates & performance — convert the input, not the column
--------------------------------------------------------------------------------
-- Bad pattern (may disable index on emp_no if it's a VARCHAR2 column):
--   WHERE TO_NUMBER(emp_no) = 12345
-- Good pattern: convert the bind/input to the column's type
--   WHERE emp_no = TO_CHAR(:emp_no_num)
-- Below is a simple illustration (no table needed to run the block):
DECLARE
  v_emp_no_num NUMBER := 12345;
  v_clause_bad VARCHAR2(100) := 'WHERE TO_NUMBER(emp_no) = :b1';
  v_clause_ok  VARCHAR2(100) := 'WHERE emp_no = TO_CHAR(:b1)';
BEGIN
  DBMS_OUTPUT.PUT_LINE('Anti-pattern : ' || v_clause_bad);
  DBMS_OUTPUT.PUT_LINE('Best practice: ' || v_clause_ok);
END;
/
--------------------------------------------------------------------------------
-- End of File
--------------------------------------------------------------------------------
