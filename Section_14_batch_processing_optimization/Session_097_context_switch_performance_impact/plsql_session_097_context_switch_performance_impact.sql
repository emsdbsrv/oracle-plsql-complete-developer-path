SET SERVEROUTPUT ON SIZE UNLIMITED;

--------------------------------------------------------------------------------
-- Script: plsql_session_097_context_switch_performance_impact.sql
-- Session: 097 - Context Switch Performance Impact
-- Purpose:
--   Show how frequent SQL ⇄ PL/SQL context switches slow down PL/SQL and how
--   to improve performance using:
--     • Set-based SQL
--     • BULK COLLECT
--     • FORALL
--   Each example is heavily commented to explain what is happening.
--------------------------------------------------------------------------------

/******************************************************************************
Example 1: Naive SELECT in loop (many context switches)
******************************************************************************/
DECLARE
  v_emp_name tg_employees.emp_name%TYPE;
  v_max_id   PLS_INTEGER := 10;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Example 1: Row-by-row SELECT inside loop');
  FOR v_id IN 1 .. v_max_id LOOP
    -- One SQL call per iteration (one context switch per loop)
    SELECT emp_name
      INTO v_emp_name
      FROM tg_employees
     WHERE emp_id = v_id;

    DBMS_OUTPUT.PUT_LINE('emp_id='||v_id||' name='||v_emp_name);
  END LOOP;
END;
/
--------------------------------------------------------------------------------

/******************************************************************************
Example 2: BULK COLLECT – reduce to one SQL call
******************************************************************************/
DECLARE
  TYPE t_id_tab   IS TABLE OF tg_employees.emp_id%TYPE;
  TYPE t_name_tab IS TABLE OF tg_employees.emp_name%TYPE;

  v_ids   t_id_tab;
  v_names t_name_tab;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Example 2: BULK COLLECT instead of per-row SELECT');

  -- One SQL call to fetch all required rows
  SELECT emp_id, emp_name
  BULK COLLECT INTO v_ids, v_names
  FROM tg_employees
  WHERE emp_id BETWEEN 1 AND 10
  ORDER BY emp_id;

  -- Pure PL/SQL loop over collections (no SQL calls, no context switches)
  FOR i IN 1 .. v_ids.COUNT LOOP
    DBMS_OUTPUT.PUT_LINE('emp_id='||v_ids(i)||' name='||v_names(i));
  END LOOP;
END;
/
--------------------------------------------------------------------------------

/******************************************************************************
Example 3: Row-by-row UPDATE in cursor loop (anti-pattern)
******************************************************************************/
DECLARE
  v_dept_id tg_employees.dept_id%TYPE := 10;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Example 3: Row-by-row UPDATE in cursor loop');

  FOR r_emp IN (
    SELECT emp_id, salary
    FROM   tg_employees
    WHERE  dept_id = v_dept_id
  ) LOOP
    -- One UPDATE per row (one context switch per row)
    UPDATE tg_employees
       SET salary = r_emp.salary * 1.05
     WHERE emp_id = r_emp.emp_id;
  END LOOP;
END;
/
--------------------------------------------------------------------------------

/******************************************************************************
Example 4: FORALL bulk UPDATE – far fewer context switches
******************************************************************************/
DECLARE
  v_dept_id tg_employees.dept_id%TYPE := 10;

  TYPE t_id_tab IS TABLE OF tg_employees.emp_id%TYPE;
  TYPE t_sal_tab IS TABLE OF tg_employees.salary%TYPE;

  v_ids t_id_tab;
  v_sals t_sal_tab;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Example 4: FORALL bulk UPDATE');

  -- One SQL call to fetch keys + old salaries
  SELECT emp_id, salary
  BULK COLLECT INTO v_ids, v_sals
  FROM tg_employees
  WHERE dept_id = v_dept_id;

  -- One bulk DML dispatch instead of N single-row UPDATEs
  FORALL i IN 1 .. v_ids.COUNT
    UPDATE tg_employees
       SET salary = v_sals(i) * 1.05
     WHERE emp_id = v_ids(i);
END;
/
--------------------------------------------------------------------------------

/******************************************************************************
Example 5: Timing naive SELECT-in-loop
******************************************************************************/
DECLARE
  v_dummy      tg_employees.emp_name%TYPE;
  v_iterations PLS_INTEGER := 500;
  t_start      NUMBER;
  t_end        NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Example 5: Timing naive row-by-row SELECT');
  t_start := DBMS_UTILITY.GET_TIME;

  FOR i IN 1 .. v_iterations LOOP
    SELECT emp_name
      INTO v_dummy
      FROM tg_employees
     WHERE emp_id = 1;
  END LOOP;

  t_end := DBMS_UTILITY.GET_TIME;

  DBMS_OUTPUT.PUT_LINE('Naive loop elapsed (hundredths of sec) = '||(t_end - t_start));
END;
/
--------------------------------------------------------------------------------

/******************************************************************************
Example 6: Timing bulk pattern (one SELECT, many PL/SQL iterations)
******************************************************************************/
DECLARE
  v_tab        SYS.ODCIVARCHAR2LIST;
  v_iterations PLS_INTEGER := 500;
  t_start      NUMBER;
  t_end        NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Example 6: Timing BULK SELECT + PL/SQL loop');

  t_start := DBMS_UTILITY.GET_TIME;

  SELECT emp_name
  BULK COLLECT INTO v_tab
  FROM tg_employees
  WHERE emp_id = 1;

  FOR i IN 1 .. v_iterations LOOP
    IF v_tab.COUNT > 0 THEN
      NULL; -- simulate some work
    END IF;
  END LOOP;

  t_end := DBMS_UTILITY.GET_TIME;

  DBMS_OUTPUT.PUT_LINE('Bulk pattern elapsed (hundredths of sec) = '||(t_end - t_start));
END;
/
--------------------------------------------------------------------------------

/******************************************************************************
Example 7: Set-based UPDATE – no PL/SQL loop at all
******************************************************************************/
UPDATE tg_employees
   SET salary = salary * 1.03
 WHERE dept_id = 20;
/
--------------------------------------------------------------------------------

-- End of Lesson: Session 097 - Context Switch Performance Impact
--------------------------------------------------------------------------------
