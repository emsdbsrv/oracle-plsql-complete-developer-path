SET SERVEROUTPUT ON SIZE UNLIMITED;
--------------------------------------------------------------------------------
-- Assignment – Session 076 Strong vs Weak REF Cursors
-- 10 questions with complete commented solutions
--------------------------------------------------------------------------------

-- Q1: Declare a strong REF CURSOR returning rt_orders%ROWTYPE and fetch rows.
-- Answer:
-- DECLARE
--   TYPE t_strong IS REF CURSOR RETURN rt_orders%ROWTYPE;
--   v_rc t_strong;
--   v_row rt_orders%ROWTYPE;
-- BEGIN
--   OPEN v_rc FOR SELECT * FROM rt_orders;
--   LOOP
--     FETCH v_rc INTO v_row;
--     EXIT WHEN v_rc%NOTFOUND;
--     DBMS_OUTPUT.PUT_LINE(v_row.order_id||' '||v_row.item_name);
--   END LOOP;
--   CLOSE v_rc;
-- END;
-- /

-- Q2: Use SYS_REFCURSOR to fetch id + status from rt_orders.
-- Answer:
-- DECLARE
--   v_rc SYS_REFCURSOR;
--   v_id NUMBER; v_stat VARCHAR2(20);
-- BEGIN
--   OPEN v_rc FOR SELECT order_id, status FROM rt_orders;
--   LOOP
--     FETCH v_rc INTO v_id, v_stat;
--     EXIT WHEN v_rc%NOTFOUND;
--     DBMS_OUTPUT.PUT_LINE(v_id||' '||v_stat);
--   END LOOP;
--   CLOSE v_rc;
-- END;
-- /

-- Q3: Dynamic SQL: Accept min_price, open REF CURSOR for rows > min_price.

-- Q4: Write a helper procedure returning strong REF CURSOR.

-- Q5: Write a helper procedure returning SYS_REFCURSOR.

-- Q6: Explain when strong REF CURSOR is better.

-- Q7: Explain when weak REF CURSOR is necessary.

-- Q8: Show exception-safe cleanup of REF CURSOR.

-- Q9: Demonstrate REF CURSOR OUT parameter usage across nested calls.

-- Q10: Show a design that mixes explicit and REF CURSORs.

-- End Assignment
