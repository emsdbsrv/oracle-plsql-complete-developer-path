SET SERVEROUTPUT ON SIZE UNLIMITED;
--------------------------------------------------------------------------------
-- Session: 075 – Simplified FOR Loop Processing
-- Topic:
--   Cursor FOR loops in PL/SQL:
--   • Implicit OPEN–FETCH–EXIT–CLOSE for query-based FOR loops
--   • Using inline queries vs named explicit cursors in FOR loops
--   • Joining multiple tables inside the FOR loop query
--   • Filtering, ordering, and using column aliases
--   • When to prefer FOR loops vs manual explicit cursor handling
--
-- How to run:
--   • Enable DBMS_OUTPUT in your client.
--   • Execute each block separately (terminated by '/').
--   • This script is idempotent; the bootstrap block only creates objects if missing.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 0) Bootstrap: ensure rt_customers and rt_orders exist with sample data
--    If created earlier in other sessions, this block will simply skip creation.
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
    EXECUTE IMMEDIATE q'{INSERT INTO rt_orders VALUES (9001,1,'SSD 1TB',  1, 6500,'NEW',  SYSDATE-5)}';
    EXECUTE IMMEDIATE q'{INSERT INTO rt_orders VALUES (9002,2,'Laptop',   1,55000,'PAID', SYSDATE-4)}';
    EXECUTE IMMEDIATE q'{INSERT INTO rt_orders VALUES (9003,1,'USB-C Hub',2, 1200,'NEW',  SYSDATE-3)}';
    EXECUTE IMMEDIATE q'{INSERT INTO rt_orders VALUES (9004,2,'Mouse',    1,  900,'CANCELLED',SYSDATE-1)}';
  END IF;

  COMMIT;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 1: Basic cursor FOR loop over a simple SELECT
-- Scenario:
--   List all orders, printing order_id, item_name, and status.
-- Key ideas:
--   • The FOR loop implicitly opens a cursor over the SELECT statement.
--   • Each iteration implicitly FETCHes into record variable r.
--   • When there are no more rows, the loop exits and the cursor is closed.
--------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('--- Example 1: All orders via cursor FOR loop ---');
  FOR r IN (
    SELECT order_id, item_name, status
    FROM   rt_orders
    ORDER  BY order_id
  )
  LOOP
    DBMS_OUTPUT.PUT_LINE(
      'order_id='||r.order_id||' item='||r.item_name||' status='||r.status
    );
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 2: Cursor FOR loop with join to rt_customers
-- Scenario:
--   Produce a user-friendly report in the format:
--   "<customer_name> -> order <order_id>: <item_name> (<status>)"
-- Key ideas:
--   • The SELECT inside the FOR loop can join multiple tables.
--   • Column aliases become fields on the loop record variable r.
--------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('--- Example 2: Orders with customer names ---');
  FOR r IN (
    SELECT o.order_id,
           o.item_name,
           o.status,
           c.full_name AS customer_name
    FROM   rt_orders    o
    JOIN   rt_customers c ON c.customer_id = o.customer_id
    ORDER  BY o.order_id
  )
  LOOP
    DBMS_OUTPUT.PUT_LINE(
      r.customer_name||' -> order '||r.order_id||': '||r.item_name||
      ' ('||r.status||')'
    );
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 3: Cursor FOR loop with WHERE filter and computed column
-- Scenario:
--   Show only NEW orders, and compute a total_amount (qty * unit_price) for
--   each row. Demonstrates inline expressions and aliases.
--------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('--- Example 3: NEW orders with computed total ---');
  FOR r IN (
    SELECT order_id,
           item_name,
           qty,
           unit_price,
           (qty * unit_price) AS total_amount
    FROM   rt_orders
    WHERE  status = 'NEW'
    ORDER  BY order_id
  )
  LOOP
    DBMS_OUTPUT.PUT_LINE(
      'order_id='||r.order_id||
      ' item='||r.item_name||
      ' qty='||r.qty||
      ' unit='||r.unit_price||
      ' total='||r.total_amount
    );
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 4: Cursor FOR loop using a named explicit cursor
-- Scenario:
--   Define an explicit cursor c_paid, then use it inside a FOR loop instead
--   of writing the SELECT query inline.
-- Key ideas:
--   • The FOR c_paid_rec IN c_paid LOOP form automatically OPENs and CLOSEs
--     the cursor c_paid, and FETCHes into record variable c_paid_rec.
--------------------------------------------------------------------------------
DECLARE
  CURSOR c_paid IS
    SELECT order_id, item_name, unit_price
    FROM   rt_orders
    WHERE  status = 'PAID'
    ORDER  BY order_id;
BEGIN
  DBMS_OUTPUT.PUT_LINE('--- Example 4: Using named explicit cursor in FOR loop ---');
  FOR c_paid_rec IN c_paid
  LOOP
    DBMS_OUTPUT.PUT_LINE(
      'PAID order '||c_paid_rec.order_id||' -> '||c_paid_rec.item_name||
      ' amount='||c_paid_rec.unit_price
    );
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 5: Cursor FOR loop with simple parameter pattern via subquery
-- Scenario:
--   The filter value comes from a variable; instead of a parameterized cursor,
--   we use a WHERE clause that references a PL/SQL variable.
-- Design:
--   • Declare p_status and p_min_amount.
--   • Use them inside the query in the FOR loop.
--------------------------------------------------------------------------------
DECLARE
  p_status     rt_orders.status%TYPE      := 'NEW';
  p_min_amount rt_orders.unit_price%TYPE  := 1000;
BEGIN
  DBMS_OUTPUT.PUT_LINE('--- Example 5: Filter using PL/SQL variables ---');
  FOR r IN (
    SELECT order_id, item_name, unit_price, status
    FROM   rt_orders
    WHERE  status = p_status
    AND    unit_price >= p_min_amount
    ORDER  BY unit_price DESC
  )
  LOOP
    DBMS_OUTPUT.PUT_LINE(
      'status='||r.status||' order_id='||r.order_id||
      ' item='||r.item_name||' amount='||r.unit_price
    );
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 6: Nested FOR loops (customer -> orders)
-- Scenario:
--   Outer loop scans all customers; inner loop scans orders per customer.
--   Result format:
--     Customer: <name>
--       order <id>: <item> (<status>)
-- Notes:
--   • Each FOR loop has its own implicit cursor context.
--   • This is logically similar to two nested explicit cursors, but shorter.
--------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('--- Example 6: Nested FOR loops (customers and orders) ---');
  FOR c IN (
    SELECT customer_id, full_name
    FROM   rt_customers
    ORDER  BY customer_id
  )
  LOOP
    DBMS_OUTPUT.PUT_LINE('Customer: '||c.full_name||' (id='||c.customer_id||')');

    FOR o IN (
      SELECT order_id, item_name, status
      FROM   rt_orders
      WHERE  customer_id = c.customer_id
      ORDER  BY order_id
    )
    LOOP
      DBMS_OUTPUT.PUT_LINE(
        '  order '||o.order_id||': '||o.item_name||' ('||o.status||')'
      );
    END LOOP;
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 7: When NOT to use cursor FOR loops
-- Scenario:
--   Show a pattern where you may prefer explicit cursors instead of FOR loops.
--   This block prints guidance rather than data.
-- Notes:
--   • FOR loops are excellent for simple, read-only scans.
--   • Explicit cursors are better when you need:
--       - Row-by-row updates with WHERE CURRENT OF
--       - Fine-grained control over FETCH timing and error handling
--       - Access to cursor attributes after the loop completes
--------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('--- Example 7: Design guidance ---');
  DBMS_OUTPUT.PUT_LINE('Use cursor FOR loops for:');
  DBMS_OUTPUT.PUT_LINE('  • Simple read-only scans of query results');
  DBMS_OUTPUT.PUT_LINE('  • Reporting where each row is printed once');
  DBMS_OUTPUT.PUT_LINE('Use explicit cursors for:');
  DBMS_OUTPUT.PUT_LINE('  • Row-level locking and WHERE CURRENT OF updates');
  DBMS_OUTPUT.PUT_LINE('  • Complex error handling per FETCH');
  DBMS_OUTPUT.PUT_LINE('  • Scenarios where you must inspect %ROWCOUNT/%FOUND after loop');
END;
/
--------------------------------------------------------------------------------
-- End of Lesson File
--------------------------------------------------------------------------------
