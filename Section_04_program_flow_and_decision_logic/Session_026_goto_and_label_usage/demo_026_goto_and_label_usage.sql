-- demo_026_goto_and_label_usage.sql
-- Session : 026_goto_and_label_usage
-- Topic   : GOTO and Label Usage
-- Purpose : Show how GOTO works, and why it should be used with care.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Demo 1: Basic GOTO jumping to a label
--------------------------------------------------------------------------------
DECLARE
  v_value NUMBER := 10;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 1: Before GOTO');

  GOTO skip_calculation;

  v_value := v_value * 2;
  DBMS_OUTPUT.PUT_LINE('Demo 1: This line is skipped due to GOTO.');

  <<skip_calculation>>
  DBMS_OUTPUT.PUT_LINE('Demo 1: After label. v_value = ' || v_value);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 2: Using GOTO to reuse common cleanup code
--------------------------------------------------------------------------------
DECLARE
  v_status VARCHAR2(20);
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 2: Simulating different exit paths');

  v_status := 'ERROR';
  IF v_status = 'ERROR' THEN
    DBMS_OUTPUT.PUT_LINE('  Error encountered, jumping to cleanup.');
    GOTO do_cleanup;
  END IF;

  DBMS_OUTPUT.PUT_LINE('  Normal processing (this will be skipped).');

  <<do_cleanup>>
  DBMS_OUTPUT.PUT_LINE('  Cleanup logic executed here.');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 3: GOTO inside loops (jumping to label outside loop)
--------------------------------------------------------------------------------
DECLARE
  v_found BOOLEAN := FALSE;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 3: GOTO used to break out of nested loops');

  <<outer_loop>>
  FOR v_i IN 1 .. 3 LOOP
    FOR v_j IN 1 .. 3 LOOP
      DBMS_OUTPUT.PUT_LINE('  Checking i=' || v_i || ', j=' || v_j);

      IF v_i = 2 AND v_j = 2 THEN
        v_found := TRUE;
        GOTO found_label; -- jump outside loops
      END IF;
    END LOOP;
  END LOOP outer_loop;

  <<found_label>>
  IF v_found THEN
    DBMS_OUTPUT.PUT_LINE('  Found match at i=2, j=2, control transferred using GOTO.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('  No match found.');
  END IF;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 4: Demonstrating why excessive GOTO can reduce readability
--------------------------------------------------------------------------------
DECLARE
  v_step NUMBER := 1;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 4: Example showing multiple GOTOs (not recommended)');

  GOTO step2;

  <<step1>>
  DBMS_OUTPUT.PUT_LINE('  At step 1');
  GOTO end_block;

  <<step2>>
  DBMS_OUTPUT.PUT_LINE('  At step 2');
  GOTO step3;

  <<step3>>
  DBMS_OUTPUT.PUT_LINE('  At step 3');
  GOTO end_block;

  <<end_block>>
  DBMS_OUTPUT.PUT_LINE('  End of Demo 4.');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 5: Preferred alternative to GOTO using structured constructs
-- Note:
--   This example does NOT use GOTO. It shows that IF/EXIT and flags usually
--   provide a clearer approach compared to arbitrary GOTO jumps.
--------------------------------------------------------------------------------
DECLARE
  v_found BOOLEAN := FALSE;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 5: Preferred structured way without GOTO');

  FOR v_i IN 1 .. 3 LOOP
    FOR v_j IN 1 .. 3 LOOP
      IF v_i = 3 AND v_j = 1 THEN
        v_found := TRUE;
        DBMS_OUTPUT.PUT_LINE('  Found match at i=3, j=1, exiting loops with flags.');
        EXIT;
      END IF;
    END LOOP;

    IF v_found THEN
      EXIT;
    END IF;
  END LOOP;

  IF v_found THEN
    DBMS_OUTPUT.PUT_LINE('  Processed result after structured exit.');
  END IF;
END;
/
--------------------------------------------------------------------------------
