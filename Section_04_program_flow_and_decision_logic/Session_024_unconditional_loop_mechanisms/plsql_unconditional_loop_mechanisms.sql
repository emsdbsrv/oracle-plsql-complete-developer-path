-- Script: plsql_unconditional_loop_mechanisms.sql
-- Session: 024 - Unconditional Loop Mechanisms (LOOP ... EXIT)
-- Purpose:
--   This script demonstrates open-ended iteration using the PL/SQL LOOP construct.
--   Each example clearly explains: (1) the scenario, (2) the loop driver variables,
--   (3) how termination/skip conditions are progressed, and (4) the exact output you
--   should expect. Use this as a template for production patterns like polling loops,
--   sentinel reads, and queue/stream processing.
-- How to run:
--   1) In SQL*Plus/SQLcl/SQL Developer, run:  SET SERVEROUTPUT ON
--   2) Execute each block (delimited by / on a new line) independently.
-- Notes:
--   • LOOP must contain at least one EXIT or EXIT WHEN path to avoid infinite loops.
--   • Place EXIT WHEN close to updates so the loop’s intent is self-documenting.
--   • CONTINUE / CONTINUE WHEN skips the *rest* of the current iteration.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Example 1: Counter with EXIT WHEN (post-test style)
-- Scenario:
--   We want to perform a unit of work at least once, then stop when a threshold
--   is reached. This emulates a post-test loop: the condition is checked after work.
-- Driver Variables:
--   v_i  -> iteration counter; increases by 1 each pass.
-- Termination:
--   EXIT WHEN v_i >= 5  -> loop stops after printing 1..5.
-- Expected Output:
--   i=1, i=2, i=3, i=4, i=5 (one per line).
--------------------------------------------------------------------------------
DECLARE
  v_i PLS_INTEGER := 0;  -- start at 0; we increment before printing
BEGIN
  LOOP
    v_i := v_i + 1;  -- driver update: ensures progress
    DBMS_OUTPUT.PUT_LINE('i='||v_i);
    EXIT WHEN v_i >= 5;  -- termination check close to driver update
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 2: CONTINUE WHEN skip rule + EXIT WHEN threshold
-- Scenario:
--   Process values 1..12, but skip multiples of 3 and stop once we reach 12.
-- Drivers:
--   v_i  -> iteration counter.
-- Skip Rule:
--   CONTINUE WHEN MOD(v_i,3)=0  -> skips 3,6,9,12 (no DBMS_OUTPUT for them).
-- Termination:
--   EXIT WHEN v_i >= 12         -> ensures we don't run forever.
-- Expected Output:
--   val=1,2,4,5,7,8,10,11
--------------------------------------------------------------------------------
DECLARE
  v_i PLS_INTEGER := 0;
BEGIN
  LOOP
    v_i := v_i + 1;
    CONTINUE WHEN MOD(v_i,3)=0;        -- skip multiples of 3
    DBMS_OUTPUT.PUT_LINE('val='||v_i); -- print only non-multiples of 3
    EXIT WHEN v_i >= 12;               -- stop at 12
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 3: Sentinel-driven input loop (array simulation)
-- Scenario:
--   Keep consuming tokens until a sentinel value ('END') is encountered.
-- Drivers:
--   v_idx -> index into the token array; increases by 1 each pass.
-- Termination:
--   1) EXIT WHEN v_idx > v_tokens.COUNT  -> out-of-data guard.
--   2) EXIT WHEN v_tok = 'END'           -> sentinel found.
-- Expected Output:
--   tok=alpha, tok=beta   (stops before 'END'; ignores 'gamma')
--------------------------------------------------------------------------------
DECLARE
  TYPE t_tab IS TABLE OF VARCHAR2(20);
  v_tokens t_tab := t_tab('alpha','beta','END','gamma'); -- example input stream
  v_idx PLS_INTEGER := 0;
  v_tok VARCHAR2(20);
BEGIN
  LOOP
    v_idx := v_idx + 1;                            -- advance to next token
    EXIT WHEN v_idx > v_tokens.COUNT;              -- out of tokens
    v_tok := v_tokens(v_idx);
    EXIT WHEN v_tok = 'END';                       -- sentinel
    DBMS_OUTPUT.PUT_LINE('tok='||v_tok);
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 4: Polling pattern with MAX_ITERS safety cap
-- Scenario:
--   Poll for a readiness flag to flip to TRUE. To prevent infinite looping, we
--   add a hard MAX_ITERS cap. This is common when waiting on external systems.
-- Drivers:
--   v_ready -> external readiness flag (simulated).
--   v_iters -> loop counter to enforce a hard cap.
-- Termination:
--   EXIT WHEN v_ready OR v_iters >= c_max
-- Expected Output:
--   poll #1, poll #2, poll #3 ... 'ready=TRUE' after simulated flip or cap.
--------------------------------------------------------------------------------
DECLARE
  v_ready  BOOLEAN := FALSE;
  v_iters  PLS_INTEGER := 0;
  c_max    CONSTANT PLS_INTEGER := 5;   -- defensive cap
BEGIN
  LOOP
    v_iters := v_iters + 1;
    DBMS_OUTPUT.PUT_LINE('poll #'||v_iters);

    -- Simulate external change on 3rd poll
    IF v_iters = 3 THEN
      v_ready := TRUE;
    END IF;

    EXIT WHEN v_ready;              -- desired completion
    EXIT WHEN v_iters >= c_max;     -- safety cap
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('ready='||CASE WHEN v_ready THEN 'TRUE' ELSE 'FALSE' END);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 5: Data-driven break on NULL
-- Scenario:
--   Iterate a numeric array; stop if a NULL is encountered. Useful for streams
--   where NULL marks boundary, corruption, or end-of-batch.
-- Drivers:
--   v_i    -> index through array
--   v_arr  -> numeric array that may contain NULL
-- Termination:
--   EXIT WHEN v_i > v_arr.COUNT          -> out of range guard
--   IF v_arr(v_i) IS NULL THEN EXIT;     -> data-driven break
-- Expected Output:
--   arr[1]=10, arr[2]=20, then 'NULL encountered at index 3'
--------------------------------------------------------------------------------
DECLARE
  TYPE t_nums IS TABLE OF NUMBER;
  v_arr t_nums := t_nums(10,20,NULL,40);
  v_i PLS_INTEGER := 0;
BEGIN
  LOOP
    v_i := v_i + 1;
    EXIT WHEN v_i > v_arr.COUNT;         -- guard
    IF v_arr(v_i) IS NULL THEN
      DBMS_OUTPUT.PUT_LINE('NULL encountered at index '||v_i);
      EXIT;                              -- data-driven break
    END IF;
    DBMS_OUTPUT.PUT_LINE('arr['||v_i||']='||v_arr(v_i));
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 6: Producer–Consumer toy model (queue drain)
-- Scenario:
--   Consume items from a FIFO-like list until empty; each iteration removes the
--   head of the queue and processes it.
-- Drivers:
--   v_q   -> a simple PL/SQL table acting as a queue
-- Termination:
--   EXIT WHEN v_q.COUNT = 0
-- Expected Output:
--   Processing: job1
--   Processing: job2
--   Processing: job3
--   Queue drained.
--------------------------------------------------------------------------------
DECLARE
  TYPE t_q IS TABLE OF VARCHAR2(20);
  v_q t_q := t_q('job1','job2','job3');  -- starting queue
BEGIN
  LOOP
    EXIT WHEN v_q.COUNT = 0;             -- stop when queue empty
    DBMS_OUTPUT.PUT_LINE('Processing: '||v_q(1));
    v_q.DELETE(1);                       -- consume the head
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('Queue drained.');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 7: Defensive cap against unintended infinite loops
-- Scenario:
--   Demonstrate adding a defensive EXIT WHEN using an iteration counter. This is
--   helpful during early development, when true termination logic isn’t wired yet.
-- Drivers:
--   v_c -> iteration counter
-- Termination:
--   EXIT WHEN v_c >= 2
-- Expected Output:
--   Defensive cap reached at 2
--------------------------------------------------------------------------------
DECLARE
  v_c  PLS_INTEGER := 0;
BEGIN
  LOOP
    v_c := v_c + 1;                -- always progress the driver
    EXIT WHEN v_c >= 2;            -- defensive cap
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('Defensive cap reached at '||v_c);
END;
/
--------------------------------------------------------------------------------
-- End of File
--------------------------------------------------------------------------------
