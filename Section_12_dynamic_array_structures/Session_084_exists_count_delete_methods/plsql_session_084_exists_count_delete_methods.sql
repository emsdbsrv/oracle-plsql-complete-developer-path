SET SERVEROUTPUT ON SIZE UNLIMITED;
--------------------------------------------------------------------------------
-- Session 084 – EXISTS, COUNT, DELETE Methods (Deep Dive)
-- This lesson demonstrates how EXISTS, COUNT, DELETE, and LAST behave on
-- nested tables and associative arrays, especially when collections are sparse.
-- Includes 7 detailed examples with commentary.
--------------------------------------------------------------------------------


/******************************************************************************
 EXAMPLE 1
 Basic COUNT and LAST on dense nested table
******************************************************************************/
DECLARE
  TYPE t_nt IS TABLE OF VARCHAR2(20);
  v t_nt := t_nt('A','B','C');
BEGIN
  DBMS_OUTPUT.PUT_LINE('Dense COUNT='||v.COUNT); -- 3
  DBMS_OUTPUT.PUT_LINE('Dense LAST='||v.LAST);   -- 3
END;
/
--------------------------------------------------------------------------------


/******************************************************************************
 EXAMPLE 2
 DELETE(n) and sparsity: COUNT vs LAST
******************************************************************************/
DECLARE
  TYPE t_nt IS TABLE OF VARCHAR2(20);
  v t_nt := t_nt('One','Two','Three','Four','Five');
BEGIN
  v.DELETE(2); -- remove 'Two'
  v.DELETE(4); -- remove 'Four'

  DBMS_OUTPUT.PUT_LINE('COUNT after DELETEs='||v.COUNT); -- 3
  DBMS_OUTPUT.PUT_LINE('LAST after DELETEs='||v.LAST);   -- still 5

  IF v.EXISTS(2) THEN
    DBMS_OUTPUT.PUT_LINE('Index 2 exists');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Index 2 does NOT exist');
  END IF;
END;
/
--------------------------------------------------------------------------------


/******************************************************************************
 EXAMPLE 3
 DELETE(m, n) – range deletion
******************************************************************************/
DECLARE
  TYPE t_nt IS TABLE OF NUMBER;
  v t_nt := t_nt(10,20,30,40,50,60);
BEGIN
  v.DELETE(3,5); -- delete 30,40,50

  DBMS_OUTPUT.PUT_LINE('After DELETE(3,5): COUNT='||v.COUNT||' LAST='||v.LAST);

  FOR i IN 1..v.LAST LOOP
    IF v.EXISTS(i) THEN
      DBMS_OUTPUT.PUT_LINE('i='||i||' val='||v(i));
    END IF;
  END LOOP;
END;
/
--------------------------------------------------------------------------------


/******************************************************************************
 EXAMPLE 4
 DELETE (no arguments) – full reset
******************************************************************************/
DECLARE
  TYPE t_nt IS TABLE OF VARCHAR2(20);
  v t_nt := t_nt('X','Y','Z');
BEGIN
  v.DELETE;  -- remove all elements

  DBMS_OUTPUT.PUT_LINE('After v.DELETE -> COUNT='||v.COUNT);
  IF v.LAST IS NULL THEN
    DBMS_OUTPUT.PUT_LINE('LAST is NULL for empty collection');
  END IF;
END;
/
--------------------------------------------------------------------------------


/******************************************************************************
 EXAMPLE 5
 EXISTS with associative array (sparse keys)
******************************************************************************/
DECLARE
  TYPE t_map IS TABLE OF VARCHAR2(30) INDEX BY PLS_INTEGER;
  v t_map;
  k PLS_INTEGER;
BEGIN
  v(10) := 'Ten';
  v(20) := 'Twenty';
  v(50) := 'Fifty';

  k := v.FIRST;
  WHILE k IS NOT NULL LOOP
    DBMS_OUTPUT.PUT_LINE('Key='||k||' -> '||v(k));
    k := v.NEXT(k);
  END LOOP;

  IF v.EXISTS(30) THEN
    DBMS_OUTPUT.PUT_LINE('Key 30 exists');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Key 30 does NOT exist');
  END IF;
END;
/
--------------------------------------------------------------------------------


/******************************************************************************
 EXAMPLE 6
 Safe iteration template for sparse nested tables
******************************************************************************/
DECLARE
  TYPE t_nt IS TABLE OF VARCHAR2(20);
  v t_nt := t_nt('A','B','C','D','E','F');
BEGIN
  v.DELETE(2);
  v.DELETE(5);

  FOR i IN 1..v.LAST LOOP
    IF v.EXISTS(i) THEN
      DBMS_OUTPUT.PUT_LINE('Processing index '||i||' val='||v(i));
    ELSE
      DBMS_OUTPUT.PUT_LINE('Index '||i||' is missing (sparse)');
    END IF;
  END LOOP;
END;
/
--------------------------------------------------------------------------------


/******************************************************************************
 EXAMPLE 7
 Combining BULK COLLECT with DELETE for conditional cleanup
******************************************************************************/
DECLARE
  TYPE t_nums IS TABLE OF NUMBER;
  v t_nums;
BEGIN
  SELECT LEVEL BULK COLLECT INTO v
  FROM dual CONNECT BY LEVEL <= 12;

  FOR i IN 1..v.LAST LOOP
    IF v.EXISTS(i) AND MOD(v(i),2) = 1 THEN
      v.DELETE(i); -- remove odd numbers
    END IF;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('Even numbers after DELETE of odds:');
  FOR i IN 1..v.LAST LOOP
    IF v.EXISTS(i) THEN
      DBMS_OUTPUT.PUT_LINE('i='||i||' val='||v(i));
    END IF;
  END LOOP;
END;
/
--------------------------------------------------------------------------------

-- End Lesson
