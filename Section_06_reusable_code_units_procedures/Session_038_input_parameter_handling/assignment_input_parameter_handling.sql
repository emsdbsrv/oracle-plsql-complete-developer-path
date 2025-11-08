-- Script: assignment_input_parameter_handling.sql
-- Session: 038 - Input Parameter Handling
-- Format:
--   • 10 detailed questions with complete solutions provided as COMMENTED hints.
--   • To run a solution: copy the commented block and remove leading '--'.
-- Guidance:
--   • Anchor types with %TYPE; validate NULL/empty; TRIM whitespace
--   • Normalize textual inputs (UPPER/LOWER), validate against lists
--   • For numeric/date text, use TO_NUMBER/TO_DATE with error handling

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Q1 (Name update): Create iph_update_name(p_cust_id IN %TYPE, p_name IN %TYPE) with TRIM + NULL check.
-- Answer (commented):
-- CREATE OR REPLACE PROCEDURE iph_update_name(p_cust_id IN iph_customers.cust_id%TYPE, p_name IN iph_customers.cust_name%TYPE) IS
--   v_name iph_customers.cust_name%TYPE := TRIM(p_name);
-- BEGIN
--   IF v_name IS NULL THEN RAISE_APPLICATION_ERROR(-20100,'name empty'); END IF;
--   UPDATE iph_customers SET cust_name=v_name WHERE cust_id=p_cust_id;
--   DBMS_OUTPUT.PUT_LINE('rows='||SQL%ROWCOUNT);
-- END;
-- /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q2 (Status whitelist): Implement iph_set_status validating ACTIVE/INACTIVE/SUSPENDED.
-- Answer (commented):
-- CREATE OR REPLACE PROCEDURE iph_set_status(p_cust_id IN iph_customers.cust_id%TYPE, p_status IN iph_customers.status%TYPE) IS
--   v iph_customers.status%TYPE := UPPER(TRIM(p_status));
-- BEGIN
--   IF v NOT IN ('ACTIVE','INACTIVE','SUSPENDED') THEN RAISE_APPLICATION_ERROR(-20101,'bad status'); END IF;
--   UPDATE iph_customers SET status=v WHERE cust_id=p_cust_id;
-- END;
-- /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q3 (Add credit positive): iph_add_credit(p_cust_id IN, p_amount IN NUMBER) rounding to 2 decimals and >0.
-- Answer (commented):
-- CREATE OR REPLACE PROCEDURE iph_add_credit(p_cust_id IN iph_customers.cust_id%TYPE, p_amount IN NUMBER) IS v NUMBER(12,2);
-- BEGIN v := ROUND(p_amount,2); IF v<=0 THEN RAISE_APPLICATION_ERROR(-20102,'>0'); END IF;
-- UPDATE iph_customers SET credit_amt=NVL(credit_amt,0)+v WHERE cust_id=p_cust_id; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q4 (Text to number): iph_add_credit_text(p_cust_id IN, p_amount_text IN VARCHAR2) with VALUE_ERROR mapping.
-- Answer (commented):
-- CREATE OR REPLACE PROCEDURE iph_add_credit_text(p_cust_id IN iph_customers.cust_id%TYPE, p_amount_text IN VARCHAR2) IS v NUMBER(12,2);
-- BEGIN IF TRIM(p_amount_text) IS NULL THEN RAISE_APPLICATION_ERROR(-20104,'empty'); END IF;
-- BEGIN v := ROUND(TO_NUMBER(TRIM(p_amount_text)),2); EXCEPTION WHEN VALUE_ERROR THEN RAISE_APPLICATION_ERROR(-20105,'not numeric'); END;
-- IF v<=0 THEN RAISE_APPLICATION_ERROR(-20106,'>0'); END IF;
-- UPDATE iph_customers SET credit_amt=NVL(credit_amt,0)+v WHERE cust_id=p_cust_id; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q5 (Date text): iph_set_created_on(p_cust_id IN, p_date_text IN VARCHAR2) format 'YYYY-MM-DD'.
-- Answer (commented):
-- CREATE OR REPLACE PROCEDURE iph_set_created_on(p_cust_id IN iph_customers.cust_id%TYPE, p_date_text IN VARCHAR2) IS v DATE; BEGIN
--   BEGIN v := TO_DATE(TRIM(p_date_text),'YYYY-MM-DD'); EXCEPTION WHEN OTHERS THEN RAISE_APPLICATION_ERROR(-20107,'bad date'); END;
--   UPDATE iph_customers SET created_on=v WHERE cust_id=p_cust_id; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q6 (Email domain whitelist): iph_set_email(p_cust_id IN, p_email IN VARCHAR2) verifying domain in table.
-- Answer (commented):
-- CREATE OR REPLACE PROCEDURE iph_set_email(p_cust_id IN iph_customers.cust_id%TYPE, p_email IN VARCHAR2) IS
--   v VARCHAR2(320):=LOWER(TRIM(p_email)); d VARCHAR2(200); c NUMBER;
-- BEGIN IF v IS NULL OR INSTR(v,'@')=0 THEN RAISE_APPLICATION_ERROR(-20108,'invalid'); END IF;
-- d := SUBSTR(v, INSTR(v,'@')+1); SELECT COUNT(*) INTO c FROM iph_valid_domains WHERE domain=d;
-- IF c=0 THEN RAISE_APPLICATION_ERROR(-20109,'domain not allowed'); END IF;
-- UPDATE iph_customers SET email=v WHERE cust_id=p_cust_id; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q7 (Named notation): Call iph_set_status using named parameters (show example call).
-- Answer (commented):
-- BEGIN iph_set_status(p_status=>'ACTIVE', p_cust_id=>1); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q8 (Introduce guard rails): Modify iph_add_credit to reject amounts > 1,000,000,000.
-- Answer (commented):
-- CREATE OR REPLACE PROCEDURE iph_add_credit(p_cust_id IN iph_customers.cust_id%TYPE, p_amount IN NUMBER) IS v NUMBER(12,2);
-- BEGIN v := ROUND(p_amount,2); IF v<=0 THEN RAISE_APPLICATION_ERROR(-20102,'>0'); END IF;
-- IF v>1000000000 THEN RAISE_APPLICATION_ERROR(-20103,'too large'); END IF;
-- UPDATE iph_customers SET credit_amt=NVL(credit_amt,0)+v WHERE cust_id=p_cust_id; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q9 (Register): iph_register(p_cust_id, p_name, p_email, p_credit) with checks and DUP_VAL_ON_INDEX mapping.
-- Answer (commented):
-- CREATE OR REPLACE PROCEDURE iph_register(p_cust_id IN iph_customers.cust_id%TYPE, p_name IN iph_customers.cust_name%TYPE, p_email IN VARCHAR2, p_credit IN NUMBER) IS
-- BEGIN IF p_cust_id IS NULL OR p_cust_id<=0 THEN RAISE_APPLICATION_ERROR(-20110,'cust_id'); END IF;
-- IF TRIM(p_name) IS NULL THEN RAISE_APPLICATION_ERROR(-20111,'name'); END IF;
-- IF p_credit IS NULL OR p_credit<0 THEN RAISE_APPLICATION_ERROR(-20112,'credit'); END IF;
-- INSERT INTO iph_customers(cust_id,cust_name,email,credit_amt,status) VALUES (p_cust_id, TRIM(p_name), LOWER(TRIM(p_email)), ROUND(p_credit,2), 'ACTIVE');
-- EXCEPTION WHEN DUP_VAL_ON_INDEX THEN RAISE_APPLICATION_ERROR(-20113,'exists'); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q10 (Validation wrapper): Write a wrapper block that calls iph_set_created_on with input '2025-11-08' for cust 2.
-- Answer (commented):
-- BEGIN iph_set_created_on(2,'2025-11-08'); END; /
--------------------------------------------------------------------------------
-- End of Assignment
--------------------------------------------------------------------------------
