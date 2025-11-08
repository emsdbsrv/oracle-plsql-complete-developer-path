-- Script: plsql_input_parameter_handling.sql
-- Session: 038 - Input Parameter Handling
-- Purpose:
--   Showcase robust patterns for IN parameters: type anchoring, validation, normalization, named notation,
--   conversion, and clear domain errors. At least 7 examples with detailed commentary.
-- How to run:
--   SET SERVEROUTPUT ON; Execute each example separately (terminated by '/').

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Setup: reference table used by several procedures (idempotent)
--------------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'DROP TABLE iph_customers PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE TABLE iph_customers (
  cust_id    NUMBER CONSTRAINT iph_customers_pk PRIMARY KEY,
  cust_name  VARCHAR2(80) NOT NULL,
  email      VARCHAR2(120),
  credit_amt NUMBER(12,2) DEFAULT 0,
  status     VARCHAR2(20) DEFAULT 'ACTIVE',
  created_on DATE DEFAULT SYSDATE
);

INSERT INTO iph_customers VALUES (1,'Avi','avi@example.com',  5000.00,'ACTIVE',SYSDATE-5);
INSERT INTO iph_customers VALUES (2,'Raj','raj@example.com', 12000.00,'ACTIVE',SYSDATE-2);
COMMIT;

--------------------------------------------------------------------------------
-- Example 1: Basic IN parameters with %TYPE anchoring and NULL/empty check
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE iph_update_name(
  p_cust_id  IN iph_customers.cust_id%TYPE,
  p_cust_name IN iph_customers.cust_name%TYPE
) IS
  v_name iph_customers.cust_name%TYPE := TRIM(p_cust_name); -- normalize whitespace
BEGIN
  IF v_name IS NULL THEN
    RAISE_APPLICATION_ERROR(-20100, 'Customer name cannot be NULL/empty');
  END IF;

  UPDATE iph_customers
     SET cust_name = v_name
   WHERE cust_id = p_cust_id;

  DBMS_OUTPUT.PUT_LINE('rows='||SQL%ROWCOUNT||' updated name='||v_name);
END iph_update_name;
/
BEGIN
  iph_update_name(1, '  Avishesh  '); -- positional
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 2: Named notation call for readability and safety
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE iph_set_status(
  p_cust_id IN iph_customers.cust_id%TYPE,
  p_status  IN iph_customers.status%TYPE
) IS
  v_status iph_customers.status%TYPE := UPPER(TRIM(p_status));
BEGIN
  IF v_status NOT IN ('ACTIVE','INACTIVE','SUSPENDED') THEN
    RAISE_APPLICATION_ERROR(-20101,'Invalid status: '||v_status);
  END IF;

  UPDATE iph_customers SET status = v_status WHERE cust_id = p_cust_id;
  DBMS_OUTPUT.PUT_LINE('rows='||SQL%ROWCOUNT||' status='||v_status);
END iph_set_status;
/
BEGIN
  iph_set_status(p_status => 'suspended', p_cust_id => 2); -- named
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 3: Numeric range validation for money-like inputs NUMBER(12,2)
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE iph_add_credit(
  p_cust_id   IN iph_customers.cust_id%TYPE,
  p_amount_in IN NUMBER -- caller may pass NUMBER; we validate range and scale formatting on display
) IS
  v_amt NUMBER(12,2);
BEGIN
  -- Normalize/constrain: force two-decimal arithmetic for printing; validate domain
  v_amt := ROUND(p_amount_in, 2);
  IF v_amt IS NULL OR v_amt <= 0 THEN
    RAISE_APPLICATION_ERROR(-20102, 'Amount must be positive');
  END IF;
  IF v_amt > 1000000000 THEN -- cap for safety
    RAISE_APPLICATION_ERROR(-20103, 'Amount too large');
  END IF;

  UPDATE iph_customers SET credit_amt = NVL(credit_amt,0) + v_amt WHERE cust_id=p_cust_id;
  DBMS_OUTPUT.PUT_LINE('credit added='||TO_CHAR(v_amt,'FM9999999990.00')||' rows='||SQL%ROWCOUNT);
END iph_add_credit;
/
BEGIN
  iph_add_credit(1, 1250.456);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 4: String-to-number conversion with robust handling
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE iph_add_credit_text(
  p_cust_id IN iph_customers.cust_id%TYPE,
  p_amount_text IN VARCHAR2
) IS
  v_amt NUMBER(12,2);
BEGIN
  -- Reject blank/whitespace input
  IF TRIM(p_amount_text) IS NULL THEN
    RAISE_APPLICATION_ERROR(-20104,'Amount text is empty');
  END IF;

  -- Attempt conversion; explicit format model can be used if required
  BEGIN
    v_amt := ROUND(TO_NUMBER(TRIM(p_amount_text)), 2);
  EXCEPTION WHEN VALUE_ERROR THEN
    RAISE_APPLICATION_ERROR(-20105,'Amount text not numeric: '||p_amount_text);
  END;

  IF v_amt <= 0 THEN
    RAISE_APPLICATION_ERROR(-20106,'Amount must be positive');
  END IF;

  UPDATE iph_customers SET credit_amt = NVL(credit_amt,0) + v_amt WHERE cust_id=p_cust_id;
  DBMS_OUTPUT.PUT_LINE('credit added (text)='||TO_CHAR(v_amt,'FM9999999990.00'));
END iph_add_credit_text;
/
BEGIN
  iph_add_credit_text(p_cust_id=>2, p_amount_text=>' 300.40 ');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 5: DATE conversion input with format mask and error mapping
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE iph_set_created_on(
  p_cust_id IN iph_customers.cust_id%TYPE,
  p_date_text IN VARCHAR2
) IS
  v_dt DATE;
  e_bad_date EXCEPTION; PRAGMA EXCEPTION_INIT(e_bad_date, -1843); -- ORA-01843: invalid month
BEGIN
  BEGIN
    v_dt := TO_DATE(TRIM(p_date_text), 'YYYY-MM-DD');
  EXCEPTION
    WHEN e_bad_date OR VALUE_ERROR THEN
      RAISE_APPLICATION_ERROR(-20107,'Invalid date format; expected YYYY-MM-DD');
  END;

  UPDATE iph_customers SET created_on = v_dt WHERE cust_id = p_cust_id;
  DBMS_OUTPUT.PUT_LINE('created_on set to '||TO_CHAR(v_dt,'YYYY-MM-DD')||' rows='||SQL%ROWCOUNT);
END iph_set_created_on;
/
BEGIN
  iph_set_created_on(1, '2025-10-15');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 6: Whitelist lookups via reference table (domain validation)
--------------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'DROP TABLE iph_valid_domains PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE iph_valid_domains(domain VARCHAR2(40) PRIMARY KEY);
INSERT INTO iph_valid_domains VALUES ('example.com');
INSERT INTO iph_valid_domains VALUES ('corp.local');
COMMIT;
/
CREATE OR REPLACE PROCEDURE iph_set_email(
  p_cust_id IN iph_customers.cust_id%TYPE,
  p_email   IN VARCHAR2
) IS
  v_email VARCHAR2(320) := LOWER(TRIM(p_email));
  v_dom   VARCHAR2(200);
  v_cnt   NUMBER;
BEGIN
  IF v_email IS NULL OR INSTR(v_email,'@')=0 THEN
    RAISE_APPLICATION_ERROR(-20108,'Invalid email');
  END IF;
  v_dom := SUBSTR(v_email, INSTR(v_email,'@')+1);
  SELECT COUNT(*) INTO v_cnt FROM iph_valid_domains WHERE domain=v_dom;
  IF v_cnt=0 THEN
    RAISE_APPLICATION_ERROR(-20109,'Email domain not allowed: '||v_dom);
  END IF;

  UPDATE iph_customers SET email=v_email WHERE cust_id=p_cust_id;
  DBMS_OUTPUT.PUT_LINE('email updated to '||v_email||' rows='||SQL%ROWCOUNT);
END iph_set_email;
/
BEGIN
  iph_set_email(1,'AVI@EXAMPLE.COM');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 7: Combined validation with early returns via exceptions
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE iph_register(
  p_cust_id  IN iph_customers.cust_id%TYPE,
  p_name     IN iph_customers.cust_name%TYPE,
  p_email    IN VARCHAR2,
  p_credit   IN NUMBER
) IS
BEGIN
  IF p_cust_id IS NULL OR p_cust_id <= 0 THEN
    RAISE_APPLICATION_ERROR(-20110,'cust_id must be positive');
  END IF;
  IF TRIM(p_name) IS NULL THEN
    RAISE_APPLICATION_ERROR(-20111,'name required');
  END IF;
  IF p_credit IS NULL OR p_credit < 0 THEN
    RAISE_APPLICATION_ERROR(-20112,'credit must be >= 0');
  END IF;

  INSERT INTO iph_customers(cust_id,cust_name,email,credit_amt,status)
  VALUES (p_cust_id, TRIM(p_name), LOWER(TRIM(p_email)), ROUND(p_credit,2), 'ACTIVE');

  DBMS_OUTPUT.PUT_LINE('registered cust_id='||p_cust_id);
EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN
    RAISE_APPLICATION_ERROR(-20113,'cust_id already exists');
END iph_register;
/
BEGIN
  iph_register(3,'  Neha  ','neha@corp.local', 1500.555);
END;
/
--------------------------------------------------------------------------------
-- End of File
--------------------------------------------------------------------------------
