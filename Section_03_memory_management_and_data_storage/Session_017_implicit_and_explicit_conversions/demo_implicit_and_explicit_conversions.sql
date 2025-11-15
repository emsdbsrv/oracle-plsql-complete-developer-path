-- demo_implicit_and_explicit_conversions.sql
-- Session : 017_implicit_and_explicit_conversions
-- Topic   : Implicit and Explicit Conversions in PL/SQL.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Demo 1: Implicit Conversion in String Concatenation
--------------------------------------------------------------------------------
DECLARE
  v_number NUMBER := 123;
  v_text   VARCHAR2(50);
BEGIN
  -- NUMBER is implicitly converted to VARCHAR2 during concatenation.
  v_text := 'Value is ' || v_number;
  DBMS_OUTPUT.PUT_LINE('Demo 1: ' || v_text);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 2: Explicit Conversion NUMBER <-> VARCHAR2
--------------------------------------------------------------------------------
DECLARE
  v_num NUMBER        := 98765;
  v_str VARCHAR2(20);
BEGIN
  v_str := TO_CHAR(v_num, '999,999');
  DBMS_OUTPUT.PUT_LINE('Demo 2: Formatted number = ' || v_str);

  v_num := TO_NUMBER('12345');
  DBMS_OUTPUT.PUT_LINE('Demo 2: String to number = ' || v_num);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 3: Explicit Conversion VARCHAR2 -> DATE
--------------------------------------------------------------------------------
DECLARE
  v_date_text VARCHAR2(20) := '2025-11-15';
  v_date_val  DATE;
BEGIN
  v_date_val := TO_DATE(v_date_text, 'YYYY-MM-DD');
  DBMS_OUTPUT.PUT_LINE('Demo 3: Date value = ' || TO_CHAR(v_date_val, 'DD-MON-YYYY'));
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 4: Explicit Conversion DATE -> VARCHAR2 with Custom Format
--------------------------------------------------------------------------------
DECLARE
  v_today DATE := SYSDATE;
  v_display VARCHAR2(50);
BEGIN
  v_display := TO_CHAR(v_today, 'Day, DD-Mon-YYYY HH24:MI:SS');
  DBMS_OUTPUT.PUT_LINE('Demo 4: Today = ' || v_display);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 5: Handling Conversion Errors Safely with Exception Block
--------------------------------------------------------------------------------
DECLARE
  v_text VARCHAR2(10) := 'ABC';
  v_num  NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 5: Attempting TO_NUMBER on non-numeric text.');

  BEGIN
    v_num := TO_NUMBER(v_text);
    DBMS_OUTPUT.PUT_LINE('Demo 5: Converted value = ' || v_num);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Demo 5: Conversion failed: ' || SQLERRM);
  END;
END;
/
--------------------------------------------------------------------------------
