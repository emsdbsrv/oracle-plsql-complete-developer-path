-- assignment_026_goto_and_label_usage.sql
-- Session : 026_goto_and_label_usage
-- Topic   : Practice - GOTO and Label Usage
-- Note    : Use sparingly; prefer structured constructs in real code.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Assignment 1: Simple GOTO to skip a calculation
--------------------------------------------------------------------------------
DECLARE
  v_value NUMBER := 5;
BEGIN
  DBMS_OUTPUT.PUT_LINE('A1: Start');

  GOTO skip;

  v_value := v_value * 10; -- this will be skipped

  <<skip>>
  DBMS_OUTPUT.PUT_LINE('A1: End, v_value = ' || v_value);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 2: Jump to common error handling section
--------------------------------------------------------------------------------
DECLARE
  v_status VARCHAR2(10) := 'FAIL';
BEGIN
  IF v_status = 'FAIL' THEN
    GOTO error_handler;
  END IF;

  DBMS_OUTPUT.PUT_LINE('A2: Normal completion.');
  GOTO done;

  <<error_handler>>
  DBMS_OUTPUT.PUT_LINE('A2: Error handler executed due to FAIL status.');

  <<done>>
  DBMS_OUTPUT.PUT_LINE('A2: End of block.');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 3: Use GOTO to break nested loops
--------------------------------------------------------------------------------
DECLARE
  v_match BOOLEAN := FALSE;
BEGIN
  <<outer_loop>>
  FOR v_i IN 1 .. 5 LOOP
    FOR v_j IN 1 .. 5 LOOP
      IF v_i * v_j = 12 THEN
        v_match := TRUE;
        GOTO finish_search;
      END IF;
    END LOOP;
  END LOOP outer_loop;

  <<finish_search>>
  IF v_match THEN
    DBMS_OUTPUT.PUT_LINE('A3: Found product 12 within nested loops.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('A3: Product 12 not found.');
  END IF;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 4: Demonstrate that code after GOTO is not executed
--------------------------------------------------------------------------------
DECLARE
  v_msg VARCHAR2(50) := 'Initial';
BEGIN
  GOTO label_only;

  v_msg := 'Changed'; -- skipped

  <<label_only>>
  DBMS_OUTPUT.PUT_LINE('A4: Message = ' || v_msg);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 5: Simulate multi-step process with GOTO (not ideal but educational)
--------------------------------------------------------------------------------
DECLARE
  v_step NUMBER := 1;
BEGIN
  <<start>>
  DBMS_OUTPUT.PUT_LINE('A5: Start at step ' || v_step);

  IF v_step = 1 THEN
    v_step := 2;
    GOTO step2;
  END IF;

  <<step2>>
  IF v_step = 2 THEN
    DBMS_OUTPUT.PUT_LINE('A5: Performing step 2 work');
    v_step := 3;
    GOTO step3;
  END IF;

  <<step3>>
  IF v_step = 3 THEN
    DBMS_OUTPUT.PUT_LINE('A5: Performing step 3 work');
  END IF;

  DBMS_OUTPUT.PUT_LINE('A5: End of process');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 6: Compare approach without GOTO (structured exit)
--------------------------------------------------------------------------------
DECLARE
  v_found BOOLEAN := FALSE;
BEGIN
  FOR v_i IN 1 .. 4 LOOP
    FOR v_j IN 1 .. 4 LOOP
      IF v_i + v_j = 5 THEN
        v_found := TRUE;
        EXIT;
      END IF;
    END LOOP;

    IF v_found THEN
      EXIT;
    END IF;
  END LOOP;

  IF v_found THEN
    DBMS_OUTPUT.PUT_LINE('A6: Found pair with sum 5 using structured exit.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('A6: No pair found.');
  END IF;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 7: GOTO to shared logging label
--------------------------------------------------------------------------------
DECLARE
  v_mode VARCHAR2(10) := 'DEBUG';
BEGIN
  IF v_mode = 'DEBUG' THEN
    GOTO log_label;
  END IF;

  DBMS_OUTPUT.PUT_LINE('A7: Non-debug mode logic');

  <<log_label>>
  DBMS_OUTPUT.PUT_LINE('A7: Log entry written for mode = ' || v_mode);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 8: GOTO used to centralize resource release
--------------------------------------------------------------------------------
DECLARE
  v_need_cleanup BOOLEAN := TRUE;
BEGIN
  DBMS_OUTPUT.PUT_LINE('A8: Doing some work');

  IF v_need_cleanup THEN
    GOTO cleanup;
  END IF;

  DBMS_OUTPUT.PUT_LINE('A8: No cleanup required.');
  GOTO end_block;

  <<cleanup>>
  DBMS_OUTPUT.PUT_LINE('A8: Cleanup section executed.');

  <<end_block>>
  DBMS_OUTPUT.PUT_LINE('A8: End.');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 9: Demonstrate potential confusion from multiple GOTOs
--------------------------------------------------------------------------------
DECLARE
  v_state VARCHAR2(10) := 'B';
BEGIN
  IF v_state = 'A' THEN
    GOTO label_a;
  ELSIF v_state = 'B' THEN
    GOTO label_b;
  ELSE
    GOTO label_c;
  END IF;

  <<label_a>>
  DBMS_OUTPUT.PUT_LINE('A9: In state A');
  GOTO end_label;

  <<label_b>>
  DBMS_OUTPUT.PUT_LINE('A9: In state B');
  GOTO end_label;

  <<label_c>>
  DBMS_OUTPUT.PUT_LINE('A9: In state C');

  <<end_label>>
  DBMS_OUTPUT.PUT_LINE('A9: End of state machine.');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 10: Use comment to remind that GOTO is rarely needed
--------------------------------------------------------------------------------
DECLARE
  v_dummy NUMBER := 1;
BEGIN
  -- In real production PL/SQL, prefer IF/LOOP/EXIT rather than GOTO.
  GOTO my_label;

  v_dummy := 2; -- skipped

  <<my_label>>
  DBMS_OUTPUT.PUT_LINE('A10: v_dummy = ' || v_dummy);
END;
/
--------------------------------------------------------------------------------
