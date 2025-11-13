SET SERVEROUTPUT ON;
--------------------------------------------------------------------------------
-- Session 082 – Bounded Array Collections (Advanced VARRAY Usage)
-- 7 detailed examples exploring VARRAY constraints, operations, and SQL storage.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 1: Create and access VARRAY elements
--------------------------------------------------------------------------------
DECLARE
  TYPE t_va IS VARRAY(5) OF VARCHAR2(20);
  v t_va := t_va('A','B','C');
BEGIN
  FOR i IN 1..v.COUNT LOOP
    DBMS_OUTPUT.PUT_LINE('pos='||i||' val='||v(i));
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 2: Demonstrate upper bound restriction
--------------------------------------------------------------------------------
DECLARE
  TYPE t_va IS VARRAY(3) OF NUMBER;
  v t_va := t_va(1,2,3);
BEGIN
  BEGIN
    v.EXTEND; -- not allowed
  EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Cannot EXTEND VARRAY: '||SQLERRM);
  END;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 3: Using TRIM to shrink VARRAY
--------------------------------------------------------------------------------
DECLARE
  TYPE t_va IS VARRAY(4) OF VARCHAR2(20);
  v t_va := t_va('One','Two','Three','Four');
BEGIN
  v.TRIM; -- removes 'Four'
  DBMS_OUTPUT.PUT_LINE('Count='||v.COUNT);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 4: VARRAY inside SQL TYPE
--------------------------------------------------------------------------------
CREATE OR REPLACE TYPE va_numbers AS VARRAY(5) OF NUMBER;
/
DECLARE
  v va_numbers := va_numbers(10,20,30);
BEGIN
  FOR r IN (SELECT COLUMN_VALUE val FROM TABLE(v))
  LOOP
    DBMS_OUTPUT.PUT_LINE(r.val);
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 5: Storing VARRAY inside a table
--------------------------------------------------------------------------------
CREATE TABLE product_features (
  product_id NUMBER,
  features va_numbers
);
/

INSERT INTO product_features VALUES (101, va_numbers(1,2,3));
/

SELECT product_id, COLUMN_VALUE feature
FROM product_features p
     CROSS JOIN TABLE(p.features);
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 6: Replacing values inside a VARRAY
--------------------------------------------------------------------------------
DECLARE
  TYPE t_va IS VARRAY(4) OF VARCHAR2(20);
  v t_va := t_va('Red','Blue','Green');
BEGIN
  v(2) := 'Yellow';
  DBMS_OUTPUT.PUT_LINE('Updated='||v(2));
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 7: Compare VARRAY vs Nested Table
--------------------------------------------------------------------------------
DECLARE
  TYPE t_va IS VARRAY(3) OF NUMBER;
  TYPE t_nt IS TABLE OF NUMBER;

  v t_va := t_va(1,2,3);
  n t_nt := t_nt(1,2,3);
BEGIN
  DBMS_OUTPUT.PUT_LINE('VARRAY COUNT='||v.COUNT);
  DBMS_OUTPUT.PUT_LINE('NT COUNT='||n.COUNT);

  DBMS_OUTPUT.PUT_LINE('VARRAY supports order and size limit.');
  DBMS_OUTPUT.PUT_LINE('Nested table supports DELETE and sparse behavior.');
END;
/
--------------------------------------------------------------------------------

-- End Lesson
