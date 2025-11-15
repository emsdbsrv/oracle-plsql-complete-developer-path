-- assignment_024_unconditional_loop_mechanisms.sql
-- Session : 024_unconditional_loop_mechanisms
-- Topic   : Practice - Unconditional LOOP, EXIT, EXIT WHEN

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Assignment 1: Basic LOOP counting 1..5
--------------------------------------------------------------------------------
DECLARE
  v_i NUMBER := 1;
BEGIN
  LOOP
    DBMS_OUTPUT.PUT_LINE('A1: i = ' || v_i);
    v_i := v_i + 1;
    EXIT WHEN v_i > 5;
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 2: LOOP generating multiplication table of 7
--------------------------------------------------------------------------------
DECLARE
  v_i NUMBER := 1;
BEGIN
  LOOP
    DBMS_OUTPUT.PUT_LINE('A2: 7 x ' || v_i || ' = ' || (7 * v_i));
    v_i := v_i + 1;
    EXIT WHEN v_i > 10;
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 3: LOOP to find first multiple of 9 greater than 50
--------------------------------------------------------------------------------
DECLARE
  v_num NUMBER := 1;
BEGIN
  LOOP
    IF v_num > 50 AND MOD(v_num, 9) = 0 THEN
      DBMS_OUTPUT.PUT_LINE('A3: First multiple of 9 > 50 is ' || v_num);
      EXIT;
    END IF;

    v_num := v_num + 1;
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 4: Simulate countdown timer
--------------------------------------------------------------------------------
DECLARE
  v_seconds NUMBER := 5;
BEGIN
  LOOP
    DBMS_OUTPUT.PUT_LINE('A4: Remaining seconds = ' || v_seconds);
    v_seconds := v_seconds - 1;
    EXIT WHEN v_seconds < 0;
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 5: LOOP with input validation style logic (simulated)
--------------------------------------------------------------------------------
DECLARE
  v_value NUMBER := -1;
  v_attempts NUMBER := 0;
BEGIN
  LOOP
    v_attempts := v_attempts + 1;

    IF v_value < 0 THEN
      DBMS_OUTPUT.PUT_LINE('A5: Attempt ' || v_attempts ||
                           ' - invalid value: ' || v_value);
      v_value := 10; -- simulate user re-entering a valid value
    ELSE
      DBMS_OUTPUT.PUT_LINE('A5: Valid value received: ' || v_value);
      EXIT;
    END IF;

    EXIT WHEN v_attempts > 3;
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 6: LOOP accumulating values until sum exceeds 200
--------------------------------------------------------------------------------
DECLARE
  v_sum NUMBER := 0;
  v_i   NUMBER := 20;
BEGIN
  LOOP
    v_sum := v_sum + v_i;
    DBMS_OUTPUT.PUT_LINE('A6: Added ' || v_i || ', Sum = ' || v_sum);

    v_i := v_i + 20;

    EXIT WHEN v_sum > 200;
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 7: LOOP with EXIT WHEN using boolean flag
--------------------------------------------------------------------------------
DECLARE
  v_flag  BOOLEAN := FALSE;
  v_count NUMBER := 0;
BEGIN
  LOOP
    v_count := v_count + 1;
    DBMS_OUTPUT.PUT_LINE('A7: Iteration ' || v_count);

    IF v_count = 4 THEN
      v_flag := TRUE;
    END IF;

    EXIT WHEN v_flag;
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 8: Use LOOP to search in a small array
--------------------------------------------------------------------------------
DECLARE
  TYPE t_num_tab IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
  v_data t_num_tab;
  v_key  NUMBER := 30;
  v_index PLS_INTEGER;
  v_found BOOLEAN := FALSE;
BEGIN
  v_data(1) := 10;
  v_data(2) := 20;
  v_data(3) := 30;
  v_data(4) := 40;

  v_index := v_data.FIRST;
  LOOP
    EXIT WHEN v_index IS NULL;

    IF v_data(v_index) = v_key THEN
      v_found := TRUE;
      EXIT;
    END IF;

    v_index := v_data.NEXT(v_index);
  END LOOP;

  IF v_found THEN
    DBMS_OUTPUT.PUT_LINE('A8: Found key ' || v_key ||
                         ' at index ' || v_index);
  ELSE
    DBMS_OUTPUT.PUT_LINE('A8: Key not found.');
  END IF;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 9: LOOP to simulate retries with max limit
--------------------------------------------------------------------------------
DECLARE
  v_retry NUMBER := 0;
  v_max_retry CONSTANT NUMBER := 3;
BEGIN
  LOOP
    v_retry := v_retry + 1;
    DBMS_OUTPUT.PUT_LINE('A9: Retry attempt ' || v_retry);

    -- simulate success on second attempt
    IF v_retry = 2 THEN
      DBMS_OUTPUT.PUT_LINE('A9: Operation successful.');
      EXIT;
    END IF;

    EXIT WHEN v_retry >= v_max_retry;
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 10: Nested LOOP with EXIT WHEN on inner loop
--------------------------------------------------------------------------------
DECLARE
  v_outer NUMBER := 1;
  v_inner NUMBER;
BEGIN
  LOOP
    EXIT WHEN v_outer > 3;
    DBMS_OUTPUT.PUT_LINE('A10: Outer iteration ' || v_outer);

    v_inner := 1;
    LOOP
      EXIT WHEN v_inner > 2;
      DBMS_OUTPUT.PUT_LINE('      Inner iteration ' || v_inner);
      v_inner := v_inner + 1;
    END LOOP;

    v_outer := v_outer + 1;
  END LOOP;
END;
/
--------------------------------------------------------------------------------
