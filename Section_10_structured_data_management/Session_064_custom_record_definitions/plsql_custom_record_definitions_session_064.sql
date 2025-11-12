SET SERVEROUTPUT ON SIZE UNLIMITED;
--------------------------------------------------------------------------------
-- Session: 064 – Custom Record Definitions
-- Purpose:
--   Show user-defined RECORD types that are stable and decoupled from tables,
--   while still leveraging %TYPE anchors for column-accurate scalar fields.
--   Reuses rt_customers (Session 062) and rt_orders (Session 063).
--
-- Covered:
--   (1) Define reusable sub-records and a composite customer_order_summary
--   (2) Initialize via constructor-like procedures
--   (3) Map from table%ROWTYPE into custom RECORDs
--   (4) Compute derived fields (order_count, total_amount)
--   (5) Serialize to text for logging
--   (6) Pass custom records via IN/OUT/IN OUT
--
-- How to run:
--   SET SERVEROUTPUT ON; Execute each block separately (terminated by '/').
-- Notes:
--   • Prefer %TYPE anchors for stability on scalar fields.
--   • Use explicit assignment for shape-mismatched copies.
--   • Keep invariants and domain checks in one place (constructor/validator).
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 0) Lab pre-checks (idempotent): ensure rt_customers and rt_orders exist
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
-- 1) Define reusable subtypes and custom RECORDs
--    We anchor scalars with %TYPE to follow table column definitions.
--------------------------------------------------------------------------------
DECLARE
  SUBTYPE t_cust_id IS rt_customers.customer_id%TYPE;
  SUBTYPE t_name    IS rt_customers.full_name%TYPE;
  SUBTYPE t_email   IS rt_customers.email%TYPE;
  SUBTYPE t_flag    IS rt_customers.is_active%TYPE;

  SUBTYPE t_order_id   IS rt_orders.order_id%TYPE;
  SUBTYPE t_qty        IS rt_orders.qty%TYPE;
  SUBTYPE t_price      IS rt_orders.unit_price%TYPE;
  SUBTYPE t_status     IS rt_orders.status%TYPE;

  TYPE t_contact IS RECORD(email t_email, created_at DATE);
  TYPE t_customer_public IS RECORD(
    id      t_cust_id,
    name    t_name,
    contact t_contact,
    active  t_flag
  );

  TYPE t_order_line IS RECORD(
    order_id t_order_id,
    item     rt_orders.item_name%TYPE,
    qty      t_qty,
    price    t_price,
    status   t_status
  );

  TYPE t_customer_order_summary IS RECORD(
    customer t_customer_public,
    order_count PLS_INTEGER,
    total_amount NUMBER,
    last_order_date DATE
  );

BEGIN
  DBMS_OUTPUT.PUT_LINE('Types compiled: t_customer_public, t_order_line, t_customer_order_summary');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 2) Constructor and validator procedures for custom RECORDs
--------------------------------------------------------------------------------
DECLARE
  SUBTYPE t_cust_id IS rt_customers.customer_id%TYPE;
  SUBTYPE t_name    IS rt_customers.full_name%TYPE;
  SUBTYPE t_email   IS rt_customers.email%TYPE;
  SUBTYPE t_flag    IS rt_customers.is_active%TYPE;

  TYPE t_contact IS RECORD(email t_email, created_at DATE);
  TYPE t_customer_public IS RECORD(id t_cust_id, name t_name, contact t_contact, active t_flag);

  PROCEDURE init_customer(p_id IN t_cust_id, p_name IN t_name, p_email IN t_email,
                          p_created IN DATE, p_active IN t_flag, p_out OUT t_customer_public) IS
  BEGIN
    p_out.id := p_id;
    p_out.name := p_name;
    p_out.contact.email := p_email;
    p_out.contact.created_at := p_created;
    IF p_active NOT IN ('Y','N') THEN
      RAISE_APPLICATION_ERROR(-20640, 'active must be Y or N');
    END IF;
    p_out.active := p_active;
  END;

  PROCEDURE validate_customer(p IN t_customer_public) IS
  BEGIN
    IF p.id IS NULL OR p.name IS NULL THEN
      RAISE_APPLICATION_ERROR(-20641, 'id and name are required');
    END IF;
    IF p.active NOT IN ('Y','N') THEN
      RAISE_APPLICATION_ERROR(-20642, 'invalid active flag');
    END IF;
  END;

  v t_customer_public;
BEGIN
  init_customer(1, 'Avi', 'avi@example.com', SYSDATE-10, 'Y', v);
  validate_customer(v);
  DBMS_OUTPUT.PUT_LINE('constructor ok -> '||v.id||' '||v.name||' active='||v.active);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 3) Mapper: table%ROWTYPE -> custom RECORD (customer_public)
--------------------------------------------------------------------------------
DECLARE
  TYPE t_contact IS RECORD(email rt_customers.email%TYPE, created_at DATE);
  TYPE t_customer_public IS RECORD(
    id rt_customers.customer_id%TYPE,
    name rt_customers.full_name%TYPE,
    contact t_contact,
    active rt_customers.is_active%TYPE
  );

  PROCEDURE map_customer(p_row IN rt_customers%ROWTYPE, p_out OUT t_customer_public) IS
  BEGIN
    p_out.id := p_row.customer_id;
    p_out.name := p_row.full_name;
    p_out.contact.email := p_row.email;
    p_out.contact.created_at := p_row.created_at;
    p_out.active := p_row.is_active;
  END;

  r_tab rt_customers%ROWTYPE;
  r_out t_customer_public;
BEGIN
  SELECT * INTO r_tab FROM rt_customers WHERE customer_id = 1;
  map_customer(r_tab, r_out);
  DBMS_OUTPUT.PUT_LINE('mapped -> '||r_out.id||' '||r_out.name||' '||r_out.contact.email);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 4) Aggregate builder: build customer_order_summary with derived fields
--------------------------------------------------------------------------------
DECLARE
  TYPE t_contact IS RECORD(email rt_customers.email%TYPE, created_at DATE);
  TYPE t_customer_public IS RECORD(
    id rt_customers.customer_id%TYPE,
    name rt_customers.full_name%TYPE,
    contact t_contact,
    active rt_customers.is_active%TYPE
  );
  TYPE t_customer_order_summary IS RECORD(
    customer t_customer_public,
    order_count PLS_INTEGER,
    total_amount NUMBER,
    last_order_date DATE
  );

  PROCEDURE build_summary(p_customer_id IN rt_customers.customer_id%TYPE,
                          p_out OUT t_customer_order_summary) IS
  BEGIN
    -- map customer
    SELECT customer_id, full_name, email, created_at, is_active
      INTO p_out.customer.id, p_out.customer.name,
           p_out.customer.contact.email, p_out.customer.contact.created_at,
           p_out.customer.active
      FROM rt_customers WHERE customer_id = p_customer_id;

    -- derived fields from orders
    SELECT COUNT(*),
           NVL(SUM(qty*unit_price),0),
           MAX(created_at)
      INTO p_out.order_count, p_out.total_amount, p_out.last_order_date
      FROM rt_orders WHERE customer_id = p_customer_id;
  END;

  s t_customer_order_summary;
BEGIN
  build_summary(1, s);
  DBMS_OUTPUT.PUT_LINE('summary -> id='||s.customer.id||
                       ' orders='||s.order_count||' total='||s.total_amount||
                       ' last='||TO_CHAR(s.last_order_date,'YYYY-MM-DD'));
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 5) Serializer: convert custom record into a single-line text
--------------------------------------------------------------------------------
DECLARE
  TYPE t_contact IS RECORD(email rt_customers.email%TYPE, created_at DATE);
  TYPE t_customer_public IS RECORD(
    id rt_customers.customer_id%TYPE,
    name rt_customers.full_name%TYPE,
    contact t_contact,
    active rt_customers.is_active%TYPE
  );

  FUNCTION serialize(p t_customer_public) RETURN VARCHAR2 IS
  BEGIN
    RETURN 'id='||p.id||';name='||p.name||';email='||NVL(p.contact.email,'-')||
           ';created='||TO_CHAR(p.contact.created_at,'YYYY-MM-DD')||
           ';active='||p.active;
  END;

  r_tab rt_customers%ROWTYPE;
  r_out t_customer_public;
BEGIN
  SELECT * INTO r_tab FROM rt_customers WHERE customer_id = 2;
  -- manual map
  r_out.id := r_tab.customer_id;
  r_out.name := r_tab.full_name;
  r_out.contact.email := r_tab.email;
  r_out.contact.created_at := r_tab.created_at;
  r_out.active := r_tab.is_active;

  DBMS_OUTPUT.PUT_LINE(serialize(r_out));
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 6) IN/OUT/IN OUT with custom record
--------------------------------------------------------------------------------
DECLARE
  TYPE t_contact IS RECORD(email rt_customers.email%TYPE, created_at DATE);
  TYPE t_customer_public IS RECORD(
    id rt_customers.customer_id%TYPE,
    name rt_customers.full_name%TYPE,
    contact t_contact,
    active rt_customers.is_active%TYPE
  );

  PROCEDURE print_customer(p IN t_customer_public) IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE('print -> '||p.id||' '||p.name||' '||NVL(p.contact.email,'-')||' '||p.active);
  END;

  PROCEDURE activate(p IN OUT t_customer_public) IS
  BEGIN
    IF p.active <> 'Y' THEN p.active := 'Y'; END IF;
  END;

  PROCEDURE load_customer(p_id IN rt_customers.customer_id%TYPE, p OUT t_customer_public) IS
    r rt_customers%ROWTYPE;
  BEGIN
    SELECT * INTO r FROM rt_customers WHERE customer_id = p_id;
    p.id := r.customer_id; p.name := r.full_name; p.contact.email := r.email;
    p.contact.created_at := r.created_at; p.active := r.is_active;
  END;

  v t_customer_public;
BEGIN
  load_customer(1, v);
  print_customer(v);
  v.active := 'N';
  activate(v);
  print_customer(v);
END;
/
--------------------------------------------------------------------------------

-- End of Lesson File
