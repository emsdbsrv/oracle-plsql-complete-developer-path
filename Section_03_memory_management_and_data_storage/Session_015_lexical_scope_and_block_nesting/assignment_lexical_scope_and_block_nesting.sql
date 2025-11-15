-- assignment_lexical_scope_and_block_nesting.sql
-- Session : 015_lexical_scope_and_block_nesting
-- Topic   : Practice - Lexical Scope and Block Nesting

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Assignment 1: Show outer variable visible in inner block
--------------------------------------------------------------------------------
DECLARE
  v_message VARCHAR2(40) := 'Outer message';
BEGIN
  DBMS_OUTPUT.PUT_LINE('A1: ' || v_message);

  DECLARE
    v_detail VARCHAR2(40) := 'Inner detail';
  BEGIN
    DBMS_OUTPUT.PUT_LINE('A1 (inner): ' || v_message);
    DBMS_OUTPUT.PUT_LINE('A1 (inner): ' || v_detail);
  END;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 2: Demonstrate variable shadowing
--------------------------------------------------------------------------------
DECLARE
  v_value NUMBER := 10;
BEGIN
  DBMS_OUTPUT.PUT_LINE('A2 outer v_value = ' || v_value);

  DECLARE
    v_value NUMBER := 20;
  BEGIN
    DBMS_OUTPUT.PUT_LINE('A2 inner v_value = ' || v_value);
  END;

  DBMS_OUTPUT.PUT_LINE('A2 outer v_value after inner = ' || v_value);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 3: Nested blocks with separate variables
--------------------------------------------------------------------------------
DECLARE
  v_outer NUMBER := 1;
BEGIN
  DBMS_OUTPUT.PUT_LINE('A3 outer value = ' || v_outer);

  DECLARE
    v_inner NUMBER := 2;
  BEGIN
    DBMS_OUTPUT.PUT_LINE('A3 inner value = ' || v_inner);
  END;

  DBMS_OUTPUT.PUT_LINE('A3 outer value again = ' || v_outer);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 4: Using labels for clarity
--------------------------------------------------------------------------------
DECLARE
  v_text VARCHAR2(30) := 'Outer';
BEGIN
  <<outer_block>>
  BEGIN
    DBMS_OUTPUT.PUT_LINE('A4 outer_block v_text = ' || v_text);

    DECLARE
      v_text VARCHAR2(30) := 'Inner';
    BEGIN
      DBMS_OUTPUT.PUT_LINE('A4 inner block v_text = ' || v_text);
    END;
  END outer_block;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 5: Inner exception block handling error locally
--------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('A5: Outer block start');

  DECLARE
    v_num NUMBER := 5;
  BEGIN
    v_num := v_num / 0; -- raises ZERO_DIVIDE
  EXCEPTION
    WHEN ZERO_DIVIDE THEN
      DBMS_OUTPUT.PUT_LINE('A5: Inner block handled ZERO_DIVIDE');
  END;

  DBMS_OUTPUT.PUT_LINE('A5: Outer block continues normally');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 6: Show that outer exception handles errors not caught inside
--------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('A6: Outer block start');

  DECLARE
    v_num NUMBER := 5;
  BEGIN
    v_num := v_num / 0; -- no exception section here
  END;

  DBMS_OUTPUT.PUT_LINE('A6: This line will not execute');

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('A6: Outer block caught error: ' || SQLERRM);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 7: Variable lifetime limited to inner block
--------------------------------------------------------------------------------
DECLARE
  v_main NUMBER := 100;
BEGIN
  DBMS_OUTPUT.PUT_LINE('A7: v_main = ' || v_main);

  DECLARE
    v_temp NUMBER := 200;
  BEGIN
    DBMS_OUTPUT.PUT_LINE('A7 inner: v_temp = ' || v_temp);
  END;

  DBMS_OUTPUT.PUT_LINE('A7: v_temp not visible here (outer block).');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 8: Reusing variable names in nested scopes for different roles
--------------------------------------------------------------------------------
DECLARE
  v_counter NUMBER := 1;
BEGIN
  DBMS_OUTPUT.PUT_LINE('A8 outer: v_counter = ' || v_counter);

  DECLARE
    v_counter NUMBER := 10;
  BEGIN
    DBMS_OUTPUT.PUT_LINE('A8 inner: v_counter used as local loop counter.');

    FOR i IN 1 .. 3 LOOP
      DBMS_OUTPUT.PUT_LINE('A8 inner loop iteration ' || i ||
                           ', local v_counter = ' || v_counter);
      v_counter := v_counter + 1;
    END LOOP;
  END;

  DBMS_OUTPUT.PUT_LINE('A8 outer: v_counter still = ' || v_counter);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 9: Triple-nested blocks with different variables
--------------------------------------------------------------------------------
DECLARE
  v_level1 NUMBER := 1;
BEGIN
  DBMS_OUTPUT.PUT_LINE('A9: Level 1 value = ' || v_level1);

  DECLARE
    v_level2 NUMBER := 2;
  BEGIN
    DBMS_OUTPUT.PUT_LINE('A9: Level 2 value = ' || v_level2);

    DECLARE
      v_level3 NUMBER := 3;
    BEGIN
      DBMS_OUTPUT.PUT_LINE('A9: Level 3 value = ' || v_level3);
      DBMS_OUTPUT.PUT_LINE('A9: From level 3 we see level1=' ||
                           v_level1 || ', level2=' || v_level2);
    END;
  END;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 10: Nested blocks simulating small workflow stages
--------------------------------------------------------------------------------
DECLARE
  v_status VARCHAR2(20) := 'INIT';
BEGIN
  DBMS_OUTPUT.PUT_LINE('A10: Initial status = ' || v_status);

  DECLARE
    v_status VARCHAR2(20) := 'VALIDATING';
  BEGIN
    DBMS_OUTPUT.PUT_LINE('A10 inner: status = ' || v_status);
  END;

  v_status := 'DONE';
  DBMS_OUTPUT.PUT_LINE('A10 outer: final status = ' || v_status);
END;
/
--------------------------------------------------------------------------------
