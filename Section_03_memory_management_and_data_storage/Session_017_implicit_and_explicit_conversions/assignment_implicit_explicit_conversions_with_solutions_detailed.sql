-- Script: assignment_implicit_explicit_conversions_with_solutions_detailed.sql
-- Session: 017 - Implicit and Explicit Conversions
-- Purpose: 10 detailed questions with complete, runnable answers.
-- Notes  : Run in a safe training schema. You can execute each Q/A block independently.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Q1 (Basics) – Print a number and a date using explicit formats.
-- Question:
--   Print the number 1234567.8 with thousands separators and 2 decimals,
--   and print today's date as DD-MON-YYYY.
-- Answer:
--------------------------------------------------------------------------------
DECLARE
  v_num NUMBER := 1234567.8;
  v_dt  DATE   := SYSDATE;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Number  : ' || TO_CHAR(v_num, 'FM9G999G999D00', 'NLS_NUMERIC_CHARACTERS=.,'));
  DBMS_OUTPUT.PUT_LINE('Today   : ' || TO_CHAR(v_dt,  'DD-MON-YYYY'));
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q2 (Implicit vs Explicit) – Show both conversions NUMBER -> VARCHAR2.
-- Question:
--   Demonstrate one implicit conversion and one explicit conversion for NUMBER->VARCHAR2.
-- Answer:
--------------------------------------------------------------------------------
DECLARE
  v_num NUMBER := 4321.5;
  v_txt VARCHAR2(50);
BEGIN
  -- Implicit (NLS-dependent; not recommended for production readability)
  v_txt := v_num;
  DBMS_OUTPUT.PUT_LINE('Implicit NUMBER->VARCHAR2: ' || v_txt);

  -- Explicit
  DBMS_OUTPUT.PUT_LINE('Explicit NUMBER->VARCHAR2: ' || TO_CHAR(v_num, 'FM9990D00', 'NLS_NUMERIC_CHARACTERS=.,'));
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q3 (TO_NUMBER + NLS) – Parse EU-style number.
-- Question:
--   Convert the text '1.234,50' to a NUMBER assuming comma is decimal and dot is thousands.
-- Answer:
--------------------------------------------------------------------------------
DECLARE
  v_eu VARCHAR2(20) := '1.234,50';
  n NUMBER;
BEGIN
  n := TO_NUMBER(v_eu, '9G999D99', 'NLS_NUMERIC_CHARACTERS=,.');
  DBMS_OUTPUT.PUT_LINE('Parsed EU number = ' || n);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q4 (TO_DATE) – Parse text into DATE and reformat.
-- Question:
--   Parse '2025-11-06 17:45:00' as DATE and print as '06-NOV-2025 17:45'.
-- Answer:
--------------------------------------------------------------------------------
DECLARE
  d DATE;
BEGIN
  d := TO_DATE('2025-11-06 17:45:00', 'YYYY-MM-DD HH24:MI:SS');
  DBMS_OUTPUT.PUT_LINE(TO_CHAR(d, 'DD-MON-YYYY HH24:MI'));
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q5 (Error Handling) – Handle invalid numeric conversion.
-- Question:
--   Convert 'abc' to NUMBER and handle the error gracefully, printing SQLERRM.
-- Answer:
--------------------------------------------------------------------------------
DECLARE
  v_txt VARCHAR2(10) := 'abc';
  n NUMBER;
BEGIN
  BEGIN
    n := TO_NUMBER(v_txt);
    DBMS_OUTPUT.PUT_LINE('Converted: ' || n);
  EXCEPTION
    WHEN VALUE_ERROR THEN
      DBMS_OUTPUT.PUT_LINE('Handled VALUE_ERROR: ' || SQLERRM);
  END;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q6 (Predicate Best Practice) – Convert input, not column.
-- Question:
--   Given an indexed VARCHAR2 column emp_code, demonstrate the correct predicate
--   to compare a NUMBER bind value without disabling the index.
-- Answer:
--   We will print the anti-pattern and the correct pattern.
--------------------------------------------------------------------------------
DECLARE
  v_bad VARCHAR2(200) := 'WHERE TO_NUMBER(emp_code) = :b1';
  v_ok  VARCHAR2(200) := 'WHERE emp_code = TO_CHAR(:b1)';
BEGIN
  DBMS_OUTPUT.PUT_LINE('Anti-pattern : ' || v_bad);
  DBMS_OUTPUT.PUT_LINE('Best practice: ' || v_ok);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q7 (Date Math) – Add 7 days.
-- Question:
--   Convert '06-11-2025' to DATE, add 7 days, and print both dates in DD-MON-YYYY.
-- Answer:
--------------------------------------------------------------------------------
DECLARE
  d1 DATE := TO_DATE('06-11-2025', 'DD-MM-YYYY');
  d2 DATE;
BEGIN
  d2 := d1 + 7;
  DBMS_OUTPUT.PUT_LINE('Original: ' || TO_CHAR(d1, 'DD-MON-YYYY'));
  DBMS_OUTPUT.PUT_LINE('Plus 7  : ' || TO_CHAR(d2, 'DD-MON-YYYY'));
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q8 (Format Model) – Locale-stable formatting.
-- Question:
--   Print 1234567.8 as '1,234,567.80' regardless of NLS settings.
-- Answer:
--------------------------------------------------------------------------------
DECLARE
  v NUMBER := 1234567.8;
BEGIN
  DBMS_OUTPUT.PUT_LINE(
    TO_CHAR(v, 'FM9G999G999D00', 'NLS_NUMERIC_CHARACTERS=.,')
  );
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q9 (TO_TIMESTAMP) – ISO-8601 output.
-- Question:
--   Convert '2025/11/06 18:20:33' to TIMESTAMP and print it as ISO-8601 'YYYY-MM-DD""T""HH24:MI:SS'.
-- Answer:
--------------------------------------------------------------------------------
DECLARE
  t TIMESTAMP;
BEGIN
  t := TO_TIMESTAMP('2025/11/06 18:20:33', 'YYYY/MM/DD HH24:MI:SS');
  DBMS_OUTPUT.PUT_LINE(TO_CHAR(t, 'YYYY-MM-DD"T"HH24:MI:SS'));
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q10 (End-to-end) – Clean and parse currency-like text.
-- Question:
--   Given the text 'Rs 1,25,000.50', extract the numeric portion and convert it
--   to NUMBER 125000.50, then display the value with grouping and 2 decimals.
-- Answer:
--------------------------------------------------------------------------------
DECLARE
  v_txt   VARCHAR2(30) := 'Rs 1,25,000.50';
  v_clean VARCHAR2(30);
  n       NUMBER;
BEGIN
  -- Remove non-digit, non-separator characters
  v_clean := REGEXP_REPLACE(v_txt, '[^0-9,.-]', '');
  -- Parse using Indian-style grouping (comma group sep, dot decimal)
  n := TO_NUMBER(v_clean, '9G99G999D99', 'NLS_NUMERIC_CHARACTERS=.,');
  DBMS_OUTPUT.PUT_LINE('Parsed    = ' || n);
  DBMS_OUTPUT.PUT_LINE('Formatted = ' || TO_CHAR(n, 'FM9G99G999D99', 'NLS_NUMERIC_CHARACTERS=.,'));
END;
/
--------------------------------------------------------------------------------
-- End of Assignment (Detailed Questions + Complete Answers)
--------------------------------------------------------------------------------
