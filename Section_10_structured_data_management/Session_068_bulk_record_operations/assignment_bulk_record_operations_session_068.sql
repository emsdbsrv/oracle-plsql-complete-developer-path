SET SERVEROUTPUT ON SIZE UNLIMITED;
--------------------------------------------------------------------------------
-- Assignment: Session 068 – Bulk Record Operations
-- Format:
--   • 10 tasks with complete solutions provided as COMMENTED blocks.
--   • To run a solution: copy the commented block and remove leading '--'.
-- Guidance:
--   • Start with BULK COLLECT LIMIT for memory control; use FORALL with SAVE EXCEPTIONS.
--   • Always log failed rows to rt_orders_log for later review.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q1 (Bulk load): BULK COLLECT all NEW orders into v_rows and print count.
-- Answer (commented):
-- DECLARE TYPE t_rows IS TABLE OF rt_orders%ROWTYPE; v_rows t_rows;
-- BEGIN SELECT * BULK COLLECT INTO v_rows FROM rt_orders WHERE status='NEW'; DBMS_OUTPUT.PUT_LINE(v_rows.COUNT); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q2 (LIMIT): Use a cursor and BULK COLLECT LIMIT 3; print batch sizes.
-- Answer (commented):
-- DECLARE CURSOR c IS SELECT * FROM rt_orders ORDER BY order_id; TYPE t_rows IS TABLE OF c%ROWTYPE; v_rows t_rows;
-- BEGIN OPEN c; LOOP FETCH c BULK COLLECT INTO v_rows LIMIT 3; EXIT WHEN v_rows.COUNT=0; DBMS_OUTPUT.PUT_LINE('batch='||v_rows.COUNT); END LOOP; CLOSE c; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q3 (FORALL UPDATE): Increment qty by 1 for all NEW orders using a collection of ids.
-- Answer (commented):
-- DECLARE TYPE t_ids IS TABLE OF rt_orders.order_id%TYPE INDEX BY PLS_INTEGER; v t_ids; i PLS_INTEGER:=0;
-- BEGIN FOR r IN (SELECT order_id FROM rt_orders WHERE status='NEW') LOOP i:=i+1; v(i):=r.order_id; END LOOP;
-- FORALL k IN v.FIRST..v.LAST UPDATE rt_orders SET qty=NVL(qty,1)+1 WHERE order_id=v(k); COMMIT; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q4 (SAVE EXCEPTIONS): Force an error on one row and capture with SQL%BULK_EXCEPTIONS.
-- Answer (commented):
-- DECLARE TYPE t_ids IS TABLE OF rt_orders.order_id%TYPE INDEX BY PLS_INTEGER; v t_ids; i PLS_INTEGER:=0;
-- BEGIN FOR r IN (SELECT order_id FROM rt_orders ORDER BY order_id) LOOP i:=i+1; v(i):=r.order_id; END LOOP;
-- BEGIN FORALL k IN v.FIRST..v.LAST SAVE EXCEPTIONS UPDATE rt_orders SET status='PAID' WHERE order_id=v(k); EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE(SQL%BULK_EXCEPTIONS.COUNT); END; COMMIT; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q5 (Bulk INSERT): Build a RECORD collection and FORALL insert rows into rt_orders_log.
-- Answer (commented):
-- DECLARE TYPE t_log IS RECORD(order_id NUMBER, action VARCHAR2(30), msg VARCHAR2(200)); TYPE t_logs IS TABLE OF t_log INDEX BY PLS_INTEGER; v t_logs; v(1).order_id:=1001; v(1).action:='AUDIT'; v(1).msg:='ok'; FORALL i IN v.FIRST..v.LAST INSERT INTO rt_orders_log(order_id,action,msg) VALUES (v(i).order_id,v(i).action,v(i).msg); COMMIT; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q6 (Bulk DELETE): Delete by id list using FORALL with SAVE EXCEPTIONS and log errors.
-- Answer (commented):
-- DECLARE TYPE t_ids IS TABLE OF NUMBER INDEX BY PLS_INTEGER; v t_ids; v(1):=9991; v(2):=9992;
-- BEGIN BEGIN FORALL i IN v.FIRST..v.LAST SAVE EXCEPTIONS DELETE FROM rt_orders WHERE order_id=v(i); EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE(SQL%BULK_EXCEPTIONS.COUNT); END; COMMIT; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q7 (End-to-end batch): BULK COLLECT LIMIT 2 ids, FORALL update to CANCELLED, log.
-- Answer (commented):
-- DECLARE CURSOR c IS SELECT order_id FROM rt_orders WHERE status='PAID' ORDER BY order_id; TYPE t_ids IS TABLE OF NUMBER; v t_ids;
-- BEGIN OPEN c; LOOP FETCH c BULK COLLECT INTO v LIMIT 2; EXIT WHEN v.COUNT=0; FORALL i IN 1..v.COUNT UPDATE rt_orders SET status='CANCELLED' WHERE order_id=v(i); FOR i IN 1..v.COUNT LOOP INSERT INTO rt_orders_log(order_id,action,msg) VALUES (v(i),'STATUS_CHANGE','PAID->CANCELLED'); END LOOP; COMMIT; END LOOP; CLOSE c; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q8 (Derived values): During FORALL UPDATE set unit_price = unit_price*1.05 for ids.
-- Answer (commented):
-- DECLARE TYPE t_ids IS TABLE OF NUMBER INDEX BY PLS_INTEGER; v t_ids; v(1):=1001; v(2):=1002;
-- BEGIN FORALL i IN v.FIRST..v.LAST UPDATE rt_orders SET unit_price = unit_price*1.05 WHERE order_id=v(i); COMMIT; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q9 (Array-of-scalar vs RECORD): Show a RECORD collection update vs scalar id list.
-- Answer (commented):
-- DECLARE TYPE t_rec IS RECORD(order_id NUMBER, qty NUMBER); TYPE t_recs IS TABLE OF t_rec INDEX BY PLS_INTEGER; r t_recs; r(1).order_id:=1003; r(1).qty:=5;
-- FORALL i IN r.FIRST..r.LAST UPDATE rt_orders SET qty=r(i).qty WHERE order_id=r(i).order_id; COMMIT; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q10 (Design note): Choose LIMIT size based on redo, PGA, and latch waits observed.
-- Answer (commented):
-- -- Start with 100–1000; measure and tune. Keep commits per batch to a safe size for your SLA and recovery objectives.
--------------------------------------------------------------------------------

-- End of Assignment
