
SET SERVEROUTPUT ON SIZE UNLIMITED;
--------------------------------------------------------------------------------
-- Session 081 – Variable-Length Nested Tables
-- Complete lesson with 7 examples and detailed commentary.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 1: Basic nested table creation
--------------------------------------------------------------------------------
DECLARE
  TYPE t_nt IS TABLE OF VARCHAR2(30);
  v t_nt := t_nt('A','B','C');
BEGIN
  DBMS_OUTPUT.PUT_LINE('COUNT='||v.COUNT);
  DBMS_OUTPUT.PUT_LINE('LAST='||v.LAST);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 2: EXTEND and DELETE
--------------------------------------------------------------------------------
DECLARE
  TYPE t_nt IS TABLE OF VARCHAR2(30);
  v t_nt := t_nt('One','Two','Three');
BEGIN
  v.EXTEND(2);   -- adds slots 4, 5
  v(4) := 'Four';
  v.DELETE(2);   -- remove index 2
  DBMS_OUTPUT.PUT_LINE('COUNT='||v.COUNT);
  DBMS_OUTPUT.PUT_LINE('LAST='||v.LAST);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 3: EXISTS for sparse collections
--------------------------------------------------------------------------------
DECLARE
  TYPE t_nt IS TABLE OF VARCHAR2(30);
  v t_nt := t_nt('A','B','C','D');
BEGIN
  v.DELETE(3);
  FOR i IN 1..v.LAST LOOP
    IF v.EXISTS(i) THEN
      DBMS_OUTPUT.PUT_LINE('i='||i||' val='||v(i));
    END IF;
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 4: SQL nested type + TABLE() operator
--------------------------------------------------------------------------------
CREATE OR REPLACE TYPE nt_color AS TABLE OF VARCHAR2(20);
/

DECLARE
  v nt_color := nt_color('Red','Blue','Green');
BEGIN
  FOR r IN (SELECT COLUMN_VALUE col FROM TABLE(v))
  LOOP
    DBMS_OUTPUT.PUT_LINE('Color='||r.col);
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 5: BULK COLLECT
--------------------------------------------------------------------------------
DECLARE
  TYPE t_nums IS TABLE OF NUMBER;
  v t_nums;
BEGIN
  SELECT LEVEL BULK COLLECT INTO v FROM dual CONNECT BY LEVEL<=10;

  FOR i IN 1..v.COUNT LOOP
    DBMS_OUTPUT.PUT_LINE('num='||v(i));
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 6: TRIM examples
--------------------------------------------------------------------------------
DECLARE
  TYPE t_nt IS TABLE OF VARCHAR2(20);
  v t_nt := t_nt('X','Y','Z','W');
BEGIN
  v.TRIM;     -- remove W
  v.TRIM(2);  -- remove Z,Y
  DBMS_OUTPUT.PUT_LINE('COUNT='||v.COUNT);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 7: MULTISET UNION
--------------------------------------------------------------------------------
DECLARE
  TYPE t_nt IS TABLE OF VARCHAR2(10);
  a t_nt := t_nt('A','B','C');
  b t_nt := t_nt('C','D');
  u t_nt;
BEGIN
  u := a MULTISET UNION b;
  FOR i IN 1..u.COUNT LOOP
    DBMS_OUTPUT.PUT_LINE('u='||u(i));
  END LOOP;
END;
/
--------------------------------------------------------------------------------

-- End Lesson
