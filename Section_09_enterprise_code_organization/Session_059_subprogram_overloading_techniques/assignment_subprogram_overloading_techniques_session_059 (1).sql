SET SERVEROUTPUT ON SIZE UNLIMITED;
--------------------------------------------------------------------------------
-- Assignment: Session 059 – Subprogram Overloading Techniques
-- Format:
--   • 10 detailed tasks with complete solutions provided as COMMENTED blocks.
--   • To run a solution: copy the commented block and remove leading '--'.
-- Guidance:
--   • Prefer a canonical routine + thin overloads
--   • Keep overloads orthogonal (arity/type/subtype), not only defaults
--   • Test positional, named, and mixed calls for each overload
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q1 (Warm-up): Call sum_vals(10, 15) and sum_vals(PLS_INTEGER, PLS_INTEGER).
-- Answer (commented):
-- BEGIN DBMS_OUTPUT.PUT_LINE(math_ops_pkg.sum_vals(10,15)); END; /
-- DECLARE a PLS_INTEGER:=2; b PLS_INTEGER:=3; BEGIN DBMS_OUTPUT.PUT_LINE(math_ops_pkg.sum_vals(a,b)); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q2 (Default multiplier): Verify default is 1; then call with p_multiply=>0.1.
-- Answer (commented):
-- BEGIN
--   DBMS_OUTPUT.PUT_LINE(math_ops_pkg.sum_vals(10,20));           -- 30
--   DBMS_OUTPUT.PUT_LINE(math_ops_pkg.sum_vals(10,20,0.1));       -- 3
-- END;
-- /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q3 (Named notation): Call sum3 with mixed named/positional parameters.
-- Answer (commented):
-- BEGIN
--   DBMS_OUTPUT.PUT_LINE(math_ops_pkg.sum3(1, p_c=>4, p_b=>2, p_multiply=>3)); -- (1+2+4)*3=21
-- END;
-- /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q4 (List sum): Build t_num_tab(5, NULL, 10) and sum; show NVL handling.
-- Answer (commented):
-- DECLARE
--   l math_ops_pkg.t_num_tab := math_ops_pkg.t_num_tab(5, NULL, 10);
-- BEGIN
--   DBMS_OUTPUT.PUT_LINE(math_ops_pkg.sum_list(l)); -- 15
-- END;
-- /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q5 (CSV sum): Sum '1,2,3,4' and with multiplier 2.5.
-- Answer (commented):
-- BEGIN
--   DBMS_OUTPUT.PUT_LINE(math_ops_pkg.sum_vals('1,2,3,4'));     -- 10
--   DBMS_OUTPUT.PUT_LINE(math_ops_pkg.sum_vals('1,2,3,4',2.5)); -- 25
-- END;
-- /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q6 (Ambiguity check): Show that NUMBER+PLS_INTEGER selects NUMBER overload.
-- Answer (commented):
-- DECLARE
--   a NUMBER:=7; b PLS_INTEGER:=9;
-- BEGIN
--   DBMS_OUTPUT.PUT_LINE(math_ops_pkg.sum_vals(a,b)); -- 16 via NUMBER overload
-- END;
-- /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q7 (Subtype steering): Force integer overload by using PLS_INTEGER variables.
-- Answer (commented):
-- DECLARE
--   a PLS_INTEGER:=7; b PLS_INTEGER:=9;
-- BEGIN
--   DBMS_OUTPUT.PUT_LINE(math_ops_pkg.sum_vals(a,b)); -- 16 via int overload
-- END;
-- /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q8 (Defaults after selection): Demonstrate overload is chosen before defaults apply.
-- Answer (commented):
-- -- Explanation: Candidate chosen by arity/types; only afterwards does default p_multiply=1 fill in.
-- BEGIN
--   DBMS_OUTPUT.PUT_LINE(math_ops_pkg.sum_vals(1,2));   -- 3 using NUMBER overload
-- END;
-- /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q9 (Negative test): CSV contains 'a'; catch and show error.
-- Answer (commented):
-- BEGIN
--   BEGIN
--     DBMS_OUTPUT.PUT_LINE(math_ops_pkg.sum_vals('1,a,3'));
--   EXCEPTION
--     WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('caught: '||SQLERRM);
--   END;
-- END;
-- /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q10 (Design critique): Propose an additional overload and explain why it should or should not exist.
-- Answer (commented):
-- -- Suggestion: FUNCTION sum_vals(p_a DATE, p_b DATE) RETURN NUMBER;
-- -- Rationale: Not recommended. Mixing numeric semantics with DATE types invites ambiguity
-- -- and violates the principle that overloads should do the same conceptual work.
--------------------------------------------------------------------------------

-- End of Assignment
