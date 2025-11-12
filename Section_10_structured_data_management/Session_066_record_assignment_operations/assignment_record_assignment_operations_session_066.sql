SET SERVEROUTPUT ON SIZE UNLIMITED;
--------------------------------------------------------------------------------
-- Assignment: Session 066 – Record Assignment Operations
-- Format:
--   • 10 detailed questions with complete solutions provided as COMMENTED blocks.
--   • To run a solution: copy the commented block and remove leading '--'.
-- Guidance:
--   • Use direct assignment only when shapes are identical.
--   • Prefer explicit mapping when shapes differ or aliases are present.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q1 (Whole copy): Create t_r(id,name) and copy a to b; print equality.
-- Answer (commented):
-- DECLARE TYPE t_r IS RECORD(id NUMBER, name VARCHAR2(30)); a t_r; b t_r; same BOOLEAN;
-- BEGIN a.id:=1; a.name:='X'; b:=a; same:=(a.id=b.id AND a.name=b.name); DBMS_OUTPUT.PUT_LINE(same); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q2 (Table->custom): Map rt_customers%ROWTYPE to t_public(id,name,mail,active).
-- Answer (commented):
-- DECLARE TYPE t_public IS RECORD(id rt_customers.customer_id%TYPE, name rt_customers.full_name%TYPE, mail rt_customers.email%TYPE, active rt_customers.is_active%TYPE);
-- r_tab rt_customers%ROWTYPE; r_pub t_public; BEGIN SELECT * INTO r_tab FROM rt_customers WHERE customer_id=1;
-- r_pub.id:=r_tab.customer_id; r_pub.name:=r_tab.full_name; r_pub.mail:=r_tab.email; r_pub.active:=r_tab.is_active;
-- DBMS_OUTPUT.PUT_LINE(r_pub.id||' '||r_pub.name); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q3 (Projection merge): Cursor(oid,q) → update qty in table for 'NEW' orders.
-- Answer (commented):
-- DECLARE CURSOR c IS SELECT order_id oid, qty q FROM rt_orders WHERE status='NEW'; v c%ROWTYPE; t rt_orders%ROWTYPE;
-- BEGIN OPEN c; LOOP FETCH c INTO v; EXIT WHEN c%NOTFOUND; SELECT * INTO t FROM rt_orders WHERE order_id=v.oid; t.qty:=v.q+1; UPDATE rt_orders SET qty=t.qty WHERE order_id=t.order_id; END LOOP; CLOSE c; COMMIT; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q4 (Optional field): Add 'note' when mapping to API record; default 'std' when NULL.
-- Answer (commented):
-- DECLARE TYPE t_api IS RECORD(id rt_orders.order_id%TYPE, item rt_orders.item_name%TYPE, qty rt_orders.qty%TYPE, price rt_orders.unit_price%TYPE, note VARCHAR2(50));
-- r rt_orders%ROWTYPE; a t_api; BEGIN SELECT * INTO r FROM rt_orders WHERE order_id=1001;
-- a.id:=r.order_id; a.item:=r.item_name; a.qty:=NVL(r.qty,1); a.price:=NVL(r.unit_price,0); a.note:=NVL(a.note,'std'); DBMS_OUTPUT.PUT_LINE(a.item||' note='||a.note); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q5 (Array copy): Copy elements between two associative arrays of same element shape.
-- Answer (commented):
-- DECLARE TYPE t_line IS RECORD(id NUMBER, qty NUMBER); TYPE t_lines IS TABLE OF t_line INDEX BY PLS_INTEGER; a t_lines; b t_lines; i PLS_INTEGER;
-- BEGIN a(1).id:=1; a(1).qty:=2; a(2).id:=2; a(2).qty:=3; FOR i IN a.FIRST..a.LAST LOOP IF a.EXISTS(i) THEN b(i):=a(i); END IF; END LOOP; DBMS_OUTPUT.PUT_LINE('count='||b.COUNT); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q6 (Validator): Reject active not in ('Y','N') before assignment.
-- Answer (commented):
-- DECLARE TYPE t_pub IS RECORD(id NUMBER, name VARCHAR2(30), active CHAR(1)); PROCEDURE chk(p IN t_pub) IS BEGIN IF p.active NOT IN ('Y','N') THEN RAISE_APPLICATION_ERROR(-20661,'bad'); END IF; END;
-- a t_pub; b t_pub; BEGIN a.id:=1; a.name:='A'; a.active:='Y'; chk(a); b:=a; DBMS_OUTPUT.PUT_LINE(b.active); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q7 (Alias dependency): Show that changing aliases changes c%ROWTYPE field names.
-- Answer (commented):
-- DECLARE CURSOR c IS SELECT order_id oid, item_name itm FROM rt_orders WHERE order_id=1001; v c%ROWTYPE;
-- BEGIN OPEN c; FETCH c INTO v; CLOSE c; DBMS_OUTPUT.PUT_LINE(v.oid||' '||v.itm); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q8 (Default copy): On NULL price, default to 0 during mapping.
-- Answer (commented):
-- DECLARE r rt_orders%ROWTYPE; TYPE t_api IS RECORD(id NUMBER, price NUMBER); a t_api;
-- BEGIN SELECT * INTO r FROM rt_orders WHERE order_id=1003; a.id:=r.order_id; a.price:=NVL(r.unit_price,0); DBMS_OUTPUT.PUT_LINE(a.id||' '||a.price); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q9 (Subset copy): Copy only id and status into t_small(id,status) from table row.
-- Answer (commented):
-- DECLARE TYPE t_small IS RECORD(id rt_orders.order_id%TYPE, status rt_orders.status%TYPE); r rt_orders%ROWTYPE; s t_small;
-- BEGIN SELECT * INTO r FROM rt_orders WHERE order_id=1002; s.id:=r.order_id; s.status:=r.status; DBMS_OUTPUT.PUT_LINE(s.id||' '||s.status); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q10 (Design answer): When should you avoid whole-record assignment?
-- Answer (commented):
-- -- Avoid when shapes may diverge due to schema changes or when using cursor projections with aliases; prefer explicit field mapping to make contracts clear and resilient.
--------------------------------------------------------------------------------

-- End of Assignment
