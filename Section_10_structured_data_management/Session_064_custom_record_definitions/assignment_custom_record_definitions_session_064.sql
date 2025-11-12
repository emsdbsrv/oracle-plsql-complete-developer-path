SET SERVEROUTPUT ON SIZE UNLIMITED;
--------------------------------------------------------------------------------
-- Assignment: Session 064 – Custom Record Definitions
-- Format:
--   • 10 detailed tasks with complete solutions provided as COMMENTED blocks.
--   • To run a solution: copy the commented block and remove leading '--'.
-- Guidance:
--   • Anchor scalars with %TYPE; keep custom RECORDs stable and decoupled.
--   • Centralize validation and mapping for maintainability.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q1 (Subtype anchors): Create t_id, t_name, t_active subtypes from rt_customers and print a sample.
-- Answer (commented):
-- DECLARE SUBTYPE t_id IS rt_customers.customer_id%TYPE; SUBTYPE t_name IS rt_customers.full_name%TYPE; SUBTYPE t_active IS rt_customers.is_active%TYPE;
-- t t_id:=1; n t_name:='Sample'; a t_active:='Y'; BEGIN DBMS_OUTPUT.PUT_LINE(t||' '||n||' '||a); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q2 (Custom record): Define t_contact(email, created_at) and print.
-- Answer (commented):
-- DECLARE TYPE t_contact IS RECORD(email rt_customers.email%TYPE, created_at DATE);
-- v t_contact; BEGIN v.email:='x@example.com'; v.created_at:=SYSDATE; DBMS_OUTPUT.PUT_LINE(v.email||' '||TO_CHAR(v.created_at,'YYYY-MM-DD')); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q3 (Customer public): Build t_customer_public and populate from a rt_customers row.
-- Answer (commented):
-- DECLARE TYPE t_contact IS RECORD(email rt_customers.email%TYPE, created_at DATE);
-- TYPE t_customer_public IS RECORD(id rt_customers.customer_id%TYPE, name rt_customers.full_name%TYPE, contact t_contact, active rt_customers.is_active%TYPE);
-- r_tab rt_customers%ROWTYPE; r_out t_customer_public;
-- BEGIN SELECT * INTO r_tab FROM rt_customers WHERE customer_id=1;
-- r_out.id:=r_tab.customer_id; r_out.name:=r_tab.full_name; r_out.contact.email:=r_tab.email; r_out.contact.created_at:=r_tab.created_at; r_out.active:=r_tab.is_active;
-- DBMS_OUTPUT.PUT_LINE(r_out.id||' '||r_out.name||' '||r_out.active); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q4 (Validator): Write validate_customer that checks id/name and active in ('Y','N').
-- Answer (commented):
-- DECLARE TYPE t_contact IS RECORD(email rt_customers.email%TYPE, created_at DATE);
-- TYPE t_customer_public IS RECORD(id rt_customers.customer_id%TYPE, name rt_customers.full_name%TYPE, contact t_contact, active rt_customers.is_active%TYPE);
-- PROCEDURE validate_customer(p IN t_customer_public) IS BEGIN IF p.id IS NULL OR p.name IS NULL THEN RAISE_APPLICATION_ERROR(-20641,'id/name required'); END IF; IF p.active NOT IN ('Y','N') THEN RAISE_APPLICATION_ERROR(-20642,'bad active'); END IF; END;
-- v t_customer_public; BEGIN v.id:=1; v.name:='A'; v.active:='Y'; validate_customer(v); DBMS_OUTPUT.PUT_LINE('ok'); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q5 (Order line): Define t_order_line and map from rt_orders row.
-- Answer (commented):
-- DECLARE TYPE t_order_line IS RECORD(order_id rt_orders.order_id%TYPE, item rt_orders.item_name%TYPE, qty rt_orders.qty%TYPE, price rt_orders.unit_price%TYPE, status rt_orders.status%TYPE);
-- r_tab rt_orders%ROWTYPE; l t_order_line;
-- BEGIN SELECT * INTO r_tab FROM rt_orders WHERE order_id=1001;
-- l.order_id:=r_tab.order_id; l.item:=r_tab.item_name; l.qty:=r_tab.qty; l.price:=r_tab.unit_price; l.status:=r_tab.status;
-- DBMS_OUTPUT.PUT_LINE(l.order_id||' '||l.item||' x'||l.qty||' @'||l.price||' '||l.status); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q6 (Summary): Build customer_order_summary with order_count and total_amount.
-- Answer (commented):
-- DECLARE TYPE t_contact IS RECORD(email rt_customers.email%TYPE, created_at DATE);
-- TYPE t_customer_public IS RECORD(id rt_customers.customer_id%TYPE, name rt_customers.full_name%TYPE, contact t_contact, active rt_customers.is_active%TYPE);
-- TYPE t_summary IS RECORD(customer t_customer_public, order_count PLS_INTEGER, total_amount NUMBER, last_order_date DATE);
-- s t_summary;
-- BEGIN SELECT customer_id, full_name, email, created_at, is_active INTO s.customer.id, s.customer.name, s.customer.contact.email, s.customer.contact.created_at, s.customer.active FROM rt_customers WHERE customer_id=1;
-- SELECT COUNT(*), NVL(SUM(qty*unit_price),0), MAX(created_at) INTO s.order_count, s.total_amount, s.last_order_date FROM rt_orders WHERE customer_id=1;
-- DBMS_OUTPUT.PUT_LINE('cnt='||s.order_count||' total='||s.total_amount); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q7 (Serializer): Implement function serialize(t_customer_public) and print for id=2.
-- Answer (commented):
-- DECLARE TYPE t_contact IS RECORD(email rt_customers.email%TYPE, created_at DATE);
-- TYPE t_customer_public IS RECORD(id rt_customers.customer_id%TYPE, name rt_customers.full_name%TYPE, contact t_contact, active rt_customers.is_active%TYPE);
-- FUNCTION serialize(p t_customer_public) RETURN VARCHAR2 IS BEGIN RETURN p.id||':'||p.name||':'||NVL(p.contact.email,'-')||':'||p.active; END;
-- r rt_customers%ROWTYPE; v t_customer_public; BEGIN SELECT * INTO r FROM rt_customers WHERE customer_id=2; v.id:=r.customer_id; v.name:=r.full_name; v.contact.email:=r.email; v.contact.created_at:=r.created_at; v.active:=r.is_active; DBMS_OUTPUT.PUT_LINE(serialize(v)); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q8 (IN OUT): Write activate(p IN OUT t_customer_public) that ensures active='Y'.
-- Answer (commented):
-- DECLARE TYPE t_contact IS RECORD(email rt_customers.email%TYPE, created_at DATE);
-- TYPE t_customer_public IS RECORD(id rt_customers.customer_id%TYPE, name rt_customers.full_name%TYPE, contact t_contact, active rt_customers.is_active%TYPE);
-- PROCEDURE activate(p IN OUT t_customer_public) IS BEGIN IF p.active<>'Y' THEN p.active:='Y'; END IF; END;
-- v t_customer_public; BEGIN v.id:=1; v.name:='A'; v.active:='N'; activate(v); DBMS_OUTPUT.PUT_LINE(v.active); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q9 (Round-trip): Map table->custom->text for order_id=1003 using t_order_line and print.
-- Answer (commented):
-- DECLARE TYPE t_order_line IS RECORD(order_id rt_orders.order_id%TYPE, item rt_orders.item_name%TYPE, qty rt_orders.qty%TYPE, price rt_orders.unit_price%TYPE, status rt_orders.status%TYPE);
-- FUNCTION serialize(l t_order_line) RETURN VARCHAR2 IS BEGIN RETURN l.order_id||'|'||l.item||'|'||l.qty||'|'||l.price||'|'||l.status; END;
-- r rt_orders%ROWTYPE; l t_order_line; BEGIN SELECT * INTO r FROM rt_orders WHERE order_id=1003; l.order_id:=r.order_id; l.item:=r.item_name; l.qty:=r.qty; l.price:=r.unit_price; l.status:=r.status; DBMS_OUTPUT.PUT_LINE(serialize(l)); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q10 (Design note): Why prefer custom RECORD in public APIs?
-- Answer (commented):
-- -- Because it decouples the API contract from table schema, allowing internal DDL changes without breaking callers. It also enables derived fields and strict whitelisting of exposed data.
--------------------------------------------------------------------------------

-- End of Assignment
