SET SERVEROUTPUT ON SIZE UNLIMITED;
/*
Assignment: Session 056 – Public Interface Declaration
Format:
  • 10 detailed tasks with complete commented solutions.
  • To run a solution: copy the commented block, remove leading '--', execute.
Guidance:
  • SPEC = public contract (types/constants/exceptions/signatures)
  • BODY = private implementation (helpers/state/algorithms)
  • Publish diagnostics (version, calls) but no public mutable variables
  • Use canonical + thin wrapper pattern for evolvability
*/

--------------------------------------------------------------------------------
-- Q1 (Hello SPEC): Create a minimal package exposing PROCEDURE hello in SPEC.
-- Answer (commented):
-- CREATE OR REPLACE PACKAGE s56_q1 AS PROCEDURE hello; END s56_q1; /
-- CREATE OR REPLACE PACKAGE BODY s56_q1 AS PROCEDURE hello IS BEGIN DBMS_OUTPUT.PUT_LINE('hello'); END; END s56_q1; /
-- BEGIN s56_q1.hello; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q2 (Constants): Add c_new, c_active, c_hold in SPEC; print them via BODY proc.
-- Answer (commented):
-- CREATE OR REPLACE PACKAGE s56_q2 AS c_new CONSTANT VARCHAR2(12):='NEW'; c_active CONSTANT VARCHAR2(12):='ACTIVE'; c_hold CONSTANT VARCHAR2(12):='HOLD'; PROCEDURE show; END; /
-- CREATE OR REPLACE PACKAGE BODY s56_q2 AS PROCEDURE show IS BEGIN DBMS_OUTPUT.PUT_LINE(c_new||','||c_active||','||c_hold); END; END; /
-- BEGIN s56_q2.show; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q3 (Exceptions): Declare e_not_found in SPEC and map to −20740; raise from BODY.
-- Answer (commented):
-- CREATE OR REPLACE PACKAGE s56_q3 AS e_not_found EXCEPTION; PRAGMA EXCEPTION_INIT(e_not_found,-20740); PROCEDURE fail; END; /
-- CREATE OR REPLACE PACKAGE BODY s56_q3 AS PROCEDURE fail IS BEGIN RAISE e_not_found; END; END; /
-- BEGIN BEGIN s56_q3.fail; EXCEPTION WHEN s56_q3.e_not_found THEN DBMS_OUTPUT.PUT_LINE('caught'); END; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q4 (Diagnostics): SPEC exposes version() and calls_made(); BODY tracks g_calls privately.
-- Answer (commented):
-- CREATE OR REPLACE PACKAGE s56_q4 AS FUNCTION version RETURN VARCHAR2; FUNCTION calls_made RETURN PLS_INTEGER; PROCEDURE ping; END; /
-- CREATE OR REPLACE PACKAGE BODY s56_q4 AS g_calls PLS_INTEGER:=0; g_ver CONSTANT VARCHAR2(10):='1.0.0'; FUNCTION version RETURN VARCHAR2 IS BEGIN RETURN g_ver; END; FUNCTION calls_made RETURN PLS_INTEGER IS BEGIN RETURN NVL(g_calls,0); END; PROCEDURE ping IS BEGIN g_calls:=NVL(g_calls,0)+1; END; END; /
-- BEGIN s56_q4.ping; s56_q4.ping; DBMS_OUTPUT.PUT_LINE(s56_q4.version||' calls='||s56_q4.calls_made); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q5 (Canonical + wrappers): SPEC with set_amount overloads forwarding to a canonical BODY proc.
-- Answer (commented):
-- CREATE OR REPLACE PACKAGE s56_q5 AS
--   SUBTYPE t_id IS NUMBER;
--   PROCEDURE set_amount(p_id IN t_id, p_amt IN NUMBER);
--   PROCEDURE set_amount(p_id IN t_id, p_amt IN NUMBER, p_note IN VARCHAR2);
--   PROCEDURE set_amount(p_id IN t_id, p_amt IN NUMBER, p_note IN VARCHAR2, p_cap IN NUMBER);
-- END s56_q5; /
-- CREATE OR REPLACE PACKAGE BODY s56_q5 AS
--   PROCEDURE canon(p_id IN NUMBER, p_amt IN NUMBER, p_note IN VARCHAR2, p_cap IN NUMBER) IS
--   BEGIN IF p_cap IS NOT NULL AND p_amt>p_cap THEN RAISE_APPLICATION_ERROR(-20770,'cap'); END IF; DBMS_OUTPUT.PUT_LINE('id='||p_id||' amt='||p_amt||' note='||NVL(p_note,'-')); END;
--   PROCEDURE set_amount(p_id IN t_id, p_amt IN NUMBER) IS BEGIN canon(p_id,p_amt,NULL,NULL); END;
--   PROCEDURE set_amount(p_id IN t_id, p_amt IN NUMBER, p_note IN VARCHAR2) IS BEGIN canon(p_id,p_amt,p_note,NULL); END;
--   PROCEDURE set_amount(p_id IN t_id, p_amt IN NUMBER, p_note IN VARCHAR2, p_cap IN NUMBER) IS BEGIN canon(p_id,p_amt,p_note,p_cap); END;
-- END s56_q5; /
-- BEGIN s56_q5.set_amount(1,10); s56_q5.set_amount(1,20,'x'); s56_q5.set_amount(1,30,'y',50); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q6 (Getter/Setter rule): Replace public var with get_/set_ in SPEC; keep var private in BODY.
-- Answer (commented):
-- CREATE OR REPLACE PACKAGE s56_q6 AS FUNCTION get_limit RETURN NUMBER; PROCEDURE set_limit(p NUMBER); END; /
-- CREATE OR REPLACE PACKAGE BODY s56_q6 AS g_limit NUMBER:=1000; FUNCTION get_limit RETURN NUMBER IS BEGIN RETURN g_limit; END; PROCEDURE set_limit(p NUMBER) IS BEGIN g_limit:=p; END; END; /
-- BEGIN DBMS_OUTPUT.PUT_LINE(s56_q6.get_limit); s56_q6.set_limit(750); DBMS_OUTPUT.PUT_LINE(s56_q6.get_limit); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q7 (Named notation): Call a 4‑arity wrapper with two named actuals; defaults fill the rest.
-- Answer (commented):
-- -- Example pattern: s56_q5.set_amount(p_id=>7, p_amt=>99);
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q8 (SQL‑safe function): SPEC declares DETERMINISTIC function usable in SQL; BODY must be pure.
-- Answer (commented):
-- CREATE OR REPLACE PACKAGE s56_q8 AS FUNCTION classify(p NUMBER) RETURN VARCHAR2 DETERMINISTIC; END; /
-- CREATE OR REPLACE PACKAGE BODY s56_q8 AS FUNCTION classify(p NUMBER) RETURN VARCHAR2 IS BEGIN RETURN CASE WHEN p<10 THEN 'LOW' WHEN p<20 THEN 'MID' ELSE 'HIGH' END; END; END; /
-- SELECT s56_q8.classify(level) AS cls FROM dual CONNECT BY level<=5;
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q9 (SPEC stability): Modify BODY to add a private helper; verify callers unaffected.
-- Answer (commented):
-- -- Edit BODY only; keep SPEC untouched; re‑run prior calls to confirm unchanged behavior.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q10 (Mini public interface): Build a compact order‑like SPEC with version(), calls_made(), set/get amount; implement BODY privately.
-- Answer (commented):
-- CREATE OR REPLACE PACKAGE s56_q10 AS FUNCTION version RETURN VARCHAR2; FUNCTION calls RETURN PLS_INTEGER; PROCEDURE set_amt(p_id NUMBER,p NUMBER); FUNCTION get_amt(p_id NUMBER) RETURN NUMBER DETERMINISTIC; END; /
-- CREATE OR REPLACE PACKAGE BODY s56_q10 AS g_calls PLS_INTEGER:=0; g_ver CONSTANT VARCHAR2(10):='1.0.0'; TYPE t_tab IS TABLE OF NUMBER INDEX BY PLS_INTEGER; g_store t_tab; FUNCTION version RETURN VARCHAR2 IS BEGIN RETURN g_ver; END; FUNCTION calls RETURN PLS_INTEGER IS BEGIN RETURN g_calls; END; PROCEDURE set_amt(p_id NUMBER,p NUMBER) IS BEGIN g_store(p_id):=p; g_calls:=g_calls+1; END; FUNCTION get_amt(p_id NUMBER) RETURN NUMBER DETERMINISTIC IS BEGIN RETURN g_store(p_id); END; END; /
-- BEGIN s56_q10.set_amt(1,42); DBMS_OUTPUT.PUT_LINE(s56_q10.version||' calls='||s56_q10.calls||' amt='||s56_q10.get_amt(1)); END; /
--------------------------------------------------------------------------------

-- End of Assignment
