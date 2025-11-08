-- Script: assignment_purity_levels_and_restrictions.sql
-- Session: 046 - Purity Levels and Restrictions
-- Format:
--   • 10 tasks with fully commented solutions. Copy a solution block, remove '--', and execute.
-- Guidance:
--   • Choose appropriate RESTRICT_REFERENCES flags based on real behavior.
--   • Avoid package-state and DB-state access if you need pure SQL-callable functions.
--   • Prefer modern pure functions with DETERMINISTIC/RESULT_CACHE when applicable.
SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Q1 (Flags meaning): Write comments describing WNDS, RNDS, WNPS, RNPS, then create a pure function f1 and apply all four.
-- Answer (commented):
-- -- WNDS: Writes No Database State
-- -- RNDS: Reads No Database State
-- -- WNPS: Writes No Package State
-- -- RNPS: Reads No Package State
-- -- CREATE OR REPLACE PACKAGE q1_pkg AS
-- --   FUNCTION f1(x IN NUMBER) RETURN NUMBER;
-- --   PRAGMA RESTRICT_REFERENCES(f1, WNDS, WNPS, RNDS, RNPS);
-- -- END q1_pkg;
-- -- /
-- -- CREATE OR REPLACE PACKAGE BODY q1_pkg AS
-- --   FUNCTION f1(x IN NUMBER) RETURN NUMBER IS BEGIN RETURN NVL(x,0)*2; END;
-- -- END q1_pkg;
-- -- /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q2 (Violation demo): Create a function that claims RNDS but selects from a table; observe error.
-- Answer (commented):
-- -- CREATE OR REPLACE PACKAGE q2_bad AS
-- --   FUNCTION f(p_id IN pr_orders.order_id%TYPE) RETURN VARCHAR2;
-- --   PRAGMA RESTRICT_REFERENCES(f, RNDS);
-- -- END;
-- -- /
-- -- CREATE OR REPLACE PACKAGE BODY q2_bad AS
-- --   FUNCTION f(p_id IN pr_orders.order_id%TYPE) RETURN VARCHAR2 IS v VARCHAR2(20);
-- --   BEGIN SELECT status INTO v FROM pr_orders WHERE order_id=p_id; RETURN v; END;
-- -- END;
-- -- /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q3 (Correct flags): Function that reads DB but not package state; choose flags.
-- Answer (commented):
-- -- CREATE OR REPLACE PACKAGE q3_pkg AS
-- --   FUNCTION get_amount(p_id IN pr_orders.order_id%TYPE) RETURN pr_orders.amount%TYPE;
-- --   PRAGMA RESTRICT_REFERENCES(get_amount, WNDS, WNPS);
-- -- END;
-- -- /
-- -- CREATE OR REPLACE PACKAGE BODY q3_pkg AS
-- --   FUNCTION get_amount(p_id IN pr_orders.order_id%TYPE) RETURN pr_orders.amount%TYPE IS v pr_orders.amount%TYPE;
-- --   BEGIN SELECT amount INTO v FROM pr_orders WHERE order_id=p_id; RETURN v; END;
-- -- END;
-- -- /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q4 (Package state): Show why RNPS cannot be claimed if a function reads a package variable.
-- Answer (commented):
-- -- CREATE OR REPLACE PACKAGE q4_state AS g_k NUMBER := 2; FUNCTION mult(p IN NUMBER) RETURN NUMBER; END; /
-- -- CREATE OR REPLACE PACKAGE BODY q4_state AS FUNCTION mult(p IN NUMBER) RETURN NUMBER IS BEGIN RETURN p*g_k; END; END; /
-- -- -- Do NOT claim RNPS/WNPS because function depends on package variable g_k.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q5 (Modern pure): Implement DETERMINISTIC normalizer and call from SQL.
-- Answer (commented):
-- -- CREATE OR REPLACE FUNCTION q5_norm(p IN VARCHAR2) RETURN VARCHAR2 DETERMINISTIC IS BEGIN RETURN UPPER(TRIM(p)); END; /
-- -- SELECT q5_norm(' x ') FROM dual; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q6 (RESULT_CACHE): Create cached lookup for pr_orders amount by id.
-- Answer (commented):
-- -- CREATE OR REPLACE FUNCTION q6_amount_cached(p_id IN pr_orders.order_id%TYPE) RETURN pr_orders.amount%TYPE RESULT_CACHE RELIES_ON(pr_orders) IS v pr_orders.amount%TYPE; BEGIN SELECT amount INTO v FROM pr_orders WHERE order_id=p_id; RETURN v; EXCEPTION WHEN NO_DATA_FOUND THEN RETURN -1; END; /
-- -- BEGIN DBMS_OUTPUT.PUT_LINE(q6_amount_cached(1)); DBMS_OUTPUT.PUT_LINE(q6_amount_cached(1)); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q7 (Refactor to purity): Replace package-state usage by passing explicit parameter.
-- Answer (commented):
-- -- Original anti-pattern: function reads q7_pkg.rate (package var).
-- -- Refactor:
-- -- CREATE OR REPLACE FUNCTION q7_apply(p_amount IN NUMBER, p_rate IN NUMBER) RETURN NUMBER DETERMINISTIC IS BEGIN RETURN ROUND(NVL(p_amount,0)*(1+NVL(p_rate,0)),2); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q8 (SQL-callable safety): Create a function usable in SQL that throws NO_DATA_FOUND to caller.
-- Answer (commented):
-- -- CREATE OR REPLACE FUNCTION q8_find(p_id IN pr_orders.order_id%TYPE) RETURN VARCHAR2 IS v VARCHAR2(20); BEGIN SELECT status INTO v FROM pr_orders WHERE order_id=p_id; RETURN v; END; /
-- -- SELECT q8_find(2) FROM dual; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q9 (Document guarantees): Add comments explaining why a given function is safe for SQL.
-- Answer (commented):
-- -- Example: q5_norm is pure (no DB/package state), DETERMINISTIC, uses only input -> safe in SQL.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q10 (Checklist): Produce a checklist comment block you will copy to every SQL-callable function.
-- Answer (commented):
-- -- /* SQL-callable checklist:
--    1) No writes to DB/package state
--    2) No reads from package state (or document if any)
--    3) Avoid non-determinism (SYSDATE, RANDOM, sequences)
--    4) Use %TYPE anchors
--    5) Consider DETERMINISTIC / RESULT_CACHE
--    6) Unit tests for edge/null cases
-- */

--------------------------------------------------------------------------------
-- End of Assignment
--------------------------------------------------------------------------------
