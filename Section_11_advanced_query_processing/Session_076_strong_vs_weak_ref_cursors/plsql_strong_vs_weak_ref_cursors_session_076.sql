SET SERVEROUTPUT ON SIZE UNLIMITED;
--------------------------------------------------------------------------------
-- Session 076 – Strong vs Weak REF Cursors
-- Detailed examples demonstrating:
--   1) Declaring strong REF CURSOR types
--   2) Using SYS_REFCURSOR (weak)
--   3) Dynamic SQL with OPEN ... FOR
--   4) Passing REF CURSORs OUT of procedures
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 1: Strong REF CURSOR returning a known row structure
--------------------------------------------------------------------------------
DECLARE
  TYPE t_order_rc IS REF CURSOR RETURN rt_orders%ROWTYPE;
  v_rc t_order_rc;
  v_row rt_orders%ROWTYPE;
BEGIN
  OPEN v_rc FOR
    SELECT * FROM rt_orders ORDER BY order_id;

  LOOP
    FETCH v_rc INTO v_row;
    EXIT WHEN v_rc%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('StrongRC -> '||v_row.order_id||' '||v_row.item_name);
  END LOOP;

  CLOSE v_rc;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 2: Weak REF CURSOR (SYS_REFCURSOR)
--------------------------------------------------------------------------------
DECLARE
  v_rc SYS_REFCURSOR;
  v_id rt_orders.order_id%TYPE;
  v_item rt_orders.item_name%TYPE;
BEGIN
  OPEN v_rc FOR
    SELECT order_id, item_name FROM rt_orders ORDER BY order_id;

  LOOP
    FETCH v_rc INTO v_id, v_item;
    EXIT WHEN v_rc%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('WeakRC -> '||v_id||' '||v_item);
  END LOOP;

  CLOSE v_rc;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 3: Dynamic SQL using OPEN ... FOR with SYS_REFCURSOR
--------------------------------------------------------------------------------
DECLARE
  v_sql VARCHAR2(4000);
  v_rc  SYS_REFCURSOR;
  v_id  rt_orders.order_id%TYPE;
  v_amt rt_orders.unit_price%TYPE;
BEGIN
  v_sql := 'SELECT order_id, unit_price FROM rt_orders WHERE unit_price > :x';
  OPEN v_rc FOR v_sql USING 1000;

  LOOP
    FETCH v_rc INTO v_id, v_amt;
    EXIT WHEN v_rc%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('Dyn -> '||v_id||' amt='||v_amt);
  END LOOP;

  CLOSE v_rc;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 4: Procedure returning REF CURSOR
--------------------------------------------------------------------------------
DECLARE
  PROCEDURE get_paid_orders(p_rc OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_rc FOR
      SELECT order_id, item_name, unit_price
      FROM   rt_orders
      WHERE  status='PAID'
      ORDER  BY order_id;
  END;

  v_rc SYS_REFCURSOR;
  v_id rt_orders.order_id%TYPE;
  v_item rt_orders.item_name%TYPE;
  v_amt rt_orders.unit_price%TYPE;
BEGIN
  get_paid_orders(v_rc);

  LOOP
    FETCH v_rc INTO v_id, v_item, v_amt;
    EXIT WHEN v_rc%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('PROC -> '||v_id||' '||v_item||' '||v_amt);
  END LOOP;

  CLOSE v_rc;
END;
/
--------------------------------------------------------------------------------

-- End Lesson
