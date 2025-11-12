SET SERVEROUTPUT ON SIZE UNLIMITED;
--------------------------------------------------------------------------------
-- Session: 065 – Nested Record Structures
-- Purpose:
--   Demonstrate multi-level RECORD composition and a TABLE OF RECORD collection
--   to model one-to-many relationships (customer -> orders). We reuse rt_customers
--   and rt_orders from prior sessions.
--
-- Covered:
--   (1) Subtypes and base RECORDs
--   (2) Order-line RECORD and collection (TABLE OF)
--   (3) Customer profile with nested orders
--   (4) Loader that populates nested collection
--   (5) Serializer and printer utilities
--   (6) IN/OUT/IN OUT usage and defensive copying
--   (7) ≥ 5 worked examples
--
-- How to run:
--   Execute each block separately (terminated by '/'). Ensure SERVEROUTPUT is ON.
-- Notes:
--   • Collections of RECORDs require a SQL or PL/SQL collection; here we use a
--     PL/SQL index-by table (associative array) for simplicity in examples.
--   • For persistence or SQL-level DML with collections, a SQL nested table type
--     would be required (not covered here).
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 0) Pre-check: Ensure base tables exist (idempotent bootstrap)
--------------------------------------------------------------------------------
DECLARE
  v_cnt NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_cnt FROM user_tables WHERE table_name = 'RT_CUSTOMERS';
  IF v_cnt = 0 THEN
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

  SELECT COUNT(*) INTO v_cnt FROM user_tables WHERE table_name = 'RT_ORDERS';
  IF v_cnt = 0 THEN
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
-- 1) Subtypes and base RECORDs
--------------------------------------------------------------------------------
DECLARE
  SUBTYPE t_cust_id IS rt_customers.customer_id%TYPE;
  SUBTYPE t_name    IS rt_customers.full_name%TYPE;
  SUBTYPE t_email   IS rt_customers.email%TYPE;
  SUBTYPE t_flag    IS rt_customers.is_active%TYPE;

  SUBTYPE t_order_id IS rt_orders.order_id%TYPE;
  SUBTYPE t_qty      IS rt_orders.qty%TYPE;
  SUBTYPE t_price    IS rt_orders.unit_price%TYPE;
  SUBTYPE t_status   IS rt_orders.status%TYPE;

  TYPE t_contact IS RECORD(email t_email, created_at DATE);
  TYPE t_customer_public IS RECORD(
    id t_cust_id, name t_name, contact t_contact, active t_flag
  );

BEGIN
  DBMS_OUTPUT.PUT_LINE('Base subtypes and records compiled.');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 2) Order-line RECORD and collection
--    We use an associative array (index-by table) of t_order_line for in-memory use.
--------------------------------------------------------------------------------
DECLARE
  SUBTYPE t_order_id IS rt_orders.order_id%TYPE;
  TYPE t_order_line IS RECORD(
    order_id  t_order_id,
    item      rt_orders.item_name%TYPE,
    qty       rt_orders.qty%TYPE,
    unit_price rt_orders.unit_price%TYPE,
    status    rt_orders.status%TYPE,
    created_at DATE
  );

  -- Index-by table (associative array) of order lines keyed by PLS_INTEGER
  TYPE t_order_lines IS TABLE OF t_order_line INDEX BY PLS_INTEGER;

  v_lines t_order_lines;
BEGIN
  -- Illustrate basic initialization and element assignment
  v_lines(1).order_id   := 1001;
  v_lines(1).item       := 'SSD 1TB';
  v_lines(1).qty        := 1;
  v_lines(1).unit_price := 6500;
  v_lines(1).status     := 'NEW';
  v_lines(1).created_at := SYSDATE-5;

  DBMS_OUTPUT.PUT_LINE('collection seeded, first item='||v_lines(1).item);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 3) Customer profile with nested orders collection
--------------------------------------------------------------------------------
DECLARE
  SUBTYPE t_cust_id IS rt_customers.customer_id%TYPE;
  SUBTYPE t_name    IS rt_customers.full_name%TYPE;
  SUBTYPE t_email   IS rt_customers.email%TYPE;
  SUBTYPE t_flag    IS rt_customers.is_active%TYPE;

  TYPE t_contact IS RECORD(email t_email, created_at DATE);
  TYPE t_customer_public IS RECORD(id t_cust_id, name t_name, contact t_contact, active t_flag);

  TYPE t_order_line IS RECORD(
    order_id  rt_orders.order_id%TYPE,
    item      rt_orders.item_name%TYPE,
    qty       rt_orders.qty%TYPE,
    unit_price rt_orders.unit_price%TYPE,
    status    rt_orders.status%TYPE,
    created_at DATE
  );
  TYPE t_order_lines IS TABLE OF t_order_line INDEX BY PLS_INTEGER;

  TYPE t_customer_profile IS RECORD(
    info          t_customer_public,
    orders        t_order_lines,
    order_count   PLS_INTEGER,
    total_amount  NUMBER,
    last_order_at DATE
  );

  v t_customer_profile;
BEGIN
  -- Initialize shallow info manually for demonstration
  v.info.id := 1;
  v.info.name := 'Avi';
  v.info.contact.email := 'avi@example.com';
  v.info.contact.created_at := SYSDATE-10;
  v.info.active := 'Y';

  -- Initialize orders collection with two entries
  v.orders(1).order_id := 1001; v.orders(1).item := 'SSD 1TB'; v.orders(1).qty := 1; v.orders(1).unit_price := 6500; v.orders(1).status:='NEW'; v.orders(1).created_at:=SYSDATE-5;
  v.orders(2).order_id := 1003; v.orders(2).item := 'USB-C Hub'; v.orders(2).qty := 2; v.orders(2).unit_price := 1200; v.orders(2).status:='NEW'; v.orders(2).created_at:=SYSDATE-1;

  v.order_count := v.orders.COUNT;
  v.total_amount := NVL(v.orders(1).qty,0)*NVL(v.orders(1).unit_price,0) +
                    NVL(v.orders(2).qty,0)*NVL(v.orders(2).unit_price,0);
  v.last_order_at := GREATEST(v.orders(1).created_at, v.orders(2).created_at);

  DBMS_OUTPUT.PUT_LINE('profile -> id='||v.info.id||' orders='||v.order_count||' total='||v.total_amount);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 4) Loader: populate a customer profile from tables
--------------------------------------------------------------------------------
DECLARE
  TYPE t_contact IS RECORD(email rt_customers.email%TYPE, created_at DATE);
  TYPE t_customer_public IS RECORD(id rt_customers.customer_id%TYPE, name rt_customers.full_name%TYPE, contact t_contact, active rt_customers.is_active%TYPE);

  TYPE t_order_line IS RECORD(
    order_id  rt_orders.order_id%TYPE,
    item      rt_orders.item_name%TYPE,
    qty       rt_orders.qty%TYPE,
    unit_price rt_orders.unit_price%TYPE,
    status    rt_orders.status%TYPE,
    created_at DATE
  );
  TYPE t_order_lines IS TABLE OF t_order_line INDEX BY PLS_INTEGER;

  TYPE t_customer_profile IS RECORD(
    info          t_customer_public,
    orders        t_order_lines,
    order_count   PLS_INTEGER,
    total_amount  NUMBER,
    last_order_at DATE
  );

  PROCEDURE load_profile(p_customer_id IN rt_customers.customer_id%TYPE, p_out OUT t_customer_profile) IS
    i PLS_INTEGER := 0;
  BEGIN
    -- Load customer base info
    SELECT customer_id, full_name, email, created_at, is_active
      INTO p_out.info.id, p_out.info.name, p_out.info.contact.email, p_out.info.contact.created_at, p_out.info.active
      FROM rt_customers WHERE customer_id = p_customer_id;

    -- Load orders into nested collection
    FOR r IN (SELECT order_id, item_name, qty, unit_price, status, created_at
                FROM rt_orders
               WHERE customer_id = p_customer_id
               ORDER BY created_at) LOOP
      i := i + 1;
      p_out.orders(i).order_id   := r.order_id;
      p_out.orders(i).item       := r.item_name;
      p_out.orders(i).qty        := r.qty;
      p_out.orders(i).unit_price := r.unit_price;
      p_out.orders(i).status     := r.status;
      p_out.orders(i).created_at := r.created_at;
    END LOOP;

    -- Derived stats
    p_out.order_count := p_out.orders.COUNT;
    p_out.total_amount := 0;
    p_out.last_order_at := NULL;
    IF p_out.order_count > 0 THEN
      FOR j IN p_out.orders.FIRST .. p_out.orders.LAST LOOP
        IF p_out.orders.EXISTS(j) THEN
          p_out.total_amount := p_out.total_amount +
            NVL(p_out.orders(j).qty,0) * NVL(p_out.orders(j).unit_price,0);
          p_out.last_order_at := GREATEST(NVL(p_out.last_order_at, p_out.orders(j).created_at),
                                          p_out.orders(j).created_at);
        END IF
      END LOOP;
    END IF;
  END;

  v t_customer_profile;
BEGIN
  load_profile(1, v);
  DBMS_OUTPUT.PUT_LINE('loaded profile -> '||v.info.name||' orders='||v.order_count||' total='||v.total_amount);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 5) Serializer and printer utilities for nested structures
--------------------------------------------------------------------------------
DECLARE
  TYPE t_contact IS RECORD(email rt_customers.email%TYPE, created_at DATE);
  TYPE t_customer_public IS RECORD(id rt_customers.customer_id%TYPE, name rt_customers.full_name%TYPE, contact t_contact, active rt_customers.is_active%TYPE);

  TYPE t_order_line IS RECORD(order_id rt_orders.order_id%TYPE, item rt_orders.item_name%TYPE, qty rt_orders.qty%TYPE,
                              unit_price rt_orders.unit_price%TYPE, status rt_orders.status%TYPE, created_at DATE);
  TYPE t_order_lines IS TABLE OF t_order_line INDEX BY PLS_INTEGER;

  TYPE t_customer_profile IS RECORD(
    info          t_customer_public,
    orders        t_order_lines,
    order_count   PLS_INTEGER,
    total_amount  NUMBER,
    last_order_at DATE
  );

  FUNCTION serialize(p t_customer_profile) RETURN VARCHAR2 IS
    s VARCHAR2(4000);
  BEGIN
    s := 'id='||p.info.id||';name='||p.info.name||';active='||p.info.active||';orders='||p.order_count||';total='||p.total_amount;
    RETURN s;
  END;

  PROCEDURE print_profile(p t_customer_profile) IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE(serialize(p));
    IF p.order_count = 0 THEN
      DBMS_OUTPUT.PUT_LINE('no orders');
    ELSE
      FOR i IN p.orders.FIRST .. p.orders.LAST LOOP
        IF p.orders.EXISTS(i) THEN
          DBMS_OUTPUT.PUT_LINE('  #'||i||' '||p.orders(i).order_id||' '||p.orders(i).item||' x'||p.orders(i).qty||' @'||p.orders(i).unit_price||' '||p.orders(i).status);
        END IF;
      END LOOP;
    END IF;
  END;

  v t_customer_profile;
BEGIN
  -- Build and print profile
  -- Reuse loader from previous block pattern (inline here for brevity)
  v.info.id := 1; v.info.name := 'Avi'; v.info.contact.email := 'avi@example.com'; v.info.contact.created_at := SYSDATE-10; v.info.active := 'Y';
  v.orders(1).order_id:=1001; v.orders(1).item:='SSD 1TB'; v.orders(1).qty:=1; v.orders(1).unit_price:=6500; v.orders(1).status:='NEW'; v.orders(1).created_at:=SYSDATE-5;
  v.orders(2).order_id:=1003; v.orders(2).item:='USB-C Hub'; v.orders(2).qty:=2; v.orders(2).unit_price:=1200; v.orders(2).status:='NEW'; v.orders(2).created_at:=SYSDATE-1;
  v.order_count := v.orders.COUNT; v.total_amount := 6500 + 2*1200;

  print_profile(v);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 6) IN OUT and defensive copy of nested structures
--------------------------------------------------------------------------------
DECLARE
  TYPE t_order_line IS RECORD(order_id rt_orders.order_id%TYPE, item rt_orders.item_name%TYPE, qty rt_orders.qty%TYPE,
                              unit_price rt_orders.unit_price%TYPE, status rt_orders.status%TYPE, created_at DATE);
  TYPE t_order_lines IS TABLE OF t_order_line INDEX BY PLS_INTEGER;

  TYPE t_contact IS RECORD(email rt_customers.email%TYPE, created_at DATE);
  TYPE t_customer_public IS RECORD(id rt_customers.customer_id%TYPE, name rt_customers.full_name%TYPE, contact t_contact, active rt_customers.is_active%TYPE);

  TYPE t_customer_profile IS RECORD(
    info          t_customer_public,
    orders        t_order_lines,
    order_count   PLS_INTEGER,
    total_amount  NUMBER,
    last_order_at DATE
  );

  PROCEDURE add_order(p IN OUT t_customer_profile, p_line IN t_order_line) IS
    nxt PLS_INTEGER;
  BEGIN
    nxt := CASE WHEN p.orders.COUNT = 0 THEN 1 ELSE p.orders.LAST + 1 END;
    p.orders(nxt) := p_line; -- copy record by value
    p.order_count := p.orders.COUNT;
    p.total_amount := NVL(p.total_amount,0) + NVL(p_line.qty,0)*NVL(p_line.unit_price,0);
    p.last_order_at := GREATEST(NVL(p.last_order_at, p_line.created_at), p_line.created_at);
  END;

  v t_customer_profile;
  l t_order_line;
BEGIN
  -- Minimal profile
  v.info.id := 2; v.info.name := 'Neha'; v.info.contact.email := 'neha@example.com'; v.info.active := 'Y';
  v.order_count := 0; v.total_amount := 0; v.last_order_at := NULL;

  -- Add a new order line via IN OUT
  l.order_id:=3001; l.item:='Mouse'; l.qty:=1; l.unit_price:=800; l.status:='NEW'; l.created_at:=SYSDATE;
  add_order(v, l);

  DBMS_OUTPUT.PUT_LINE('after add -> orders='||v.order_count||' total='||v.total_amount);
END;
/
--------------------------------------------------------------------------------

-- End of Lesson File
