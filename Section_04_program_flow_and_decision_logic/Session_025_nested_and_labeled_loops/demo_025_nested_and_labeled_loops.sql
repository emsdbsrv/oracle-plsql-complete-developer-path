-- demo_025_nested_and_labeled_loops.sql
-- Session : 025_nested_and_labeled_loops
-- Topic   : Nested Loops and Loop Labels
-- Purpose : Show how to control flow in multi-level loops using labels and EXIT.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Demo 1: Simple nested loops (rows and columns)
--------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 1: Nested loops - 3 rows x 4 columns');

  FOR v_row IN 1 .. 3 LOOP
    FOR v_col IN 1 .. 4 LOOP
      DBMS_OUTPUT.PUT_LINE('  Row ' || v_row || ', Col ' || v_col);
    END LOOP;
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 2: Using labels to EXIT only inner loop
--------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 2: Exit only inner loop when col = 2');

  <<outer_loop>>
  FOR v_row IN 1 .. 3 LOOP
    <<inner_loop>>
    FOR v_col IN 1 .. 4 LOOP
      IF v_col = 2 THEN
        DBMS_OUTPUT.PUT_LINE('  Breaking inner loop at row ' ||
                             v_row || ', col ' || v_col);
        EXIT inner_loop;
      END IF;
      DBMS_OUTPUT.PUT_LINE('  Row ' || v_row || ', Col ' || v_col);
    END LOOP inner_loop;
  END LOOP outer_loop;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 3: EXIT outer loop using label
--------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 3: Exit outer loop when row=2 and col=3');

  <<outer_loop>>
  FOR v_row IN 1 .. 3 LOOP
    FOR v_col IN 1 .. 4 LOOP
      IF v_row = 2 AND v_col = 3 THEN
        DBMS_OUTPUT.PUT_LINE('  Condition met at row ' || v_row ||
                             ', col ' || v_col || ' - exiting outer loop.');
        EXIT outer_loop;
      END IF;

      DBMS_OUTPUT.PUT_LINE('  Row ' || v_row || ', Col ' || v_col);
    END LOOP;
  END LOOP outer_loop;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 4: Using labels with LOOP (not FOR)
--------------------------------------------------------------------------------
DECLARE
  v_row NUMBER := 1;
  v_col NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 4: Labeled LOOP with manual counters');

  <<outer_loop>>
  LOOP
    EXIT WHEN v_row > 3;
    v_col := 1;

    <<inner_loop>>
    LOOP
      EXIT WHEN v_col > 3;
      DBMS_OUTPUT.PUT_LINE('  Row ' || v_row || ', Col ' || v_col);

      IF v_row = 3 AND v_col = 2 THEN
        DBMS_OUTPUT.PUT_LINE('  Exiting both loops at row 3, col 2.');
        EXIT outer_loop;
      END IF;

      v_col := v_col + 1;
    END LOOP inner_loop;

    v_row := v_row + 1;
  END LOOP outer_loop;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 5: Nested loops used for generating a small pattern
--------------------------------------------------------------------------------
DECLARE
  v_line VARCHAR2(20);
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 5: Right-angled triangle pattern');

  FOR v_row IN 1 .. 5 LOOP
    v_line := NULL;
    FOR v_col IN 1 .. v_row LOOP
      v_line := v_line || '*';
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('  ' || v_line);
  END LOOP;
END;
/
--------------------------------------------------------------------------------
