SET SERVEROUTPUT ON SIZE UNLIMITED;
--------------------------------------------------------------------------------
-- Session: 071 – SQL%FOUND Attribute Usage
-- Purpose:
--   Explore implicit cursor attributes, especially SQL%FOUND, and how to use
--   them safely with DML and SELECT INTO against rt_orders / rt_customers.
--
-- How to run:
--   Execute each block separately ('/') with SERVEROUTPUT ON.
-- Notes:
--   • SQL%FOUND is TRUE if the last implicit SQL statement affected at least one row.
--   • SQL%NOTFOUND is the inverse; SQL%ROWCOUNT shows affected rows.
--   • For explicit cursors use <cursor>%FOUND, not SQL%FOUND.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 0) Bootstrap: ensure tables and a few rows exist (idempotent)
--------------------------------------------------------------------------------
DECLARE n NUMBER;
BEGIN
  SELECT COUNT(*) INTO n FROM user_tables WHERE table_name='RT_CUSTOMERS';
  IF n=0 THEN
    EXECUTE IMMEDIATE 'CREATE TABLE rt_customers(
      customer_id NUMBER PRIMARY KEY,
      full_name   VARCHAR2(60) NOT NULL,
      email       VARCHAR2(120),
      is_active   CHAR(1) DEFAULT ''Y'' CHECK (is_active IN (''Y'',''N'')),
      created_at  DATE DEFAULT SYSDATE
    )';
    EXECUTE IMMEDIATE 'INSERT INTO rt_customers VALUES (1,''Avi'',''avi@example.com'',''Y'',SYSDATE-30)';
    EXECUTE IMMEDIATE 'INSERT INTO rt_customers VALUES (2,''Neha'',''neha@example.com'',''Y'',SYSDATE-20)';
  END IF;

  SELECT COUNT(*) INTO n FROM user_tables WHERE table_name='RT_ORDERS';
  IF n=0 THEN
    EXECUTE IMMEDIATE 'CREATE TABLE rt_orders(
      order_id    NUMBER PRIMARY KEY,
      customer_id NUMBER NOT NULL,
      item_name   VARCHAR2(100) NOT NULL,
      qty         NUMBER(10) DEFAULT 1 CHECK (qty>0),
      unit_price  NUMBER(12,2) CHECK (unit_price>=0),
      status      VARCHAR2(12) DEFAULT ''NEW'' CHECK (status IN (''NEW'',''PAID'',''CANCELLED'')),
      created_at  DATE DEFAULT SYSDATE
    )';
    EXECUTE IMMEDIATE 'INSERT INTO rt_orders VALUES (4101,1,''SSD 1TB'',1,6500,''NEW'',SYSDATE-5)';
    EXECUTE IMMEDIATE 'INSERT INTO rt_orders VALUES (4102,2,''Laptop'',1,55000,''PAID'',SYSDATE-4)';
    EXECUTE IMMEDIATE 'INSERT INTO rt_orders VALUES (4103,1,''USB-C Hub'',2,1200,''NEW'',SYSDATE-3)';
  END IF;
  COMMIT;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 1: UPDATE then check SQL%FOUND and SQL%ROWCOUNT
-- Scenario:
--   Increase qty by 1 for NEW orders; print whether any row was affected.
--------------------------------------------------------------------------------
BEGIN
  UPDATE rt_orders SET qty = qty + 1 WHERE status='NEW';
  DBMS_OUTPUT.PUT_LINE('SQL%FOUND='||CASE WHEN SQL%FOUND THEN 'TRUE' ELSE 'FALSE' END
                       ||'  SQL%ROWCOUNT='||SQL%ROWCOUNT);
  ROLLBACK; -- keep dataset stable for repeated runs
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 2: DELETE guard: only delete when a condition matches
-- Scenario:
--   Attempt to delete a non-existing order id; show NOTFOUND behavior.
--------------------------------------------------------------------------------
DECLARE
  v_target NUMBER := 999999; -- likely absent
BEGIN
  DELETE FROM rt_orders WHERE order_id = v_target;
  IF SQL%FOUND THEN
    DBMS_OUTPUT.PUT_LINE('Deleted '||SQL%ROWCOUNT||' row(s)');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Nothing deleted for order_id='||v_target);
  END IF;
  ROLLBACK;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 3: Upsert-style flow: UPDATE first, if NOT FOUND then INSERT
-- Scenario:
--   Ensure an order exists with a given key; avoid exceptions.
--------------------------------------------------------------------------------
DECLARE
  v_id   rt_orders.order_id%TYPE := 4200;
  v_cid  rt_orders.customer_id%TYPE := 1;
BEGIN
  UPDATE rt_orders
     SET qty = 2, item_name='Learning Book', unit_price=500, status='NEW'
   WHERE order_id = v_id;

  IF SQL%FOUND THEN
    DBMS_OUTPUT.PUT_LINE('Updated existing order_id='||v_id);
  ELSE
    INSERT INTO rt_orders(order_id, customer_id, item_name, qty, unit_price, status, created_at)
    VALUES (v_id, v_cid, 'Learning Book', 2, 500, 'NEW', SYSDATE);
    DBMS_OUTPUT.PUT_LINE('Inserted new order_id='||v_id);
  END IF;
  ROLLBACK;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 4: SELECT INTO with pre-check to avoid NO_DATA_FOUND
-- Scenario:
--   Safely retrieve a single value using an existence check.
--------------------------------------------------------------------------------
DECLARE
  v_price rt_orders.unit_price%TYPE;
  v_id    rt_orders.order_id%TYPE := 4101;
  v_cnt   NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_cnt FROM rt_orders WHERE order_id=v_id;
  IF v_cnt = 1 THEN
    SELECT unit_price INTO v_price FROM rt_orders WHERE order_id=v_id;
    DBMS_OUTPUT.PUT_LINE('unit_price for '||v_id||' = '||v_price);
  ELSE
    DBMS_OUTPUT.PUT_LINE('order_id='||v_id||' not found or not unique');
  END IF;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 5: SELECT INTO + exception block vs SQL%FOUND (contrast)
-- Scenario:
--   Show traditional exception-based approach, then compare with COUNT pre-check.
--------------------------------------------------------------------------------
DECLARE
  v_email rt_customers.email%TYPE;
BEGIN
  BEGIN
    SELECT email INTO v_email FROM rt_customers WHERE customer_id=9999; -- likely absent
    DBMS_OUTPUT.PUT_LINE('email='||v_email);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('NO_DATA_FOUND caught; consider existence pre-check');
    WHEN TOO_MANY_ROWS THEN
      DBMS_OUTPUT.PUT_LINE('TOO_MANY_ROWS caught; refine filter or SELECT list');
  END;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 6: Multi-step DML: UPDATE, if not found then INSERT into customers
-- Scenario:
--   Toggle is_active to 'Y' for a user; else create the user.
--------------------------------------------------------------------------------
DECLARE
  v_id rt_customers.customer_id%TYPE := 9001;
BEGIN
  UPDATE rt_customers SET is_active='Y' WHERE customer_id=v_id;
  IF SQL%FOUND THEN
    DBMS_OUTPUT.PUT_LINE('Re-activated customer_id='||v_id);
  ELSE
    INSERT INTO rt_customers(customer_id, full_name, email, is_active, created_at)
    VALUES (v_id, 'Trial User', 'trial@example.com', 'Y', SYSDATE);
    DBMS_OUTPUT.PUT_LINE('Inserted new customer_id='||v_id);
  END IF;
  ROLLBACK;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 7: Safe archive: move rows that match condition, report counts
-- Scenario:
--   Illustrate counting and checking before committing.
--------------------------------------------------------------------------------
DECLARE
  v_cnt NUMBER;
BEGIN
  -- pretend archive: mark as CANCELLED and report impact
  UPDATE rt_orders SET status='CANCELLED' WHERE status='NEW' AND created_at < SYSDATE-1;
  v_cnt := SQL%ROWCOUNT;
  IF SQL%FOUND THEN
    DBMS_OUTPUT.PUT_LINE('archived '||v_cnt||' rows to CANCELLED (not committed)');
  ELSE
    DBMS_OUTPUT.PUT_LINE('no rows matched archive criteria');
  END IF;
  ROLLBACK;
END;
/
--------------------------------------------------------------------------------

-- End of Lesson File
