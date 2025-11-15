-- assignment_implicit_and_explicit_conversions.sql
-- Session : 017_implicit_and_explicit_conversions
-- Topic   : Practice - Implicit and Explicit Conversions

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Assignment 1: Implicit NUMBER to VARCHAR2
--------------------------------------------------------------------------------
DECLARE
  v_num NUMBER := 555;
  v_msg VARCHAR2(30);
BEGIN
  v_msg := 'Score = ' || v_num;
  DBMS_OUTPUT.PUT_LINE('A1: ' || v_msg);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 2: Explicit VARCHAR2 to NUMBER then calculation
--------------------------------------------------------------------------------
DECLARE
  v_text  VARCHAR2(20) := '4500';
  v_value NUMBER;
BEGIN
  v_value := TO_NUMBER(v_text);
  v_value := v_value + 500;
  DBMS_OUTPUT.PUT_LINE('A2: Final numeric value = ' || v_value);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 3: Explicit DATE conversion from string
--------------------------------------------------------------------------------
DECLARE
  v_date_text VARCHAR2(20) := '31-12-2025';
  v_date_val  DATE;
BEGIN
  v_date_val := TO_DATE(v_date_text, 'DD-MM-YYYY');
  DBMS_OUTPUT.PUT_LINE('A3: Date = ' || TO_CHAR(v_date_val, 'YYYY/MM/DD'));
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 4: Format date in different styles
--------------------------------------------------------------------------------
DECLARE
  v_d DATE := SYSDATE;
BEGIN
  DBMS_OUTPUT.PUT_LINE('A4: ISO format    = ' || TO_CHAR(v_d, 'YYYY-MM-DD'));
  DBMS_OUTPUT.PUT_LINE('A4: US format     = ' || TO_CHAR(v_d, 'MM/DD/YYYY'));
  DBMS_OUTPUT.PUT_LINE('A4: Time included = ' || TO_CHAR(v_d, 'DD-MON-YYYY HH24:MI'));
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 5: Explicit NUMBER to CHAR for padded output
--------------------------------------------------------------------------------
DECLARE
  v_num NUMBER := 42;
  v_str VARCHAR2(20);
BEGIN
  v_str := TO_CHAR(v_num, '0000'); -- padded with zeros
  DBMS_OUTPUT.PUT_LINE('A5: Padded value = ' || v_str);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 6: Avoid implicit conversion by always using TO_CHAR in concatenation
--------------------------------------------------------------------------------
DECLARE
  v_salary NUMBER := 72000;
BEGIN
  DBMS_OUTPUT.PUT_LINE('A6: Salary = ' || TO_CHAR(v_salary));
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 7: Handle invalid numeric conversion with exception
--------------------------------------------------------------------------------
DECLARE
  v_text VARCHAR2(10) := '99X';
  v_num  NUMBER;
BEGIN
  BEGIN
    v_num := TO_NUMBER(v_text);
    DBMS_OUTPUT.PUT_LINE('A7: Converted value = ' || v_num);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('A7: Conversion error: ' || SQLERRM);
  END;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 8: Convert string time to date and add one hour
--------------------------------------------------------------------------------
DECLARE
  v_time_text VARCHAR2(20) := '15-11-2025 10:30';
  v_time_val  DATE;
BEGIN
  v_time_val := TO_DATE(v_time_text, 'DD-MM-YYYY HH24:MI');
  v_time_val := v_time_val + (1/24);

  DBMS_OUTPUT.PUT_LINE('A8: New time = ' ||
                       TO_CHAR(v_time_val, 'DD-MM-YYYY HH24:MI'));
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 9: Convert date to fiscal year label
--------------------------------------------------------------------------------
DECLARE
  v_d      DATE := DATE '2025-04-01';
  v_year   VARCHAR2(9);
BEGIN
  v_year := TO_CHAR(v_d, 'YYYY') || '-' || TO_CHAR(v_d + 365, 'YY');
  DBMS_OUTPUT.PUT_LINE('A9: Fiscal year label = ' || v_year);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 10: Combine multiple conversions in one report line
--------------------------------------------------------------------------------
DECLARE
  v_amount_text VARCHAR2(20) := '123456.78';
  v_amount      NUMBER;
  v_date        DATE := SYSDATE;
BEGIN
  v_amount := TO_NUMBER(v_amount_text);

  DBMS_OUTPUT.PUT_LINE(
    'A10: Amount=' || TO_CHAR(v_amount, '999,999.99') ||
    ', Date=' || TO_CHAR(v_date, 'YYYY-MM-DD')
  );
END;
/
--------------------------------------------------------------------------------
