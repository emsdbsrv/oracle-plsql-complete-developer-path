-- Script: plsql_lexical_scope_and_nesting.sql
-- Session: 015 - Lexical Scope and Block Nesting
-- Purpose : Demonstrate scope rules, shadowing, labels, qualified names, and local subprograms.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Example 1: Basic Outer/Inner Visibility
-- Concept : Inner block sees outer variable when not shadowed.
--------------------------------------------------------------------------------
DECLARE
  v_msg VARCHAR2(40) := 'Hello from OUTER';
BEGIN
  DBMS_OUTPUT.PUT_LINE('Outer sees: ' || v_msg);
  BEGIN
    -- No redeclare here -> inner can read outer v_msg
    DBMS_OUTPUT.PUT_LINE('Inner sees outer: ' || v_msg);
  END;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 2: Shadowing (Name Hiding) in Inner Block
-- Concept : Inner variable with same name hides the outer variable within inner scope.
--------------------------------------------------------------------------------
DECLARE
  v_value NUMBER := 10; -- outer
BEGIN
  DBMS_OUTPUT.PUT_LINE('Outer v_value = ' || v_value); -- 10
  BEGIN
    DECLARE
      v_value NUMBER := 99; -- inner shadows outer
    BEGIN
      DBMS_OUTPUT.PUT_LINE('Inner v_value (shadow) = ' || v_value); -- 99
    END;
  END;
  DBMS_OUTPUT.PUT_LINE('Back to outer v_value = ' || v_value); -- 10
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 3: Block Labels and Qualified References
-- Concept : Use labels to refer to an outer variable explicitly when shadowed.
--------------------------------------------------------------------------------
<<outer_block>>
DECLARE
  v_name VARCHAR2(20) := 'OuterName';
BEGIN
  DBMS_OUTPUT.PUT_LINE('Outer = ' || v_name);
  <<inner_block>>
  DECLARE
    v_name VARCHAR2(20) := 'InnerName'; -- shadows outer
  BEGIN
    DBMS_OUTPUT.PUT_LINE('Inner (shadow) = ' || v_name);
    -- Qualified reference to the outer variable using the label:
    DBMS_OUTPUT.PUT_LINE('Qualified outer = ' || outer_block.v_name);
  END inner_block;
END outer_block;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 4: Local Subprogram Accessing Enclosing Variables
-- Concept : Procedure declared in DECLARE can use enclosing scope variables.
--------------------------------------------------------------------------------
DECLARE
  v_counter NUMBER := 0;
  PROCEDURE inc_counter(p_step NUMBER) IS
  BEGIN
    v_counter := v_counter + p_step; -- uses outer v_counter
  END;
BEGIN
  inc_counter(5);
  inc_counter(7);
  DBMS_OUTPUT.PUT_LINE('v_counter after calls = ' || v_counter); -- 12
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 5: Exception Scope (Inner Handles, Outer Continues)
-- Concept : Inner block handles its own error; execution resumes in outer block.
--------------------------------------------------------------------------------
DECLARE
  v_res NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Outer: before inner.');
  BEGIN
    v_res := 10/0; -- raises ZERO_DIVIDE
  EXCEPTION
    WHEN ZERO_DIVIDE THEN
      DBMS_OUTPUT.PUT_LINE('Inner handled ZERO_DIVIDE.');
  END;
  DBMS_OUTPUT.PUT_LINE('Outer: after inner.');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 6: Exception Propagation (Outer Handles)
-- Concept : Inner does not handle; exception propagates to outer EXCEPTION.
--------------------------------------------------------------------------------
DECLARE
  v_res NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Outer: before inner (no inner handler).');
  BEGIN
    v_res := 10/0; -- raises ZERO_DIVIDE
  END;
  DBMS_OUTPUT.PUT_LINE('This line will not run');
EXCEPTION
  WHEN ZERO_DIVIDE THEN
    DBMS_OUTPUT.PUT_LINE('Outer handled ZERO_DIVIDE from inner.');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 7: Label-Guided Structure with Multiple Nested Levels
-- Concept : Use labels to keep orientation in deep nesting; mix with shadowing carefully.
--------------------------------------------------------------------------------
<<L1>>
DECLARE
  v_id NUMBER := 1;
BEGIN
  DBMS_OUTPUT.PUT_LINE('L1 v_id = ' || v_id);
  <<L2>>
  DECLARE
    v_id NUMBER := 2; -- shadows L1.v_id
  BEGIN
    DBMS_OUTPUT.PUT_LINE('L2 v_id = ' || v_id);
    DBMS_OUTPUT.PUT_LINE('Ref L1.v_id via qualified name = ' || L1.v_id);
    <<L3>>
    DECLARE
      v_id NUMBER := 3; -- shadows L2.v_id
    BEGIN
      DBMS_OUTPUT.PUT_LINE('L3 v_id = ' || v_id);
      DBMS_OUTPUT.PUT_LINE('Ref L2.v_id = ' || L2.v_id || ', Ref L1.v_id = ' || L1.v_id);
    END L3;
  END L2;
END L1;
/
--------------------------------------------------------------------------------
-- End of File
--------------------------------------------------------------------------------
