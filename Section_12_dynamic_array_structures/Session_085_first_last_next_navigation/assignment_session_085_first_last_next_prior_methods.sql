SET SERVEROUTPUT ON SIZE UNLIMITED;

--------------------------------------------------------------------------------
-- Assignment – Session 085: FIRST, LAST, NEXT, PRIOR Navigation Methods
-- Format:
--   • 10 questions, each with a complete solution provided in commented form.
--   • To try a solution, copy the block, remove leading '--', and execute.
-- Guidance:
--   • Always check for NULL FIRST/LAST before using them in ranges.
--   • Use EXISTS for sparse nested tables when iterating 1..LAST.
--   • Prefer FIRST/NEXT and LAST/PRIOR for associative arrays.
--------------------------------------------------------------------------------


/**********************************
 Q1 – FIRST/LAST on dense nested table
 Task:
   Create a nested table with values 100,200,300 and print FIRST, LAST, COUNT.
**********************************/
-- Solution:
-- DECLARE
--   TYPE t_nt IS TABLE OF NUMBER;
--   v t_nt := t_nt(100,200,300);
-- BEGIN
--   DBMS_OUTPUT.PUT_LINE('COUNT='||v.COUNT);
--   DBMS_OUTPUT.PUT_LINE('FIRST='||v.FIRST);
--   DBMS_OUTPUT.PUT_LINE('LAST='||v.LAST);
-- END;
-- /
--------------------------------------------------------------------------------


/**********************************
 Q2 – Sparse nested table and safe traversal
 Task:
   Create nested table of 5 strings, delete index 3, then:
--   • Print FIRST and LAST
--   • Iterate 1..LAST and print only existing elements using EXISTS.
**********************************/
-- Solution:
-- DECLARE
--   TYPE t_nt IS TABLE OF VARCHAR2(20);
--   v t_nt := t_nt('A','B','C','D','E');
-- BEGIN
--   v.DELETE(3);
--   DBMS_OUTPUT.PUT_LINE('FIRST='||v.FIRST);
--   DBMS_OUTPUT.PUT_LINE('LAST='||v.LAST);
--   FOR i IN 1..v.LAST LOOP
--     IF v.EXISTS(i) THEN
--       DBMS_OUTPUT.PUT_LINE('i='||i||' val='||v(i));
--     END IF;
--   END LOOP;
-- END;
-- /
--------------------------------------------------------------------------------


/**********************************
 Q3 – Associative array forward navigation with FIRST/NEXT
 Task:
   Create associative array mapping 10->'X', 40->'Y', 90->'Z'.
   Use FIRST/NEXT to print keys and values in ascending key order.
**********************************/
-- Solution:
-- DECLARE
--   TYPE t_map IS TABLE OF VARCHAR2(10) INDEX BY PLS_INTEGER;
--   v t_map;
--   k PLS_INTEGER;
-- BEGIN
--   v(10) := 'X';
--   v(40) := 'Y';
--   v(90) := 'Z';
--   k := v.FIRST;
--   WHILE k IS NOT NULL LOOP
--     DBMS_OUTPUT.PUT_LINE('key='||k||' val='||v(k));
--     k := v.NEXT(k);
--   END LOOP;
-- END;
-- /
--------------------------------------------------------------------------------


/**********************************
 Q4 – Associative array backward navigation with LAST/PRIOR
 Task:
   Reuse values from Q3 but traverse in reverse order using LAST/PRIOR.
**********************************/
-- Solution:
-- DECLARE
--   TYPE t_map IS TABLE OF VARCHAR2(10) INDEX BY PLS_INTEGER;
--   v t_map;
--   k PLS_INTEGER;
-- BEGIN
--   v(10) := 'X';
--   v(40) := 'Y';
--   v(90) := 'Z';
--   k := v.LAST;
--   WHILE k IS NOT NULL LOOP
--     DBMS_OUTPUT.PUT_LINE('key='||k||' val='||v(k));
--     k := v.PRIOR(k);
--   END LOOP;
-- END;
-- /
--------------------------------------------------------------------------------


/**********************************
 Q5 – Defensive handling of empty nested table
 Task:
   Declare an empty nested table and show how to avoid using v.FIRST..v.LAST
   when both are NULL (print a message instead).
**********************************/
-- Solution:
-- DECLARE
--   TYPE t_nt IS TABLE OF NUMBER;
--   v t_nt := t_nt();  -- empty
--   lo PLS_INTEGER;
--   hi PLS_INTEGER;
-- BEGIN
--   lo := v.FIRST;
--   hi := v.LAST;
--   IF lo IS NULL OR hi IS NULL THEN
--     DBMS_OUTPUT.PUT_LINE('Collection is empty.');
--   ELSE
--     FOR i IN lo..hi LOOP
--       IF v.EXISTS(i) THEN DBMS_OUTPUT.PUT_LINE(v(i)); END IF;
--     END LOOP;
--   END IF;
-- END;
-- /
--------------------------------------------------------------------------------


/**********************************
 Q6 – Combining DELETE with FIRST/LAST on nested table
 Task:
   Use nested table (10,20,30,40,50), delete indexes 1 and 5, then:
--   • Print FIRST, LAST, COUNT
--   • Traverse 1..LAST and label missing slots as "hole".
**********************************/
-- Solution:
-- DECLARE
--   TYPE t_nt IS TABLE OF NUMBER;
--   v t_nt := t_nt(10,20,30,40,50);
-- BEGIN
--   v.DELETE(1);
--   v.DELETE(5);
--   DBMS_OUTPUT.PUT_LINE('COUNT='||v.COUNT);
--   DBMS_OUTPUT.PUT_LINE('FIRST='||v.FIRST);
--   DBMS_OUTPUT.PUT_LINE('LAST='||v.LAST);
--   FOR i IN 1..v.LAST LOOP
--     IF v.EXISTS(i) THEN
--       DBMS_OUTPUT.PUT_LINE('i='||i||' val='||v(i));
--     ELSE
--       DBMS_OUTPUT.PUT_LINE('i='||i||' (hole)');
--     END IF;
--   END LOOP;
-- END;
-- /
--------------------------------------------------------------------------------


/**********************************
 Q7 – Find next free index in associative array
 Task:
   In an associative array with keys 2,4,10, compute next_key = LAST+1
   (or 1 if empty) and insert a new value at next_key.
**********************************/
-- Solution:
-- DECLARE
--   TYPE t_map IS TABLE OF VARCHAR2(10) INDEX BY PLS_INTEGER;
--   v t_map;
--   next_key PLS_INTEGER;
-- BEGIN
--   v(2) := 'A';
--   v(4) := 'B';
--   v(10) := 'C';
--   IF v.COUNT = 0 OR v.LAST IS NULL THEN
--     next_key := 1;
--   ELSE
--     next_key := v.LAST + 1;
--   END IF;
--   v(next_key) := 'NEW';
--   DBMS_OUTPUT.PUT_LINE('Inserted at key='||next_key||' val='||v(next_key));
-- END;
-- /
--------------------------------------------------------------------------------


/**********************************
 Q8 – Count live elements using FIRST..LAST + EXISTS
 Task:
   Create nested table with 6 integers, delete 2 of them, then compute
   how many live elements remain using EXISTS and print the count.
**********************************/
-- Solution:
-- DECLARE
--   TYPE t_nt IS TABLE OF NUMBER;
--   v t_nt := t_nt(1,2,3,4,5,6);
--   live_count PLS_INTEGER := 0;
-- BEGIN
--   v.DELETE(2);
--   v.DELETE(5);
--   FOR i IN v.FIRST..v.LAST LOOP
--     IF v.EXISTS(i) THEN
--       live_count := live_count + 1;
--     END IF;
--   END LOOP;
--   DBMS_OUTPUT.PUT_LINE('Live elements='||live_count);
-- END;
-- /
--------------------------------------------------------------------------------


/**********************************
 Q9 – Use PRIOR to compute reverse-order concatenation
 Task:
   Associative array keys 1,3,5 mapped to 'A','B','C'.
   Using LAST/PRIOR, build a string 'C-B-A' and print it.
**********************************/
-- Solution:
-- DECLARE
--   TYPE t_map IS TABLE OF VARCHAR2(10) INDEX BY PLS_INTEGER;
--   v t_map;
--   k PLS_INTEGER;
--   out_str VARCHAR2(100) := '';
-- BEGIN
--   v(1) := 'A';
--   v(3) := 'B';
--   v(5) := 'C';
--   k := v.LAST;
--   WHILE k IS NOT NULL LOOP
--     IF out_str IS NULL OR out_str = '' THEN
--       out_str := v(k);
--     ELSE
--       out_str := out_str||'-'||v(k);
--     END IF;
--     k := v.PRIOR(k);
--   END LOOP;
--   DBMS_OUTPUT.PUT_LINE('Result='||out_str); -- C-B-A
-- END;
-- /
--------------------------------------------------------------------------------


/**********************************
 Q10 – Combine BULK COLLECT + sparse deletes + FIRST/NEXT traversal
 Task:
   BULK COLLECT numbers 1..12 into nested table, delete all values
   divisible by 4, then:
--   • For nested table: use FIRST..LAST + EXISTS to print remaining values.
--   • Explain qualitatively how you would do similar with associative array.
**********************************/
-- Solution:
-- DECLARE
--   TYPE t_nums IS TABLE OF NUMBER;
--   v t_nums;
-- BEGIN
--   SELECT LEVEL BULK COLLECT INTO v FROM dual CONNECT BY LEVEL <= 12;
--   FOR i IN v.FIRST..v.LAST LOOP
--     IF v.EXISTS(i) AND MOD(v(i),4)=0 THEN
--       v.DELETE(i);
--     END IF;
--   END LOOP;
--   DBMS_OUTPUT.PUT_LINE('Remaining after deleting multiples of 4:');
--   FOR i IN v.FIRST..v.LAST LOOP
--     IF v.EXISTS(i) THEN DBMS_OUTPUT.PUT_LINE(v(i)); END IF;
--   END LOOP;
--   -- For associative array, we would use k := v.FIRST; WHILE k IS NOT NULL LOOP ... k := v.NEXT(k); END LOOP;
-- END;
-- /
--------------------------------------------------------------------------------

-- End of Assignment
--------------------------------------------------------------------------------
