SET SERVEROUTPUT ON SIZE UNLIMITED;
--------------------------------------------------------------------------------
-- Session: 073 – OPEN–FETCH–CLOSE Pattern
-- Purpose:
--   Demonstrate the explicit cursor lifecycle and REF CURSOR usage with detailed,
--   step-by-step commentary:
--   (1) Static explicit cursor OPEN–FETCH–EXIT–CLOSE
--   (2) Cursor attributes and row counting
--   (3) REF CURSOR with OPEN ... FOR (dynamic query)
--   (4) Parameterized REF CURSOR helper procedure
--   (5) Exception-safe cleanup and responsibility for closing cursors
--
-- How to run:
--   • Ensure SERVEROUTPUT is enabled.
--   • Execute each block separately (terminated by '/').
--   • This script is idempotent; bootstrap block creates demo tables if missing.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 0) Bootstrap: ensure rt_customers and rt_orders exist with some sample rows
--------------------------------------------------------------------------------
DECLARE
  v_cnt NUMBER;
BEGIN
  -- rt_customers
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
    EXECUTE IMMEDIATE q'{INSERT INTO rt_customers VALUES (1,'Avi','avi@example.com','Y',SYSDATE-45)}';
    EXECUTE IMMEDIATE q'{INSERT INTO rt_customers VALUES (2,'Neha','neha@example.com','Y',SYSDATE-20)}';
  END IF;

  -- rt_orders
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
    EXECUTE IMMEDIATE q'{INSERT INTO rt_orders VALUES (7001,1,'SSD 1TB',  1, 6500,'NEW',  SYSDATE-5)}';
    EXECUTE IMMEDIATE q'{INSERT INTO rt_orders VALUES (7002,2,'Laptop',   1,55000,'PAID', SYSDATE-4)}';
    EXECUTE IMMEDIATE q'{INSERT INTO rt_orders VALUES (7003,1,'USB-C Hub',2, 1200,'NEW',  SYSDATE-3)}';
    EXECUTE IMMEDIATE q'{INSERT INTO rt_orders VALUES (7004,2,'Mouse',    1,  900,'CANCELLED',SYSDATE-1)}';
  END IF;
  COMMIT;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 1: Classic OPEN–FETCH–EXIT–CLOSE with static explicit cursor
-- Scenario:
--   Iterate NEW orders and print each order_id and item_name.
-- Drivers:
--   • Cursor c_new over filtered rt_orders rows.
--   • Loop condition uses c_new%NOTFOUND after each FETCH.
--------------------------------------------------------------------------------
DECLARE
  CURSOR c_new IS
    SELECT order_id, item_name
    FROM   rt_orders
    WHERE  status = 'NEW'
    ORDER  BY order_id;

  v_order_id  rt_orders.order_id%TYPE;
  v_item_name rt_orders.item_name%TYPE;
BEGIN
  OPEN c_new;  -- allocate cursor and attach result set
  DBMS_OUTPUT.PUT_LINE('Opened c_new');

  LOOP
    FETCH c_new INTO v_order_id, v_item_name; -- move to next row
    EXIT WHEN c_new%NOTFOUND;                -- stop once no more rows
    DBMS_OUTPUT.PUT_LINE('NEW order '||v_order_id||' -> '||v_item_name);
  END LOOP;

  CLOSE c_new; -- always close
  DBMS_OUTPUT.PUT_LINE('Closed c_new');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 2: OPEN–FETCH–CLOSE with attributes (%ROWCOUNT, %ISOPEN)
-- Scenario:
--   Show how c%ROWCOUNT increases per successful FETCH and how %ISOPEN behaves.
--------------------------------------------------------------------------------
DECLARE
  CURSOR c_all IS
    SELECT order_id, status
    FROM   rt_orders
    ORDER  BY order_id;

  v_id    rt_orders.order_id%TYPE;
  v_stat  rt_orders.status%TYPE;
BEGIN
  OPEN c_all;
  DBMS_OUTPUT.PUT_LINE('c_all%ISOPEN after OPEN = '||CASE WHEN c_all%ISOPEN THEN 'TRUE' ELSE 'FALSE' END);

  LOOP
    FETCH c_all INTO v_id, v_stat;
    EXIT WHEN c_all%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('#'||c_all%ROWCOUNT||' -> order_id='||v_id||' status='||v_stat);
  END LOOP;

  CLOSE c_all;
  DBMS_OUTPUT.PUT_LINE('c_all%ISOPEN after CLOSE = '||CASE WHEN c_all%ISOPEN THEN 'TRUE' ELSE 'FALSE' END);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 3: REF CURSOR (weak) with dynamic query via OPEN ... FOR
-- Scenario:
--   Build a WHERE clause at runtime (status and min_unit_price) and OPEN a
--   REF CURSOR FOR a dynamic SELECT. Then FETCH until NOTFOUND.
-- Notes:
--   • REF CURSOR variables must still follow OPEN–FETCH–CLOSE pattern.
--   • Here we use SYS_REFCURSOR (predefined weak REF CURSOR type).
--------------------------------------------------------------------------------
DECLARE
  v_rc         SYS_REFCURSOR;         -- weak REF CURSOR
  v_sql        VARCHAR2(4000);        -- dynamic SQL text
  v_status     rt_orders.status%TYPE := 'NEW';
  v_min_price  rt_orders.unit_price%TYPE := 1000;
  v_id         rt_orders.order_id%TYPE;
  v_item       rt_orders.item_name%TYPE;
  v_price      rt_orders.unit_price%TYPE;
BEGIN
  v_sql := 'SELECT order_id, item_name, unit_price ' ||
           'FROM rt_orders ' ||
           'WHERE status = :b_status AND unit_price >= :b_min ' ||
           'ORDER BY order_id';

  OPEN v_rc FOR v_sql USING v_status, v_min_price;

  LOOP
    FETCH v_rc INTO v_id, v_item, v_price;
    EXIT WHEN v_rc%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('REF: '||v_id||' '||v_item||' price='||v_price);
  END LOOP;

  CLOSE v_rc;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 4: Parameterized REF CURSOR helper procedure
-- Scenario:
--   Encapsulate dynamic query construction into a helper procedure that returns
--   an open REF CURSOR. The caller is responsible for FETCH and CLOSE.
-- Pattern:
--   • Procedure get_orders_by_status(p_status, p_rc OUT SYS_REFCURSOR)
--   • Caller: OPEN is performed inside helper; caller just FETCHes.
--------------------------------------------------------------------------------
DECLARE
  PROCEDURE get_orders_by_status(
    p_status IN  rt_orders.status%TYPE,
    p_rc     OUT SYS_REFCURSOR
  ) IS
  BEGIN
    OPEN p_rc FOR
      SELECT o.order_id, o.item_name, o.status, c.full_name AS customer_name
      FROM   rt_orders   o
      JOIN   rt_customers c ON c.customer_id = o.customer_id
      WHERE  o.status = p_status
      ORDER  BY o.order_id;
  END get_orders_by_status;

  v_rc    SYS_REFCURSOR;
  v_id    rt_orders.order_id%TYPE;
  v_item  rt_orders.item_name%TYPE;
  v_stat  rt_orders.status%TYPE;
  v_name  rt_customers.full_name%TYPE;
BEGIN
  -- Get cursor for NEW orders
  get_orders_by_status('NEW', v_rc);

  LOOP
    FETCH v_rc INTO v_id, v_item, v_stat, v_name;
    EXIT WHEN v_rc%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('helper NEW -> '||v_id||' '||v_item||' ('||v_stat||') for '||v_name);
  END LOOP;

  CLOSE v_rc; -- caller must close
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 5: OPEN–FETCH–CLOSE inside a reusable reporting procedure
-- Scenario:
--   Provide a static explicit cursor inside a procedure that prints all orders
--   above a given minimum amount. Demonstrates packaging the pattern.
--------------------------------------------------------------------------------
DECLARE
  PROCEDURE print_orders_above_amount(p_min_amount IN rt_orders.unit_price%TYPE) IS
    CURSOR c_high IS
      SELECT order_id, item_name, unit_price
      FROM   rt_orders
      WHERE  unit_price >= p_min_amount
      ORDER  BY unit_price DESC;

    v_id   rt_orders.order_id%TYPE;
    v_item rt_orders.item_name%TYPE;
    v_amt  rt_orders.unit_price%TYPE;
  BEGIN
    OPEN c_high;
    LOOP
      FETCH c_high INTO v_id, v_item, v_amt;
      EXIT WHEN c_high%NOTFOUND;
      DBMS_OUTPUT.PUT_LINE('order='||v_id||' item='||v_item||' amount='||v_amt);
    END LOOP;
    CLOSE c_high;
  END print_orders_above_amount;
BEGIN
  DBMS_OUTPUT.PUT_LINE('--- Orders with amount >= 5000 ---');
  print_orders_above_amount(5000);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 6: Exception-safe cleanup for explicit cursor
-- Scenario:
--   Show that even if an error occurs mid-loop, we still close the cursor.
-- Pattern:
--   • Open cursor in outer block.
--   • Fetch loop in inner BEGIN..EXCEPTION..END.
--   • In outer block, IF c%ISOPEN THEN CLOSE c; END IF;
--------------------------------------------------------------------------------
DECLARE
  CURSOR c_demo IS
    SELECT order_id, unit_price
    FROM   rt_orders
    ORDER  BY order_id;

  v_id   rt_orders.order_id%TYPE;
  v_amt  rt_orders.unit_price%TYPE;
BEGIN
  OPEN c_demo;
  BEGIN
    LOOP
      FETCH c_demo INTO v_id, v_amt;
      EXIT WHEN c_demo%NOTFOUND;

      -- Artificial error condition: treat huge amount as invalid
      IF v_amt > 100000 THEN
        RAISE_APPLICATION_ERROR(-20999,'Amount too large for demo');
      END IF;

      DBMS_OUTPUT.PUT_LINE('ok '||v_id||' amount='||v_amt);
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Caught error inside loop: '||SQLERRM);
  END;

  IF c_demo%ISOPEN THEN
    CLOSE c_demo;
    DBMS_OUTPUT.PUT_LINE('c_demo closed in outer block');
  END IF;
END;
/
--------------------------------------------------------------------------------
-- End of Lesson File
--------------------------------------------------------------------------------
