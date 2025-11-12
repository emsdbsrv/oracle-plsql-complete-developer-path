SET SERVEROUTPUT ON SIZE UNLIMITED;
--------------------------------------------------------------------------------
-- Session: 063 – Database Table Record Types
-- Focus:
--   Work with table-shaped records using %ROWTYPE and keep scalars aligned with %TYPE.
--   New table introduced: rt_orders (separate from rt_customers in Session 062).
--
-- Covered Examples:
--   (1) Create rt_orders and seed data
--   (2) Load a row into rt_orders%ROWTYPE
--   (3) Update a row using a table-shaped record
--   (4) Transfer data between cursor%ROWTYPE and table%ROWTYPE
--   (5) Parameterize procedures with %TYPE and %ROWTYPE
--   (6) Safe INSERT using a %ROWTYPE record
--
-- How to run:
--   SET SERVEROUTPUT ON; Execute each block separately (terminated by '/').
-- Notes:
--   • %ROWTYPE yields a record matching the table layout at compile time.
--   • %TYPE mirrors a single column's type and constraints, reducing errors.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 0) Lab setup (idempotent) — create orders table
--------------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'DROP TABLE rt_orders PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE TABLE rt_orders(
  order_id     NUMBER        CONSTRAINT rt_orders_pk PRIMARY KEY,
  customer_id  NUMBER        NOT NULL,
  item_name    VARCHAR2(100) NOT NULL,
  qty          NUMBER(10)    DEFAULT 1 CHECK (qty > 0),
  unit_price   NUMBER(12,2)  NOT NULL CHECK (unit_price >= 0),
  status       VARCHAR2(12)  DEFAULT 'NEW' CHECK (status IN ('NEW','PAID','CANCELLED')),
  created_at   DATE          DEFAULT SYSDATE NOT NULL
);

INSERT INTO rt_orders(order_id, customer_id, item_name, qty, unit_price, status, created_at)
VALUES (1001, 1, 'SSD 1TB', 1, 6500, 'NEW', SYSDATE-5);
INSERT INTO rt_orders VALUES (1002, 2, 'Laptop', 1, 55000, 'PAID', SYSDATE-2);
INSERT INTO rt_orders VALUES (1003, 1, 'USB-C Hub', 2, 1200, 'NEW', SYSDATE-1);
COMMIT;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1) Example: Load a row into table%ROWTYPE via SELECT * INTO
-- Scenario:
--   Use rt_orders%ROWTYPE to hold the full row and print selected fields.
--------------------------------------------------------------------------------
DECLARE
  r rt_orders%ROWTYPE;  -- record shape mirrors the table columns
BEGIN
  SELECT * INTO r FROM rt_orders WHERE order_id = 1002;
  DBMS_OUTPUT.PUT_LINE('order '||r.order_id||' item='||r.item_name||' qty='||r.qty||' status='||r.status);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 2) Example: Update using a table-shaped record
-- Scenario:
--   Load row into record, modify fields on the record, then push changes with an UPDATE.
--------------------------------------------------------------------------------
DECLARE
  r rt_orders%ROWTYPE;
BEGIN
  SELECT * INTO r FROM rt_orders WHERE order_id = 1001;
  r.qty := r.qty + 1;                 -- increment quantity
  r.status := 'PAID';                 -- change status

  UPDATE rt_orders
     SET qty = r.qty,
         status = r.status
   WHERE order_id = r.order_id;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('updated order_id='||r.order_id||' qty='||r.qty||' status='||r.status);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 3) Example: Transfer between cursor%ROWTYPE and table%ROWTYPE
-- Scenario:
--   Build a projection cursor with aliases (projection-shaped record),
--   then move compatible fields to a table-shaped record for DML.
--------------------------------------------------------------------------------
DECLARE
  CURSOR c_proj IS
    SELECT order_id oid, item_name itm, qty q, unit_price price
      FROM rt_orders
     WHERE status = 'NEW'
     ORDER BY order_id;

  v c_proj%ROWTYPE;           -- fields: oid, itm, q, price
  t rt_orders%ROWTYPE;        -- table-shaped

BEGIN
  OPEN c_proj;
  LOOP
    FETCH c_proj INTO v;
    EXIT WHEN c_proj%NOTFOUND;

    -- Load the full table row to keep other fields intact
    SELECT * INTO t FROM rt_orders WHERE order_id = v.oid;

    -- Update using mixed sources (projection + existing table fields)
    t.qty := v.q + 1;  -- e.g., bump qty for NEW orders
    UPDATE rt_orders
       SET qty = t.qty
     WHERE order_id = t.order_id;
  END LOOP;
  CLOSE c_proj;
  COMMIT;

  DBMS_OUTPUT.PUT_LINE('projection-to-table transfer completed.');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 4) Example: Procedure APIs with %TYPE and %ROWTYPE
-- Scenario:
--   Use %TYPE for scalar arguments and %ROWTYPE for OUT parameters to keep types aligned.
--------------------------------------------------------------------------------
DECLARE
  PROCEDURE load_order(p_id IN rt_orders.order_id%TYPE, p_out OUT rt_orders%ROWTYPE) IS
  BEGIN
    SELECT * INTO p_out FROM rt_orders WHERE order_id = p_id;
  END;

  PROCEDURE set_status(p_id IN rt_orders.order_id%TYPE, p_status IN rt_orders.status%TYPE) IS
  BEGIN
    UPDATE rt_orders SET status = p_status WHERE order_id = p_id;
  END;

  r rt_orders%ROWTYPE;
BEGIN
  load_order(1003, r);
  DBMS_OUTPUT.PUT_LINE('before -> '||r.order_id||' status='||r.status);

  set_status(1003, 'PAID');
  load_order(1003, r);
  DBMS_OUTPUT.PUT_LINE('after  -> '||r.order_id||' status='||r.status);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 5) Example: Safe INSERT using a %ROWTYPE record
-- Scenario:
--   Populate a table-shaped record and insert it, avoiding mismatched types/lengths.
--------------------------------------------------------------------------------
DECLARE
  r rt_orders%ROWTYPE;
BEGIN
  r.order_id   := 2001;
  r.customer_id:= 3;
  r.item_name  := 'Monitor 27"';
  r.qty        := 1;
  r.unit_price := 18500;
  r.status     := 'NEW';
  r.created_at := SYSDATE;

  INSERT INTO rt_orders VALUES r;
  COMMIT;

  DBMS_OUTPUT.PUT_LINE('inserted order '||r.order_id||' item='||r.item_name);
END;
/
--------------------------------------------------------------------------------

-- End of Lesson File
