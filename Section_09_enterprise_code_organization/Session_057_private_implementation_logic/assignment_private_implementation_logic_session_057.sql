SET SERVEROUTPUT ON SIZE UNLIMITED;
/*
Assignment: Session 057 – Private Implementation Logic
Format:
  • 10 tasks with fully commented solutions. Copy, uncomment, run.
Guidance:
  • Refactor BODY without touching SPEC.
  • Use helpers for validation and caching.
  • Keep diagnostics read‑only; avoid public mutable state.
*/

--------------------------------------------------------------------------------
-- Q1 (Private helper): Add dbg(p VARCHAR2) in BODY and toggle with enable/disable.
-- Answer (commented):
-- -- Add to BODY:
-- --   PROCEDURE dbg(p IN VARCHAR2) IS BEGIN IF g_debug THEN DBMS_OUTPUT.PUT_LINE('[dbg] '||p); END IF; END;
-- -- Verify:
-- --   BEGIN order_pub.enable_debug; order_pub.disable_debug; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q2 (Counter): Increment g_calls in each public entrypoint via bump helper.
-- Answer (commented):
-- -- BODY:
-- --   PROCEDURE bump IS BEGIN g_calls := NVL(g_calls,0) + 1; END;
-- --   Call bump at end of each public routine.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q3 (Cache): Add amount cache and wire it in get_amount; show hit/miss in debug.
-- Answer (commented):
-- -- BODY:
-- --   TYPE t_amt_cache IS TABLE OF NUMBER INDEX BY PLS_INTEGER; g_amt_cache t_amt_cache;
-- --   PROCEDURE cache_put(p_id NUMBER, p_amt NUMBER); FUNCTION cache_get(p_id NUMBER) RETURN NUMBER;
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q4 (Validation): Centralize amount/status validation and reuse in canonical proc.
-- Answer (commented):
-- -- BODY:
-- --   PROCEDURE validate_amount(p NUMBER) IS IF p IS NULL OR p<0 THEN RAISE e_invalid_amount; END IF; END;
-- --   PROCEDURE validate_status(p VARCHAR2) IS IF p NOT IN (...) THEN RAISE e_invalid_status; END IF; END;
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q5 (Canonical + wrappers): Keep public overloads thin; delegate to set_amount_canon.
-- Answer (commented):
-- -- BODY:
-- --   PROCEDURE set_amount_canon(...);  -- full logic
-- --   PROCEDURE set_amount(p_id,p_amt) IS BEGIN set_amount_canon(p_id,p_amt,NULL,NULL); END;
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q6 (Diagnostics): Expose version(), calls_made(), last_init_time() only.
-- Answer (commented):
-- -- SPEC stays the same; BODY returns private g_version/g_calls/g_last_init.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q7 (Refactor proof): Change SQL in BODY (e.g., add a hint) and verify callers unaffected.
-- Answer (commented):
-- -- Edit BODY UPDATE with an optimizer hint; recompile; re-run existing tests.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q8 (Negative tests): Show catching e_invalid_amount and e_not_found.
-- Answer (commented):
-- -- BEGIN BEGIN order_pub.set_amount(9999,10); EXCEPTION WHEN order_pub.e_not_found THEN DBMS_OUTPUT.PUT_LINE('not found'); END; END; /
-- -- BEGIN BEGIN order_pub.set_amount(101,-1);  EXCEPTION WHEN order_pub.e_invalid_amount THEN DBMS_OUTPUT.PUT_LINE('bad amount'); END; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q9 (Cache invalidation): After set_amount, ensure cache_put is called.
-- Answer (commented):
-- -- BODY:
-- --   After UPDATE, call cache_put(p_id,p_amount); verify with two consecutive get_amount calls.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q10 (Clear state): Implement clear_state to reset counters and cache.
-- Answer (commented):
-- -- BODY:
-- --   PROCEDURE clear_state IS BEGIN g_calls := 0; g_amt_cache.DELETE; END;
-- -- Test:
-- --   BEGIN order_pub.clear_state; DBMS_OUTPUT.PUT_LINE(order_pub.calls_made); END; /
--------------------------------------------------------------------------------

-- End of Assignment
