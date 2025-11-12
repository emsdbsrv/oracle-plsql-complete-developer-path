SET SERVEROUTPUT ON SIZE UNLIMITED;
--------------------------------------------------------------------------------
-- Session: 062 – Record Type Architecture
-- Purpose:
--   Show core patterns for PL/SQL records with detailed, line-by-line commentary.
--   Covered:
--     (1) User-defined RECORD basics
--     (2) %ROWTYPE from table and cursor
--     (3) Nested RECORD structures
--     (4) Record assignment and comparison
--     (5) Passing records to subprograms (IN, OUT, IN OUT)
--
-- How to run:
--   SET SERVEROUTPUT ON; Execute each block separately (terminated by '/').
-- Notes:
--   • RECORDs are composite types with named fields of possibly differing types.
--   • %ROWTYPE tracks underlying table/cursor shape and adjusts on DDL.
--   • Always initialize records explicitly before use to avoid NULL surprises.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 0) Lab setup (idempotent) — create a small schema to work against
--------------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'DROP TABLE rt_customers PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE rt_customers(
  customer_id   NUMBER       CONSTRAINT rt_customers_pk PRIMARY KEY,
  full_name     VARCHAR2(60) NOT NULL,
  email         VARCHAR2(120),
  is_active     CHAR(1)      DEFAULT 'Y' CHECK (is_active IN ('Y','N')),
  created_at    DATE         DEFAULT SYSDATE
);
INSERT INTO rt_customers VALUES (1, 'Avi',    'avi@example.com',    'Y', SYSDATE-10);
INSERT INTO rt_customers VALUES (2, 'Neha',   'neha@example.com',   'Y', SYSDATE-5);
INSERT INTO rt_customers VALUES (3, 'Rahul',  'rahul@example.com',  'N', SYSDATE-1);
COMMIT;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1) Example: User-defined RECORD basics
-- Scenario:
--   Define TYPE t_customer IS RECORD(...) and populate it manually.
--   This decouples PL/SQL structure from table shape.
--------------------------------------------------------------------------------
DECLARE
  TYPE t_customer IS RECORD(
    id      NUMBER,
    name    VARCHAR2(60),
    email   VARCHAR2(120),
    active  CHAR(1)
  );
  v_c t_customer;  -- uninitialized; fields are NULL
BEGIN
  -- Initialize field-by-field
  v_c.id     := 10;
  v_c.name   := 'Alice';
  v_c.email  := 'alice@example.com';
  v_c.active := 'Y';

  DBMS_OUTPUT.PUT_LINE(
    'user-defined -> id='||v_c.id||', name='||v_c.name||', email='||v_c.email||', active='||v_c.active
  );
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 2) Example: %ROWTYPE from table
-- Scenario:
--   Fetch a single row into a table-shaped record using SELECT ... INTO.
--   %ROWTYPE keeps parity with rt_customers columns automatically.
--------------------------------------------------------------------------------
DECLARE
  v_row rt_customers%ROWTYPE; -- has all columns with matching names/types
BEGIN
  SELECT * INTO v_row FROM rt_customers WHERE customer_id = 2;

  DBMS_OUTPUT.PUT_LINE(
    'table%ROWTYPE -> id='||v_row.customer_id||', name='||v_row.full_name||
    ', email='||v_row.email||', active='||v_row.is_active
  );
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 3) Example: %ROWTYPE from cursor (projection-shaped)
-- Scenario:
--   Define an explicit cursor selecting a projection/subset with aliases.
--   Cursor%ROWTYPE matches the projection, not the base table.
--------------------------------------------------------------------------------
DECLARE
  CURSOR c_active IS
    SELECT customer_id id, full_name name, created_at joined_on
    FROM rt_customers
    WHERE is_active = 'Y'
    ORDER BY customer_id;
  v_proj c_active%ROWTYPE; -- fields: id, name, joined_on (per SELECT list)
BEGIN
  OPEN c_active;
  FETCH c_active INTO v_proj;
  CLOSE c_active;

  DBMS_OUTPUT.PUT_LINE(
    'cursor%ROWTYPE -> id='||v_proj.id||', name='||v_proj.name||
    ', joined_on='||TO_CHAR(v_proj.joined_on, 'YYYY-MM-DD')
  );
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 4) Example: Nested RECORD structures
-- Scenario:
--   Compose a record out of smaller records. Useful to model aggregates.
--------------------------------------------------------------------------------
DECLARE
  TYPE t_name IS RECORD(first VARCHAR2(30), last VARCHAR2(30));
  TYPE t_contact IS RECORD(email VARCHAR2(120), phone VARCHAR2(20));
  TYPE t_profile IS RECORD(id NUMBER, name t_name, contact t_contact, active BOOLEAN);

  v_p t_profile;
BEGIN
  v_p.id := 1001;
  v_p.name.first := 'Riya';
  v_p.name.last  := 'Sharma';
  v_p.contact.email := 'riya.sharma@example.com';
  v_p.contact.phone := '+91-9000000000';
  v_p.active := TRUE;

  DBMS_OUTPUT.PUT_LINE(
    'nested -> id='||v_p.id||', name='||v_p.name.first||' '||v_p.name.last||
    ', email='||v_p.contact.email||', active='||CASE WHEN v_p.active THEN 'TRUE' ELSE 'FALSE' END
  );
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 5) Example: Record assignment and comparison pattern
-- Scenario:
--   Copying RECORDs requires compatible shapes. For equality checks, compare fields.
--------------------------------------------------------------------------------
DECLARE
  TYPE t_customer IS RECORD(id NUMBER, name VARCHAR2(60), email VARCHAR2(120), active CHAR(1));
  v1 t_customer;
  v2 t_customer;
  same BOOLEAN;
BEGIN
  v1.id:=1; v1.name:='A'; v1.email:='a@x'; v1.active:='Y';
  v2 := v1; -- structure-compatible assignment (deep copy of scalar fields)
  same := (v1.id = v2.id) AND (v1.name=v2.name) AND (v1.email=v2.email) AND (v1.active=v2.active);

  DBMS_OUTPUT.PUT_LINE('assignment ok; same='||CASE WHEN same THEN 'TRUE' ELSE 'FALSE' END);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 6) Example: Passing RECORDs to subprograms (IN, OUT, IN OUT)
-- Scenario:
--   Create utilities that accept and return records, documenting mutation intent.
--------------------------------------------------------------------------------
DECLARE
  -- Define a public record type for the scope of the block.
  TYPE t_customer IS RECORD(id NUMBER, name VARCHAR2(60), email VARCHAR2(120), active CHAR(1));

  PROCEDURE print_customer(p_c IN t_customer) IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE('print -> id='||p_c.id||', name='||p_c.name||', email='||p_c.email||', active='||p_c.active);
  END;

  PROCEDURE activate_if_missing(p_c IN OUT t_customer) IS
  BEGIN
    IF p_c.active <> 'Y' THEN p_c.active := 'Y'; END IF;
  END;

  PROCEDURE load_by_id(p_id IN NUMBER, p_c OUT t_customer) IS
  BEGIN
    -- Map from table row to our custom record.
    SELECT customer_id, full_name, email, is_active INTO p_c.id, p_c.name, p_c.email, p_c.active
    FROM rt_customers WHERE customer_id = p_id;
  END;

  v t_customer;
BEGIN
  load_by_id(3, v);            -- OUT: populate from table
  print_customer(v);           -- IN: read-only view
  activate_if_missing(v);      -- IN OUT: may toggle active flag
  print_customer(v);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 7) Example: Procedure returning table-shaped record
-- Scenario:
--   Standardize a loader using %ROWTYPE to minimize field mapping code.
--------------------------------------------------------------------------------
DECLARE
  PROCEDURE load_row(p_id IN NUMBER, p_row OUT rt_customers%ROWTYPE) IS
  BEGIN
    SELECT * INTO p_row FROM rt_customers WHERE customer_id = p_id;
  END;
  r rt_customers%ROWTYPE;
BEGIN
  load_row(1, r);
  DBMS_OUTPUT.PUT_LINE('loader -> '||r.customer_id||' '||r.full_name||' '||NVL(r.email,'-'));
END;
/
--------------------------------------------------------------------------------

-- End of Lesson File
