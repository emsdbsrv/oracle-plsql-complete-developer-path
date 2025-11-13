SET SERVEROUTPUT ON SIZE UNLIMITED;
--------------------------------------------------------------------------------
-- Assignment – Session 084 EXISTS, COUNT, DELETE Methods (Deep Dive)
-- 10 questions with detailed commented solutions.
--------------------------------------------------------------------------------

/**********************************
 Q1 – Show difference between COUNT and LAST on dense collection (no DELETE).
**********************************/
-- Solution:
-- DECLARE
--   TYPE t_nt IS TABLE OF VARCHAR2(10);
--   v t_nt := t_nt('A','B','C');
-- BEGIN
--   DBMS_OUTPUT.PUT_LINE('COUNT='||v.COUNT); -- 3
--   DBMS_OUTPUT.PUT_LINE('LAST='||v.LAST);   -- 3
-- END;
-- /


/**********************************
 Q2 – Show difference between COUNT and LAST after DELETE(2) and DELETE(4).
**********************************/
-- Solution:
-- DECLARE
--   TYPE t_nt IS TABLE OF NUMBER;
--   v t_nt := t_nt(1,2,3,4,5);
-- BEGIN
--   v.DELETE(2);
--   v.DELETE(4);
--   DBMS_OUTPUT.PUT_LINE('COUNT='||v.COUNT);
--   DBMS_OUTPUT.PUT_LINE('LAST='||v.LAST);
-- END;
-- /


/**********************************
 Q3 – Use DELETE(m,n) to remove middle range and print remaining with EXISTS.
**********************************/
-- Solution:
-- DECLARE
--   TYPE t_nt IS TABLE OF VARCHAR2(10);
--   v t_nt := t_nt('A','B','C','D','E','F');
-- BEGIN
--   v.DELETE(3,5);
--   FOR i IN 1..v.LAST LOOP
--     IF v.EXISTS(i) THEN DBMS_OUTPUT.PUT_LINE('i='||i||'='||v(i)); END IF;
--   END LOOP;
-- END;
-- /


/**********************************
 Q4 – Demonstrate DELETE (no arguments) and show LAST IS NULL.
**********************************/
-- Solution:
-- DECLARE
--   TYPE t_nt IS TABLE OF VARCHAR2(10);
--   v t_nt := t_nt('X','Y');
-- BEGIN
--   v.DELETE;
--   DBMS_OUTPUT.PUT_LINE('COUNT='||v.COUNT);
--   IF v.LAST IS NULL THEN DBMS_OUTPUT.PUT_LINE('LAST is NULL'); END IF;
-- END;
-- /


/**********************************
 Q5 – Use EXISTS on associative array to detect non-existent key.
**********************************/
-- Solution:
-- DECLARE
--   TYPE t_map IS TABLE OF VARCHAR2(20) INDEX BY PLS_INTEGER;
--   v t_map;
-- BEGIN
--   v(10) := 'Ten';
--   IF v.EXISTS(5) THEN
--     DBMS_OUTPUT.PUT_LINE('5 exists');
--   ELSE
--     DBMS_OUTPUT.PUT_LINE('5 does NOT exist');
--   END IF;
-- END;
-- /


/**********************************
 Q6 – Implement safe iteration template for sparse nested table.
**********************************/
-- Solution:
-- DECLARE
--   TYPE t_nt IS TABLE OF NUMBER;
--   v t_nt := t_nt(10,20,30,40);
-- BEGIN
--   v.DELETE(2);
--   FOR i IN 1..v.LAST LOOP
--     IF v.EXISTS(i) THEN
--       DBMS_OUTPUT.PUT_LINE('Val='||v(i));
--     END IF;
--   END LOOP;
-- END;
-- /


/**********************************
 Q7 – Delete all odd numbers using DELETE(i) inside a FOR loop and print remaining.
**********************************/
-- Solution:
-- DECLARE
--   TYPE t_nums IS TABLE OF NUMBER;
--   v t_nums;
-- BEGIN
--   SELECT LEVEL BULK COLLECT INTO v FROM dual CONNECT BY LEVEL <= 10;
--   FOR i IN 1..v.LAST LOOP
--     IF v.EXISTS(i) AND MOD(v(i),2)=1 THEN v.DELETE(i); END IF;
--   END LOOP;
--   DBMS_OUTPUT.PUT_LINE('Even numbers:');
--   FOR i IN 1..v.LAST LOOP
--     IF v.EXISTS(i) THEN DBMS_OUTPUT.PUT_LINE(v(i)); END IF;
--   END LOOP;
-- END;
-- /


/**********************************
 Q8 – Show that DELETE does not re-index remaining elements.
**********************************/
-- Solution:
-- DECLARE
--   TYPE t_nt IS TABLE OF VARCHAR2(10);
--   v t_nt := t_nt('A','B','C','D');
-- BEGIN
--   v.DELETE(2);
--   IF v.EXISTS(3) THEN
--     DBMS_OUTPUT.PUT_LINE('Index 3 still holds '||v(3));
--   END IF;
--   DBMS_OUTPUT.PUT_LINE('COUNT='||v.COUNT||' LAST='||v.LAST);
-- END;
-- /


/**********************************
 Q9 – Use EXISTS to count how many live elements remain after random DELETE.
**********************************/
-- Solution:
-- DECLARE
--   TYPE t_nt IS TABLE OF NUMBER;
--   v t_nt := t_nt(1,2,3,4,5,6);
--   live_count PLS_INTEGER := 0;
-- BEGIN
--   v.DELETE(2);
--   v.DELETE(5);
--   FOR i IN 1..v.LAST LOOP
--     IF v.EXISTS(i) THEN
--       live_count := live_count + 1;
--     END IF;
--   END LOOP;
--   DBMS_OUTPUT.PUT_LINE('Live elements='||live_count);
-- END;
-- /


/**********************************
 Q10 – Combine BULK COLLECT + DELETE(m,n) + EXISTS in one scenario.
**********************************/
-- Solution:
-- DECLARE
--   TYPE t_nums IS TABLE OF NUMBER;
--   v t_nums;
-- BEGIN
--   SELECT LEVEL BULK COLLECT INTO v FROM dual CONNECT BY LEVEL <= 12;
--   v.DELETE(5,8); -- remove 5,6,7,8
--   DBMS_OUTPUT.PUT_LINE('Remaining after DELETE(5,8):');
--   FOR i IN 1..v.LAST LOOP
--     IF v.EXISTS(i) THEN DBMS_OUTPUT.PUT_LINE('i='||i||' val='||v(i)); END IF;
--   END LOOP;
-- END;
-- /

--------------------------------------------------------------------------------
-- End Assignment
--------------------------------------------------------------------------------
