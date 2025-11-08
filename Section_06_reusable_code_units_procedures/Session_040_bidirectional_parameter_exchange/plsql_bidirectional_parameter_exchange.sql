-- Script: plsql_bidirectional_parameter_exchange.sql
-- Session: 040 - Bidirectional Parameter Exchange (IN OUT)
-- Purpose: Detailed IN OUT patterns with step-by-step commentary (7 examples).
-- How to run: SET SERVEROUTPUT ON; run each block individually.

SET SERVEROUTPUT ON;

BEGIN EXECUTE IMMEDIATE 'DROP TABLE inout_items PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE TABLE inout_items (
  item_id    NUMBER CONSTRAINT inout_items_pk PRIMARY KEY,
  name       VARCHAR2(80) NOT NULL,
  price      NUMBER(12,2) NOT NULL,
  discount   NUMBER(5,2) DEFAULT 0,
  status     VARCHAR2(20) DEFAULT 'ACTIVE',
  created_on DATE DEFAULT SYSDATE
);

INSERT INTO inout_items VALUES (1,'Notebook',  999.90, 0, 'ACTIVE', SYSDATE-10);
INSERT INTO inout_items VALUES (2,'Backpack', 1299.00, 0, 'ACTIVE', SYSDATE-5);
COMMIT;

CREATE OR REPLACE PROCEDURE io_apply_discount(p_amount IN OUT NUMBER, p_pct IN NUMBER) IS
BEGIN
  p_amount := ROUND(p_amount, 2);
  IF p_pct < 0 OR p_pct > 50 THEN
    RAISE_APPLICATION_ERROR(-20500, 'Discount out of allowed range (0..50)');
  END IF;
  p_amount := ROUND(p_amount * (1 - (p_pct/100)), 2);
END io_apply_discount;
/

DECLARE v NUMBER := 1000; BEGIN io_apply_discount(v, 12.5); DBMS_OUTPUT.PUT_LINE('after='||TO_CHAR(v,'FM9999999990.00')); END; /

CREATE OR REPLACE PROCEDURE io_normalize_name(p_name IN OUT VARCHAR2) IS
BEGIN
  p_name := TRIM(p_name);
  IF p_name IS NULL THEN RAISE_APPLICATION_ERROR(-20510,'Name cannot be NULL/empty'); END IF;
  p_name := UPPER(p_name);
  p_name := REGEXP_REPLACE(p_name, '\s+', ' ');
END io_normalize_name;
/

DECLARE s VARCHAR2(80) := '  premium    notebook  '; BEGIN io_normalize_name(s); DBMS_OUTPUT.PUT_LINE('norm='||s); END; /

CREATE OR REPLACE PROCEDURE io_set_price(p_item_id IN inout_items.item_id%TYPE, p_price IN OUT inout_items.price%TYPE) IS
BEGIN
  p_price := ROUND(p_price, 2);
  IF p_price <= 0 THEN RAISE_APPLICATION_ERROR(-20520,'Price must be positive'); END IF;
  UPDATE inout_items SET price=p_price WHERE item_id=p_item_id;
  IF SQL%ROWCOUNT=0 THEN RAISE_APPLICATION_ERROR(-20521,'Item not found: '||p_item_id); END IF;
END io_set_price;
/

DECLARE p NUMBER := 1499.995; BEGIN io_set_price(1, p); DBMS_OUTPUT.PUT_LINE('stored='||TO_CHAR(p,'FM9999999990.00')); END; /

CREATE OR REPLACE PROCEDURE io_negotiate_price(p_price IN OUT NUMBER, p_discount IN OUT NUMBER) IS
  c_max CONSTANT NUMBER := 40;
BEGIN
  p_price := ROUND(p_price, 2);
  p_discount := ROUND(p_discount, 2);
  IF p_discount < 0 THEN p_discount := 0; END IF;
  IF p_discount > c_max THEN p_discount := c_max; END IF;
  p_price := ROUND(p_price * (1 - p_discount/100), 2);
END io_negotiate_price;
/

DECLARE pr NUMBER := 2000; d NUMBER := 55; BEGIN io_negotiate_price(pr, d); DBMS_OUTPUT.PUT_LINE('price='||pr||' disc='||d); END; /

CREATE OR REPLACE PROCEDURE io_adjust_item(p_name IN OUT VARCHAR2, p_price IN OUT NUMBER) IS
  c_floor CONSTANT NUMBER := 99.00;
BEGIN
  p_name := TRIM(REGEXP_REPLACE(UPPER(p_name), '\s+', ' '));
  IF p_name IS NULL THEN RAISE_APPLICATION_ERROR(-20530,'Name required'); END IF;
  p_price := ROUND(NVL(p_price,0), 2);
  IF p_price < c_floor THEN p_price := c_floor; END IF;
END io_adjust_item;
/

DECLARE nm VARCHAR2(80):='  basic   pack '; pr NUMBER := 50; BEGIN io_adjust_item(nm, pr); DBMS_OUTPUT.PUT_LINE('name='||nm||' price='||TO_CHAR(pr,'FM9999999990.00')); END; /

CREATE OR REPLACE PROCEDURE io_bump_discount(p_item_id IN inout_items.item_id%TYPE, p_step IN NUMBER, p_newdisc IN OUT NUMBER) IS
  v_curr NUMBER(5,2);
BEGIN
  SELECT NVL(discount,0) INTO v_curr FROM inout_items WHERE item_id=p_item_id;
  p_newdisc := ROUND(NVL(p_newdisc, v_curr) + NVL(p_step,0), 2);
  IF p_newdisc < 0 THEN p_newdisc := 0; END IF;
  IF p_newdisc > 50 THEN p_newdisc := 50; END IF;
  UPDATE inout_items SET discount=p_newdisc WHERE item_id=p_item_id;
EXCEPTION WHEN NO_DATA_FOUND THEN
  p_newdisc := 0; DBMS_OUTPUT.PUT_LINE('Item not found: '||p_item_id);
END io_bump_discount;
/

DECLARE nd NUMBER := NULL; BEGIN io_bump_discount(2, 7.75, nd); DBMS_OUTPUT.PUT_LINE('effective='||nd); END; /

CREATE OR REPLACE PROCEDURE io_items_rc(p_rc OUT SYS_REFCURSOR) IS
BEGIN
  OPEN p_rc FOR SELECT item_id, name, price, discount FROM inout_items ORDER BY item_id;
END io_items_rc;
/

DECLARE c SYS_REFCURSOR; a NUMBER; n VARCHAR2(80); p NUMBER; d NUMBER;
BEGIN io_items_rc(c); LOOP FETCH c INTO a,n,p,d; EXIT WHEN c%NOTFOUND; DBMS_OUTPUT.PUT_LINE(a||':'||n||' price='||TO_CHAR(p,'FM9999999990.00')||' disc='||d); END LOOP; CLOSE c; END; /
