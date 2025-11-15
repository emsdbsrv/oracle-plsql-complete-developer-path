-- demo_lexical_scope_and_block_nesting.sql
-- Session : 015_lexical_scope_and_block_nesting
-- Topic   : Lexical Scope and Block Nesting
-- Purpose : Explain how variables are visible inside/outside nested blocks.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Demo 1: Simple Outer and Inner Block Scope
--------------------------------------------------------------------------------
DECLARE
  v_level VARCHAR2(30) := 'Outer';
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 1: In outer block, v_level = ' || v_level);

  DECLARE
    v_level VARCHAR2(30) := 'Inner';
  BEGIN
    DBMS_OUTPUT.PUT_LINE('Demo 1: In inner block, v_level = ' || v_level);
  END;

  DBMS_OUTPUT.PUT_LINE('Demo 1: After inner block, outer v_level = ' || v_level);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 2: Inner Block Accessing Outer Variables
--------------------------------------------------------------------------------
DECLARE
  v_outer_value NUMBER := 100;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 2: Outer block v_outer_value = ' || v_outer_value);

  DECLARE
    v_inner_value NUMBER := 200;
  BEGIN
    DBMS_OUTPUT.PUT_LINE('Demo 2: Inner block sees v_outer_value = ' || v_outer_value);
    DBMS_OUTPUT.PUT_LINE('Demo 2: Inner block v_inner_value = ' || v_inner_value);
  END;

  DBMS_OUTPUT.PUT_LINE('Demo 2: Outer block cannot see v_inner_value (only v_outer_value).');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 3: Shadowing Variables and Using Labels
--------------------------------------------------------------------------------
DECLARE
  v_data VARCHAR2(30) := 'Outer Data';
BEGIN
  <<outer_block>>
  BEGIN
    DBMS_OUTPUT.PUT_LINE('Demo 3: outer_block v_data = ' || v_data);

    DECLARE
      v_data VARCHAR2(30) := 'Inner Data';
    BEGIN
      DBMS_OUTPUT.PUT_LINE('Demo 3: Inner block v_data = ' || v_data);
      DBMS_OUTPUT.PUT_LINE('Demo 3: Outer v_data still exists but is shadowed here.');
    END;
  END outer_block;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 4: Nested Exception Blocks with Separate Handling
--------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 4: Outer block start.');

  DECLARE
    v_num NUMBER := 10;
  BEGIN
    DBMS_OUTPUT.PUT_LINE('Demo 4: Inner block about to divide by zero.');
    v_num := v_num / 0;
  EXCEPTION
    WHEN ZERO_DIVIDE THEN
      DBMS_OUTPUT.PUT_LINE('Demo 4: Inner block handled ZERO_DIVIDE.');
  END;

  DBMS_OUTPUT.PUT_LINE('Demo 4: Outer block continues after inner exception handling.');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 5: Using Nested Blocks to Limit Variable Lifetime
--------------------------------------------------------------------------------
DECLARE
  v_session_id NUMBER := 999;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 5: Start. Session id = ' || v_session_id);

  DECLARE
    v_temp_calc NUMBER := 0;
  BEGIN
    v_temp_calc := 100 + 50;
    DBMS_OUTPUT.PUT_LINE('Demo 5: v_temp_calc inside inner block = ' || v_temp_calc);
  END;

  DBMS_OUTPUT.PUT_LINE('Demo 5: After inner block, v_temp_calc is no longer accessible.');
END;
/
--------------------------------------------------------------------------------
