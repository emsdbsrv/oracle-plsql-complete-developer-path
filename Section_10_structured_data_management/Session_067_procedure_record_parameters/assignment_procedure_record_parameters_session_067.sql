SET SERVEROUTPUT ON SIZE UNLIMITED;
--------------------------------------------------------------------------------
-- Assignment: Session 067 – Procedure Record Parameters
-- Format:
--   • 10 detailed tasks with complete solutions as COMMENTED blocks.
--   • To run a solution: copy the commented block and remove leading '--'.
-- Guidance:
--   • Use OUT for loaders, IN for pure updaters, IN OUT for mutators.
--   • Validate before mutate; document mapping assumptions.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q1 (OUT loader): load_customer(p_id, p_out) returning rt_customers%ROWTYPE.
-- Answer (commented):
-- DECLARE PROCEDURE load_customer(p_id IN rt_customers.customer_id%TYPE, p_out OUT rt_customers%ROWTYPE) IS BEGIN SELECT * INTO p_out FROM rt_customers WHERE customer_id=p_id; END;
-- r rt_customers%ROWTYPE; BEGIN load_customer(1, r); DBMS_OUTPUT.PUT_LINE(r.full_name); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q2 (IN updater): update_order_status(p_row IN rt_orders%ROWTYPE).
-- Answer (commented):
-- DECLARE PROCEDURE update_order_status(p_row IN rt_orders%ROWTYPE) IS BEGIN UPDATE rt_orders SET status=p_row.status WHERE order_id=p_row.order_id; END;
-- r rt_orders%ROWTYPE; BEGIN SELECT * INTO r FROM rt_orders WHERE order_id=1001; r.status:='PAID'; update_order_status(r); COMMIT; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q3 (IN OUT mutator): bump_qty(p IN OUT rt_orders%ROWTYPE) + persist.
-- Answer (commented):
-- DECLARE PROCEDURE bump_qty(p IN OUT rt_orders%ROWTYPE) IS BEGIN p.qty:=NVL(p.qty,1)+1; END;
-- r rt_orders%ROWTYPE; BEGIN SELECT * INTO r FROM rt_orders WHERE order_id=1003; bump_qty(r); UPDATE rt_orders SET qty=r.qty WHERE order_id=r.order_id; COMMIT; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q4 (Projection mapping): cursor%ROWTYPE(oid,q) -> update table qty.
-- Answer (commented):
-- DECLARE CURSOR c IS SELECT order_id oid, qty q FROM rt_orders WHERE status='NEW'; PROCEDURE apply(p IN c%ROWTYPE) IS t rt_orders%ROWTYPE; BEGIN SELECT * INTO t FROM rt_orders WHERE order_id=p.oid; t.qty:=NVL(p.q,1)+2; UPDATE rt_orders SET qty=t.qty WHERE order_id=t.order_id; END;
-- BEGIN FOR v IN c LOOP apply(v); END LOOP; COMMIT; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q5 (Custom API OUT): get_public(p_id, p_out t_customer_public).
-- Answer (commented):
-- DECLARE TYPE t_contact IS RECORD(email rt_customers.email%TYPE, created_at DATE); TYPE t_customer_public IS RECORD(id rt_customers.customer_id%TYPE, name rt_customers.full_name%TYPE, contact t_contact, active rt_customers.is_active%TYPE);
-- PROCEDURE get_public(p_id IN rt_customers.customer_id%TYPE, p_out OUT t_customer_public) IS r rt_customers%ROWTYPE; BEGIN SELECT * INTO r FROM rt_customers WHERE customer_id=p_id; p_out.id:=r.customer_id; p_out.name:=r.full_name; p_out.contact.email:=r.email; p_out.contact.created_at:=r.created_at; p_out.active:=r.is_active; END;
-- v t_customer_public; BEGIN get_public(2, v); DBMS_OUTPUT.PUT_LINE(v.id||' '||v.name); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q6 (Validator): validate(p IN t_customer_public) for id/name + active flag.
-- Answer (commented):
-- DECLARE TYPE t_contact IS RECORD(email rt_customers.email%TYPE, created_at DATE); TYPE t_customer_public IS RECORD(id rt_customers.customer_id%TYPE, name rt_customers.full_name%TYPE, contact t_contact, active rt_customers.is_active%TYPE);
-- PROCEDURE validate(p IN t_customer_public) IS BEGIN IF p.id IS NULL OR p.name IS NULL THEN RAISE_APPLICATION_ERROR(-20670,'id/name'); END IF; IF p.active NOT IN ('Y','N') THEN RAISE_APPLICATION_ERROR(-20671,'active'); END IF; END;
-- v t_customer_public; BEGIN v.id:=1; v.name:='Avi'; v.active:='Y'; validate(v); DBMS_OUTPUT.PUT_LINE('ok'); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q7 (Safe wrapper): safe_set_status(p_row IN rt_orders%ROWTYPE) with error messages.
-- Answer (commented):
-- DECLARE PROCEDURE safe_set_status(p_row IN rt_orders%ROWTYPE) IS BEGIN IF p_row.order_id IS NULL THEN RAISE_APPLICATION_ERROR(-20672,'order_id'); END IF; UPDATE rt_orders SET status=p_row.status WHERE order_id=p_row.order_id; IF SQL%ROWCOUNT=0 THEN RAISE_APPLICATION_ERROR(-20673,'no row'); END IF; EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('error: '||SQLERRM); END;
-- r rt_orders%ROWTYPE; BEGIN r.order_id:=9999; r.status:='PAID'; safe_set_status(r); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q8 (Record echo): echo(p IN t_api, p_out OUT t_api) to show OUT of composite.
-- Answer (commented):
-- DECLARE TYPE t_api IS RECORD(order rt_orders%ROWTYPE, note VARCHAR2(100)); PROCEDURE echo(p IN t_api, p_out OUT t_api) IS BEGIN p_out:=p; END;
-- a t_api; b t_api; BEGIN SELECT * INTO a.order FROM rt_orders WHERE order_id=1001; a.note:='hello'; echo(a,b); DBMS_OUTPUT.PUT_LINE(b.order.order_id||' '||b.note); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q9 (IN purity): show that IN parameter cannot be assigned inside procedure body.
-- Answer (commented):
-- DECLARE TYPE t_r IS RECORD(x NUMBER); PROCEDURE bad(p IN t_r) IS BEGIN NULL; /* p.x:=1; -- not allowed */ END; BEGIN NULL; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q10 (Design note): When to prefer custom RECORD in params over table%ROWTYPE?
-- Answer (commented):
-- -- Prefer custom RECORD for public APIs to decouple from table DDL, expose only needed fields, and allow derived values; table%ROWTYPE is fine internally where you own the schema.
--------------------------------------------------------------------------------

-- End of Assignment
