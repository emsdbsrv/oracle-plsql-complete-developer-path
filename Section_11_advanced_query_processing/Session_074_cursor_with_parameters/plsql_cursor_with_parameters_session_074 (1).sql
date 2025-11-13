SET SERVEROUTPUT ON SIZE UNLIMITED;
--------------------------------------------------------------------------------
-- Session: 074 – Cursor with Parameters
-- Topic:
--   Parameterized explicit cursors in PL/SQL:
--   • Passing filter values (status, date range, minimum amount)
--   • Reusing the same cursor body with different parameter sets
--   • Combining parameters with joins (orders and customers)
--   • Good practices for readability and performance
--
-- How to run:
--   • Enable DBMS_OUTPUT (SET SERVEROUTPUT ON SIZE UNLIMITED).
--   • Execute each block separately, terminated by a single '/'. 
--   • This script is idempotent; the bootstrap block only creates objects if missing.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 0) Bootstrap: ensure rt_customers and rt_orders exist and have some rows
--    These tables are reused across multiple sessions. If they already exist
--    from earlier lessons, this block will simply detect them and skip creation.
--------------------------------------------------------------------------------
DECLARE
  v_cnt NUMBER;
BEGIN
  -- rt_customers
  SELECT COUNT(*) INTO v_cnt FROM user_tables WHERE table_name = 'RT_CUSTOMERS';
  IF v_cnt = 0 THEN
    EXECUTE IMMEDIATE q'{
      CREATE TABLE rt_customers(
        customer_id NUMBER       PRIMARY KEY,
        full_name   VARCHAR2(60) NOT NULL,
        email       VARCHAR2(120),
        is_active   CHAR(1)      DEFAULT 'Y' CHECK (is_active IN ('Y','N')),
        created_at  DATE         DEFAULT SYSDATE
      )
    }';
    EXECUTE IMMEDIATE q'{INSERT INTO rt_customers VALUES (1,'Avi','avi@example.com','Y',SYSDATE-60)}';
    EXECUTE IMMEDIATE q'{INSERT INTO rt_customers VALUES (2,'Neha','neha@example.com','Y',SYSDATE-30)}';
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
    EXECUTE IMMEDIATE q'{INSERT INTO rt_orders VALUES (8001,1,'SSD 1TB',  1, 6500,'NEW',  SYSDATE-5)}';
    EXECUTE IMMEDIATE q'{INSERT INTO rt_orders VALUES (8002,2,'Laptop',   1,55000,'PAID', SYSDATE-4)}';
    EXECUTE IMMEDIATE q'{INSERT INTO rt_orders VALUES (8003,1,'USB-C Hub',2, 1200,'NEW',  SYSDATE-3)}';
    EXECUTE IMMEDIATE q'{INSERT INTO rt_orders VALUES (8004,2,'Mouse',    1,  900,'CANCELLED',SYSDATE-1)}';
  END IF;

  COMMIT;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 1: Single-parameter cursor for simple status filter
-- Scenario:
--   A parameterized cursor c_by_status(p_status) that returns orders matching
--   the given status. The same cursor body is reused for different statuses.
-- Key ideas:
--   • Parameter appears in the cursor signature and in the WHERE clause.
--   • Each OPEN binds a different value to p_status and generates its own result set.
--------------------------------------------------------------------------------
DECLARE
  CURSOR c_by_status(p_status rt_orders.status%TYPE) IS
    SELECT order_id, status, item_name
    FROM   rt_orders
    WHERE  status = p_status
    ORDER  BY order_id;

  v_id    rt_orders.order_id%TYPE;
  v_stat  rt_orders.status%TYPE;
  v_item  rt_orders.item_name%TYPE;
BEGIN
  DBMS_OUTPUT.PUT_LINE('--- Orders with status = NEW ---');
  OPEN c_by_status('NEW');
  LOOP
    FETCH c_by_status INTO v_id, v_stat, v_item;
    EXIT WHEN c_by_status%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('order_id='||v_id||' status='||v_stat||' item='||v_item);
  END LOOP;
  CLOSE c_by_status;

  DBMS_OUTPUT.PUT_LINE('--- Orders with status = PAID ---');
  OPEN c_by_status('PAID');
  LOOP
    FETCH c_by_status INTO v_id, v_stat, v_item;
    EXIT WHEN c_by_status%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('order_id='||v_id||' status='||v_stat||' item='||v_item);
  END LOOP;
  CLOSE c_by_status;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 2: Two-parameter cursor (status and minimum amount)
-- Scenario:
--   A cursor that returns orders for a given status and minimum unit_price.
--   This mimics many production patterns like "all paid orders above threshold".
-- Key ideas:
--   • Parameters can be of different types and used together in WHERE clause.
--   • The plan can often be shared across parameter combinations by the optimizer.
--------------------------------------------------------------------------------
DECLARE
  CURSOR c_status_amount(
    p_status     rt_orders.status%TYPE,
    p_min_amount rt_orders.unit_price%TYPE
  ) IS
    SELECT order_id, item_name, unit_price, status
    FROM   rt_orders
    WHERE  status = p_status
    AND    unit_price >= p_min_amount
    ORDER  BY unit_price DESC;

  v_id   rt_orders.order_id%TYPE;
  v_item rt_orders.item_name%TYPE;
  v_amt  rt_orders.unit_price%TYPE;
  v_stat rt_orders.status%TYPE;
BEGIN
  DBMS_OUTPUT.PUT_LINE('--- NEW orders with amount >= 1000 ---');
  OPEN c_status_amount('NEW', 1000);
  LOOP
    FETCH c_status_amount INTO v_id, v_item, v_amt, v_stat;
    EXIT WHEN c_status_amount%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('id='||v_id||' item='||v_item||' amt='||v_amt||' status='||v_stat);
  END LOOP;
  CLOSE c_status_amount;

  DBMS_OUTPUT.PUT_LINE('--- PAID orders with amount >= 5000 ---');
  OPEN c_status_amount('PAID', 5000);
  LOOP
    FETCH c_status_amount INTO v_id, v_item, v_amt, v_stat;
    EXIT WHEN c_status_amount%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('id='||v_id||' item='||v_item||' amt='||v_amt||' status='||v_stat);
  END LOOP;
  CLOSE c_status_amount;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 3: Date-range parameterized cursor
-- Scenario:
--   A cursor that returns orders for a given customer within a date range.
-- Parameters:
--   • p_customer_id : which customer to report
--   • p_from_date   : inclusive start of period
--   • p_to_date     : inclusive end of period
-- Notes:
--   • TRUNC is used to normalise date comparisons on created_at.
--------------------------------------------------------------------------------
DECLARE
  CURSOR c_orders_period(
    p_customer_id rt_orders.customer_id%TYPE,
    p_from_date   DATE,
    p_to_date     DATE
  ) IS
    SELECT order_id, created_at, item_name, unit_price
    FROM   rt_orders
    WHERE  customer_id = p_customer_id
    AND    TRUNC(created_at) BETWEEN TRUNC(p_from_date) AND TRUNC(p_to_date)
    ORDER  BY created_at;

  v_id    rt_orders.order_id%TYPE;
  v_date  rt_orders.created_at%TYPE;
  v_item  rt_orders.item_name%TYPE;
  v_amt   rt_orders.unit_price%TYPE;
BEGIN
  DBMS_OUTPUT.PUT_LINE('--- Orders for customer 1 in last 10 days ---');
  OPEN c_orders_period(
    p_customer_id => 1,
    p_from_date   => SYSDATE-10,
    p_to_date     => SYSDATE
  );

  LOOP
    FETCH c_orders_period INTO v_id, v_date, v_item, v_amt;
    EXIT WHEN c_orders_period%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('id='||v_id||' dt='||TO_CHAR(v_date,'YYYY-MM-DD')||
                         ' item='||v_item||' amt='||v_amt);
  END LOOP;

  CLOSE c_orders_period;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 4: Join cursor with parameter (customer filter)
-- Scenario:
--   Combine parameters with joins to print a human-readable report:
--   "<customer_name> -> order <id> : <item> (<status>)"
-- Parameter:
--   • p_customer_id : restrict report to a single customer
--------------------------------------------------------------------------------
DECLARE
  CURSOR c_customer_orders(p_customer_id rt_customers.customer_id%TYPE) IS
    SELECT c.full_name      AS customer_name,
           o.order_id       AS order_id,
           o.item_name      AS item_name,
           o.status         AS status,
           o.unit_price     AS unit_price
    FROM   rt_customers c
    JOIN   rt_orders    o ON o.customer_id = c.customer_id
    WHERE  c.customer_id = p_customer_id
    ORDER  BY o.order_id;

  v_name rt_customers.full_name%TYPE;
  v_id   rt_orders.order_id%TYPE;
  v_item rt_orders.item_name%TYPE;
  v_stat rt_orders.status%TYPE;
  v_amt  rt_orders.unit_price%TYPE;
BEGIN
  DBMS_OUTPUT.PUT_LINE('--- Orders for customer_id = 1 ---');
  OPEN c_customer_orders(1);
  LOOP
    FETCH c_customer_orders INTO v_name, v_id, v_item, v_stat, v_amt;
    EXIT WHEN c_customer_orders%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE(v_name||' -> order '||v_id||' : '||v_item||
                         ' ('||v_stat||', '||v_amt||')');
  END LOOP;
  CLOSE c_customer_orders;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 5: Parameter used to control conceptual "mode"
-- Scenario:
--   A cursor that uses the parameter to control which logical slice of data
--   is returned (for example, "active" vs "inactive" customers). Here we show
--   a simple pattern using CASE in the WHERE clause.
-- Notes:
--   • This allows one cursor definition to support multiple report variants.
--------------------------------------------------------------------------------
DECLARE
  CURSOR c_customers_by_flag(p_active_flag CHAR) IS
    SELECT customer_id, full_name, is_active
    FROM   rt_customers
    WHERE  (p_active_flag = 'A' AND is_active = 'Y')
       OR  (p_active_flag = 'I' AND is_active = 'N')
    ORDER  BY customer_id;

  v_id   rt_customers.customer_id%TYPE;
  v_name rt_customers.full_name%TYPE;
  v_act  rt_customers.is_active%TYPE;
BEGIN
  DBMS_OUTPUT.PUT_LINE('--- Active customers (p_active_flag = A) ---');
  OPEN c_customers_by_flag('A');
  LOOP
    FETCH c_customers_by_flag INTO v_id, v_name, v_act;
    EXIT WHEN c_customers_by_flag%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('id='||v_id||' name='||v_name||' active='||v_act);
  END LOOP;
  CLOSE c_customers_by_flag;

  DBMS_OUTPUT.PUT_LINE('--- Inactive customers (p_active_flag = I) ---');
  -- If none exist, the cursor simply returns zero rows and the loop body never runs.
  OPEN c_customers_by_flag('I');
  LOOP
    FETCH c_customers_by_flag INTO v_id, v_name, v_act;
    EXIT WHEN c_customers_by_flag%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('id='||v_id||' name='||v_name||' active='||v_act);
  END LOOP;
  CLOSE c_customers_by_flag;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 6: Using parameterized cursor inside a reusable procedure
-- Scenario:
--   Wrap parameterized cursor logic inside a procedure show_orders_for_status
--   so that calling code only passes parameters and does not repeat the loop.
-- Notes:
--   • This is a common pattern for reusable reporting and data access layers.
--------------------------------------------------------------------------------
DECLARE
  PROCEDURE show_orders_for_status(
    p_status      IN rt_orders.status%TYPE,
    p_min_amount  IN rt_orders.unit_price%TYPE
  ) IS
    CURSOR c_orders IS
      SELECT order_id, item_name, unit_price
      FROM   rt_orders
      WHERE  status = p_status
      AND    unit_price >= p_min_amount
      ORDER  BY order_id;

    v_id   rt_orders.order_id%TYPE;
    v_item rt_orders.item_name%TYPE;
    v_amt  rt_orders.unit_price%TYPE;
  BEGIN
    DBMS_OUTPUT.PUT_LINE('Orders with status='||p_status||
                         ' and unit_price>='||p_min_amount);
    OPEN c_orders;
    LOOP
      FETCH c_orders INTO v_id, v_item, v_amt;
      EXIT WHEN c_orders%NOTFOUND;
      DBMS_OUTPUT.PUT_LINE('  '||v_id||' -> '||v_item||' amt='||v_amt);
    END LOOP;
    CLOSE c_orders;
  END show_orders_for_status;
BEGIN
  show_orders_for_status('NEW', 500);
  show_orders_for_status('PAID', 10000);
END;
/
--------------------------------------------------------------------------------
-- End of Lesson File
--------------------------------------------------------------------------------
