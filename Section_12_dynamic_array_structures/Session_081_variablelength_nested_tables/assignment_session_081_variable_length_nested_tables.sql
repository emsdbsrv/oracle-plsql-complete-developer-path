
SET SERVEROUTPUT ON SIZE UNLIMITED;
--------------------------------------------------------------------------------
-- Assignment – Session 081 Variable-Length Nested Tables
-- 10 questions with detailed commented solutions.
--------------------------------------------------------------------------------

-- Q1: Create nested table of 5 names, delete 2 and 4, print remaining.
-- Solution:
-- DECLARE
--   TYPE t_nt IS TABLE OF VARCHAR2(20);
--   v t_nt := t_nt('A','B','C','D','E');
-- BEGIN
--   v.DELETE(2);
--   v.DELETE(4);
--   FOR i IN 1..v.LAST LOOP
--     IF v.EXISTS(i) THEN DBMS_OUTPUT.PUT_LINE(v(i)); END IF;
--   END LOOP;
-- END;
-- /

-- Q2: Demonstrate EXTEND(3) then TRIM(2).
-- Solution:
-- DECLARE
--   TYPE t_nt IS TABLE OF NUMBER;
--   v t_nt := t_nt(10,20);
-- BEGIN
--   v.EXTEND(3);
--   v(3):=30; v(4):=40; v(5):=50;
--   v.TRIM(2);
--   FOR i IN 1..v.LAST LOOP IF v.EXISTS(i) THEN DBMS_OUTPUT.PUT_LINE(v(i)); END IF; END LOOP;
-- END;
-- /

-- Q3: Use TABLE() operator to print SQL nested type.

-- Q4: BULK COLLECT 1..15 → print multiples of 3.

-- Q5: Demonstrate DELETE(n) vs DELETE(n,m).

-- Q6: Delete random indexes to create sparsity and prove EXISTS.

-- Q7: MULTISET UNION of two nested tables.

-- Q8: MULTISET INTERSECT of two nested tables.

-- Q9: Delete salaries < 30000 from nested table.

-- Q10: Create SQL nested table type and query via TABLE() with filtering.

--------------------------------------------------------------------------------
-- End Assignment
--------------------------------------------------------------------------------
