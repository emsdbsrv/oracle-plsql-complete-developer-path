SET SERVEROUTPUT ON SIZE UNLIMITED;
--------------------------------------------------------------------------------
-- Session: 072 – Explicit Cursor Syntax
-- Topic:
--   Declare → OPEN → FETCH → EXIT → CLOSE; cursor attributes (%ISOPEN, %FOUND,
--   %NOTFOUND, %ROWCOUNT); parameterized cursors; join cursors; FOR UPDATE with
--   WHERE CURRENT OF; defensive cleanup in EXCEPTION blocks.
--
-- How to run:
--   • SET SERVEROUTPUT ON;
--   • Execute each block separately (terminated by '/').
--
-- Conventions used:
--   • All example variables are typed with %TYPE to resist column-type changes.
--   • ROLLBACK is used in training examples that modify data.
--   • Each example documents scenario, drivers, and expected outcome.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 0) Bootstrap (idempotent): Create seed tables and data if missing
--------------------------------------------------------------------------------
DECLARE
  v_cnt NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_cnt FROM user_tables WHERE table_name = 'RT_CUSTOMERS';
  IF v_cnt = 0 THEN
    EXECUTE IMMEDIATE q'{
      CREATE TABLE rt_customers(
        customer_id NUMBER PRIMARY KEY,
        full_name   VARCHAR2(60)  NOT NULL,
        email       VARCHAR2(120),
        is_active   CHAR(1)       DEFAULT 'Y' CHECK (is_active IN ('Y','N')),
        created_at  DATE          DEFAULT SYSDATE
      )
    }';
    EXECUTE IMMEDIATE q'{INSERT INTO rt_customers VALUES (1,'Avi','avi@example.com','Y',SYSDATE-60)}';
    EXECUTE IMMEDIATE q'{INSERT INTO rt_customers VALUES (2,'Neha','neha@example.com','Y',SYSDATE-30)}';
  END IF;

  SELECT COUNT(*) INTO v_cnt FROM user_tables WHERE table_name = 'RT_ORDERS';
  IF v_cnt = 0 THEN
    EXECUTE IMMEDIATE q'{
      CREATE TABLE rt_orders(
        order_id    NUMBER        PRIMARY KEY,
        customer_id NUMBER        NOT NULL,
        item_name   VARCHAR2(100) NOT NULL,
        qty         NUMBER(10)    DEFAULT 1 CHECK (qty > 0),
        unit_price  NUMBER(12,2)  CHECK (unit_price >= 0),
        status      VARCHAR2(12)  DEFAULT 'NEW' CHECK (status IN ('NEW','PAID','CANCELLED')),
        created_at  DATE          DEFAULT SYSDATE
      )
    }';
    EXECUTE IMMEDIATE q'{INSERT INTO rt_orders VALUES (6001,1,'SSD 1TB',  1, 6500,'NEW',  SYSDATE-5)}';
    EXECUTE IMMEDIATE q'{INSERT INTO rt_orders VALUES (6002,2,'Laptop',   1,55000,'PAID', SYSDATE-4)}';
    EXECUTE IMMEDIATE q'{INSERT INTO rt_orders VALUES (6003,1,'USB-C Hub',2, 1200,'NEW',  SYSDATE-3)}';
    EXECUTE IMMEDIATE q'{INSERT INTO rt_orders VALUES (6004,2,'Mouse',    1,  900,'NEW',  SYSDATE-1)}';
  END IF;
  COMMIT;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 1: Minimal explicit cursor lifecycle + attributes
-- Scenario:
--   Iterate NEW orders; show how c%ROWCOUNT increments and c%ISOPEN toggles.
-- Drivers:
--   c_new cursor over filtered rows; v_oid/v_itm/v_qty target variables.
-- Expected:
--   Prints one line per row, then shows c%ISOPEN FALSE after CLOSE.
--------------------------------------------------------------------------------
DECLARE
  CURSOR c_new IS
    SELECT order_id, item_name, qty
    FROM   rt_orders
    WHERE  status='NEW'
    ORDER  BY order_id;

  v_oid rt_orders.order_id%TYPE;
  v_itm rt_orders.item_name%TYPE;
  v_qty rt_orders.qty%TYPE;
BEGIN
  OPEN c_new;  -- allocate server resources and bind resultset
  DBMS_OUTPUT.PUT_LINE('OPEN -> c_new%ISOPEN='||CASE WHEN c_new%ISOPEN THEN 'TRUE' ELSE 'FALSE' END);

  LOOP
    FETCH c_new INTO v_oid, v_itm, v_qty; -- advance by one row
    EXIT WHEN c_new%NOTFOUND;             -- after last row, loop exits
    DBMS_OUTPUT.PUT_LINE('#'||c_new%ROWCOUNT||' oid='||v_oid||' item='||v_itm||' qty='||v_qty);
  END LOOP;

  CLOSE c_new; -- always close
  DBMS_OUTPUT.PUT_LINE('CLOSE -> c_new%ISOPEN='||CASE WHEN c_new%ISOPEN THEN 'TRUE' ELSE 'FALSE' END);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 2: Parameterized cursor for reusable WHERE filter
-- Scenario:
--   Reuse the same query body to scan first NEW then PAID orders.
-- Notes:
--   • Parameters are bound at OPEN time.
--   • Each OPEN creates a fresh resultset snapshot for that parameter.
--------------------------------------------------------------------------------
DECLARE
  CURSOR c_by_status(p_status rt_orders.status%TYPE) IS
    SELECT order_id, customer_id, qty
    FROM   rt_orders
    WHERE  status = p_status
    ORDER  BY order_id;

  v_oid rt_orders.order_id%TYPE;
  v_cid rt_orders.customer_id%TYPE;
  v_qty rt_orders.qty%TYPE;
BEGIN
  OPEN c_by_status('NEW');
  LOOP
    FETCH c_by_status INTO v_oid, v_cid, v_qty;
    EXIT WHEN c_by_status%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('[NEW] oid='||v_oid||' cid='||v_cid||' qty='||v_qty);
  END LOOP;
  CLOSE c_by_status;

  OPEN c_by_status('PAID');
  LOOP
    FETCH c_by_status INTO v_oid, v_cid, v_qty;
    EXIT WHEN c_by_status%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('[PAID] oid='||v_oid||' cid='||v_cid||' qty='||v_qty);
  END LOOP;
  CLOSE c_by_status;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 3: Join cursor (orders ↔ customers) with aliases and %TYPE variables
-- Scenario:
--   Print "<customer_name> -> <item> (<status>)" for all orders.
-- Design:
--   • Join inside cursor body; alias columns to control FETCH order.
--   • Variables use %TYPE to stay in sync with table definitions.
--------------------------------------------------------------------------------
DECLARE
  CURSOR c_join IS
    SELECT c.full_name  AS customer_name,
           o.item_name  AS item_name,
           o.status     AS status
    FROM   rt_orders o
    JOIN   rt_customers c ON c.customer_id = o.customer_id
    ORDER  BY o.order_id;

  v_cname rt_customers.full_name%TYPE;
  v_item  rt_orders.item_name%TYPE;
  v_stat  rt_orders.status%TYPE;
BEGIN
  OPEN c_join;
  LOOP
    FETCH c_join INTO v_cname, v_item, v_stat;
    EXIT WHEN c_join%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE(v_cname||' -> '||v_item||' ('||v_stat||')');
  END LOOP;
  CLOSE c_join;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 4: Cursor FOR loop vs manual explicit loop (comparison)
-- Scenario:
--   Show succinct FOR loop that implicitly OPENs/FETCHes/CLOSEs for read-only scans.
-- Guidance:
--   • Prefer FOR loop for read-only traversals.
--   • Choose explicit cursor when you need attributes every step or interleave complex logic.
--------------------------------------------------------------------------------
DECLARE
  CURSOR c IS SELECT order_id, item_name FROM rt_orders WHERE status='NEW' ORDER BY order_id;
  v_id   rt_orders.order_id%TYPE;
  v_item rt_orders.item_name%TYPE;
BEGIN
  -- Manual explicit version
  OPEN c;
  LOOP
    FETCH c INTO v_id, v_item;
    EXIT WHEN c%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('manual '||v_id||' '||v_item);
  END LOOP;
  CLOSE c;

  -- Cursor FOR loop version (preferred for read-only scans)
  FOR r IN c LOOP
    DBMS_OUTPUT.PUT_LINE('forloop '||r.order_id||' '||r.item_name);
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 5: FOR UPDATE + WHERE CURRENT OF (row-by-row update)
-- Scenario:
--   For NEW orders created today, increment qty by 1 using WHERE CURRENT OF.
-- Safety:
--   • Cursor FOR UPDATE locks the selected rows until COMMIT/ROLLBACK.
--   • This example ends with ROLLBACK (training only).
--------------------------------------------------------------------------------
DECLARE
  CURSOR c_todays_new IS
    SELECT order_id, qty
    FROM   rt_orders
    WHERE  status='NEW' AND created_at >= TRUNC(SYSDATE)
    FOR UPDATE OF qty; -- required to use WHERE CURRENT OF
  v_id  rt_orders.order_id%TYPE;
  v_qty rt_orders.qty%TYPE;
BEGIN
  OPEN c_todays_new;
  LOOP
    FETCH c_todays_new INTO v_id, v_qty;
    EXIT WHEN c_todays_new%NOTFOUND;

    UPDATE rt_orders
       SET qty = v_qty + 1
     WHERE CURRENT OF c_todays_new;

    DBMS_OUTPUT.PUT_LINE('incremented order_id='||v_id);
  END LOOP;
  ROLLBACK;
  CLOSE c_todays_new;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 6: Defensive cleanup in EXCEPTION path
-- Scenario:
--   Ensure cursor is closed even when an error occurs inside the loop.
-- Pattern:
--   • Wrap the loop in a nested block; close in outer scope if still open.
--------------------------------------------------------------------------------
DECLARE
  CURSOR c_prices IS
    SELECT order_id, unit_price FROM rt_orders ORDER BY order_id;

  v_id  rt_orders.order_id%TYPE;
  v_prc rt_orders.unit_price%TYPE;
BEGIN
  OPEN c_prices;
  BEGIN
    LOOP
      FETCH c_prices INTO v_id, v_prc;
      EXIT WHEN c_prices%NOTFOUND;
      IF v_prc < 0 THEN
        RAISE_APPLICATION_ERROR(-20772,'negative price not allowed');
      END IF;
      DBMS_OUTPUT.PUT_LINE('ok order_id='||v_id||' price='||v_prc);
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('caught: '||SQLERRM);
  END;

  IF c_prices%ISOPEN THEN
    CLOSE c_prices;
  END IF;
END;
/
--------------------------------------------------------------------------------
-- End of Lesson File
--------------------------------------------------------------------------------
