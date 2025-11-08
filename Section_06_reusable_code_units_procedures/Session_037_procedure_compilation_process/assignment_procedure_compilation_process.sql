-- Script: assignment_procedure_compilation_process.sql
-- Session: 037 - Procedure Compilation Process
-- Format:
--   • 10 detailed questions with complete solutions provided as COMMENTED hints.
--   • To run a solution: copy the commented block and remove leading '--'.
-- Guidance:
--   • Prefer NUMBER(p, s) where money-like values use s=2 (e.g., NUMBER(12,2) for prices).
--   • Enable warnings to see helpful messages about unreachable code or performance.
--   • Use SHOW ERRORS and USER_ERRORS for compilation diagnostics.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Q1 (Enable warnings): Turn on all PL/SQL warnings for the current session.
-- Answer (commented):
-- ALTER SESSION SET PLSQL_WARNINGS='ENABLE:ALL';
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q2 (Broken compile): Create pc_test with an intentional typo; then SHOW ERRORS.
-- Answer (commented):
-- CREATE OR REPLACE PROCEDURE pc_test IS
--   v NUMBER;                                       -- unscaled NUMBER is fine for COUNT(*)
-- BEGIN
--   SELECT coun(*) INTO v FROM dual;                -- typo 'coun' -> should be COUNT; triggers PLS- error
-- END pc_test;
-- /
-- SHOW ERRORS PROCEDURE pc_test
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q3 (USER_ERRORS): Print error line/position/text for pc_test.
-- Answer (commented):
-- COLUMN text FORMAT A80
-- SELECT line, position, text FROM user_errors WHERE name='PC_TEST' ORDER BY sequence;
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q4 (Fix & test): Correct the procedure and print v.
-- Answer (commented):
-- CREATE OR REPLACE PROCEDURE pc_test IS
--   v NUMBER;                                       -- holds result of COUNT(*)
-- BEGIN
--   SELECT COUNT(*) INTO v FROM dual;               -- COUNT(*) always yields 1 on DUAL
--   DBMS_OUTPUT.PUT_LINE('v='||v);
-- END pc_test;
-- /
-- BEGIN pc_test; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q5 (Dependency invalidation): Build pc_dep reading a table; DDL it; then call pc_dep.
-- Answer (commented):
-- -- Setup a small table with a numeric literal and a scale justification
-- BEGIN
--   EXECUTE IMMEDIATE 'BEGIN EXECUTE IMMEDIATE ''DROP TABLE pc_dep_tab PURGE''; EXCEPTION WHEN OTHERS THEN NULL; END;';
--   EXECUTE IMMEDIATE 'CREATE TABLE pc_dep_tab(id NUMBER(10) PRIMARY KEY, amount NUMBER(12,2))';
--   -- NUMBER(10) for id supports up to 10 digits; NUMBER(12,2) for amount supports cents/paise.
--   EXECUTE IMMEDIATE 'INSERT INTO pc_dep_tab VALUES (1, 250.00)';
--   COMMIT;
-- END;
-- /
-- CREATE OR REPLACE PROCEDURE pc_dep IS
--   v NUMBER;                                       -- stores COUNT(*)
-- BEGIN
--   SELECT COUNT(*) INTO v FROM pc_dep_tab;         -- selects from dependency
--   DBMS_OUTPUT.PUT_LINE('rows='||v);
-- END pc_dep;
-- /
-- -- Change dependency to trigger re-parse: add a column with a numeric type
-- ALTER TABLE pc_dep_tab ADD (tax_rate NUMBER(5,2) DEFAULT 18.00); -- NUMBER(5,2) fits 0..999.99 (we need up to 100.00)
-- BEGIN pc_dep; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q6 (Manual recompile): Force compilation of pc_dep and verify VALID.
-- Answer (commented):
-- ALTER PROCEDURE pc_dep COMPILE;
-- SELECT object_name, status FROM user_objects WHERE object_name='PC_DEP';
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q7 (Warnings per object): Inspect user_plsql_object_settings for pc_test.
-- Answer (commented):
-- SELECT name, plsql_warnings FROM user_plsql_object_settings WHERE name='PC_TEST';
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q8 (AUTHID options, optional): Compile both DEFINER and CURRENT_USER variants.
-- Answer (commented):
-- CREATE OR REPLACE PROCEDURE pc_def AUTHID DEFINER IS BEGIN NULL; END; /
-- CREATE OR REPLACE PROCEDURE pc_cur AUTHID CURRENT_USER IS BEGIN NULL; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q9 (INVALID→VALID): Make a bad reference, observe error, then fix it.
-- Answer (commented):
-- CREATE OR REPLACE PROCEDURE pc_bad IS v NUMBER; BEGIN SELECT badcol INTO v FROM dual; END; /
-- SHOW ERRORS PROCEDURE pc_bad
-- CREATE OR REPLACE PROCEDURE pc_bad IS v NUMBER; BEGIN SELECT 1 INTO v FROM dual; END; /
-- SELECT object_name, status FROM user_objects WHERE object_name='PC_BAD';
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q10 (Quick checker): List INVALID procedures in this schema.
-- Answer (commented):
-- COLUMN object_name FORMAT A30
-- SELECT object_name, status
-- FROM   user_objects
-- WHERE  object_type='PROCEDURE' AND status='INVALID';
--------------------------------------------------------------------------------
-- End of Assignment
--------------------------------------------------------------------------------
