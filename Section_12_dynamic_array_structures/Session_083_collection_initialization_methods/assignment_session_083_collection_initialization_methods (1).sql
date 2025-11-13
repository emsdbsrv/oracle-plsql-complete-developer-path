
SET SERVEROUTPUT ON SIZE UNLIMITED;

--------------------------------------------------------------------------------
-- Assignment – Session 083 Collection Initialization Methods
-- 10 questions with complete commented solutions.
--------------------------------------------------------------------------------

-- Q1: Initialize a nested table using a constructor with 5 names.
-- Solution:
-- DECLARE
--   TYPE t_nt IS TABLE OF VARCHAR2(20);
--   v t_nt := t_nt('A','B','C','D','E');
-- BEGIN
--   FOR i IN 1..v.COUNT LOOP DBMS_OUTPUT.PUT_LINE(v(i)); END LOOP;
-- END;
-- /

-- Q2: Create VARRAY type and initialize with constructor.

-- Q3: Use EXTEND(3, 99) to initialize three new elements with 99.

-- Q4: Use BULK COLLECT to fetch numbers 1..12.

-- Q5: Demonstrate DELETE removing all elements.

-- Q6: Copy nested table A into B and print B.

-- Q7: Show reassignment resets old data.

-- Q8: Combine constructor initialization + EXTEND in same block.

-- Q9: Create SQL nested type, initialize and query via TABLE().

-- Q10: Initialize collection inside a procedure argument.

--------------------------------------------------------------------------------
-- End Assignment
--------------------------------------------------------------------------------
