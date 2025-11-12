SET SERVEROUTPUT ON SIZE UNLIMITED;
--------------------------------------------------------------------------------
-- Session: 066 – Record Assignment Operations
-- Purpose:
--   Demonstrate safe and maintainable ways to copy and map PL/SQL RECORDs between
--   different shapes: table%ROWTYPE, cursor%ROWTYPE, and custom RECORDs.
--
-- Covered (≥5 examples):
--   (1) Whole-record assignment for identical custom types
--   (2) Table%ROWTYPE -> custom RECORD selective copy
--   (3) Cursor%ROWTYPE (aliased) -> table%ROWTYPE merge
--   (4) Partial/optional fields and defaulting
--   (5) Array of RECORDs: element-wise copy
--   (6) Defensive mapping with validators
--
-- How to run:
--   SET SERVEROUTPUT ON; Execute each block separately (terminated by '/').
-- Notes:
--   • Direct assignment works only for shape-identical RECORD types.
--   • When shapes differ, copy fields explicitly with comments.
--   • Cursor%ROWTYPE depends on SELECT list aliases — document them.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 0) Bootstrap (idempotent): ensure rt_customers and rt_orders exist with seed data
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
    EXECUTE IMMEDIATE 'INSERT INTO rt_customers VALUES (1, ''Avi'',''avi@example.com'',''Y'',SYSDATE-10)';
    EXECUTE IMMEDIATE 'INSERT INTO rt_customers VALUES (2, ''Neha'',''neha@example.com'',''Y'',SYSDATE-5)';
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
-- 1) Whole-record assignment: identical custom RECORD shapes
--------------------------------------------------------------------------------
DECLARE
  TYPE t_min IS RECORD(id NUMBER, name VARCHAR2(30));
  a t_min; b t_min; same BOOLEAN;
BEGIN
  a.id := 1; a.name := 'Avi';
  b := a; -- identical shapes → direct copy
  same := (a.id=b.id AND a.name=b.name);
  DBMS_OUTPUT.PUT_LINE('whole-copy same='||CASE WHEN same THEN 'TRUE' ELSE 'FALSE' END);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 2) Table%ROWTYPE -> custom RECORD: selective copy with comments
--------------------------------------------------------------------------------
DECLARE
  TYPE t_public IS RECORD(
    id   rt_customers.customer_id%TYPE,
    name rt_customers.full_name%TYPE,
    mail rt_customers.email%TYPE,
    active rt_customers.is_active%TYPE
  );
  r_tab rt_customers%ROWTYPE;  -- full table shape
  r_pub t_public;              -- API shape (subset/renamed)
BEGIN
  SELECT * INTO r_tab FROM rt_customers WHERE customer_id = 1;

  -- Explicit field mapping with rationale
  r_pub.id     := r_tab.customer_id;       -- preserve PK
  r_pub.name   := r_tab.full_name;         -- expose display name only
  r_pub.mail   := r_tab.email;             -- rename for API contract
  r_pub.active := r_tab.is_active;         -- 'Y'/'N' business flag

  DBMS_OUTPUT.PUT_LINE('mapped -> '||r_pub.id||' '||r_pub.name||' '||NVL(r_pub.mail,'-'));
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 3) Cursor%ROWTYPE (aliased) -> table%ROWTYPE merge update
--------------------------------------------------------------------------------
DECLARE
  CURSOR c IS
    SELECT order_id oid, qty q, status st FROM rt_orders WHERE status='NEW' ORDER BY order_id;

  v_proj c%ROWTYPE;             -- fields: oid, q, st
  v_tab  rt_orders%ROWTYPE;     -- table-shaped
BEGIN
  OPEN c;
  LOOP
    FETCH c INTO v_proj; EXIT WHEN c%NOTFOUND;

    -- Load full row first
    SELECT * INTO v_tab FROM rt_orders WHERE order_id = v_proj.oid;

    -- Merge changes coming from projection
    v_tab.qty    := v_proj.q + 1;   -- increment quantity
    v_tab.status := 'PAID';         -- mark paid

    UPDATE rt_orders
       SET qty = v_tab.qty, status = v_tab.status
     WHERE order_id = v_tab.order_id;
  END LOOP;
  CLOSE c; COMMIT;
  DBMS_OUTPUT.PUT_LINE('projection merge complete');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 4) Optional/partial field handling with defaults
--------------------------------------------------------------------------------
DECLARE
  TYPE t_api IS RECORD(
    id   rt_orders.order_id%TYPE,
    item rt_orders.item_name%TYPE,
    qty  rt_orders.qty%TYPE,
    price rt_orders.unit_price%TYPE,
    note  VARCHAR2(100)  -- optional field not present in table
  );
  row_tab rt_orders%ROWTYPE;
  row_api t_api;
BEGIN
  SELECT * INTO row_tab FROM rt_orders WHERE order_id=1001;

  -- Map mandatory fields
  row_api.id    := row_tab.order_id;
  row_api.item  := row_tab.item_name;
  row_api.qty   := NVL(row_tab.qty, 1);
  row_api.price := NVL(row_tab.unit_price, 0);

  -- Optional field default
  row_api.note  := 'standard';

  DBMS_OUTPUT.PUT_LINE('api -> '||row_api.id||' '||row_api.item||' x'||row_api.qty||' @'||row_api.price||' note='||row_api.note);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 5) Array of RECORDs: element-wise copy between compatible shapes
--------------------------------------------------------------------------------
DECLARE
  TYPE t_line IS RECORD(id NUMBER, qty NUMBER);
  TYPE t_lines IS TABLE OF t_line INDEX BY PLS_INTEGER;

  TYPE t_line2 IS RECORD(id NUMBER, qty NUMBER);
  TYPE t_lines2 IS TABLE OF t_line2 INDEX BY PLS_INTEGER;

  a t_lines; b t_lines2; i PLS_INTEGER;
BEGIN
  -- Seed source collection
  a(1).id:=10; a(1).qty:=2; a(2).id:=11; a(2).qty:=5;

  -- Element-wise copy (same shapes per element)
  IF a.COUNT>0 THEN
    FOR i IN a.FIRST..a.LAST LOOP
      IF a.EXISTS(i) THEN b(i).id := a(i).id; b(i).qty := a(i).qty; END IF;
    END LOOP;
  END IF;

  DBMS_OUTPUT.PUT_LINE('copied elements='||b.COUNT);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 6) Defensive validator before assignment
--------------------------------------------------------------------------------
DECLARE
  TYPE t_pub IS RECORD(id NUMBER, name VARCHAR2(60), active CHAR(1));
  PROCEDURE validate(p IN t_pub) IS
  BEGIN
    IF p.id IS NULL OR p.name IS NULL THEN
      RAISE_APPLICATION_ERROR(-20660, 'id/name required');
    END IF;
    IF p.active NOT IN ('Y','N') THEN
      RAISE_APPLICATION_ERROR(-20661, 'active must be Y/N');
    END IF;
  END;

  src t_pub; dst t_pub;
BEGIN
  src.id:=1; src.name:='Avi'; src.active:='Y';
  validate(src);        -- precondition check
  dst := src;           -- now safe whole-record copy
  DBMS_OUTPUT.PUT_LINE('validated copy ok -> '||dst.id||' '||dst.name);
END;
/
--------------------------------------------------------------------------------

-- End of Lesson File
