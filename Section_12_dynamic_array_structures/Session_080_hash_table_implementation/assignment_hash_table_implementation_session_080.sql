SET SERVEROUTPUT ON;
--------------------------------------------------------------------------------
-- Assignment – Session 080 Hash Table Implementation
-- 10 questions with complete commented solutions.
--------------------------------------------------------------------------------

-- Q1: Create an integer-key associative array of 5 items and print them.
-- Answer:
-- DECLARE
--   TYPE t_h IS TABLE OF VARCHAR2(30) INDEX BY PLS_INTEGER;
--   v t_h; i PLS_INTEGER;
-- BEGIN
--   v(1):='A'; v(2):='B'; v(3):='C'; v(4):='D'; v(5):='E';
--   i := v.FIRST;
--   WHILE i IS NOT NULL LOOP
--     DBMS_OUTPUT.PUT_LINE(i||'='||v(i));
--     i := v.NEXT(i);
--   END LOOP;
-- END;
-- /

-- Q2: Insert 3 products into a string-key hash and retrieve price.

-- Q3: Demonstrate DELETE(key) on a hash table.

-- Q4: Iterate over a sparse associative array using EXISTS.

-- Q5: Build put/get/del API.

-- Q6: Show what happens when reading a non-existent key.

-- Q7: Create a hash table mapping country->currency.

-- Q8: Implementation of case-insensitive key lookups.

-- Q9: Combine FIRST/NEXT to show ordered report.

-- Q10: Explain when associative arrays outperform nested tables.

--------------------------------------------------------------------------------
-- End Assignment
--------------------------------------------------------------------------------
