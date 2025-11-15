-- assignment_030_row_type_anchoring_with_percentrowtype.sql
-- Session : 030_row_type_anchoring_with_percentrowtype
-- Topic   : Practice - %ROWTYPE
SET SERVEROUTPUT ON;

BEGIN
  BEGIN EXECUTE IMMEDIATE 'DROP TABLE demo30_cust_assign'; EXCEPTION WHEN OTHERS THEN NULL; END;
END;
/
CREATE TABLE demo30_cust_assign (
  cust_id    NUMBER PRIMARY KEY,
  cust_name  VARCHAR2(100),
  city       VARCHAR2(50),
  credit_lim NUMBER
);
/
INSERT INTO demo30_cust_assign VALUES (1, 'Alpha Corp',   'Mumbai',  500000);
INSERT INTO demo30_cust_assign VALUES (2, 'Beta Traders', 'Delhi',   200000);
INSERT INTO demo30_cust_assign VALUES (3, 'Gamma Stores', 'Chennai', 300000);
INSERT INTO demo30_cust_assign VALUES (4, 'Delta Retail', 'Pune',    150000);
COMMIT;
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Assignment 1: Load one row into %ROWTYPE and print summary
------------------------------------------------------------------------------
DECLARE
  v_c demo30_cust_assign%ROWTYPE;
BEGIN
  SELECT * INTO v_c
    FROM demo30_cust_assign
   WHERE cust_id = 1;

  DBMS_OUTPUT.PUT_LINE('A1: ' || v_c.cust_name || ', City=' || v_c.city);
END;
/
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Assignment 2: Cursor loop with local %ROWTYPE copy
------------------------------------------------------------------------------
DECLARE
  v_c demo30_cust_assign%ROWTYPE;
BEGIN
  FOR r IN (SELECT * FROM demo30_cust_assign ORDER BY cust_id) LOOP
    v_c := r;
    DBMS_OUTPUT.PUT_LINE('A2: ' || v_c.cust_id || ' - ' ||
                         v_c.cust_name || ', Limit=' || v_c.credit_lim);
  END LOOP;
END;
/
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Assignment 3: Procedure with %ROWTYPE IN parameter
------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE a30_print_customer (
  p_cust IN demo30_cust_assign%ROWTYPE
) IS
BEGIN
  DBMS_OUTPUT.PUT_LINE('A3: ' || p_cust.cust_name || ' from ' || p_cust.city);
END;
/
DECLARE
  v demo30_cust_assign%ROWTYPE;
BEGIN
  SELECT * INTO v FROM demo30_cust_assign WHERE cust_id = 2;
  a30_print_customer(v);
END;
/
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Assignment 4: Function returning %ROWTYPE
------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION a30_get_customer (
  p_id IN demo30_cust_assign.cust_id%TYPE
) RETURN demo30_cust_assign%ROWTYPE IS
  v demo30_cust_assign%ROWTYPE;
BEGIN
  SELECT * INTO v FROM demo30_cust_assign WHERE cust_id = p_id;
  RETURN v;
END;
/
DECLARE
  v demo30_cust_assign%ROWTYPE;
BEGIN
  v := a30_get_customer(3);
  DBMS_OUTPUT.PUT_LINE('A4: Returned ' || v.cust_name ||
                       ' with limit ' || v.credit_lim);
END;
/
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Assignment 5: UPDATE using %ROWTYPE record
------------------------------------------------------------------------------
DECLARE
  v demo30_cust_assign%ROWTYPE;
BEGIN
  SELECT * INTO v FROM demo30_cust_assign WHERE cust_id = 4;
  v.credit_lim := v.credit_lim + 25000;

  UPDATE demo30_cust_assign SET ROW = v WHERE cust_id = v.cust_id;
  DBMS_OUTPUT.PUT_LINE('A5: Increased limit for ' || v.cust_name);
END;
/
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Assignment 6: Partial update using %ROWTYPE variable field
------------------------------------------------------------------------------
DECLARE
  v demo30_cust_assign%ROWTYPE;
BEGIN
  SELECT * INTO v FROM demo30_cust_assign WHERE cust_id = 1;
  v.city := 'Bengaluru';

  UPDATE demo30_cust_assign
     SET city = v.city
   WHERE cust_id = v.cust_id;

  DBMS_OUTPUT.PUT_LINE('A6: City updated for ' || v.cust_name);
END;
/
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Assignment 7: "What-if" scenario using separate copy
------------------------------------------------------------------------------
DECLARE
  v demo30_cust_assign%ROWTYPE;
  v_future demo30_cust_assign%ROWTYPE;
BEGIN
  SELECT * INTO v FROM demo30_cust_assign WHERE cust_id = 2;
  v_future := v;
  v_future.credit_lim := v_future.credit_lim * 1.1;

  DBMS_OUTPUT.PUT_LINE('A7: Customer = ' || v.cust_name);
  DBMS_OUTPUT.PUT_LINE('    Current limit  = ' || v.credit_lim);
  DBMS_OUTPUT.PUT_LINE('    Future  limit  = ' || v_future.credit_lim);
END;
/
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Assignment 8: FOR UPDATE cursor with %ROWTYPE
------------------------------------------------------------------------------
DECLARE
  v demo30_cust_assign%ROWTYPE;
BEGIN
  FOR r IN (SELECT * FROM demo30_cust_assign WHERE city = 'Chennai' FOR UPDATE) LOOP
    v := r;
    v.credit_lim := v.credit_lim + 10000;
    UPDATE demo30_cust_assign SET credit_lim = v.credit_lim WHERE CURRENT OF r;
    DBMS_OUTPUT.PUT_LINE('A8: Boosted limit for ' || v.cust_name);
  END LOOP;
END;
/
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Assignment 9: Index-by table of %ROWTYPE
------------------------------------------------------------------------------
DECLARE
  TYPE t_cust_tab IS TABLE OF demo30_cust_assign%ROWTYPE INDEX BY PLS_INTEGER;
  v_tab t_cust_tab;
  i PLS_INTEGER := 0;
BEGIN
  FOR r IN (SELECT * FROM demo30_cust_assign ORDER BY cust_id) LOOP
    i := i + 1;
    v_tab(i) := r;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('A9: Loaded ' || v_tab.COUNT || ' customers into PL/SQL table.');
END;
/
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Assignment 10: Procedure that prints high-limit customers using %ROWTYPE
------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE a30_print_if_high (
  p_cust IN demo30_cust_assign%ROWTYPE
) IS
BEGIN
  IF p_cust.credit_lim >= 300000 THEN
    DBMS_OUTPUT.PUT_LINE('A10: High limit customer -> ' || p_cust.cust_name);
  END IF;
END;
/
DECLARE
  v demo30_cust_assign%ROWTYPE;
BEGIN
  FOR r IN (SELECT * FROM demo30_cust_assign) LOOP
    v := r;
    a30_print_if_high(v);
  END LOOP;
END;
/
------------------------------------------------------------------------------
