SET SERVEROUTPUT ON SIZE UNLIMITED;
--------------------------------------------------------------------------------
-- Session 077 – Cursor Variables and Sharing
-- Detailed SQL lesson demonstrating:
--   (1) Creating REF CURSOR types
--   (2) Passing cursor variables to/from procedures
--   (3) Building reusable data pipelines
--   (4) Dynamic SQL with REF CURSOR
--   (5) Ownership rules and cleanup guarantees
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 1: Basic cursor variable usage
--------------------------------------------------------------------------------
DECLARE
  v_rc SYS_REFCURSOR;
  v_id rt_orders.order_id%TYPE;
  v_item rt_orders.item_name%TYPE;
BEGIN
  OPEN v_rc FOR
    SELECT order_id, item_name
    FROM   rt_orders
    ORDER  BY order_id;

  LOOP
    FETCH v_rc INTO v_id, v_item;
    EXIT WHEN v_rc%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('CursorVar -> '||v_id||' '||v_item);
  END LOOP;

  CLOSE v_rc;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 2: Passing cursor variable OUT of a procedure
--------------------------------------------------------------------------------
DECLARE
  PROCEDURE get_new_orders(p_rc OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_rc FOR
      SELECT order_id, item_name, unit_price
      FROM   rt_orders
      WHERE  status='NEW'
      ORDER  BY order_id;
  END;

  v_rc SYS_REFCURSOR;
  v_id   rt_orders.order_id%TYPE;
  v_item rt_orders.item_name%TYPE;
  v_amt  rt_orders.unit_price%TYPE;
BEGIN
  get_new_orders(v_rc);

  LOOP
    FETCH v_rc INTO v_id, v_item, v_amt;
    EXIT WHEN v_rc%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('NEW: '||v_id||' '||v_item||' '||v_amt);
  END LOOP;

  CLOSE v_rc;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 3: Multi-stage pipeline pattern
-- Stage 1: Build dynamic query and open cursor
-- Stage 2: Consumer procedure fetches and prints results
--------------------------------------------------------------------------------
DECLARE
  PROCEDURE pipeline_stage1(p_min_amt NUMBER, p_rc OUT SYS_REFCURSOR) IS
    v_sql VARCHAR2(4000);
  BEGIN
    v_sql := 'SELECT order_id, item_name, unit_price '
          || 'FROM rt_orders WHERE unit_price >= :x ORDER BY unit_price';
    OPEN p_rc FOR v_sql USING p_min_amt;
  END;

  PROCEDURE pipeline_stage2(p_rc IN OUT SYS_REFCURSOR) IS
    v_id   rt_orders.order_id%TYPE;
    v_item rt_orders.item_name%TYPE;
    v_amt  rt_orders.unit_price%TYPE;
  BEGIN
    LOOP
      FETCH p_rc INTO v_id, v_item, v_amt;
      EXIT WHEN p_rc%NOTFOUND;
      DBMS_OUTPUT.PUT_LINE('PIPE -> '||v_id||' '||v_item||' '||v_amt);
    END LOOP;
    IF p_rc%ISOPEN THEN
      CLOSE p_rc;
    END IF;
  END;

  v_main SYS_REFCURSOR;
BEGIN
  pipeline_stage1(2000, v_main);
  pipeline_stage2(v_main);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 4: Cursor variable with conditional dynamic query selection
--------------------------------------------------------------------------------
DECLARE
  v_rc SYS_REFCURSOR;
  v_sql VARCHAR2(4000);
  v_id rt_orders.order_id%TYPE;
  v_item rt_orders.item_name%TYPE;
BEGIN
  IF TO_CHAR(SYSDATE,'D') IN ('1','7') THEN
    v_sql := 'SELECT order_id, item_name FROM rt_orders WHERE status=''NEW''';
  ELSE
    v_sql := 'SELECT order_id, item_name FROM rt_orders WHERE status=''PAID''';
  END IF;

  OPEN v_rc FOR v_sql;

  LOOP
    FETCH v_rc INTO v_id, v_item;
    EXIT WHEN v_rc%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('DayBased -> '||v_id||' '||v_item);
  END LOOP;

  CLOSE v_rc;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 5: Exception-safe cursor variable handling
--------------------------------------------------------------------------------
DECLARE
  v_rc SYS_REFCURSOR;
  v_id   rt_orders.order_id%TYPE;
  v_item rt_orders.item_name%TYPE;
BEGIN
  OPEN v_rc FOR SELECT order_id, item_name FROM rt_orders ORDER BY order_id;

  BEGIN
    LOOP
      FETCH v_rc INTO v_id, v_item;
      EXIT WHEN v_rc%NOTFOUND;
      IF v_id > 9002 THEN
        RAISE_APPLICATION_ERROR(-20055,'Demo failure');
      END IF;
      DBMS_OUTPUT.PUT_LINE('SAFE -> '||v_item);
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Caught error: '||SQLERRM);
  END;

  IF v_rc%ISOPEN THEN
    CLOSE v_rc;
  END IF;
END;
/
--------------------------------------------------------------------------------

-- End Lesson
