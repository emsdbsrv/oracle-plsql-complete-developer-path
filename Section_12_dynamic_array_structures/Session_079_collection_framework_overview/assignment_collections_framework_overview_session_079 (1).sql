SET SERVEROUTPUT ON SIZE UNLIMITED;
--------------------------------------------------------------------------------
-- Assignment – Session 079 Collection Framework Overview
-- 10 questions with complete commented solutions (remove '--' to execute).
--------------------------------------------------------------------------------


/**********************************
 Q1 – Create an associative array of 5 names and print them using FIRST/NEXT.
**********************************/
-- Answer:
-- DECLARE
--   TYPE t_map IS TABLE OF VARCHAR2(30) INDEX BY PLS_INTEGER;
--   v_map t_map;
--   idx PLS_INTEGER;
-- BEGIN
--   v_map(1):='Avi'; v_map(2):='Neha'; v_map(3):='Raj'; v_map(4):='Kiran'; v_map(5):='Asha';
--   idx := v_map.FIRST;
--   WHILE idx IS NOT NULL LOOP
--     DBMS_OUTPUT.PUT_LINE(v_map(idx));
--     idx := v_map.NEXT(idx);
--   END LOOP;
-- END;
-- /


/**********************************
 Q2 – Create a VARCHAR2-indexed associative array of product prices.
**********************************/
-- Answer:
-- DECLARE
--   TYPE t_price IS TABLE OF NUMBER INDEX BY VARCHAR2(50);
--   v_price t_price;
-- BEGIN
--   v_price('Pen')  := 10;
--   v_price('Book') := 50;
--   DBMS_OUTPUT.PUT_LINE('Pen='||v_price('Pen'));
--   DBMS_OUTPUT.PUT_LINE('Book='||v_price('Book'));
-- END;
-- /


/**********************************
 Q3 – Create a VARRAY(4) of department names and print them.
**********************************/
-- Answer:
-- DECLARE
--   TYPE t_dep IS VARRAY(4) OF VARCHAR2(20);
--   v_dep t_dep := t_dep('HR','IT','FINANCE','SALES');
-- BEGIN
--   FOR i IN 1..v_dep.COUNT LOOP
--     DBMS_OUTPUT.PUT_LINE(v_dep(i));
--   END LOOP;
-- END;
-- /


/**********************************
 Q4 – Demonstrate VARRAY upper bound error using EXTEND.
**********************************/
-- Answer:
-- DECLARE
--   TYPE t_v IS VARRAY(2) OF NUMBER;
--   v t_v := t_v(1,2);
-- BEGIN
--   BEGIN
--     v.EXTEND;  -- Error case
--   EXCEPTION
--     WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Error='||SQLERRM);
--   END;
-- END;
-- /


/**********************************
 Q5 – Create a nested table of 5 cities, delete 2, then print remaining.
**********************************/
-- Answer:
-- DECLARE
--   TYPE t_city IS TABLE OF VARCHAR2(30);
--   v_city t_city := t_city('Delhi','Mumbai','Chennai','Kolkata','Hyderabad');
-- BEGIN
--   v_city.DELETE(3);  -- Remove Chennai
--   v_city.DELETE(5);  -- Remove Hyderabad
--   FOR i IN 1..v_city.LAST LOOP
--     IF v_city.EXISTS(i) THEN
--       DBMS_OUTPUT.PUT_LINE(v_city(i));
--     END IF;
--   END LOOP;
-- END;
-- /


/**********************************
 Q6 – Create a SQL nested table type and print its values using TABLE().
**********************************/
-- Answer:
-- CREATE OR REPLACE TYPE nt_city AS TABLE OF VARCHAR2(40);
-- /
-- DECLARE
--   v nt_city := nt_city('Bangalore','Pune','Nagpur');
-- BEGIN
--   FOR r IN (SELECT COLUMN_VALUE val FROM TABLE(v)) LOOP
--     DBMS_OUTPUT.PUT_LINE(r.val);
--   END LOOP;
-- END;
-- /


/**********************************
 Q7 – Bulk collect numbers 1..20 into a nested table, then print evens only.
**********************************/
-- Answer:
-- DECLARE
--   TYPE t_num IS TABLE OF NUMBER;
--   v t_num;
-- BEGIN
--   SELECT LEVEL BULK COLLECT INTO v FROM dual CONNECT BY LEVEL <= 20;
--   FOR i IN 1..v.COUNT LOOP
--     IF MOD(v(i),2)=0 THEN DBMS_OUTPUT.PUT_LINE(v(i)); END IF;
--   END LOOP;
-- END;
-- /


/**********************************
 Q8 – Demonstrate DELETE(n) vs DELETE in nested tables.
**********************************/
-- Answer:
-- DECLARE
--   TYPE t_nt IS TABLE OF VARCHAR2(20);
--   v t_nt := t_nt('A','B','C','D');
-- BEGIN
--   v.DELETE(2); -- Deletes index 2 only
--   v.DELETE;    -- Deletes all elements
--   DBMS_OUTPUT.PUT_LINE('Count after DELETE='||v.COUNT);
-- END;
-- /


/**********************************
 Q9 – Show EXISTS() usage for sparse nested table iteration.
**********************************/
-- Answer:
-- DECLARE
--   TYPE t_nt IS TABLE OF VARCHAR2(20);
--   v t_nt := t_nt('X','Y','Z');
-- BEGIN
--   v.DELETE(2); -- Create gap
--   FOR i IN 1..v.LAST LOOP
--     IF v.EXISTS(i) THEN DBMS_OUTPUT.PUT_LINE('Index '||i||'='||v(i)); END IF;
--   END LOOP;
-- END;
-- /


/**********************************
 Q10 – Combine BULK COLLECT + DELETE to remove odd numbers.
**********************************/
-- Answer:
-- DECLARE
--   TYPE t_num IS TABLE OF NUMBER;
--   v t_num;
-- BEGIN
--   SELECT LEVEL BULK COLLECT INTO v FROM dual CONNECT BY LEVEL <= 15;
--   FOR i IN 1..v.LAST LOOP
--     IF v.EXISTS(i) AND MOD(v(i),2)=1 THEN
--       v.DELETE(i);
--     END IF;
--   END LOOP;
--
--   DBMS_OUTPUT.PUT_LINE('Remaining (even numbers):');
--   FOR i IN 1..v.LAST LOOP
--     IF v.EXISTS(i) THEN DBMS_OUTPUT.PUT_LINE(v(i)); END IF;
--   END LOOP;
-- END;
-- /
--------------------------------------------------------------------------------
-- End Assignment
--------------------------------------------------------------------------------
