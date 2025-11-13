SET SERVEROUTPUT ON SIZE UNLIMITED;
--------------------------------------------------------------------------------
-- Assignment: Session 071 – SQL%FOUND Attribute Usage
-- Format:
--   • 10 tasks with detailed, commented solutions.
--   • To run a solution: copy the commented block and remove leading '--'.
-- Guidance:
--   • Prefer control-flow checks (SQL%FOUND / SQL%ROWCOUNT) before raising exceptions.
--   • For explicit cursors, use c%FOUND; SQL%FOUND applies to implicit cursors only.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q1 (UPDATE guard): Update NEW->PAID and print SQL%FOUND and SQL%ROWCOUNT.
-- Answer (commented):
-- BEGIN UPDATE rt_orders SET status='PAID' WHERE status='NEW'; DBMS_OUTPUT.PUT_LINE('found='||CASE WHEN SQL%FOUND THEN 'Y' ELSE 'N' END||' count='||SQL%ROWCOUNT); ROLLBACK; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q2 (DELETE outcome): Try to delete id 999999 and branch on SQL%FOUND.
-- Answer (commented):
-- BEGIN DELETE FROM rt_orders WHERE order_id=999999; IF SQL%FOUND THEN DBMS_OUTPUT.PUT_LINE('deleted '||SQL%ROWCOUNT); ELSE DBMS_OUTPUT.PUT_LINE('no delete'); END IF; ROLLBACK; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q3 (Upsert flow): UPDATE by order_id, else INSERT if not found.
-- Answer (commented):
-- DECLARE v_id NUMBER:=4300; BEGIN UPDATE rt_orders SET qty=3 WHERE order_id=v_id; IF SQL%FOUND THEN DBMS_OUTPUT.PUT_LINE('updated'); ELSE INSERT INTO rt_orders(order_id,customer_id,item_name,qty,unit_price,status,created_at) VALUES (v_id,1,'Cable',3,300,'NEW',SYSDATE); DBMS_OUTPUT.PUT_LINE('inserted'); END IF; ROLLBACK; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q4 (Safe SELECT INTO): Use COUNT pre-check then SELECT INTO a scalar.
-- Answer (commented):
-- DECLARE v_cnt NUMBER; v_price NUMBER; v_id NUMBER:=4101; BEGIN SELECT COUNT(*) INTO v_cnt FROM rt_orders WHERE order_id=v_id; IF v_cnt=1 THEN SELECT unit_price INTO v_price FROM rt_orders WHERE order_id=v_id; DBMS_OUTPUT.PUT_LINE(v_price); ELSE DBMS_OUTPUT.PUT_LINE('absent'); END IF; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q5 (Customer activate): UPDATE is_active='Y' by id; if NOT FOUND then INSERT.
-- Answer (commented):
-- DECLARE v_id NUMBER:=9100; BEGIN UPDATE rt_customers SET is_active='Y' WHERE customer_id=v_id; IF SQL%FOUND THEN DBMS_OUTPUT.PUT_LINE('reactivated'); ELSE INSERT INTO rt_customers(customer_id,full_name,email,is_active,created_at) VALUES (v_id,'Temp','temp@example.com','Y',SYSDATE); DBMS_OUTPUT.PUT_LINE('inserted'); END IF; ROLLBACK; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q6 (Rowcount report): CANCEL orders created before yesterday; print count.
-- Answer (commented):
-- BEGIN UPDATE rt_orders SET status='CANCELLED' WHERE created_at<SYSDATE-1; DBMS_OUTPUT.PUT_LINE('count='||SQL%ROWCOUNT); ROLLBACK; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q7 (NOTFOUND branch): Attempt to update a condition that matches no rows.
-- Answer (commented):
-- BEGIN UPDATE rt_orders SET qty=qty+10 WHERE order_id=-1; IF SQL%NOTFOUND THEN DBMS_OUTPUT.PUT_LINE('no matches'); END IF; ROLLBACK; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q8 (DELETE safety): DELETE where status='X'; if no impact, insert a log row (print only).
-- Answer (commented):
-- BEGIN DELETE FROM rt_orders WHERE status='X'; IF SQL%NOTFOUND THEN DBMS_OUTPUT.PUT_LINE('log: nothing to delete'); ELSE DBMS_OUTPUT.PUT_LINE('deleted '||SQL%ROWCOUNT); END IF; ROLLBACK; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q9 (Two-step check): First UPDATE price for a PAID order; if none, UPDATE NEW instead.
-- Answer (commented):
-- BEGIN UPDATE rt_orders SET unit_price=unit_price*1.02 WHERE status='PAID'; IF SQL%NOTFOUND THEN UPDATE rt_orders SET unit_price=unit_price*1.02 WHERE status='NEW'; DBMS_OUTPUT.PUT_LINE('fallback applied, count='||SQL%ROWCOUNT); ELSE DBMS_OUTPUT.PUT_LINE('updated PAID, count='||SQL%ROWCOUNT); END IF; ROLLBACK; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q10 (Design answer): When to prefer SQL%FOUND over exception handling?
-- Answer (commented):
-- -- Prefer SQL%FOUND for expected absence/presence checks after DML; reserve exceptions for truly exceptional states. This keeps execution paths predictable and avoids noisy NO_DATA_FOUND/TOO_MANY_ROWS traps.
--------------------------------------------------------------------------------

-- End of Assignment
