-- Script: plsql_deterministic_function_optimization.sql
-- Session: 044 - Deterministic Function Optimization
-- Purpose:
--   Demonstrate deterministic vs non-deterministic functions, safe usage patterns,
--   and how to leverage DETERMINISTIC and RESULT_CACHE for performance.
-- How to run:
--   SET SERVEROUTPUT ON; Execute each block separately (terminated by '/').
-- Notes:
--   • DETERMINISTIC is a contract: you promise same output for same inputs.
--   • Oracle does not verify purity; misuse can lead to wrong answers.
--   • RESULT_CACHE may cache values across sessions depending on configuration.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Setup: small reference tables (idempotent)
--------------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'DROP TABLE df_iso_country PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE TABLE df_iso_country (
  iso_code  VARCHAR2(2) CONSTRAINT df_iso_country_pk PRIMARY KEY,
  name      VARCHAR2(100) NOT NULL
);

INSERT INTO df_iso_country VALUES ('IN','India');
INSERT INTO df_iso_country VALUES ('US','United States');
INSERT INTO df_iso_country VALUES ('GB','United Kingdom');
COMMIT;
/

--------------------------------------------------------------------------------
-- Example 1: Pure, DETERMINISTIC formatter (safe)
-- Scenario:
--   Normalize ISO-2 codes to upper-case; no external state or IO; safe to mark deterministic.
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION df_norm_iso(p_code IN VARCHAR2)
  RETURN VARCHAR2 DETERMINISTIC
IS
  -- Explanation:
  --   • Uses only its input
  --   • No package state, no SYSDATE/DBMS_RANDOM
  --   • Same input -> same output
  v_out VARCHAR2(2);
BEGIN
  v_out := UPPER(SUBSTR(TRIM(p_code),1,2));
  RETURN v_out;
END df_norm_iso;
/
BEGIN
  DBMS_OUTPUT.PUT_LINE('df_norm_iso(''in'')='||df_norm_iso(''in''));
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 2: Non-deterministic anti-pattern (do NOT mark deterministic)
-- Scenario:
--   Function reads SYSDATE; same input at different times yields different outputs.
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION df_with_time(p_x IN NUMBER)
  RETURN VARCHAR2
IS
BEGIN
  RETURN TO_CHAR(SYSDATE,'YYYYMMDD')||'_'||TO_CHAR(p_x);
END df_with_time;
/
BEGIN
  DBMS_OUTPUT.PUT_LINE('with_time(1)='||df_with_time(1));
END;
/
-- Warning: Never add DETERMINISTIC to such functions.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 3: Deterministic lookup over immutable reference data
-- Scenario:
--   Map ISO code -> country name. Safe if source table is treated as read-mostly/immutable.
--   Caveat: If df_iso_country changes, cached results (via RESULT_CACHE) may be stale until invalidated.
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION df_country_name(p_iso IN VARCHAR2)
  RETURN VARCHAR2 DETERMINISTIC
IS
  v_name df_iso_country.name%TYPE;
BEGIN
  SELECT name INTO v_name FROM df_iso_country WHERE iso_code = df_norm_iso(p_iso);
  RETURN v_name;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN 'UNKNOWN';
END df_country_name;
/
BEGIN
  DBMS_OUTPUT.PUT_LINE('country(IN)='||df_country_name('in'));
  DBMS_OUTPUT.PUT_LINE('country(XX)='||df_country_name('xx'));
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 4: RESULT_CACHE (server-wide function result cache)
-- Prerequisite:
--   • RESULT_CACHE must be enabled on the database for best effect (check parameters).
--   • This example adds RESULT_CACHE to cache the function result by argument values.
-- Behavior:
--   • First call computes and populates cache; subsequent calls may be served from cache.
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION df_country_name_cached(p_iso IN VARCHAR2)
  RETURN VARCHAR2
  RESULT_CACHE RELIES_ON (df_iso_country)  -- mark dependency to help invalidation
IS
  v_name df_iso_country.name%TYPE;
BEGIN
  -- Simulate expensive work with a lookup + formatting
  SELECT name INTO v_name FROM df_iso_country WHERE iso_code = df_norm_iso(p_iso);
  RETURN v_name;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN 'UNKNOWN';
END df_country_name_cached;
/
BEGIN
  DBMS_OUTPUT.PUT_LINE('cached(IN) first='||df_country_name_cached('in'));
  DBMS_OUTPUT.PUT_LINE('cached(IN) second='||df_country_name_cached('in'));
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 5: Hashing function (pure) used in queries
-- Scenario:
--   Stable one-way hash of strings; ideal candidate for DETERMINISTIC.
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION df_hash32(p_text IN VARCHAR2)
  RETURN VARCHAR2 DETERMINISTIC
IS
  -- Simple 32-bit-like rolling hash (illustrative; not cryptographic)
  v_hash NUMBER := 0;
  v_chr  NUMBER;
BEGIN
  IF p_text IS NULL THEN RETURN '00000000'; END IF;
  FOR i IN 1..LENGTH(p_text) LOOP
    v_chr  := ASCII(SUBSTR(p_text,i,1));
    v_hash := MOD(v_hash * 31 + v_chr, POWER(2,31)-1);
  END LOOP;
  RETURN TO_CHAR(v_hash,'FM00000000');
END df_hash32;
/
-- Use inside a query (same result each time for same input)
SELECT 'Avi' who, df_hash32('Avi') h FROM dual
UNION ALL
SELECT 'Neha', df_hash32('Neha') FROM dual;
/

--------------------------------------------------------------------------------
-- Example 6: Unsafe marking demonstration (document-only)
-- Scenario:
--   A function that reads DBMS_RANDOM or a sequence is non-deterministic; do not mark deterministic.
--------------------------------------------------------------------------------
-- CREATE OR REPLACE FUNCTION df_bad(p_x IN NUMBER)
--   RETURN NUMBER DETERMINISTIC  -- WRONG: non-deterministic behavior inside
-- IS
-- BEGIN
--   RETURN DBMS_RANDOM.VALUE + p_x; -- depends on RNG state -> non-deterministic
-- END df_bad;
-- /

--------------------------------------------------------------------------------
-- Example 7: Comparing costs (conceptual)
-- Scenario:
--   Call plain vs cached multiple times. On a fully enabled result cache, the second call should be faster.
--------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('plain='||df_country_name('US'));
  DBMS_OUTPUT.PUT_LINE('cached='||df_country_name_cached('US'));
  DBMS_OUTPUT.PUT_LINE('cached again='||df_country_name_cached('US'));
END;
/
--------------------------------------------------------------------------------
-- End of File
--------------------------------------------------------------------------------
