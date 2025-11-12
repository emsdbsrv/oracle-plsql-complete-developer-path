SET SERVEROUTPUT ON SIZE UNLIMITED;
/*
Assignment: Session 055 - Packaging Concept and Benefits
Format:
  • 10 hands-on tasks. Each includes a complete solution as a commented block.
  • To run a solution, copy its commented block, remove leading '--', and execute.
Guidance:
  • Keep SPEC minimal (contract) and BODY private (helpers/state).
  • Use a consistent error code range, e.g., -20600..-20699 for this assignment.
  • Prefer getters over public variables; expose clear_state() and diagnostics.
*/

--------------------------------------------------------------------------------
-- Q1 (Hello contract): SPEC with PROCEDURE hello; BODY prints once called.
-- Answer (commented):
-- CREATE OR REPLACE PACKAGE a1_pkg AS PROCEDURE hello; END a1_pkg; /
-- CREATE OR REPLACE PACKAGE BODY a1_pkg AS PROCEDURE hello IS BEGIN DBMS_OUTPUT.PUT_LINE('hello'); END; END a1_pkg; /
-- BEGIN a1_pkg.hello; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q2 (Private counter): Add private g_hits; expose hits(), touch(), clear().
-- Answer (commented):
-- CREATE OR REPLACE PACKAGE a2_pkg AS FUNCTION hits RETURN PLS_INTEGER; PROCEDURE touch; PROCEDURE clear; END; /
-- CREATE OR REPLACE PACKAGE BODY a2_pkg AS g_hits PLS_INTEGER:=0; FUNCTION hits RETURN PLS_INTEGER IS BEGIN RETURN NVL(g_hits,0); END; PROCEDURE touch IS BEGIN g_hits:=NVL(g_hits,0)+1; END; PROCEDURE clear IS BEGIN g_hits:=0; END; BEGIN g_hits:=0; END a2_pkg; /
-- BEGIN a2_pkg.touch; a2_pkg.touch; DBMS_OUTPUT.PUT_LINE('hits='||a2_pkg.hits); a2_pkg.clear; DBMS_OUTPUT.PUT_LINE('hits='||a2_pkg.hits); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q3 (Overloading): Provide log(msg VARCHAR2) and log(code NUMBER).
-- Answer (commented):
-- CREATE OR REPLACE PACKAGE a3_pkg AS PROCEDURE log(p_msg VARCHAR2); PROCEDURE log(p_code NUMBER); END; /
-- CREATE OR REPLACE PACKAGE BODY a3_pkg AS PROCEDURE log(p_msg VARCHAR2) IS BEGIN DBMS_OUTPUT.PUT_LINE('[msg] '||p_msg); END; PROCEDURE log(p_code NUMBER) IS BEGIN DBMS_OUTPUT.PUT_LINE('[code] '||p_code); END; END; /
-- BEGIN a3_pkg.log('ok'); a3_pkg.log(200); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q4 (Initialization): Print 'initialized' once per session on first reference.
-- Answer (commented):
-- CREATE OR REPLACE PACKAGE a4_pkg AS PROCEDURE ping; END; /
-- CREATE OR REPLACE PACKAGE BODY a4_pkg AS PROCEDURE ping IS NULL; BEGIN DBMS_OUTPUT.PUT_LINE('initialized'); END a4_pkg; /
-- BEGIN a4_pkg.ping; a4_pkg.ping; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q5 (Error policy): fail_if_blank raises -20610 if input is NULL/blank.
-- Answer (commented):
-- CREATE OR REPLACE PACKAGE a5_pkg AS PROCEDURE fail_if_blank(p_text VARCHAR2); END; /
-- CREATE OR REPLACE PACKAGE BODY a5_pkg AS PROCEDURE fail_if_blank(p_text VARCHAR2) IS BEGIN IF p_text IS NULL OR TRIM(p_text)='' THEN RAISE_APPLICATION_ERROR(-20610,'blank not allowed'); END IF; END; END; /
-- BEGIN BEGIN a5_pkg.fail_if_blank('   '); EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE(SQLCODE||' '||SQLERRM); END; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q6 (SQL function): DETERMINISTIC function sqr(p NUMBER) usable in SELECT.
-- Answer (commented):
-- CREATE OR REPLACE PACKAGE a6_pkg AS FUNCTION sqr(p NUMBER) RETURN NUMBER DETERMINISTIC; END; /
-- CREATE OR REPLACE PACKAGE BODY a6_pkg AS FUNCTION sqr(p NUMBER) RETURN NUMBER IS BEGIN RETURN p*p; END; END; /
-- SELECT a6_pkg.sqr(level) AS sq FROM dual CONNECT BY level<=5;
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q7 (Refactor to getters): Replace public var with getter/setter and keep var private.
-- Answer (commented):
-- CREATE OR REPLACE PACKAGE a7_pkg AS FUNCTION get_cfg RETURN NUMBER; PROCEDURE set_cfg(p NUMBER); END; /
-- CREATE OR REPLACE PACKAGE BODY a7_pkg AS g_cfg NUMBER:=10; FUNCTION get_cfg RETURN NUMBER IS BEGIN RETURN g_cfg; END; PROCEDURE set_cfg(p NUMBER) IS BEGIN g_cfg:=p; END; END; /
-- BEGIN DBMS_OUTPUT.PUT_LINE(a7_pkg.get_cfg); a7_pkg.set_cfg(42); DBMS_OUTPUT.PUT_LINE(a7_pkg.get_cfg); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q8 (Debug toggle): Add enable_debug/disable_debug and conditional dbg(msg).
-- Answer (commented):
-- CREATE OR REPLACE PACKAGE a8_pkg AS PROCEDURE enable_debug; PROCEDURE disable_debug; PROCEDURE run; END; /
-- CREATE OR REPLACE PACKAGE BODY a8_pkg AS g_dbg BOOLEAN:=FALSE; PROCEDURE enable_debug IS BEGIN g_dbg:=TRUE; END; PROCEDURE disable_debug IS BEGIN g_dbg:=FALSE; END; PROCEDURE dbg(p VARCHAR2) IS BEGIN IF g_dbg THEN DBMS_OUTPUT.PUT_LINE('[dbg] '||p); END IF; END; PROCEDURE run IS BEGIN dbg('start'); dbg('done'); END; END; /
-- BEGIN a8_pkg.enable_debug; a8_pkg.run; a8_pkg.disable_debug; a8_pkg.run; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q9 (SPEC stability): Add a BODY-only helper without changing SPEC; demonstrate unchanged consumer code.
-- Answer (commented):
-- -- Edit BODY of a3_pkg to call a private helper format_code(); consumer calls remain a3_pkg.log(200).
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q10 (Mini customer API): Build minimal SPEC/BODY using a table, with checks and diagnostics.
-- Answer (commented):
-- BEGIN EXECUTE IMMEDIATE 'DROP TABLE a10_customers PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END; /
-- CREATE TABLE a10_customers(id NUMBER PRIMARY KEY, name VARCHAR2(50), st VARCHAR2(10) DEFAULT 'NEW'); /
-- INSERT INTO a10_customers VALUES(1,'Alex','NEW'); COMMIT; /
-- CREATE OR REPLACE PACKAGE a10_pkg AS SUBTYPE t_id IS NUMBER; FUNCTION calls RETURN PLS_INTEGER; PROCEDURE activate(p_id t_id); FUNCTION is_active(p_id t_id) RETURN NUMBER DETERMINISTIC; END; /
-- CREATE OR REPLACE PACKAGE BODY a10_pkg AS g_calls PLS_INTEGER:=0; PROCEDURE bump IS BEGIN g_calls:=NVL(g_calls,0)+1; END; FUNCTION calls RETURN PLS_INTEGER IS BEGIN RETURN NVL(g_calls,0); END; PROCEDURE activate(p_id t_id) IS BEGIN UPDATE a10_customers SET st='ACTIVE' WHERE id=p_id; IF SQL%ROWCOUNT=0 THEN RAISE_APPLICATION_ERROR(-20650,'id not found'); END IF; bump; END; FUNCTION is_active(p_id t_id) RETURN NUMBER DETERMINISTIC IS v VARCHAR2(10); BEGIN SELECT st INTO v FROM a10_customers WHERE id=p_id; RETURN CASE WHEN v='ACTIVE' THEN 1 ELSE 0 END; END; END; /
-- BEGIN a10_pkg.activate(1); DBMS_OUTPUT.PUT_LINE('calls='||a10_pkg.calls); END; /
-- SELECT id, name, st, a10_pkg.is_active(id) AS is_active FROM a10_customers; /
--------------------------------------------------------------------------------

-- End of Assignment
