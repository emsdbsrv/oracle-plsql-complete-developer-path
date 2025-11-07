-- Script: plsql_data_removal_and_cleanup.sql
-- Session: 033 - Data Removal and Cleanup (Production Patterns)
-- Purpose:
--   Demonstrate safe and efficient data removal patterns with detailed commentary:
--   (1) Targeted DELETE + RETURNING INTO
--   (2) DELETE with subquery (join-style) filters
--   (3) Archive-before-delete (INSERT…SELECT then DELETE)
--   (4) Soft delete pattern with flags and purge window
--   (5) TRUNCATE for fast reset (DDL; non-rollback)
--   (6) Bulk DELETE with SAVE EXCEPTIONS (FORALL) and logging
--   (7) Transaction control with SAVEPOINT/ROLLBACK
--   (8) Parent-child cleanup with ON DELETE CASCADE vs manual order
-- How to run:
--   SET SERVEROUTPUT ON; Execute each block separately (terminated by '/').
-- Notes:
--   • Always check SQL%%ROWCOUNT after DML. Consider printing affected ids in audit tables.
--   • Prefer set-based operations; avoid row-by-row when possible.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Setup (idempotent) – base tables for this session
--------------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'DROP TABLE orders_child PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE orders PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE orders_archive PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE orders (
  order_id    NUMBER       PRIMARY KEY,
  customer    VARCHAR2(50) NOT NULL,
  status      VARCHAR2(20) DEFAULT 'OPEN',
  amount      NUMBER(10,2),
  created_on  DATE         DEFAULT SYSDATE,
  is_deleted  CHAR(1)      DEFAULT 'N',
  deleted_on  DATE
);
CREATE TABLE orders_child (
  line_id     NUMBER       PRIMARY KEY,
  order_id    NUMBER       REFERENCES orders(order_id) ON DELETE CASCADE,
  sku         VARCHAR2(50),
  qty         NUMBER
);
CREATE TABLE orders_archive AS SELECT * FROM orders WHERE 1=0;

INSERT INTO orders VALUES (1,'Avi','OPEN',  90, SYSDATE-40, 'N', NULL);
INSERT INTO orders VALUES (2,'Raj','CLOSED',50, SYSDATE-10, 'N', NULL);
INSERT INTO orders VALUES (3,'Mani','CANCEL',35, SYSDATE-70, 'N', NULL);
INSERT INTO orders VALUES (4,'Neha','CLOSED',15, SYSDATE-5,  'N', NULL);

INSERT INTO orders_child VALUES (11,1,'SKU-1',2);
INSERT INTO orders_child VALUES (12,1,'SKU-2',1);
INSERT INTO orders_child VALUES (21,2,'SKU-9',3);

COMMIT;
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 1: Targeted DELETE + RETURNING INTO
-- Scenario: Remove CANCEL orders and capture deleted order_ids for logging.
--------------------------------------------------------------------------------
DECLARE
  v_id NUMBER;
BEGIN
  DELETE FROM orders
  WHERE status = 'CANCEL'
  RETURNING order_id INTO v_id;
  DBMS_OUTPUT.PUT_LINE('deleted CANCEL id='||v_id||'; rows='||SQL%ROWCOUNT);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 2: DELETE with subquery (join-style)
-- Scenario: Delete parent rows that have no child lines (orphans) using NOT EXISTS.
--------------------------------------------------------------------------------
BEGIN
  DELETE FROM orders o
  WHERE NOT EXISTS (SELECT 1 FROM orders_child c WHERE c.order_id = o.order_id);
  DBMS_OUTPUT.PUT_LINE('orphans removed rows='||SQL%ROWCOUNT);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 3: Archive-before-delete
-- Scenario: Move CLOSED orders older than 30 days to archive, then delete from live.
--------------------------------------------------------------------------------
DECLARE
  v_rows NUMBER;
BEGIN
  INSERT INTO orders_archive
  SELECT * FROM orders
  WHERE status = 'CLOSED' AND created_on < SYSDATE - 30;
  DBMS_OUTPUT.PUT_LINE('archived rows='||SQL%ROWCOUNT);

  DELETE FROM orders
  WHERE status = 'CLOSED' AND created_on < SYSDATE - 30;
  v_rows := SQL%ROWCOUNT;
  DBMS_OUTPUT.PUT_LINE('deleted rows='||v_rows);
  COMMIT;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 4: Soft delete pattern
-- Scenario: Mark orders as deleted (non-destructive); later a purge job will physically remove them.
--------------------------------------------------------------------------------
BEGIN
  UPDATE orders
  SET is_deleted='Y', deleted_on=SYSDATE
  WHERE status='OPEN' AND amount < 20;
  DBMS_OUTPUT.PUT_LINE('soft-deleted rows='||SQL%ROWCOUNT);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 5: TRUNCATE for fast reset (DDL; non-rollback)
-- Scenario: Clear all child lines quickly (lab-only demonstration).
--------------------------------------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE orders_child';
  DBMS_OUTPUT.PUT_LINE('orders_child truncated');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 6: Bulk DELETE with SAVE EXCEPTIONS (FORALL)
-- Scenario: Delete specific order ids in bulk, capturing failures.
--------------------------------------------------------------------------------
DECLARE
  TYPE t_ids IS TABLE OF orders.order_id%TYPE;
  v_ids t_ids := t_ids(1, 999, 4); -- 999 will fail or delete 0 rows
  errors EXCEPTION; PRAGMA EXCEPTION_INIT(errors, -24381);
BEGIN
  SAVEPOINT bulk_start;
  BEGIN
    FORALL i IN 1..v_ids.COUNT SAVE EXCEPTIONS
      DELETE FROM orders WHERE order_id = v_ids(i);
  EXCEPTION
    WHEN errors THEN
      DBMS_OUTPUT.PUT_LINE('bulk exceptions='||SQL%BULK_EXCEPTIONS.COUNT);
      FOR j IN 1..SQL%BULK_EXCEPTIONS.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(' idx='||SQL%BULK_EXCEPTIONS(j).ERROR_INDEX||' err='||SQL%BULK_EXCEPTIONS(j).ERROR_CODE);
      END LOOP;
  END;
  COMMIT;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 7: SAVEPOINT/ROLLBACK guard
-- Scenario: Attempt two deletes; rollback second if no rows affected; keep the first.
--------------------------------------------------------------------------------
BEGIN
  SAVEPOINT s1;
  DELETE FROM orders WHERE order_id = 2;
  DBMS_OUTPUT.PUT_LINE('first delete rows='||SQL%ROWCOUNT);

  SAVEPOINT s2;
  DELETE FROM orders WHERE order_id = -1; -- none
  IF SQL%ROWCOUNT = 0 THEN
    ROLLBACK TO s2;
    DBMS_OUTPUT.PUT_LINE('rolled back second delete');
  END IF;
  COMMIT;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 8: Parent-child cleanup strategies
-- Scenario: Demonstrate ON DELETE CASCADE vs manual delete order.
--------------------------------------------------------------------------------
DECLARE
  v_parent NUMBER := 1;
BEGIN
  -- Recreate a parent + child quickly
  INSERT INTO orders(order_id, customer, status, amount, created_on) VALUES (v_parent,'Tmp','OPEN',10,SYSDATE);
  INSERT INTO orders_child(line_id, order_id, sku, qty) VALUES (1001, v_parent, 'TMP', 1);
  COMMIT;

  -- Using ON DELETE CASCADE (child auto-deleted)
  DELETE FROM orders WHERE order_id = v_parent;
  DBMS_OUTPUT.PUT_LINE('cascade parent delete rows='||SQL%ROWCOUNT);
END;
/
--------------------------------------------------------------------------------
-- End of File
--------------------------------------------------------------------------------
