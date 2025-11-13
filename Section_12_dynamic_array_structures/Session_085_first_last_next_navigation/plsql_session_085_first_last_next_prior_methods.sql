SET SERVEROUTPUT ON SIZE UNLIMITED;
--------------------------------------------------------------------------------
-- Session 085 – FIRST, LAST, NEXT, PRIOR Navigation Methods
-- Purpose:
--   Explain and demonstrate how to navigate PL/SQL collections using:
--     • FIRST and LAST for boundary discovery
--     • NEXT and PRIOR for index-to-index traversal
--   Examples cover both nested tables and associative arrays, with sparse data.
-- How to run:
--   1. Enable DBMS_OUTPUT in your client.
--   2. Execute each example block separately (each ends with '/').
--------------------------------------------------------------------------------


/******************************************************************************
 Example 1: FIRST and LAST on a dense nested table
 Scenario:
   Show how FIRST and LAST behave when there are no gaps.
******************************************************************************/
DECLARE
  TYPE t_nt IS TABLE OF VARCHAR2(20);
  v t_nt := t_nt('Alpha','Bravo','Charlie');
BEGIN
  DBMS_OUTPUT.PUT_LINE('Dense collection:');
  DBMS_OUTPUT.PUT_LINE('  COUNT = '||v.COUNT);         -- 3
  DBMS_OUTPUT.PUT_LINE('  FIRST = '||v.FIRST);         -- 1
  DBMS_OUTPUT.PUT_LINE('  LAST  = '||v.LAST);          -- 3
END;
/
--------------------------------------------------------------------------------


/******************************************************************************
 Example 2: FIRST and LAST on a sparse nested table
 Scenario:
   Delete middle elements and observe that FIRST/LAST still report the
   outer bounds, even if there are gaps inside.
******************************************************************************/
DECLARE
  TYPE t_nt IS TABLE OF VARCHAR2(20);
  v t_nt := t_nt('One','Two','Three','Four','Five');
BEGIN
  v.DELETE(2);  -- remove index 2
  v.DELETE(4);  -- remove index 4

  DBMS_OUTPUT.PUT_LINE('Sparse collection:');
  DBMS_OUTPUT.PUT_LINE('  COUNT = '||v.COUNT);         -- 3
  DBMS_OUTPUT.PUT_LINE('  FIRST = '||v.FIRST);         -- 1
  DBMS_OUTPUT.PUT_LINE('  LAST  = '||v.LAST);          -- 5

  DBMS_OUTPUT.PUT_LINE('Iterating with 1..LAST + EXISTS:');
  FOR i IN 1..v.LAST LOOP
    IF v.EXISTS(i) THEN
      DBMS_OUTPUT.PUT_LINE('  i='||i||' value='||v(i));
    ELSE
      DBMS_OUTPUT.PUT_LINE('  i='||i||' (hole)');
    END IF;
  END LOOP;
END;
/
--------------------------------------------------------------------------------


/******************************************************************************
 Example 3: Associative array navigation using FIRST and NEXT
 Scenario:
   Use FIRST/NEXT to walk over non-contiguous integer keys.
******************************************************************************/
DECLARE
  TYPE t_map IS TABLE OF VARCHAR2(30) INDEX BY PLS_INTEGER;
  v t_map;
  k PLS_INTEGER;
BEGIN
  v(10) := 'Ten';
  v(30) := 'Thirty';
  v(70) := 'Seventy';

  DBMS_OUTPUT.PUT_LINE('Associative array forward walk using FIRST/NEXT:');
  k := v.FIRST;  -- lowest key, 10
  WHILE k IS NOT NULL LOOP
    DBMS_OUTPUT.PUT_LINE('  key='||k||' value='||v(k));
    k := v.NEXT(k); -- next key in ascending order
  END LOOP;
END;
/
--------------------------------------------------------------------------------


/******************************************************************************
 Example 4: Associative array navigation using LAST and PRIOR
 Scenario:
   Walk the same associative array in reverse order.
******************************************************************************/
DECLARE
  TYPE t_map IS TABLE OF VARCHAR2(30) INDEX BY PLS_INTEGER;
  v t_map;
  k PLS_INTEGER;
BEGIN
  v(10) := 'Ten';
  v(30) := 'Thirty';
  v(70) := 'Seventy';

  DBMS_OUTPUT.PUT_LINE('Associative array backward walk using LAST/PRIOR:');
  k := v.LAST;  -- highest key, 70
  WHILE k IS NOT NULL LOOP
    DBMS_OUTPUT.PUT_LINE('  key='||k||' value='||v(k));
    k := v.PRIOR(k); -- previous key in descending order
  END LOOP;
END;
/
--------------------------------------------------------------------------------


/******************************************************************************
 Example 5: Using FIRST..LAST with EXISTS for sparse nested tables
 Scenario:
   Safely traverse a nested table that has holes from DELETE operations.
******************************************************************************/
DECLARE
  TYPE t_nt IS TABLE OF NUMBER;
  v t_nt := t_nt(10,20,30,40,50,60);
BEGIN
  v.DELETE(2);  -- delete 20
  v.DELETE(5);  -- delete 50

  DBMS_OUTPUT.PUT_LINE('Safe traversal of sparse nested table:');
  FOR i IN v.FIRST..v.LAST LOOP
    IF v.EXISTS(i) THEN
      DBMS_OUTPUT.PUT_LINE('  index='||i||' value='||v(i));
    ELSE
      DBMS_OUTPUT.PUT_LINE('  index='||i||' is missing');
    END IF;
  END LOOP;
END;
/
--------------------------------------------------------------------------------


/******************************************************************************
 Example 6: Finding the next free index for insertion in an associative array
 Scenario:
   Choose a new key greater than the current LAST, or handle empty case.
******************************************************************************/
DECLARE
  TYPE t_map IS TABLE OF VARCHAR2(30) INDEX BY PLS_INTEGER;
  v t_map;
  next_key PLS_INTEGER;
BEGIN
  v(5)  := 'Item-5';
  v(20) := 'Item-20';
  v(25) := 'Item-25';

  IF v.COUNT = 0 OR v.LAST IS NULL THEN
    next_key := 1;
  ELSE
    next_key := v.LAST + 1;
  END IF;

  v(next_key) := 'New-Item';
  DBMS_OUTPUT.PUT_LINE('Next free index used = '||next_key);
END;
/
--------------------------------------------------------------------------------


/******************************************************************************
 Example 7: Defensive pattern: stop when FIRST/LAST are NULL
 Scenario:
   Show that FIRST and LAST return NULL for empty collections and demonstrate
   a defensive pattern that avoids invalid range loops.
******************************************************************************/
DECLARE
  TYPE t_nt IS TABLE OF VARCHAR2(20);
  v t_nt := t_nt();  -- start empty
  lo PLS_INTEGER;
  hi PLS_INTEGER;
BEGIN
  lo := v.FIRST;
  hi := v.LAST;

  IF lo IS NULL OR hi IS NULL THEN
    DBMS_OUTPUT.PUT_LINE('Collection is empty, nothing to iterate.');
  ELSE
    FOR i IN lo..hi LOOP
      IF v.EXISTS(i) THEN
        DBMS_OUTPUT.PUT_LINE('index='||i||' value='||v(i));
      END IF;
    END LOOP;
  END IF;
END;
/
--------------------------------------------------------------------------------
-- End of Lesson
--------------------------------------------------------------------------------
