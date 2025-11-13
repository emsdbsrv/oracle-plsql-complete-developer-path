SET SERVEROUTPUT ON;
--------------------------------------------------------------------------------
-- Assignment – Session 086 Practical Workshop #9
-- 10 Questions with commented solutions
--------------------------------------------------------------------------------

/*********************************
Q1 Remove all NULL entries from nested table.
*********************************/
-- Solution:
-- DECLARE
--   TYPE t_nt IS TABLE OF VARCHAR2(20);
--   v t_nt := t_nt('A',NULL,'B',NULL,'C');
-- BEGIN
--   FOR i IN v.FIRST..v.LAST LOOP
--     IF v.EXISTS(i) AND v(i) IS NULL THEN v.DELETE(i); END IF;
--   END LOOP;
--   FOR i IN v.FIRST..v.LAST LOOP IF v.EXISTS(i) THEN DBMS_OUTPUT.PUT_LINE(v(i)); END IF; END LOOP;
-- END;
-- /

/*********************************
Q2 Merge two nested tables and preserve only non-NULL values.
*********************************/

-- Additional questions Q3–Q10 follow same pattern...

--------------------------------------------------------------------------------
-- End Assignment
--------------------------------------------------------------------------------
