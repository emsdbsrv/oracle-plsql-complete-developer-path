SET SERVEROUTPUT ON SIZE UNLIMITED;
--------------------------------------------------------------------------------
-- Assignment – Session 077 Cursor Variables & Sharing
-- 10 questions with full commented solutions
--------------------------------------------------------------------------------

-- Q1: Create a SYS_REFCURSOR, open it for SELECT order_id FROM rt_orders, fetch rows.
-- Answer:
-- DECLARE
--   v_rc SYS_REFCURSOR;
--   v_id NUMBER;
-- BEGIN
--   OPEN v_rc FOR SELECT order_id FROM rt_orders;
--   LOOP FETCH v_rc INTO v_id; EXIT WHEN v_rc%NOTFOUND;
--     DBMS_OUTPUT.PUT_LINE(v_id);
--   END LOOP;
--   CLOSE v_rc;
-- END;
-- /

-- Q2: Write a procedure get_paid(p_rc OUT SYS_REFCURSOR) returning paid orders.

-- Q3: Create a pipeline: stage1 builds dynamic SQL; stage2 consumes cursor.

-- Q4: Return a strongly typed REF CURSOR type t_rc RETURN rt_orders%ROWTYPE.

-- Q5: Demonstrate dynamic SQL filter by minimum amount using cursor variable.

-- Q6: Explain ownership rule of REF CURSOR between caller and callee.

-- Q7: Use REF CURSOR to join customers + orders dynamically.

-- Q8: Show exception-safe close of cursor variable.

-- Q9: Pass cursor variable IN OUT across two chained procedures.

-- Q10: Describe when cursor variables are preferred over explicit cursors.

-- End Assignment
