
SET SERVEROUTPUT ON SIZE UNLIMITED;

--------------------------------------------------------------------------------
-- Session 083 – Collection Initialization Methods
-- Complete lesson with 7 fully detailed examples.
--------------------------------------------------------------------------------


/******************************************************************************
 EXAMPLE 1
 Constructor Initialization for Nested Table
******************************************************************************/
DECLARE
  TYPE t_nt IS TABLE OF VARCHAR2(30);
  v t_nt := t_nt('Red','Blue','Green');
BEGIN
  DBMS_OUTPUT.PUT_LINE('COUNT='||v.COUNT);
END;
/
--------------------------------------------------------------------------------


/******************************************************************************
 EXAMPLE 2
 Constructor Initialization for VARRAY
******************************************************************************/
CREATE OR REPLACE TYPE va_colors AS VARRAY(5) OF VARCHAR2(20);
/
DECLARE
  v va_colors := va_colors('Rose','Lily','Tulip');
BEGIN
  FOR i IN 1..v.COUNT LOOP
    DBMS_OUTPUT.PUT_LINE('Color='||v(i));
  END LOOP;
END;
/
--------------------------------------------------------------------------------


/******************************************************************************
 EXAMPLE 3
 EXTEND with value assignment
******************************************************************************/
DECLARE
  TYPE t_nt IS TABLE OF NUMBER;
  v t_nt := t_nt(1,2,3);
BEGIN
  v.EXTEND;
  v(v.LAST) := 100;

  v.EXTEND(2, 50); -- adds two new elements with default value 50

  FOR i IN 1..v.COUNT LOOP
    DBMS_OUTPUT.PUT_LINE('v('||i||')='||v(i));
  END LOOP;
END;
/
--------------------------------------------------------------------------------


/******************************************************************************
 EXAMPLE 4
 Initialization using BULK COLLECT
******************************************************************************/
DECLARE
  TYPE t_ids IS TABLE OF NUMBER;
  v t_ids;
BEGIN
  SELECT LEVEL BULK COLLECT INTO v FROM dual CONNECT BY LEVEL <= 7;

  FOR i IN 1..v.COUNT LOOP
    DBMS_OUTPUT.PUT_LINE('Val='||v(i));
  END LOOP;
END;
/
--------------------------------------------------------------------------------


/******************************************************************************
 EXAMPLE 5
 Copying collections (shallow copy)
******************************************************************************/
DECLARE
  TYPE t_nt IS TABLE OF VARCHAR2(20);
  a t_nt := t_nt('A','B','C');
  b t_nt;
BEGIN
  b := a; -- shallow copy

  DBMS_OUTPUT.PUT_LINE('Copy b(2)='||b(2));
END;
/
--------------------------------------------------------------------------------


/******************************************************************************
 EXAMPLE 6
 Resetting a collection using DELETE
******************************************************************************/
DECLARE
  TYPE t_nt IS TABLE OF VARCHAR2(10);
  v t_nt := t_nt('X','Y','Z');
BEGIN
  v.DELETE;
  DBMS_OUTPUT.PUT_LINE('COUNT after reset='||v.COUNT);
END;
/
--------------------------------------------------------------------------------


/******************************************************************************
 EXAMPLE 7
 Reinitializing collection by reassignment
******************************************************************************/
DECLARE
  TYPE t_nt IS TABLE OF VARCHAR2(10);
  v t_nt := t_nt('One','Two');
BEGIN
  v := t_nt('New1','New2','New3');

  FOR i IN 1..v.COUNT LOOP
    DBMS_OUTPUT.PUT_LINE('Item='||v(i));
  END LOOP;
END;
/
--------------------------------------------------------------------------------

-- End Lesson
