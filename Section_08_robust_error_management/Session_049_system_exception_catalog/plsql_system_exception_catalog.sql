-- Script: plsql_system_exception_catalog.sql
-- Session: 049 - System Exception Catalog — Detailed Guide
-- Purpose:
--   Comprehensive, reproducible demonstrations for common Oracle system exceptions with
--   line-by-line commentary, expected output, and recommended handling patterns.
-- How to run:
--   SET SERVEROUTPUT ON; Execute each block separately (terminated by '/').
-- Notes:
--   • Prefer specific handlers. Keep WHEN OTHERS as a final guard with diagnostics.
--   • Always include SQLCODE and SQLERRM in logs for troubleshooting.
--   • Setup is idempotent; you can re-run the script safely.
SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Setup: tables and seed data (idempotent)
--------------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'DROP TABLE se_demo PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE se_demo (
  id   NUMBER CONSTRAINT se_demo_pk PRIMARY KEY,
  val  VARCHAR2(10)
);
INSERT INTO se_demo VALUES (1,'A'); COMMIT;
/

--------------------------------------------------------------------------------
-- Demo 1: NO_DATA_FOUND — SELECT INTO returns 0 rows
-- Scenario: Query a missing id. The SELECT ... INTO requires exactly one row; 0 rows raise NO_DATA_FOUND.
-- Expected: 'Handled NO_DATA_FOUND'
--------------------------------------------------------------------------------
DECLARE
  v_val se_demo.val%TYPE;
BEGIN
  SELECT val INTO v_val FROM se_demo WHERE id = 999; -- no row
  DBMS_OUTPUT.PUT_LINE('val='||v_val);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('Handled NO_DATA_FOUND');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 2: TOO_MANY_ROWS — SELECT INTO returns >1 row
-- Scenario: Insert two rows with val='B' and then SELECT a scalar by val.
-- Expected: 'Handled TOO_MANY_ROWS'
--------------------------------------------------------------------------------
BEGIN
  INSERT INTO se_demo VALUES (2,'B');
  INSERT INTO se_demo VALUES (3,'B');
  COMMIT;
END;
/
DECLARE
  v_id NUMBER;
BEGIN
  SELECT id INTO v_id FROM se_demo WHERE val='B'; -- two rows -> TOO_MANY_ROWS
EXCEPTION
  WHEN TOO_MANY_ROWS THEN
    DBMS_OUTPUT.PUT_LINE('Handled TOO_MANY_ROWS');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 3: ZERO_DIVIDE — arithmetic exception
-- Scenario: Divide by zero in PL/SQL.
-- Expected: 'Handled ZERO_DIVIDE'
--------------------------------------------------------------------------------
DECLARE
  a NUMBER := 10;
  b NUMBER := 0;
  c NUMBER;
BEGIN
  c := a / b;
EXCEPTION
  WHEN ZERO_DIVIDE THEN
    DBMS_OUTPUT.PUT_LINE('Handled ZERO_DIVIDE');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 4: VALUE_ERROR — numeric overflow / size conversion
-- Scenario: Assign a large number to a small-precision variable.
-- Expected: 'Handled VALUE_ERROR (overflow)'
--------------------------------------------------------------------------------
DECLARE
  v_small NUMBER(3,0);
BEGIN
  v_small := 12345; -- overflow
EXCEPTION
  WHEN VALUE_ERROR THEN
    DBMS_OUTPUT.PUT_LINE('Handled VALUE_ERROR (overflow)');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 5: INVALID_NUMBER — SQL conversion failure
-- Scenario: Execute TO_NUMBER('abc') in SQL context via EXECUTE IMMEDIATE.
-- Expected: Diagnostic with SQLCODE/SQLERRM referencing invalid number.
--------------------------------------------------------------------------------
DECLARE
  v_num NUMBER;
BEGIN
  BEGIN
    EXECUTE IMMEDIATE 'BEGIN :x := TO_NUMBER(''abc''); END;' USING OUT v_num;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('INVALID_NUMBER caught: code='||SQLCODE||' msg='||SQLERRM);
  END;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 6: DUP_VAL_ON_INDEX — unique/PK constraint violation (ORA-00001)
-- Scenario: Insert duplicate primary key.
-- Expected: 'Handled DUP_VAL_ON_INDEX'
--------------------------------------------------------------------------------
BEGIN
  INSERT INTO se_demo(id,val) VALUES (1,'X');
EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN
    DBMS_OUTPUT.PUT_LINE('Handled DUP_VAL_ON_INDEX');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 7: CURSOR_ALREADY_OPEN — re-open before close
-- Scenario: Open same cursor twice without closing.
-- Expected: 'Handled CURSOR_ALREADY_OPEN'
--------------------------------------------------------------------------------
DECLARE
  CURSOR c IS SELECT * FROM se_demo;
BEGIN
  OPEN c;
  OPEN c; -- error
  CLOSE c;
EXCEPTION
  WHEN CURSOR_ALREADY_OPEN THEN
    DBMS_OUTPUT.PUT_LINE('Handled CURSOR_ALREADY_OPEN');
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Other error: '||SQLCODE||' '||SQLERRM);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 8: CASE_NOT_FOUND — CASE without ELSE where no WHEN matches
-- Scenario: Match on value 5 but only WHEN 1,2 exist.
-- Expected: 'Handled CASE_NOT_FOUND'
--------------------------------------------------------------------------------
DECLARE
  n NUMBER := 5;
  out_txt VARCHAR2(10);
BEGIN
  CASE n
    WHEN 1 THEN out_txt := 'one';
    WHEN 2 THEN out_txt := 'two';
  END CASE; -- missing ELSE -> CASE_NOT_FOUND
EXCEPTION
  WHEN CASE_NOT_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('Handled CASE_NOT_FOUND');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 9: Collections — COLLECTION_IS_NULL, SUBSCRIPT_BEYOND_COUNT, SUBSCRIPT_OUTSIDE_LIMIT
-- Scenario: Use a nested table to show uninitialized collection and bad indices.
-- Expected: Messages for each collection-related exception.
--------------------------------------------------------------------------------
DECLARE
  TYPE nt IS TABLE OF NUMBER;
  v_nt nt; -- NULL collection
  n NUMBER;
BEGIN
  -- COLLECTION_IS_NULL
  BEGIN
    n := v_nt(1);
  EXCEPTION
    WHEN COLLECTION_IS_NULL THEN
      DBMS_OUTPUT.PUT_LINE('Handled COLLECTION_IS_NULL');
  END;

  v_nt := nt(100,200);

  -- SUBSCRIPT_BEYOND_COUNT
  BEGIN
    n := v_nt(3);
  EXCEPTION
    WHEN SUBSCRIPT_BEYOND_COUNT THEN
      DBMS_OUTPUT.PUT_LINE('Handled SUBSCRIPT_BEYOND_COUNT');
  END;

  -- SUBSCRIPT_OUTSIDE_LIMIT
  BEGIN
    n := v_nt(0);
  EXCEPTION
    WHEN SUBSCRIPT_OUTSIDE_LIMIT THEN
      DBMS_OUTPUT.PUT_LINE('Handled SUBSCRIPT_OUTSIDE_LIMIT');
  END;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 10: Non-predefined system exception — PRAGMA EXCEPTION_INIT mapping
-- Scenario: Map ORA-30006 to a named exception; raise with same code for illustration.
-- Expected: 'Handled mapped non-predefined exception (-30006)'
--------------------------------------------------------------------------------
DECLARE
  e_busy EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_busy, -30006);
BEGIN
  RAISE_APPLICATION_ERROR(-30006, 'Simulated busy/timeout');
EXCEPTION
  WHEN e_busy THEN
    DBMS_OUTPUT.PUT_LINE('Handled mapped non-predefined exception (-30006)');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 11: WHEN OTHERS as final guard — diagnostics with SQLCODE/SQLERRM
-- Scenario: Raise a domain-specific error and catch in OTHERS.
-- Expected: Diagnostic with code/message.
--------------------------------------------------------------------------------
BEGIN
  RAISE_APPLICATION_ERROR(-20110, 'Domain policy violation');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Caught: code='||SQLCODE||' msg='||SQLERRM);
END;
/
--------------------------------------------------------------------------------
-- End of File
--------------------------------------------------------------------------------
