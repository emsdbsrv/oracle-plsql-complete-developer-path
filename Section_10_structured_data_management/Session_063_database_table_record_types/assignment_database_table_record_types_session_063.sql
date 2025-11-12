SET SERVEROUTPUT ON SIZE UNLIMITED;
--------------------------------------------------------------------------------
-- Assignment: Session 063 – Database Table Record Types
-- Format:
--   • 10 detailed tasks with complete solutions provided as COMMENTED blocks.
--   • To run a solution: copy the commented block and remove leading '--'.
-- Guidance:
--   • Prefer %ROWTYPE for full-row operations; use %TYPE for scalar parameters.
--   • When shapes differ, copy fields explicitly with clear comments.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q1 (Warm-up): Load order_id=1001 into rt_orders%ROWTYPE and print item_name, qty.
-- Answer (commented):
-- DECLARE r rt_orders%ROWTYPE; BEGIN SELECT * INTO r FROM rt_orders WHERE order_id=1001;
-- DBMS_OUTPUT.PUT_LINE(r.item_name||' x'||r.qty); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q2 (Update via record): Change status to 'CANCELLED' for order_id=1002 using a record.
-- Answer (commented):
-- DECLARE r rt_orders%ROWTYPE; BEGIN SELECT * INTO r FROM rt_orders WHERE order_id=1002;
-- r.status:='CANCELLED'; UPDATE rt_orders SET status=r.status WHERE order_id=r.order_id; COMMIT; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q3 (Projection cursor): Define cursor listing oid, itm; fetch one row and print.
-- Answer (commented):
-- DECLARE CURSOR c IS SELECT order_id oid, item_name itm FROM rt_orders ORDER BY order_id;
-- v c%ROWTYPE; BEGIN OPEN c; FETCH c INTO v; CLOSE c; DBMS_OUTPUT.PUT_LINE(v.oid||' '||v.itm); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q4 (%TYPE params): Write set_qty(p_id IN rt_orders.order_id%TYPE, p_q IN rt_orders.qty%TYPE).
-- Answer (commented):
-- DECLARE PROCEDURE set_qty(p_id IN rt_orders.order_id%TYPE, p_q IN rt_orders.qty%TYPE) IS BEGIN UPDATE rt_orders SET qty=p_q WHERE order_id=p_id; END;
-- BEGIN set_qty(1003, 3); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q5 (Insert via record): Build a record for order_id=2002 and insert it.
-- Answer (commented):
-- DECLARE r rt_orders%ROWTYPE; BEGIN r.order_id:=2002; r.customer_id:=1; r.item_name:='Keyboard'; r.qty:=2; r.unit_price:=2500; r.status:='NEW'; r.created_at:=SYSDATE; INSERT INTO rt_orders VALUES r; COMMIT; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q6 (Copy fields): Copy qty and unit_price from order_id=2001 to 2002 and recompute total.
-- Answer (commented):
-- DECLARE a rt_orders%ROWTYPE; b rt_orders%ROWTYPE; BEGIN SELECT * INTO a FROM rt_orders WHERE order_id=2001; SELECT * INTO b FROM rt_orders WHERE order_id=2002;
-- b.qty:=a.qty; b.unit_price:=a.unit_price; UPDATE rt_orders SET qty=b.qty, unit_price=b.unit_price WHERE order_id=b.order_id; COMMIT; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q7 (Negative test): Try to set qty=0 (should fail CHECK constraint); catch error.
-- Answer (commented):
-- BEGIN BEGIN UPDATE rt_orders SET qty=0 WHERE order_id=1001; COMMIT; EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('caught: '||SQLERRM); ROLLBACK; END; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q8 (Cursor vs table fields): Show that aliasing changes field names in c%ROWTYPE.
-- Answer (commented):
-- DECLARE CURSOR c IS SELECT order_id oid, status st FROM rt_orders WHERE order_id=1001;
-- v c%ROWTYPE; BEGIN OPEN c; FETCH c INTO v; CLOSE c; DBMS_OUTPUT.PUT_LINE(v.oid||' '||v.st); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q9 (Loader API): Implement load_order(p_id IN %TYPE, p_out OUT %ROWTYPE) and print.
-- Answer (commented):
-- DECLARE PROCEDURE load_order(p_id IN rt_orders.order_id%TYPE, p_out OUT rt_orders%ROWTYPE) IS BEGIN SELECT * INTO p_out FROM rt_orders WHERE order_id=p_id; END;
-- r rt_orders%ROWTYPE; BEGIN load_order(1002, r); DBMS_OUTPUT.PUT_LINE(r.order_id||' '||r.status); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q10 (Design note): When to avoid SELECT * INTO with table%ROWTYPE in public APIs?
-- Answer (commented):
-- -- Avoid when the table shape is not owned by your API or expected to change frequently; prefer explicit field lists to prevent accidental breaking changes.
--------------------------------------------------------------------------------

-- End of Assignment
