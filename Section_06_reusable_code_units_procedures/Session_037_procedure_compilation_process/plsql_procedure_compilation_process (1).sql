-- Script: plsql_procedure_compilation_process.sql
-- Session: 037 - Procedure Compilation Process (Deep Commentary)
-- Purpose:
--   Walk through compilation, diagnostics, invalidation, and recompile with detailed, line‑by‑line comments.
--   Every SQL statement and numeric literal is annotated to explain the intent and precision/scale choices.
-- How to run:
--   SET SERVEROUTPUT ON; Execute each section separately (terminated by '/').
-- Style:
--   • Numbers annotated: e.g., NUMBER(12,2) means up to 10 digits before decimal + 2 after.
--   • Money-like columns use NUMBER(p, s) where s=2 for cents/paise style arithmetic.
--   • Sample prices like 499.00 and 899.00 are realistic product prices for test data.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- (1) Session Warnings and Setup
--------------------------------------------------------------------------------
-- Enable ALL PL/SQL warnings so the compiler reports potential issues.
-- 'ENABLE:ALL' turns on informational (performance) and severe warnings.
ALTER SESSION SET PLSQL_WARNINGS='ENABLE:ALL';

BEGIN
  -- Drop table if it exists; we wrap in an inner block to suppress ORA- errors.
  -- PURGE bypasses recycle bin to keep the lab repeatable.
  EXECUTE IMMEDIATE 'BEGIN EXECUTE IMMEDIATE ''DROP TABLE pc_products PURGE''; EXCEPTION WHEN OTHERS THEN NULL; END;';

  -- Create a price list table used by our procedures.
  -- SKU: VARCHAR2(20) holds short product codes like 'SKU-1'. Primary key ensures uniqueness.
  -- PRICE: NUMBER(10,2) stores money-like values: up to 8 digits before decimal + 2 after.
  EXECUTE IMMEDIATE 'CREATE TABLE pc_products (sku VARCHAR2(20) PRIMARY KEY, price NUMBER(10,2))';

  -- Seed rows with realistic numeric values (499.00 and 899.00).
  -- These two inserts help demonstrate SELECT INTO and invalidation later.
  EXECUTE IMMEDIATE q'[INSERT INTO pc_products VALUES ('SKU-1', 499.00)]';
  EXECUTE IMMEDIATE q'[INSERT INTO pc_products VALUES ('SKU-2', 899.00)]';

  COMMIT; -- Make seed deterministic across runs.
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- (2) Create a BROKEN procedure to observe compile errors
--------------------------------------------------------------------------------
-- Intentional error: misspelled column 'pric' instead of 'price' to provoke a compile failure.
CREATE OR REPLACE PROCEDURE pc_get_price(
  p_sku   IN  pc_products.sku%TYPE, -- %TYPE anchors the parameter type to the table column
  p_price OUT NUMBER                -- OUT holds the looked-up numeric value
) IS
BEGIN
  SELECT pric                    -- <-- typo (missing 'e'); forces PLS- errors to demonstrate diagnostics
    INTO p_price
    FROM pc_products
   WHERE sku = p_sku;
END pc_get_price;
/
-- SHOW ERRORS prints compiler diagnostics: line/position/message.
SHOW ERRORS PROCEDURE pc_get_price
/
-- USER_ERRORS query gives the same information as rows for automation or reporting.
COLUMN text FORMAT A80
SELECT name, type, line, position, text
FROM   user_errors
WHERE  name = 'PC_GET_PRICE'
ORDER  BY sequence;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- (3) Fix the procedure and validate execution
--------------------------------------------------------------------------------
-- Correct the column name to 'price'. No other logic change.
CREATE OR REPLACE PROCEDURE pc_get_price(
  p_sku   IN  pc_products.sku%TYPE,
  p_price OUT NUMBER
) IS
BEGIN
  SELECT price                   -- exact column name; numeric precision from table definition NUMBER(10,2)
    INTO p_price
    FROM pc_products
   WHERE sku = p_sku;
END pc_get_price;
/
-- Execute to ensure the object compiles to VALID and logic returns expected numeric value (499.00 for SKU-1).
DECLARE
  v NUMBER;                      -- unscaled NUMBER is sufficient for a single SELECT COUNT/PRICE
BEGIN
  pc_get_price('SKU-1', v);
  DBMS_OUTPUT.PUT_LINE('price='||TO_CHAR(v,'FM9999990.00')); -- explicit formatting to show two decimals
END;
/
-- Confirm VALID status in USER_OBJECTS (VALID means stored p-code is ready).
SELECT object_name, status
FROM   user_objects
WHERE  object_name='PC_GET_PRICE';
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- (4) Invalidate via dependency DDL and observe auto-recompile
--------------------------------------------------------------------------------
-- Add a new column; this usually keeps dependent code VALID, but any change can trigger dependency checks.
ALTER TABLE pc_products ADD (currency CHAR(3) DEFAULT 'INR');
-- Modify the PRICE column precision to NUMBER(12,2): allows 10 digits before decimal + 2 after.
-- Rationale: future-proof for larger price points while still tracking cents/paise.
ALTER TABLE pc_products MODIFY (price NUMBER(12,2));

-- When we call pc_get_price again, Oracle can auto-reparse/recompile if dependency metadata changed.
DECLARE
  v NUMBER;  -- NUMBER is adequate; pc_get_price returns a NUMBER(12,2) which is safely representable
BEGIN
  pc_get_price('SKU-2', v);
  DBMS_OUTPUT.PUT_LINE('price after ddl='||TO_CHAR(v,'FM9999999990.00'));
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- (5) Manual recompile command
--------------------------------------------------------------------------------
-- If an object is INVALID (e.g., after heavy DDL), force compilation proactively:
ALTER PROCEDURE pc_get_price COMPILE;
-- Re-check status to confirm VALID again.
SELECT object_name, status
FROM   user_objects
WHERE  object_name='PC_GET_PRICE';
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- (6) Warnings settings per-object
--------------------------------------------------------------------------------
-- USER_PLSQL_OBJECT_SETTINGS shows whether warnings were enabled at compile time.
SELECT name, plsql_warnings
FROM   user_plsql_object_settings
WHERE  name='PC_GET_PRICE';
/
--------------------------------------------------------------------------------
-- End of File
--------------------------------------------------------------------------------
