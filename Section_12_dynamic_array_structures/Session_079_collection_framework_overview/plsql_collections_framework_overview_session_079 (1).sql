SET SERVEROUTPUT ON SIZE UNLIMITED;
--------------------------------------------------------------------------------
-- Session 079 – Collection Framework Overview
-- This lesson covers all three major PL/SQL collection types:
--   1. Associative Arrays     (In-memory, key-value, fastest access)
--   2. VARRAYs                (Fixed upper bound, stored as a single object)
--   3. Nested Tables          (Unbounded, can be stored in SQL)
--
-- This script contains 7 examples, each with detailed explanation of:
--   • When to use each type
--   • How to insert, update, delete elements
--   • How collection methods work
--   • How SQL interaction differs between collection types
--------------------------------------------------------------------------------


/******************************************************************************
 EXAMPLE 1
 Associative Array (integer-indexed)
 Demonstrates:
   • Creation
   • Assignment
   • Iteration using FIRST/NEXT
******************************************************************************/
DECLARE
  TYPE t_emp_map IS TABLE OF VARCHAR2(50) INDEX BY PLS_INTEGER;
  v_emp t_emp_map;
  idx  PLS_INTEGER;
BEGIN
  v_emp(1) := 'Avi';
  v_emp(2) := 'Neha';
  v_emp(5) := 'Shyam';

  idx := v_emp.FIRST;
  WHILE idx IS NOT NULL LOOP
    DBMS_OUTPUT.PUT_LINE('Index='||idx||' Name='||v_emp(idx));
    idx := v_emp.NEXT(idx);
  END LOOP;
END;
/
--------------------------------------------------------------------------------


/******************************************************************************
 EXAMPLE 2
 Associative Array (string-indexed)
 Demonstrates:
   • VARCHAR2 indexing
   • Dictionary-like structure
******************************************************************************/
DECLARE
  TYPE t_price_map IS TABLE OF NUMBER INDEX BY VARCHAR2(30);
  v_price t_price_map;
BEGIN
  v_price('Mouse')    := 500;
  v_price('Keyboard') := 1500;

  DBMS_OUTPUT.PUT_LINE('Mouse Price='||v_price('Mouse'));
  DBMS_OUTPUT.PUT_LINE('Keyboard Price='||v_price('Keyboard'));
END;
/
--------------------------------------------------------------------------------


/******************************************************************************
 EXAMPLE 3
 VARRAY — Basic Usage
 Demonstrates:
   • Fixed-size collection
   • Ordered list behavior
   • Index-by-position access
******************************************************************************/
DECLARE
  TYPE t_va IS VARRAY(5) OF VARCHAR2(30);
  v_items t_va := t_va('SSD','Laptop','Mouse');
BEGIN
  FOR i IN 1..v_items.COUNT LOOP
    DBMS_OUTPUT.PUT_LINE('Pos='||i||' Item='||v_items(i));
  END LOOP;
END;
/
--------------------------------------------------------------------------------


/******************************************************************************
 EXAMPLE 4
 VARRAY — Out-of-range attempt
 Demonstrates:
   • Upper bound restriction
   • Exception handling
******************************************************************************/
DECLARE
  TYPE t_va IS VARRAY(3) OF NUMBER;
  v_nums t_va := t_va(10,20,30);
BEGIN
  BEGIN
    v_nums.EXTEND;  -- Not allowed for VARRAY → Raises exception
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EXTEND not allowed on VARRAY. Error='||SQLERRM);
  END;
END;
/
--------------------------------------------------------------------------------


/******************************************************************************
 EXAMPLE 5
 Nested Table — Basic Usage with DELETE, EXTEND, EXISTS
******************************************************************************/
DECLARE
  TYPE t_nt IS TABLE OF VARCHAR2(50);
  v_countries t_nt := t_nt('India','USA','Japan','UK');
BEGIN
  v_countries.DELETE(2);  -- Remove USA

  v_countries.EXTEND;     -- Add new slot
  v_countries(5) := 'Germany';

  FOR i IN 1..v_countries.LAST LOOP
    IF v_countries.EXISTS(i) THEN
      DBMS_OUTPUT.PUT_LINE('Index='||i||' Value='||v_countries(i));
    END IF;
  END LOOP;
END;
/
--------------------------------------------------------------------------------


/******************************************************************************
 EXAMPLE 6
 Nested Table in SQL Context
 Demonstrates:
   • Using collection types at SQL level
   • Using TABLE() operator
******************************************************************************/

-- Step 1: Create SQL type (run once)
CREATE OR REPLACE TYPE nt_regions AS TABLE OF VARCHAR2(40);
/

-- Step 2: Use in PL/SQL + SQL
DECLARE
  v_r nt_regions := nt_regions('Asia','Europe','Africa');
BEGIN
  DBMS_OUTPUT.PUT_LINE('Regions via SQL:');

  FOR r IN (SELECT COLUMN_VALUE region FROM TABLE(v_r))
  LOOP
    DBMS_OUTPUT.PUT_LINE(r.region);
  END LOOP;
END;
/
--------------------------------------------------------------------------------


/******************************************************************************
 EXAMPLE 7
 Bulk COLLECT Into Collection
 Demonstrates:
   • High-performance multi-row fetch
   • Using bulk operations with collections
******************************************************************************/
DECLARE
  TYPE t_ids IS TABLE OF NUMBER;
  v_ids t_ids;
BEGIN
  SELECT LEVEL
  BULK COLLECT INTO v_ids
  FROM dual
  CONNECT BY LEVEL <= 10;

  FOR i IN 1..v_ids.COUNT LOOP
    DBMS_OUTPUT.PUT_LINE('ID='||v_ids(i));
  END LOOP;
END;
/
--------------------------------------------------------------------------------

-- End of Lesson
