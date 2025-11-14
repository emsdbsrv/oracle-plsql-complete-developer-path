SET SERVEROUTPUT ON SIZE UNLIMITED;

--------------------------------------------------------------------------------
-- Script: plsql_session_098_bulk_collect_arrays.sql
-- Session: 098 - BULK COLLECT Arrays
-- Purpose:
--   Introduce and deeply explain BULK COLLECT usage for moving many rows from
--   the SQL engine into PL/SQL memory in a single call. This script shows:
--     (1) Basic BULK COLLECT into a single nested table.
--     (2) BULK COLLECT into parallel collections for multiple columns.
--     (3) BULK COLLECT with LIMIT to protect memory.
--     (4) BULK COLLECT into an associative array (index-by table).
--     (5) BULK COLLECT from an explicit cursor.
--     (6) BULK COLLECT inside a reusable procedure.
--     (7) Handling empty result sets and collection COUNT checks.
-- How to run:
--   • Ensure tg_employees exists with emp_id, emp_name, salary, dept_id.
--   • Enable server output before running.
--   • Execute each block individually, terminated by '/'
--------------------------------------------------------------------------------


/******************************************************************************
Example 1: Basic BULK COLLECT into a nested table
Scenario:
  • We want to pull several employee names into memory with one SQL call.
  • We use a nested table of VARCHAR2 and BULK COLLECT INTO it.
Key points:
  • v_names is a collection, not a scalar.
  • The SQL statement returns many rows; BULK COLLECT transfers them all.
******************************************************************************/
DECLARE
  TYPE t_name_tab IS TABLE OF tg_employees.emp_name%TYPE;
  v_names t_name_tab;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Example 1: Basic BULK COLLECT into a nested table');

  SELECT emp_name
  BULK COLLECT INTO v_names
  FROM tg_employees
  WHERE dept_id = 10
  ORDER BY emp_id;

  DBMS_OUTPUT.PUT_LINE('Rows fetched = '||v_names.COUNT);

  FOR i IN 1 .. v_names.COUNT LOOP
    DBMS_OUTPUT.PUT_LINE('Name['||i||']='||v_names(i));
  END LOOP;
END;
/
--------------------------------------------------------------------------------


/******************************************************************************
Example 2: BULK COLLECT into multiple parallel collections
Scenario:
  • We want both emp_id and emp_name in PL/SQL.
  • We define two collections, one for each column.
Key points:
  • BULK COLLECT INTO v_ids, v_names fills both collections in parallel.
  • Index i in each collection refers to the same row.
******************************************************************************/
DECLARE
  TYPE t_id_tab   IS TABLE OF tg_employees.emp_id%TYPE;
  TYPE t_name_tab IS TABLE OF tg_employees.emp_name%TYPE;

  v_ids   t_id_tab;
  v_names t_name_tab;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Example 2: BULK COLLECT into parallel collections');

  SELECT emp_id, emp_name
  BULK COLLECT INTO v_ids, v_names
  FROM tg_employees
  WHERE dept_id = 20
  ORDER BY emp_id;

  DBMS_OUTPUT.PUT_LINE('Rows fetched = '||v_ids.COUNT);

  FOR i IN 1 .. v_ids.COUNT LOOP
    DBMS_OUTPUT.PUT_LINE('ID='||v_ids(i)||' NAME='||v_names(i));
  END LOOP;
END;
/
--------------------------------------------------------------------------------


/******************************************************************************
Example 3: BULK COLLECT with LIMIT for large result sets
Scenario:
  • We may have many employees and do not want to load all rows at once.
  • We use a loop with FETCH ... BULK COLLECT INTO ... LIMIT <chunk size>.
Key points:
  • Each FETCH fills the collection with up to LIMIT rows.
  • We process each chunk and then loop again until no more rows.
******************************************************************************/
DECLARE
  CURSOR c_emp IS
    SELECT emp_id, emp_name, salary
    FROM tg_employees
    WHERE dept_id = 30
    ORDER BY emp_id;

  TYPE t_id_tab   IS TABLE OF tg_employees.emp_id%TYPE;
  TYPE t_name_tab IS TABLE OF tg_employees.emp_name%TYPE;
  TYPE t_sal_tab  IS TABLE OF tg_employees.salary%TYPE;

  v_ids   t_id_tab;
  v_names t_name_tab;
  v_sals  t_sal_tab;

  c_limit CONSTANT PLS_INTEGER := 5;  -- chunk size
BEGIN
  DBMS_OUTPUT.PUT_LINE('Example 3: BULK COLLECT with LIMIT');

  OPEN c_emp;
  LOOP
    FETCH c_emp BULK COLLECT INTO v_ids, v_names, v_sals LIMIT c_limit;

    EXIT WHEN v_ids.COUNT = 0;  -- no more rows

    DBMS_OUTPUT.PUT_LINE('Fetched chunk size = '||v_ids.COUNT);

    FOR i IN 1 .. v_ids.COUNT LOOP
      DBMS_OUTPUT.PUT_LINE('ID='||v_ids(i)||' NAME='||v_names(i)||' SAL='||v_sals(i));
    END LOOP;
  END LOOP;
  CLOSE c_emp;
END;
/
--------------------------------------------------------------------------------


/******************************************************************************
Example 4: BULK COLLECT into an associative array (index-by table)
Scenario:
  • We want a key-value style cache of salary by emp_id.
  • Use an associative array indexed by PLS_INTEGER or BY BINARY_INTEGER.
Key points:
  • We select two columns but fill one associative array of records,
    or two associative arrays (one for keys, one for values).
******************************************************************************/
DECLARE
  TYPE t_sal_by_id IS TABLE OF tg_employees.salary%TYPE
    INDEX BY PLS_INTEGER;

  v_salaries t_sal_by_id;
  v_ids      SYS.ODCINUMBERLIST; -- simple helper for displaying keys
BEGIN
  DBMS_OUTPUT.PUT_LINE('Example 4: BULK COLLECT into associative array');

  -- Collect ids first into a growable list to drive assignments
  SELECT emp_id
  BULK COLLECT INTO v_ids
  FROM tg_employees
  WHERE dept_id = 40
  ORDER BY emp_id;

  -- Now bulk salary fetch using IN clause
  SELECT salary
  BULK COLLECT INTO v_salaries
  FROM tg_employees
  WHERE emp_id IN (SELECT COLUMN_VALUE FROM TABLE(v_ids))
  ORDER BY emp_id;

  -- Note: v_salaries.FIRST..LAST will be 1..N, parallel to v_ids.
  FOR i IN 1 .. v_ids.COUNT LOOP
    DBMS_OUTPUT.PUT_LINE('ID='||v_ids(i)||' SALARY='||v_salaries(i));
  END LOOP;
END;
/
--------------------------------------------------------------------------------


/******************************************************************************
Example 5: BULK COLLECT from an explicit cursor into a record collection
Scenario:
  • We want a collection of records (emp_id, emp_name, salary).
  • Use a PL/SQL RECORD type and a TABLE OF that record type.
Key points:
  • v_emps is a collection of records, each with fields.
  • The BULK COLLECT INTO v_emps maps each row into a record element.
******************************************************************************/
DECLARE
  CURSOR c_emp IS
    SELECT emp_id, emp_name, salary
    FROM tg_employees
    WHERE dept_id = 50
    ORDER BY emp_id;

  TYPE t_emp_rec IS RECORD (
    emp_id   tg_employees.emp_id%TYPE,
    emp_name tg_employees.emp_name%TYPE,
    salary   tg_employees.salary%TYPE
  );

  TYPE t_emp_tab IS TABLE OF t_emp_rec;

  v_emps t_emp_tab;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Example 5: BULK COLLECT into record collection');

  OPEN c_emp;
  FETCH c_emp BULK COLLECT INTO v_emps;
  CLOSE c_emp;

  DBMS_OUTPUT.PUT_LINE('Rows fetched = '||v_emps.COUNT);

  FOR i IN 1 .. v_emps.COUNT LOOP
    DBMS_OUTPUT.PUT_LINE(
      'ID='||v_emps(i).emp_id||
      ' NAME='||v_emps(i).emp_name||
      ' SAL='||v_emps(i).salary
    );
  END LOOP;
END;
/
--------------------------------------------------------------------------------


/******************************************************************************
Example 6: Wrap BULK COLLECT in a reusable procedure
Scenario:
  • Provide a procedure that loads all employees of a department into a
    collection parameter for further processing by the caller.
Key points:
  • BULK COLLECT logic is encapsulated.
  • Caller receives a fully populated collection.
******************************************************************************/
DECLARE
  TYPE t_emp_rec IS RECORD (
    emp_id   tg_employees.emp_id%TYPE,
    emp_name tg_employees.emp_name%TYPE,
    salary   tg_employees.salary%TYPE,
    dept_id  tg_employees.dept_id%TYPE
  );

  TYPE t_emp_tab IS TABLE OF t_emp_rec;

  PROCEDURE load_dept_emps(
    p_dept_id IN tg_employees.dept_id%TYPE,
    p_emps    OUT t_emp_tab
  ) IS
  BEGIN
    SELECT emp_id, emp_name, salary, dept_id
    BULK COLLECT INTO p_emps
    FROM tg_employees
    WHERE dept_id = p_dept_id
    ORDER BY emp_id;
  END load_dept_emps;

  v_emps t_emp_tab;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Example 6: BULK COLLECT inside reusable procedure');

  load_dept_emps(10, v_emps);

  DBMS_OUTPUT.PUT_LINE('Loaded rows = '||v_emps.COUNT);

  FOR i IN 1 .. v_emps.COUNT LOOP
    DBMS_OUTPUT.PUT_LINE(
      'ID='||v_emps(i).emp_id||
      ' NAME='||v_emps(i).emp_name||
      ' SAL='||v_emps(i).salary
    );
  END LOOP;
END;
/
--------------------------------------------------------------------------------


/******************************************************************************
Example 7: Handling empty result sets and COUNT checks
Scenario:
  • BULK COLLECT never raises NO_DATA_FOUND by itself.
  • Instead, the target collection is just left with COUNT = 0.
Key points:
  • Always check v_collection.COUNT before iterating.
  • Decide how to handle the "no rows" condition explicitly.
******************************************************************************/
DECLARE
  TYPE t_id_tab IS TABLE OF tg_employees.emp_id%TYPE;
  v_ids t_id_tab;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Example 7: Empty result handling with BULK COLLECT');

  -- Intentionally pick a dept that may not exist (e.g., 9999)
  SELECT emp_id
  BULK COLLECT INTO v_ids
  FROM tg_employees
  WHERE dept_id = 9999;

  IF v_ids.COUNT = 0 THEN
    DBMS_OUTPUT.PUT_LINE('No employees found for dept_id 9999');
  ELSE
    FOR i IN 1 .. v_ids.COUNT LOOP
      DBMS_OUTPUT.PUT_LINE('ID='||v_ids(i));
    END LOOP;
  END IF;
END;
/
--------------------------------------------------------------------------------

-- End of Lesson: Session 098 - BULK COLLECT Arrays
--------------------------------------------------------------------------------
