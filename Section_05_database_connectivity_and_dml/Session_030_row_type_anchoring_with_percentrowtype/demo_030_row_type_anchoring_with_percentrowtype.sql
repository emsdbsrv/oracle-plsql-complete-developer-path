-- demo_030_row_type_anchoring_with_percentrowtype.sql
-- Session : 030_row_type_anchoring_with_percentrowtype
-- Topic   : Row-Type Anchoring with %ROWTYPE
-- Purpose : Use %ROWTYPE to declare record variables that mirror table rows.

SET SERVEROUTPUT ON;

BEGIN
  BEGIN EXECUTE IMMEDIATE 'DROP TABLE demo30_customers'; EXCEPTION WHEN OTHERS THEN NULL; END;
END;
/
CREATE TABLE demo30_customers (
  cust_id    NUMBER PRIMARY KEY,
  cust_name  VARCHAR2(100),
  city       VARCHAR2(50),
  credit_lim NUMBER
);
/
INSERT INTO demo30_customers VALUES (1, 'Alpha Corp',   'Mumbai',  500000);
INSERT INTO demo30_customers VALUES (2, 'Beta Traders', 'Delhi',   200000);
INSERT INTO demo30_customers VALUES (3, 'Gamma Stores', 'Chennai', 300000);
INSERT INTO demo30_customers VALUES (4, 'Delta Retail', 'Pune',    150000);
COMMIT;
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Demo 1: Basic %ROWTYPE usage
------------------------------------------------------------------------------
DECLARE
  v_cust demo30_customers%ROWTYPE;
BEGIN
  SELECT *
    INTO v_cust
    FROM demo30_customers
   WHERE cust_id = 1;

  DBMS_OUTPUT.PUT_LINE('Demo 1: ' || v_cust.cust_id || ' - ' ||
                       v_cust.cust_name || ', ' || v_cust.city ||
                       ', Limit=' || v_cust.credit_lim);
END;
/
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Demo 2: Cursor loop assigning records to %ROWTYPE variable
------------------------------------------------------------------------------
DECLARE
  v_rec demo30_customers%ROWTYPE;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 2: Looping customers into %ROWTYPE variable');

  FOR r IN (SELECT * FROM demo30_customers ORDER BY cust_id) LOOP
    v_rec := r;
    DBMS_OUTPUT.PUT_LINE('  ' || v_rec.cust_name || ' from ' ||
                         v_rec.city || ' has limit ' || v_rec.credit_lim);
  END LOOP;
END;
/
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Demo 3: Procedure with %ROWTYPE parameter
------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE demo30_show_customer (
  p_customer IN demo30_customers%ROWTYPE
) IS
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 3: ' || p_customer.cust_id || ' - ' ||
                       p_customer.cust_name || ', City=' || p_customer.city ||
                       ', Limit=' || p_customer.credit_lim);
END;
/
DECLARE
  v_c demo30_customers%ROWTYPE;
BEGIN
  SELECT * INTO v_c FROM demo30_customers WHERE cust_id = 2;
  demo30_show_customer(v_c);
END;
/
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Demo 4: Updating a row using %ROWTYPE
------------------------------------------------------------------------------
DECLARE
  v_c demo30_customers%ROWTYPE;
BEGIN
  SELECT * INTO v_c FROM demo30_customers WHERE cust_id = 3;
  v_c.credit_lim := v_c.credit_lim + 50000;

  UPDATE demo30_customers
     SET ROW = v_c
   WHERE cust_id = v_c.cust_id;

  DBMS_OUTPUT.PUT_LINE('Demo 4: Updated credit limit for ' || v_c.cust_name);
END;
/
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Demo 5: Using %ROWTYPE for "what-if" calculations without updating table
------------------------------------------------------------------------------
DECLARE
  v_current demo30_customers%ROWTYPE;
  v_future  demo30_customers%ROWTYPE;
BEGIN
  SELECT * INTO v_current FROM demo30_customers WHERE cust_id = 4;
  v_future := v_current;
  v_future.credit_lim := v_future.credit_lim * 1.20;

  DBMS_OUTPUT.PUT_LINE('Demo 5: ' || v_current.cust_name);
  DBMS_OUTPUT.PUT_LINE('  Current limit = ' || v_current.credit_lim);
  DBMS_OUTPUT.PUT_LINE('  Future limit  = ' || v_future.credit_lim);
END;
/
------------------------------------------------------------------------------
