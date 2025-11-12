SET SERVEROUTPUT ON SIZE UNLIMITED;
--------------------------------------------------------------------------------
-- Session: 070 – Cursor Lifecycle Management
-- Detailed examples using rt_orders / rt_customers. See each block header.
--------------------------------------------------------------------------------
DECLARE n NUMBER;
BEGIN
  SELECT COUNT(*) INTO n FROM user_tables WHERE table_name='RT_CUSTOMERS';
  IF n=0 THEN
    EXECUTE IMMEDIATE 'CREATE TABLE rt_customers(customer_id NUMBER PRIMARY KEY, full_name VARCHAR2(60), email VARCHAR2(120), is_active CHAR(1) DEFAULT ''Y'', created_at DATE DEFAULT SYSDATE)';
    EXECUTE IMMEDIATE 'INSERT INTO rt_customers VALUES (1,''Avi'',''avi@example.com'',''Y'',SYSDATE-20)';
    EXECUTE IMMEDIATE 'INSERT INTO rt_customers VALUES (2,''Neha'',''neha@example.com'',''Y'',SYSDATE-10)';
  END IF;
  SELECT COUNT(*) INTO n FROM user_tables WHERE table_name='RT_ORDERS';
  IF n=0 THEN
    EXECUTE IMMEDIATE 'CREATE TABLE rt_orders(order_id NUMBER PRIMARY KEY, customer_id NUMBER NOT NULL, item_name VARCHAR2(100) NOT NULL, qty NUMBER(10) DEFAULT 1 CHECK (qty>0), unit_price NUMBER(12,2) CHECK (unit_price>=0), status VARCHAR2(12) DEFAULT ''NEW'' CHECK (status IN (''NEW'',''PAID'',''CANCELLED'')), created_at DATE DEFAULT SYSDATE)';
    EXECUTE IMMEDIATE 'INSERT INTO rt_orders VALUES (4001,1,''SSD 1TB'',1,6500,''NEW'',SYSDATE-5)';
    EXECUTE IMMEDIATE 'INSERT INTO rt_orders VALUES (4002,2,''Laptop'',1,55000,''PAID'',SYSDATE-4)';
    EXECUTE IMMEDIATE 'INSERT INTO rt_orders VALUES (4003,1,''USB-C Hub'',2,1200,''NEW'',SYSDATE-3)';
  END IF;
  COMMIT;
END;
/
--------------------------------------------------------------------------------
-- 1) Implicit cursor attributes with DML
--------------------------------------------------------------------------------
BEGIN
  UPDATE rt_orders SET qty = qty + 1 WHERE status='NEW';
  DBMS_OUTPUT.PUT_LINE('SQL%%ROWCOUNT='||SQL%ROWCOUNT||' found='||CASE WHEN SQL%FOUND THEN 'Y' ELSE 'N' END);
  ROLLBACK;
END;
/
--------------------------------------------------------------------------------
-- 2) Explicit cursor OPEN–FETCH–CLOSE with attributes
--------------------------------------------------------------------------------
DECLARE
  CURSOR c IS SELECT order_id, item_name, qty FROM rt_orders WHERE status='NEW' ORDER BY order_id;
  v_id NUMBER; v_item VARCHAR2(100); v_qty NUMBER;
BEGIN
  OPEN c;
  LOOP
    FETCH c INTO v_id, v_item, v_qty;
    EXIT WHEN c%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('#'||c%ROWCOUNT||' id='||v_id||' item='||v_item||' qty='||v_qty);
  END LOOP;
  CLOSE c;
END;
/
--------------------------------------------------------------------------------
-- 3) Parameterized cursor for reusable filtering
--------------------------------------------------------------------------------
DECLARE
  CURSOR c_by_status(p VARCHAR2) IS SELECT order_id, qty FROM rt_orders WHERE status=p ORDER BY order_id;
  v_id NUMBER; v_qty NUMBER;
BEGIN
  OPEN c_by_status('NEW');
  LOOP FETCH c_by_status INTO v_id, v_qty; EXIT WHEN c_by_status%NOTFOUND; DBMS_OUTPUT.PUT_LINE('[NEW] '||v_id||' qty='||v_qty); END LOOP;
  CLOSE c_by_status;
  OPEN c_by_status('PAID');
  LOOP FETCH c_by_status INTO v_id, v_qty; EXIT WHEN c_by_status%NOTFOUND; DBMS_OUTPUT.PUT_LINE('[PAID] '||v_id||' qty='||v_qty); END LOOP;
  CLOSE c_by_status;
END;
/
--------------------------------------------------------------------------------
-- 4) Cursor FOR loop: implicit open/fetch/close
--------------------------------------------------------------------------------
DECLARE CURSOR c IS SELECT order_id, item_name FROM rt_orders ORDER BY order_id;
BEGIN
  FOR r IN c LOOP
    DBMS_OUTPUT.PUT_LINE('FOR '||r.order_id||' '||r.item_name);
  END LOOP;
END;
/
--------------------------------------------------------------------------------
-- 5) Strong REF CURSOR function
--------------------------------------------------------------------------------
DECLARE
  TYPE t_cur IS REF CURSOR RETURN rt_orders%ROWTYPE;
  FUNCTION get_by_cust(p NUMBER) RETURN t_cur IS x t_cur; BEGIN OPEN x FOR SELECT * FROM rt_orders WHERE customer_id=p ORDER BY order_id; RETURN x; END;
  c t_cur; r rt_orders%ROWTYPE;
BEGIN
  c := get_by_cust(1);
  LOOP FETCH c INTO r; EXIT WHEN c%NOTFOUND; DBMS_OUTPUT.PUT_LINE(r.order_id||' '||r.item_name||' '||r.status); END LOOP;
  CLOSE c;
END;
/
--------------------------------------------------------------------------------
-- 6) Weak REF CURSOR with dynamic SQL
--------------------------------------------------------------------------------
DECLARE TYPE t_any IS REF CURSOR; c t_any; v1 NUMBER; v2 VARCHAR2(100);
BEGIN
  OPEN c FOR 'SELECT order_id,item_name FROM rt_orders WHERE status=:x ORDER BY order_id' USING 'NEW';
  LOOP FETCH c INTO v1,v2; EXIT WHEN c%NOTFOUND; DBMS_OUTPUT.PUT_LINE('dyn '||v1||' '||v2); END LOOP;
  CLOSE c;
END;
/
--------------------------------------------------------------------------------
-- 7) Defensive close in EXCEPTION path
--------------------------------------------------------------------------------
DECLARE CURSOR c IS SELECT order_id, unit_price FROM rt_orders ORDER BY order_id; v NUMBER; p NUMBER;
BEGIN
  OPEN c;
  BEGIN
    LOOP FETCH c INTO v,p; EXIT WHEN c%NOTFOUND; IF p<0 THEN RAISE_APPLICATION_ERROR(-20001,'invalid'); END IF; DBMS_OUTPUT.PUT_LINE('ok '||v||' '||p); END LOOP;
  EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE(SQLERRM);
  END;
  IF c%ISOPEN THEN CLOSE c; END IF;
END;
/
