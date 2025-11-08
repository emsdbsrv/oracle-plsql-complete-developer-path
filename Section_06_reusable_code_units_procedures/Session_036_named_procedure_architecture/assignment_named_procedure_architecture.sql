-- Script: assignment_named_procedure_architecture.sql
-- Session: 036 - Named Procedure Architecture
-- Format:
--   • 10 detailed questions with complete solutions provided as COMMENTED hints.
--   • To run a solution: copy the commented block and remove leading '--'.
-- Guidance:
--   • Use %TYPE anchors for parameters; validate inputs and log SQL%%ROWCOUNT
--   • OUT for results; IN OUT for in-place transformations; raise domain errors when needed

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Q1: p_ping -> prints 'pong' and call it.
-- Answer (commented):
-- CREATE OR REPLACE PROCEDURE p_ping IS BEGIN DBMS_OUTPUT.PUT_LINE('pong'); END p_ping; /
-- BEGIN p_ping; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q2: p_ins(id, cust, amt>0) -> insert into proc_orders.
-- Answer (commented):
-- CREATE OR REPLACE PROCEDURE p_ins(p_id IN proc_orders.order_id%TYPE, p_cust IN proc_orders.customer%TYPE, p_amt IN proc_orders.amount%TYPE) IS
-- BEGIN IF p_amt<=0 THEN RAISE_APPLICATION_ERROR(-20011,'amt>0'); END IF;
-- INSERT INTO proc_orders(order_id,customer,amount,status) VALUES (p_id,p_cust,p_amt,'NEW');
-- DBMS_OUTPUT.PUT_LINE('rows='||SQL%ROWCOUNT);
-- END p_ins; /
-- BEGIN p_ins(201,'Asha',450); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q3: p_sum_by_status(status IN, total OUT) -> sum(amount) by status.
-- Answer (commented):
-- CREATE OR REPLACE PROCEDURE p_sum_by_status(p_status IN proc_orders.status%TYPE, p_total OUT NUMBER) IS
-- BEGIN SELECT NVL(SUM(amount),0) INTO p_total FROM proc_orders WHERE status=p_status; END p_sum_by_status; /
-- DECLARE v NUMBER; BEGIN p_sum_by_status('NEW',v); DBMS_OUTPUT.PUT_LINE('total='||v); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q4: p_apply_tax(amount IN OUT, rate IN DEFAULT 0.18) -> modify in place.
-- Answer (commented):
-- CREATE OR REPLACE PROCEDURE p_apply_tax(p_amt IN OUT NUMBER, p_rate IN NUMBER DEFAULT 0.18) IS
-- BEGIN IF p_rate<0 OR p_rate>1 THEN RAISE_APPLICATION_ERROR(-20012,'invalid rate'); END IF;
-- p_amt := ROUND(p_amt*(1+p_rate),2); END p_apply_tax; /
-- DECLARE v NUMBER:=100; BEGIN p_apply_tax(v); DBMS_OUTPUT.PUT_LINE('v='||v); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q5: p_set_status(id IN, status IN DEFAULT 'APPROVED').
-- Answer (commented):
-- CREATE OR REPLACE PROCEDURE p_set_status(p_id IN proc_orders.order_id%TYPE, p_status IN proc_orders.status%TYPE DEFAULT 'APPROVED') IS
-- BEGIN UPDATE proc_orders SET status=p_status WHERE order_id=p_id; DBMS_OUTPUT.PUT_LINE('rows='||SQL%ROWCOUNT); END p_set_status; /
-- BEGIN p_set_status(201); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q6: p_close(id IN) -> close if exists and not already closed; else raise.
-- Answer (commented):
-- CREATE OR REPLACE PROCEDURE p_close(p_id IN proc_orders.order_id%TYPE) IS v NUMBER; BEGIN
--   SELECT COUNT(*) INTO v FROM proc_orders WHERE order_id=p_id;
--   IF v=0 THEN RAISE_APPLICATION_ERROR(-20020,'missing'); END IF;
--   UPDATE proc_orders SET status='CLOSED' WHERE order_id=p_id AND status<>'CLOSED';
--   IF SQL%ROWCOUNT=0 THEN RAISE_APPLICATION_ERROR(-20021,'already closed'); END IF;
-- END p_close; /
-- BEGIN p_close(201); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q7: Wrapper with explicit commit: insert id 202 and approve it in one block.
-- Answer (commented):
-- BEGIN p_ins(202,'Neeraj',600); p_set_status(202,'APPROVED'); COMMIT; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q8: SHOW ERRORS (manual): create p_broken then SHOW ERRORS.
-- Answer (commented):
-- -- CREATE OR REPLACE PROCEDURE p_broken IS BEGIN DBMS_OUTPUT.PUTLINE('x'); END p_broken; /
-- -- SHOW ERRORS PROCEDURE p_broken;
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q9: p_create_and_close -> call p_ins then p_close; print a message.
-- Answer (commented):
-- CREATE OR REPLACE PROCEDURE p_create_and_close(p_id IN proc_orders.order_id%TYPE, p_cust IN proc_orders.customer%TYPE, p_amt IN proc_orders.amount%TYPE) IS
-- BEGIN p_ins(p_id,p_cust,p_amt); p_close(p_id); DBMS_OUTPUT.PUT_LINE('ok '||p_id); END p_create_and_close; /
-- BEGIN p_create_and_close(203,'Isha',350); COMMIT; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q10: Caller-side WHEN OTHERS: call p_close(-1) and log SQLERRM.
-- Answer (commented):
-- BEGIN p_close(-1); EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('caught='||SQLERRM); END; /
--------------------------------------------------------------------------------
-- End of Assignment
--------------------------------------------------------------------------------
