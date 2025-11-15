-- assignment_025_nested_and_labeled_loops.sql
-- Session : 025_nested_and_labeled_loops
-- Topic   : Practice - Nested and Labeled Loops

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Assignment 1: Generate 3 x 3 matrix of numbers
--------------------------------------------------------------------------------
BEGIN
  FOR v_row IN 1 .. 3 LOOP
    FOR v_col IN 1 .. 3 LOOP
      DBMS_OUTPUT.PUT_LINE('A1: Row ' || v_row || ', Col ' || v_col);
    END LOOP;
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 2: Nested loops with inner loop exiting early
--------------------------------------------------------------------------------
BEGIN
  <<outer_loop>>
  FOR v_row IN 1 .. 3 LOOP
    DBMS_OUTPUT.PUT_LINE('A2: Row ' || v_row);
    <<inner_loop>>
    FOR v_col IN 1 .. 5 LOOP
      EXIT inner_loop WHEN v_col > 3;
      DBMS_OUTPUT.PUT_LINE('      Col ' || v_col);
    END LOOP inner_loop;
  END LOOP outer_loop;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 3: Exit outer loop when product of row*col > 8
--------------------------------------------------------------------------------
BEGIN
  <<outer_loop>>
  FOR v_row IN 1 .. 4 LOOP
    FOR v_col IN 1 .. 4 LOOP
      IF v_row * v_col > 8 THEN
        DBMS_OUTPUT.PUT_LINE('A3: Exiting at row ' || v_row ||
                             ', col ' || v_col ||
                             ' because product > 8');
        EXIT outer_loop;
      END IF;

      DBMS_OUTPUT.PUT_LINE('A3: Row ' || v_row || ', Col ' || v_col ||
                           ', Product=' || (v_row * v_col));
    END LOOP;
  END LOOP outer_loop;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 4: Nested loops to print a rectangle of stars
--------------------------------------------------------------------------------
DECLARE
  v_line VARCHAR2(20);
BEGIN
  FOR v_row IN 1 .. 3 LOOP
    v_line := NULL;
    FOR v_col IN 1 .. 5 LOOP
      v_line := v_line || '*';
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('A4: ' || v_line);
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 5: Using labels with LOOP to break out of both levels
--------------------------------------------------------------------------------
DECLARE
  v_row NUMBER := 1;
  v_col NUMBER;
BEGIN
  <<outer_loop>>
  LOOP
    EXIT WHEN v_row > 3;
    v_col := 1;

    LOOP
      EXIT WHEN v_col > 3;
      DBMS_OUTPUT.PUT_LINE('A5: Row ' || v_row || ', Col ' || v_col);

      IF v_row = 2 AND v_col = 2 THEN
        DBMS_OUTPUT.PUT_LINE('A5: Exiting both loops at row 2, col 2.');
        EXIT outer_loop;
      END IF;

      v_col := v_col + 1;
    END LOOP;

    v_row := v_row + 1;
  END LOOP outer_loop;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 6: Nested loops for times table grid (1..3 x 1..3)
--------------------------------------------------------------------------------
BEGIN
  FOR v_row IN 1 .. 3 LOOP
    FOR v_col IN 1 .. 3 LOOP
      DBMS_OUTPUT.PUT_LINE('A6: ' || v_row || ' x ' || v_col ||
                           ' = ' || (v_row * v_col));
    END LOOP;
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 7: Use nested loops to count iterations executed
--------------------------------------------------------------------------------
DECLARE
  v_count NUMBER := 0;
BEGIN
  FOR v_row IN 1 .. 4 LOOP
    FOR v_col IN 1 .. 4 LOOP
      v_count := v_count + 1;
    END LOOP;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('A7: Total iterations = ' || v_count);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 8: Upper-triangular pattern using nested loops
--------------------------------------------------------------------------------
DECLARE
  v_line VARCHAR2(20);
BEGIN
  FOR v_row IN 1 .. 4 LOOP
    v_line := NULL;
    FOR v_col IN v_row .. 4 LOOP
      v_line := v_line || '#';
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('A8: ' || v_line);
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 9: Nested loops with conditional skip using CONTINUE (simulate)
--------------------------------------------------------------------------------
DECLARE
  v_row NUMBER;
  v_col NUMBER;
BEGIN
  FOR v_row IN 1 .. 3 LOOP
    FOR v_col IN 1 .. 3 LOOP
      IF v_row = 2 AND v_col = 2 THEN
        -- simulate CONTINUE by not printing this combination
        NULL;
      ELSE
        DBMS_OUTPUT.PUT_LINE('A9: Row ' || v_row || ', Col ' || v_col);
      END IF;
    END LOOP;
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 10: Labeled nested FOR loops with EXIT inner only
--------------------------------------------------------------------------------
BEGIN
  <<outer_loop>>
  FOR v_row IN 1 .. 3 LOOP
    DBMS_OUTPUT.PUT_LINE('A10: Row ' || v_row);

    <<inner_loop>>
    FOR v_col IN 1 .. 5 LOOP
      IF v_col = 4 THEN
        DBMS_OUTPUT.PUT_LINE('      Inner loop exit at col=4');
        EXIT inner_loop;
      END IF;
      DBMS_OUTPUT.PUT_LINE('      Col ' || v_col);
    END LOOP inner_loop;
  END LOOP outer_loop;
END;
/
--------------------------------------------------------------------------------
