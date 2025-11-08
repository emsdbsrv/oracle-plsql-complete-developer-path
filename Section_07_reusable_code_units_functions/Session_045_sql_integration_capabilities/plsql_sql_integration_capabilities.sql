-- Script: plsql_sql_integration_capabilities.sql
-- Session: 045 - SQL Integration Capabilities
-- Purpose:
--   Comprehensive, production-style showcase of how PL/SQL integrates with SQL:
--     • Implicit queries (SELECT INTO), DML (INSERT/UPDATE/DELETE), MERGE
--     • RETURNING INTO for primary keys and computed columns
--     • Implicit vs explicit cursors, cursor FOR loops
--     • %TYPE and %ROWTYPE to guard against schema drift
-- How to run:
--   SET SERVEROUTPUT ON; Execute each block separately (terminated by '/').
-- Conventions:
--   • All examples include numbered commentary and expected effects.
--   • Try/catch with NO_DATA_FOUND/TOO_MANY_ROWS where relevant.
--   • Keep examples minimal yet realistic; names are illustrative.
SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Setup: idempotent schema
--------------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'DROP TABLE si_customers PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE TABLE si_customers (
  cust_id     NUMBER CONSTRAINT si_customers_pk PRIMARY KEY,
  cust_name   VARCHAR2(80) NOT NULL,
  country_iso VARCHAR2(2)  NOT NULL,
  credit_amt  NUMBER(12,2) DEFAULT 0,
  created_on  DATE         DEFAULT SYSDATE
);

INSERT INTO si_customers(cust_id, cust_name, country_iso, credit_amt, created_on)
VALUES (1, 'Avi', 'IN', 1200, SYSDATE-7);
INSERT INTO si_customers VALUES (2, 'Neha', 'US',  300, SYSDATE-2, DEFAULT);
INSERT INTO si_customers VALUES (3, 'Raj', 'GB',   950, SYSDATE-1, DEFAULT);
COMMIT;
/

--------------------------------------------------------------------------------
-- Demo 1: Implicit single-row SELECT INTO with exception handling
-- Intent:
--   Fetch a single row into scalar variables using %TYPE anchors.
-- Notes:
--   • NO_DATA_FOUND if no row; TOO_MANY_ROWS if >1 row.
--   • Use %TYPE to keep variables aligned with table types.
--------------------------------------------------------------------------------
DECLARE
  v_name  si_customers.cust_name%TYPE;  -- anchors to column type
  v_credit si_customers.credit_amt%TYPE;
BEGIN
  SELECT cust_name, credit_amt
    INTO v_name, v_credit
    FROM si_customers
   WHERE cust_id = 1;  -- expect exactly one row

  DBMS_OUTPUT.PUT_LINE('customer='||v_name||' credit='||v_credit);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('no row for cust_id=1');
  WHEN TOO_MANY_ROWS THEN
    DBMS_OUTPUT.PUT_LINE('more than one row matched');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 2: DML with RETURNING INTO to capture generated/changed values
-- Intent:
--   Insert a row and immediately capture values (e.g., new id, timestamps).
-- Pattern:
--   INSERT ... RETURNING col INTO var; Similarly for UPDATE/DELETE RETURNING.
--------------------------------------------------------------------------------
DECLARE
  v_id      si_customers.cust_id%TYPE := 4;
  v_created si_customers.created_on%TYPE;
BEGIN
  INSERT INTO si_customers(cust_id, cust_name, country_iso, credit_amt)
  VALUES (v_id, 'Meera', 'IN', 500)
  RETURNING created_on INTO v_created;  -- capture generated default

  DBMS_OUTPUT.PUT_LINE('inserted id='||v_id||' created_on='||TO_CHAR(v_created,'YYYY-MM-DD HH24:MI:SS'));
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 3: UPDATE with SQL%ROWCOUNT and RETURNING INTO (multi-col)
-- Intent:
--   Raise credit for US customers; show affected rows and capture one changed value.
--------------------------------------------------------------------------------
DECLARE
  v_after si_customers.credit_amt%TYPE;
BEGIN
  UPDATE si_customers
     SET credit_amt = credit_amt + 100
   WHERE country_iso = 'US'
  RETURNING credit_amt INTO v_after;     -- returns a value from any one updated row
  DBMS_OUTPUT.PUT_LINE('updated rows='||SQL%ROWCOUNT||' sample_after='||v_after);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 4: MERGE (upsert) with %ROWCOUNT effect
-- Intent:
--   Upsert customer id=5; if exists, update credit; if not, insert.
-- Notes:
--   • MERGE acts set-based; use for synchronization patterns.
--------------------------------------------------------------------------------
DECLARE
  v_rows NUMBER;
BEGIN
  MERGE INTO si_customers t
  USING (SELECT 5 AS cust_id, 'Sara' AS cust_name, 'US' AS country_iso, 750 AS credit_amt FROM dual) s
     ON (t.cust_id = s.cust_id)
  WHEN MATCHED THEN
    UPDATE SET t.credit_amt = t.credit_amt + 50
  WHEN NOT MATCHED THEN
    INSERT (cust_id, cust_name, country_iso, credit_amt)
    VALUES (s.cust_id, s.cust_name, s.country_iso, s.credit_amt);

  v_rows := SQL%ROWCOUNT;
  DBMS_OUTPUT.PUT_LINE('merge affected rows='||v_rows);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 5: Explicit cursor with parameters and %ROWTYPE
-- Intent:
--   Iterate customers by country with a parameterized cursor.
-- Pattern:
--   CURSOR c(x IN ...) IS SELECT ...; OPEN c(arg); LOOP FETCH ...; EXIT WHEN c%NOTFOUND; ...; CLOSE c;
--   Or prefer CURSOR FOR LOOP to auto-open/fetch/close.
--------------------------------------------------------------------------------
DECLARE
  CURSOR c_customers(p_iso VARCHAR2) IS
    SELECT cust_id, cust_name, credit_amt
      FROM si_customers
     WHERE country_iso = p_iso
     ORDER BY credit_amt DESC;

  v_row c_customers%ROWTYPE;  -- row with fields cust_id, cust_name, credit_amt
BEGIN
  OPEN c_customers('IN');           -- explicit open
  LOOP
    FETCH c_customers INTO v_row;   -- fetch next row
    EXIT WHEN c_customers%NOTFOUND; -- stop when no more
    DBMS_OUTPUT.PUT_LINE('IN -> id='||v_row.cust_id||' name='||v_row.cust_name||' credit='||v_row.credit_amt);
  END LOOP;
  CLOSE c_customers;                -- always close
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 6: Cursor FOR LOOP (implicit open/fetch/close) using %ROWTYPE
-- Intent:
--   Simpler iteration; Oracle manages the cursor lifecycle automatically.
--------------------------------------------------------------------------------
BEGIN
  FOR r IN (
    SELECT *
      FROM si_customers
     WHERE credit_amt >= 500
     ORDER BY credit_amt DESC
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('FOR LOOP -> id='||r.cust_id||', name='||r.cust_name||', credit='||r.credit_amt);
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 7: SQL functions in PL/SQL expressions and scalar subqueries
-- Intent:
--   Use SQL functions and scalar subqueries in PL/SQL calculations safely.
--------------------------------------------------------------------------------
DECLARE
  v_high NUMBER;
  v_avg  NUMBER;
BEGIN
  SELECT MAX(credit_amt), AVG(credit_amt)
    INTO v_high, v_avg
    FROM si_customers;

  DBMS_OUTPUT.PUT_LINE('max='||ROUND(v_high,2)||' avg='||ROUND(v_avg,2));

  -- Scalar subquery inside an expression
  DBMS_OUTPUT.PUT_LINE('country of id=1 -> '||(
    SELECT country_iso FROM si_customers WHERE cust_id=1
  ));
END;
/
--------------------------------------------------------------------------------
-- End of File
--------------------------------------------------------------------------------
