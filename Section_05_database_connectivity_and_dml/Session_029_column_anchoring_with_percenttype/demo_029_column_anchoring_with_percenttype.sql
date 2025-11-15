-- demo_029_column_anchoring_with_percenttype.sql
-- Session : 029_column_anchoring_with_percenttype
-- Topic   : Column Anchoring with %TYPE
-- Purpose : Show how to declare PL/SQL variables whose datatype is
--           automatically derived from a table column.
-- Style   : 5 demos with detailed comments, similar to Session 020 style.

SET SERVEROUTPUT ON;

------------------------------------------------------------------------------
-- Setup: create a small products table for this session
------------------------------------------------------------------------------
BEGIN
  BEGIN EXECUTE IMMEDIATE 'DROP TABLE demo29_products'; EXCEPTION WHEN OTHERS THEN NULL; END;
END;
/
CREATE TABLE demo29_products (
  product_id   NUMBER       PRIMARY KEY,
  product_name VARCHAR2(100),
  unit_price   NUMBER(10,2),
  stock_qty    NUMBER,
  active_flag  CHAR(1)      DEFAULT 'Y'
);
/
INSERT INTO demo29_products VALUES (1, 'Notebook',   120.50,  50, 'Y');
INSERT INTO demo29_products VALUES (2, 'Keyboard',   850.00,  15, 'Y');
INSERT INTO demo29_products VALUES (3, 'Mouse',      450.00,  80, 'Y');
INSERT INTO demo29_products VALUES (4, 'Webcam',    2200.00,  10, 'N');
COMMIT;
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Demo 1: Basic %TYPE usage for a single column
-- Concept:
--   - v_price uses the datatype of demo29_products.unit_price
--   - If we later change unit_price precision/scale, v_price adapts
------------------------------------------------------------------------------
DECLARE
  v_price demo29_products.unit_price%TYPE;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 1: Basic %TYPE usage');

  SELECT unit_price
    INTO v_price
    FROM demo29_products
   WHERE product_id = 1;

  DBMS_OUTPUT.PUT_LINE('  Price for product 1 = ' || v_price);
END;
/
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Demo 2: Using %TYPE for multiple related columns
-- Concept:
--   - We anchor variables to product_name and stock_qty
--   - We never repeat VARCHAR2 / NUMBER definitions manually
------------------------------------------------------------------------------
DECLARE
  v_name  demo29_products.product_name%TYPE;
  v_stock demo29_products.stock_qty%TYPE;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 2: Multiple %TYPE variables');

  SELECT product_name, stock_qty
    INTO v_name, v_stock
    FROM demo29_products
   WHERE product_id = 2;

  DBMS_OUTPUT.PUT_LINE('  Product   = ' || v_name);
  DBMS_OUTPUT.PUT_LINE('  In stock  = ' || v_stock);
END;
/
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Demo 3: %TYPE with expressions and validation
-- Objective:
--   Use %TYPE variables for price and stock to compute stock value
------------------------------------------------------------------------------
DECLARE
  v_id        demo29_products.product_id%TYPE   := 3;
  v_price     demo29_products.unit_price%TYPE;
  v_stock     demo29_products.stock_qty%TYPE;
  v_stock_val NUMBER(12,2);
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 3: Stock value calculation with %TYPE');

  SELECT unit_price, stock_qty
    INTO v_price, v_stock
    FROM demo29_products
   WHERE product_id = v_id;

  v_stock_val := v_price * v_stock;

  DBMS_OUTPUT.PUT_LINE('  Product id   = ' || v_id);
  DBMS_OUTPUT.PUT_LINE('  Unit price   = ' || v_price);
  DBMS_OUTPUT.PUT_LINE('  Stock qty    = ' || v_stock);
  DBMS_OUTPUT.PUT_LINE('  Stock value  = ' || v_stock_val);
END;
/
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Demo 4: %TYPE in procedure parameters and local variables
-- Concept:
--   - Procedure demo29_update_price uses %TYPE for its parameter and locals
--   - This keeps interface aligned with table definition
------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE demo29_update_price (
  p_product_id IN demo29_products.product_id%TYPE,
  p_new_price  IN demo29_products.unit_price%TYPE
) IS
  v_old_price demo29_products.unit_price%TYPE;
BEGIN
  SELECT unit_price
    INTO v_old_price
    FROM demo29_products
   WHERE product_id = p_product_id;

  UPDATE demo29_products
     SET unit_price = p_new_price
   WHERE product_id = p_product_id;

  DBMS_OUTPUT.PUT_LINE('Demo 4: Price updated for product ' || p_product_id);
  DBMS_OUTPUT.PUT_LINE('  Old price = ' || v_old_price);
  DBMS_OUTPUT.PUT_LINE('  New price = ' || p_new_price);
END;
/
BEGIN
  demo29_update_price(1, 150.75);
END;
/
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Demo 5: %TYPE inside record types and cursor loops
-- Objective:
--   Build a RECORD type that uses %TYPE for each field for safety
------------------------------------------------------------------------------
DECLARE
  TYPE t_product_rec IS RECORD (
    r_id    demo29_products.product_id%TYPE,
    r_name  demo29_products.product_name%TYPE,
    r_price demo29_products.unit_price%TYPE,
    r_stock demo29_products.stock_qty%TYPE
  );
  v_rec t_product_rec;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 5: %TYPE inside RECORD');

  FOR r IN (SELECT product_id, product_name, unit_price, stock_qty
              FROM demo29_products
             ORDER BY product_id) LOOP
    v_rec.r_id    := r.product_id;
    v_rec.r_name  := r.product_name;
    v_rec.r_price := r.unit_price;
    v_rec.r_stock := r.stock_qty;

    DBMS_OUTPUT.PUT_LINE('  ' || v_rec.r_id || ' - ' ||
                         v_rec.r_name || ' | price=' || v_rec.r_price ||
                         ' | stock=' || v_rec.r_stock);
  END LOOP;
END;
/
------------------------------------------------------------------------------
