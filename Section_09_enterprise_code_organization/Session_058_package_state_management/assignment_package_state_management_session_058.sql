SET SERVEROUTPUT ON SIZE UNLIMITED;
/*
Assignment: Session 058 – Package State Management
Format:
  • 10 tasks with fully commented solutions. Copy, uncomment, run.
Guidance:
  • Track state privately; expose diagnostics via getters only.
  • Prove session persistence; provide explicit reset.
  • Avoid public mutable variables.
*/

--------------------------------------------------------------------------------
-- Q1 (Counters): Add g_calls and bump() in BODY; expose calls_made() in SPEC.
-- Answer (commented):
-- -- SPEC: FUNCTION calls_made RETURN PLS_INTEGER;
-- -- BODY:  g_calls PLS_INTEGER:=0; PROCEDURE bump IS BEGIN g_calls:=NVL(g_calls,0)+1; END;
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q2 (Init time): Capture last_init_time at first reference; expose getter.
-- Answer (commented):
-- -- BODY init section: g_last_init := SYSDATE;  FUNCTION last_init_time RETURN DATE IS BEGIN RETURN g_last_init; END;
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q3 (Cache): Add associative array cache and hit/miss counters; integrate into get_amount.
-- Answer (commented):
-- -- BODY: TYPE t_amt_cache IS TABLE OF NUMBER INDEX BY PLS_INTEGER; g_amt_cache t_amt_cache; g_hits PLS_INTEGER:=0; g_misses PLS_INTEGER:=0;
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q4 (User context): Keep g_last_user and g_last_time; provide set_user(), last_user(), last_action_time().
-- Answer (commented):
-- -- BODY: PROCEDURE set_user(p VARCHAR2) IS BEGIN g_last_user:=p; END; PROCEDURE touch_user IS BEGIN g_last_time:=SYSTIMESTAMP; IF g_last_user IS NULL THEN g_last_user:=USER; END IF; END;
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q5 (Reset): Implement clear_state to reset all counters, user context, and cache.
-- Answer (commented):
-- -- BODY: PROCEDURE clear_state IS BEGIN g_calls:=0; g_hits:=0; g_misses:=0; g_amt_cache.DELETE; g_last_user:=NULL; g_last_time:=NULL; END;
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q6 (Persistence test): Show values before and after multiple calls proving persistence.
-- Answer (commented):
-- -- BEGIN DBMS_OUTPUT.PUT_LINE(order_pub.calls_made); order_pub.set_amount(101,1); DBMS_OUTPUT.PUT_LINE(order_pub.calls_made); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q7 (Cache test): Prove first get is a miss and second is a hit.
-- Answer (commented):
-- -- BEGIN DBMS_OUTPUT.PUT_LINE(order_pub.get_amount(101)); DBMS_OUTPUT.PUT_LINE(order_pub.get_amount(101)); DBMS_OUTPUT.PUT_LINE(order_pub.cache_hits||'/'||order_pub.cache_misses); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q8 (User test): Set user and perform actions; verify last_user/time updated.
-- Answer (commented):
-- -- BEGIN order_pub.set_user('tester'); order_pub.set_amount(102,10); DBMS_OUTPUT.PUT_LINE(order_pub.last_user||' @ '||TO_CHAR(order_pub.last_action_time,'YYYY-MM-DD HH24:MI:SS')); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q9 (Error test): Trigger e_invalid_amount and catch the exception.
-- Answer (commented):
-- -- BEGIN BEGIN order_pub.set_amount(101,-1); EXCEPTION WHEN order_pub.e_invalid_amount THEN DBMS_OUTPUT.PUT_LINE('caught'); END; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q10 (Re-init): Call clear_state then re-use API; verify counters restart.
-- Answer (commented):
-- -- BEGIN order_pub.clear_state; order_pub.set_amount(103,25); DBMS_OUTPUT.PUT_LINE('calls='||order_pub.calls_made); END; /
--------------------------------------------------------------------------------

-- End of Assignment
