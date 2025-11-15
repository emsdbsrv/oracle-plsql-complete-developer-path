-- assignment_029_column_anchoring_with_percenttype.sql
-- Session : 029_column_anchoring_with_percenttype
-- Topic   : Practice - Column Anchoring with %TYPE
-- Purpose : 10 exercises, each showing a focused %TYPE usage.
SET SERVEROUTPUT ON;

------------------------------------------------------------------------------
-- Shared setup for assignments
------------------------------------------------------------------------------
BEGIN
  BEGIN EXECUTE IMMEDIATE 'DROP TABLE demo29_prod_assign'; EXCEPTION WHEN OTHERS THEN NULL; END;
END;
/
CREATE TABLE demo29_prod_assign (
  product_id   NUMBER PRIMARY KEY,
  product_name VARCHAR2(100),
  unit_price   NUMBER(10,2),
  stock_qty    NUMBER,
  active_flag  CHAR(1) DEFAULT 'Y'
);
/
INSERT INTO demo29_prod_assign VALUES (1, 'Notebook',  120.50, 50,  'Y');
INSERT INTO demo29_prod_assign VALUES (2, 'Keyboard',  850.00, 15,  'Y');
INSERT INTO demo29_prod_assign VALUES (3, 'Mouse',     450.00, 80,  'Y');
INSERT INTO demo29_prod_assign VALUES (4, 'Monitor', 12500.00,  5,  'N');
COMMIT;
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Assignment 1: Fetch name and price using %TYPE variables
------------------------------------------------------------------------------
DECLARE
  v_name  demo29_prod_assign.product_name%TYPE;
  v_price demo29_prod_assign.unit_price%TYPE;
BEGIN
  SELECT product_name, unit_price
    INTO v_name, v_price
    FROM demo29_prod_assign
   WHERE product_id = 1;

  DBMS_OUTPUT.PUT_LINE('A1: ' || v_name || ' -> ' || v_price);
END;
/
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Assignment 2: Compute total stock value using %TYPE
------------------------------------------------------------------------------
DECLARE
  v_total demo29_prod_assign.unit_price%TYPE;
BEGIN
  SELECT SUM(unit_price * stock_qty)
    INTO v_total
    FROM demo29_prod_assign;

  DBMS_OUTPUT.PUT_LINE('A2: Total stock value = ' || v_total);
END;
/
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Assignment 3: Procedure for printing a product, using %TYPE parameter
------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE a29_print_product (
  p_product_id IN demo29_prod_assign.product_id%TYPE
) IS
  v_name  demo29_prod_assign.product_name%TYPE;
  v_price demo29_prod_assign.unit_price%TYPE;
BEGIN
  SELECT product_name, unit_price
    INTO v_name, v_price
    FROM demo29_prod_assign
   WHERE product_id = p_product_id;

  DBMS_OUTPUT.PUT_LINE('A3: ' || p_product_id || ' - ' ||
                       v_name || ', price=' || v_price);
END;
/
BEGIN
  a29_print_product(3);
END;
/
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Assignment 4: Variable anchored to stock_qty for reorder check
------------------------------------------------------------------------------
DECLARE
  v_min_stock demo29_prod_assign.stock_qty%TYPE := 10;
  v_name      demo29_prod_assign.product_name%TYPE;
  v_stock     demo29_prod_assign.stock_qty%TYPE;
BEGIN
  SELECT product_name, stock_qty
    INTO v_name, v_stock
    FROM demo29_prod_assign
   WHERE product_id = 2;

  IF v_stock < v_min_stock THEN
    DBMS_OUTPUT.PUT_LINE('A4: ' || v_name || ' requires reorder.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('A4: ' || v_name || ' has sufficient stock.');
  END IF;
END;
/
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Assignment 5: Function returning price using %TYPE
------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION a29_get_price (
  p_id IN demo29_prod_assign.product_id%TYPE
) RETURN demo29_prod_assign.unit_price%TYPE IS
  v_price demo29_prod_assign.unit_price%TYPE;
BEGIN
  SELECT unit_price INTO v_price
    FROM demo29_prod_assign
   WHERE product_id = p_id;
  RETURN v_price;
END;
/
BEGIN
  DBMS_OUTPUT.PUT_LINE('A5: Price for id=4 = ' || a29_get_price(4));
END;
/
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Assignment 6: Cursor loop with %TYPE variables
------------------------------------------------------------------------------
DECLARE
  v_name  demo29_prod_assign.product_name%TYPE;
  v_price demo29_prod_assign.unit_price%TYPE;
BEGIN
  FOR r IN (SELECT product_name, unit_price FROM demo29_prod_assign) LOOP
    v_name  := r.product_name;
    v_price := r.unit_price;
    DBMS_OUTPUT.PUT_LINE('A6: ' || v_name || ' costs ' || v_price);
  END LOOP;
END;
/
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Assignment 7: NOT NULL variable anchored to product_id
------------------------------------------------------------------------------
DECLARE
  v_id    demo29_prod_assign.product_id%TYPE NOT NULL := 2;
  v_name  demo29_prod_assign.product_name%TYPE;
BEGIN
  SELECT product_name INTO v_name
    FROM demo29_prod_assign WHERE product_id = v_id;

  DBMS_OUTPUT.PUT_LINE('A7: Product id ' || v_id || ' is ' || v_name);
END;
/
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Assignment 8: Record with %TYPE fields
------------------------------------------------------------------------------
DECLARE
  TYPE t_prod_rec IS RECORD (
    id    demo29_prod_assign.product_id%TYPE,
    name  demo29_prod_assign.product_name%TYPE,
    price demo29_prod_assign.unit_price%TYPE
  );
  v_rec t_prod_rec;
BEGIN
  SELECT product_id, product_name, unit_price
    INTO v_rec.id, v_rec.name, v_rec.price
    FROM demo29_prod_assign WHERE product_id = 3;

  DBMS_OUTPUT.PUT_LINE('A8: ' || v_rec.id || ' - ' || v_rec.name ||
                       ' | ' || v_rec.price);
END;
/
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Assignment 9: Apply discount using %TYPE parameter
------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION a29_discount_price (
  p_price   IN demo29_prod_assign.unit_price%TYPE,
  p_percent IN NUMBER
) RETURN demo29_prod_assign.unit_price%TYPE IS
BEGIN
  RETURN p_price - (p_price * p_percent / 100);
END;
/
DECLARE
  v_price demo29_prod_assign.unit_price%TYPE;
BEGIN
  v_price := a29_discount_price(1000, 15);
  DBMS_OUTPUT.PUT_LINE('A9: Discounted price = ' || v_price);
END;
/
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Assignment 10: Show that code survives column precision change
-- (Manually alter unit_price precision and rerun to see %TYPE benefit.)
------------------------------------------------------------------------------
DECLARE
  v_price demo29_prod_assign.unit_price%TYPE;
BEGIN
  SELECT unit_price
    INTO v_price
    FROM demo29_prod_assign
   WHERE product_id = 1;

  DBMS_OUTPUT.PUT_LINE('A10: Price from anchored variable = ' || v_price);
END;
/
------------------------------------------------------------------------------
