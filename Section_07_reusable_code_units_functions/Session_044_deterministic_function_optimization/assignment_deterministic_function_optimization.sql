-- Script: assignment_deterministic_function_optimization.sql
-- Session: 044 - Deterministic Function Optimization
-- Format:
--   • 10 detailed questions with complete solutions provided as COMMENTED blocks.
--   • To run a solution: copy the commented block and remove leading '--'.
-- Guidance:
--   • Only mark functions DETERMINISTIC when they are truly pure.
--   • Prefer RESULT_CACHE for expensive, read-mostly lookups. Add RELIES_ON when applicable.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Q1 (Pure normalizer): Create df_trim_upper(varchar2) RETURN varchar2 DETERMINISTIC.
-- Answer (commented):
-- CREATE OR REPLACE FUNCTION df_trim_upper(p IN VARCHAR2) RETURN VARCHAR2 DETERMINISTIC IS
-- BEGIN RETURN UPPER(TRIM(p)); END; /
-- BEGIN DBMS_OUTPUT.PUT_LINE(df_trim_upper('  in  ')); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q2 (Non-deterministic warning): Show a function that uses SYSTIMESTAMP; explain why not deterministic.
-- Answer (commented):
-- CREATE OR REPLACE FUNCTION q2_clock RETURN VARCHAR2 IS BEGIN RETURN TO_CHAR(SYSTIMESTAMP,'FF3'); END; /
-- -- Do NOT mark deterministic; output changes each call.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q3 (Lookup deterministic): country name by ISO using df_iso_country; return 'UNKNOWN' on miss.
-- Answer (commented):
-- CREATE OR REPLACE FUNCTION q3_country(p_iso IN VARCHAR2) RETURN VARCHAR2 DETERMINISTIC IS v df_iso_country.name%TYPE; BEGIN SELECT name INTO v FROM df_iso_country WHERE iso_code = UPPER(p_iso); RETURN v; EXCEPTION WHEN NO_DATA_FOUND THEN RETURN 'UNKNOWN'; END; /
-- BEGIN DBMS_OUTPUT.PUT_LINE(q3_country('us')); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q4 (RESULT_CACHE): Cache q3_country; add RELIES_ON(df_iso_country).
-- Answer (commented):
-- CREATE OR REPLACE FUNCTION q4_country_cached(p_iso IN VARCHAR2) RETURN VARCHAR2 RESULT_CACHE RELIES_ON(df_iso_country) IS v df_iso_country.name%TYPE; BEGIN SELECT name INTO v FROM df_iso_country WHERE iso_code = UPPER(p_iso); RETURN v; EXCEPTION WHEN NO_DATA_FOUND THEN RETURN 'UNKNOWN'; END; /
-- BEGIN DBMS_OUTPUT.PUT_LINE(q4_country_cached('us')); DBMS_OUTPUT.PUT_LINE(q4_country_cached('us')); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q5 (Hashing): Build q5_hash32(varchar2) deterministic (non-crypto) and test in SELECT.
-- Answer (commented):
-- CREATE OR REPLACE FUNCTION q5_hash32(p IN VARCHAR2) RETURN VARCHAR2 DETERMINISTIC IS v NUMBER:=0; c NUMBER; BEGIN IF p IS NULL THEN RETURN '00000000'; END IF; FOR i IN 1..LENGTH(p) LOOP c:=ASCII(SUBSTR(p,i,1)); v:=MOD(v*31 + c, POWER(2,31)-1); END LOOP; RETURN TO_CHAR(v,'FM00000000'); END; /
-- SELECT q5_hash32('Avi') FROM dual; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q6 (Anti-example): Document-only function that reads a sequence value; explain not deterministic.
-- Answer (commented):
-- -- CREATE OR REPLACE FUNCTION q6_seq RETURN NUMBER DETERMINISTIC IS v NUMBER; BEGIN SELECT myseq.NEXTVAL INTO v FROM dual; RETURN v; END; /
-- -- Wrong: NEXTVAL changes each call -> non-deterministic.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q7 (Refactor for determinism): Replace package-state dependency with explicit parameter.
-- Answer (commented):
-- -- Original (anti-pattern): function reads pkg_state.current_rate
-- -- Refactor: pass rate as argument -> pure & deterministic.
-- -- CREATE OR REPLACE FUNCTION q7_apply_rate(p_amount IN NUMBER, p_rate IN NUMBER) RETURN NUMBER DETERMINISTIC IS BEGIN RETURN ROUND(NVL(p_amount,0)*NVL(p_rate,0),2); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q8 (Cache warm-up): Loop over country list calling q4_country_cached to prefill cache.
-- Answer (commented):
-- DECLARE
--   TYPE t IS TABLE OF VARCHAR2(2);
--   v t := t('IN','US','GB','US','IN');
-- BEGIN
--   FOR i IN 1..v.COUNT LOOP
--     DBMS_OUTPUT.PUT_LINE('warm='||q4_country_cached(v(i)));
--   END LOOP;
-- END;
-- /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q9 (Invalidate): Show that updating df_iso_country can change outputs; comment about cache invalidation.
-- Answer (commented):
-- UPDATE df_iso_country SET name='USA' WHERE iso_code='US'; COMMIT; /
-- -- Cached functions with RELIES_ON(df_iso_country) will be invalidated accordingly.
-- -- SELECT q4_country_cached('US') FROM dual; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q10 (Performance note): Outline how to measure benefit using SQL Trace or statistics.
-- Answer (commented):
-- -- Use: ALTER SESSION SET statistics_level=ALL; run cached vs non-cached; query V$RESULT_CACHE_OBJECTS.
-- -- Compare logical reads, elapsed time before/after caching.
--------------------------------------------------------------------------------
-- End of Assignment
--------------------------------------------------------------------------------
