SET SERVEROUTPUT ON SIZE UNLIMITED;
--------------------------------------------------------------------------------
-- Session: 067 – Procedure Record Parameters
-- Purpose:
--   Show practical techniques for defining and passing PL/SQL records to procedures
--   using IN, OUT, and IN OUT modes. Uses rt_customers and rt_orders.
--
-- Covered Examples (≥5):
--   (1) OUT loader: load_customer(p_id IN %TYPE, p_out OUT rt_customers%ROWTYPE)
--   (2) IN updater: update_order_status(p_row IN rt_orders%ROWTYPE)
--   (3) IN OUT mutator: bump_qty(p_row IN OUT rt_orders%ROWTYPE)
--   (4) Projection mapping: cursor%ROWTYPE -> table%ROWTYPE via procedure
--   (5) Custom API record with validator IN + OUT round trip
--   (6) Defensive wrapper with error handling and messages
--
-- How to run:
--   Execute each block separately (terminated by '/'). Ensure SERVEROUTPUT is ON.
-- Notes:
--   • Use %TYPE and %ROWTYPE to keep parameter types tied to columns/tables.
--   • Prefer explicit field copies when shapes differ between records.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 0) Bootstrap (idempotent) — ensure base tables exist and seeded
--------------------------------------------------------------------------------
DECLARE
  v NUMBER;
BEGIN
  SELECT COUNT(*) INTO v FROM user_tables WHERE table_name = 'RT_CUSTOMERS';
  IF v = 0 THEN
    EXECUTE IMMEDIATE 'CREATE TABLE rt_customers(
      customer_id   NUMBER       CONSTRAINT rt_customers_pk PRIMARY KEY,
      full_name     VARCHAR2(60) NOT NULL,
      email         VARCHAR2(120),
      is_active     CHAR(1)      DEFAULT ''Y'' CHECK (is_active IN (''Y'',''N'')),
      created_at    DATE         DEFAULT SYSDATE
    )';
    EXECUTE IMMEDIATE 'INSERT INTO rt_customers VALUES (1, ''Avi'', ''avi@example.com'', ''Y'', SYSDATE-10)';
    EXECUTE IMMEDIATE 'INSERT INTO rt_customers VALUES (2, ''Neha'', ''neha@example.com'', ''Y'', SYSDATE-5)';
    EXECUTE IMMEDIATE 'COMMIT';
  END IF;

  SELECT COUNT(*) INTO v FROM user_tables WHERE table_name = 'RT_ORDERS';
  IF v = 0 THEN
    EXECUTE IMMEDIATE 'CREATE TABLE rt_orders(
      order_id     NUMBER        CONSTRAINT rt_orders_pk PRIMARY KEY,
      customer_id  NUMBER        NOT NULL,
      item_name    VARCHAR2(100) NOT NULL,
      qty          NUMBER(10)    DEFAULT 1 CHECK (qty > 0),
      unit_price   NUMBER(12,2)  NOT NULL CHECK (unit_price >= 0),
      status       VARCHAR2(12)  DEFAULT ''NEW'' CHECK (status IN (''NEW'',''PAID'',''CANCELLED'')),
      created_at   DATE          DEFAULT SYSDATE NOT NULL
    )';
    EXECUTE IMMEDIATE 'INSERT INTO rt_orders VALUES (1001,1,''SSD 1TB'',1,6500,''NEW'',SYSDATE-5)';
    EXECUTE IMMEDIATE 'INSERT INTO rt_orders VALUES (1002,2,''Laptop'',1,55000,''PAID'',SYSDATE-2)';
    EXECUTE IMMEDIATE 'INSERT INTO rt_orders VALUES (1003,1,''USB-C Hub'',2,1200,''NEW'',SYSDATE-1)';
    EXECUTE IMMEDIATE 'COMMIT';
  END IF;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1) OUT loader: return a full table-shaped record to the caller
--------------------------------------------------------------------------------
DECLARE
  PROCEDURE load_customer(p_id IN rt_customers.customer_id%TYPE,
                          p_out OUT rt_customers%ROWTYPE) IS
  BEGIN
    SELECT * INTO p_out FROM rt_customers WHERE customer_id = p_id;
  EXCEPTION WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('customer '||p_id||' not found');
  END;

  r rt_customers%ROWTYPE;
BEGIN
  load_customer(1, r);
  DBMS_OUTPUT.PUT_LINE('loaded -> id='||r.customer_id||' name='||r.full_name||' active='||r.is_active);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 2) IN updater: accept a table%ROWTYPE and persist selected fields
--------------------------------------------------------------------------------
DECLARE
  PROCEDURE update_order_status(p_row IN rt_orders%ROWTYPE) IS
  BEGIN
    UPDATE rt_orders SET status = p_row.status WHERE order_id = p_row.order_id;
  END;

  r rt_orders%ROWTYPE;
BEGIN
  SELECT * INTO r FROM rt_orders WHERE order_id = 1001;
  r.status := 'PAID';
  update_order_status(r);
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('order '||r.order_id||' set to '||r.status);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 3) IN OUT mutator: bump quantity and recompute derived note
--------------------------------------------------------------------------------
DECLARE
  TYPE t_api IS RECORD(
    order rt_orders%ROWTYPE,
    note  VARCHAR2(100)
  );

  PROCEDURE bump_qty(p IN OUT t_api) IS
  BEGIN
    p.order.qty := NVL(p.order.qty,1) + 1; -- mutate in place
    p.note := 'bumped on '||TO_CHAR(SYSDATE,'YYYY-MM-DD');
  END;

  a t_api;
BEGIN
  SELECT * INTO a.order FROM rt_orders WHERE order_id = 1003;
  bump_qty(a);
  UPDATE rt_orders SET qty = a.order.qty WHERE order_id = a.order.order_id;
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('order '||a.order.order_id||' qty='||a.order.qty||' note='||a.note);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 4) Projection mapping via procedure: cursor%ROWTYPE -> table%ROWTYPE
--------------------------------------------------------------------------------
DECLARE
  CURSOR c IS SELECT order_id oid, qty q FROM rt_orders WHERE status='NEW' ORDER BY order_id;

  PROCEDURE apply_qty(p IN c%ROWTYPE) IS
    t rt_orders%ROWTYPE;
  BEGIN
    SELECT * INTO t FROM rt_orders WHERE order_id = p.oid;
    t.qty := NVL(p.q,1) + 2;
    UPDATE rt_orders SET qty = t.qty WHERE order_id = t.order_id;
  END;

BEGIN
  FOR v IN c LOOP
    apply_qty(v);
  END LOOP;
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('projection qty updates complete');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 5) Custom API record with validator: IN + OUT round trip
--------------------------------------------------------------------------------
DECLARE
  TYPE t_contact IS RECORD(email rt_customers.email%TYPE, created_at DATE);
  TYPE t_customer_public IS RECORD(
    id rt_customers.customer_id%TYPE,
    name rt_customers.full_name%TYPE,
    contact t_contact,
    active rt_customers.is_active%TYPE
  );

  PROCEDURE validate(p IN t_customer_public) IS
  BEGIN
    IF p.id IS NULL OR p.name IS NULL THEN
      RAISE_APPLICATION_ERROR(-20670, 'id/name required');
    END IF;
    IF p.active NOT IN ('Y','N') THEN
      RAISE_APPLICATION_ERROR(-20671, 'active must be Y/N');
    END IF;
  END;

  PROCEDURE get_public(p_id IN rt_customers.customer_id%TYPE,
                       p_out OUT t_customer_public) IS
    r rt_customers%ROWTYPE;
  BEGIN
    SELECT * INTO r FROM rt_customers WHERE customer_id = p_id;
    p_out.id := r.customer_id;
    p_out.name := r.full_name;
    p_out.contact.email := r.email;
    p_out.contact.created_at := r.created_at;
    p_out.active := r.is_active;
  END;

  v t_customer_public;
BEGIN
  get_public(2, v);        -- OUT
  validate(v);             -- IN
  DBMS_OUTPUT.PUT_LINE('public -> '||v.id||' '||v.name||' '||v.active);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 6) Defensive wrapper: exceptions and messages around record procedures
--------------------------------------------------------------------------------
DECLARE
  PROCEDURE safe_set_status(p_row IN rt_orders%ROWTYPE) IS
  BEGIN
    IF p_row.order_id IS NULL THEN
      RAISE_APPLICATION_ERROR(-20672, 'order_id required');
    END IF;
    UPDATE rt_orders SET status = p_row.status WHERE order_id = p_row.order_id;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20673, 'no such order: '||p_row.order_id);
    END IF;
  EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('error: '||SQLERRM);
  END;

  r rt_orders%ROWTYPE;
BEGIN
  r.order_id := 9999;  -- non-existent
  r.status := 'PAID';
  safe_set_status(r);  -- prints error but does not stop session
END;
/
--------------------------------------------------------------------------------

-- End of Lesson File
