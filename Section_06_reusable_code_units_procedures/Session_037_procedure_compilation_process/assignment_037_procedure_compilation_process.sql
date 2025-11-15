-- assignment_037_procedure_compilation_process.sql
-- Session 037: Assignments - Procedure Compilation

SET SERVEROUTPUT ON;

-------------------------------------------------------------------------------
-- A1: Create a simple procedure a37_ping and execute it
-------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE a37_ping
IS
BEGIN
  DBMS_OUTPUT.PUT_LINE('A1: a37_ping executed successfully.');
END a37_ping;
/
BEGIN
  a37_ping;
END;
/
-------------------------------------------------------------------------------
-- A2: Intentionally create a procedure with syntax error and inspect USER_ERRORS
-------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE a37_broken_proc
IS
BEGIN
  DBMS_OUTPUT.PUT_LINE('Missing semicolon')  -- error here
END a37_broken_proc;
/
BEGIN
  DBMS_OUTPUT.PUT_LINE('A2: USER_ERRORS for A37_BROKEN_PROC');
  FOR r IN (
    SELECT line, position, text
      FROM user_errors
     WHERE name = 'A37_BROKEN_PROC'
     ORDER BY sequence
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('  line ' || r.line || ':' || r.position ||
                         ' -> ' || r.text);
  END LOOP;
END;
/
-------------------------------------------------------------------------------
-- A3: Fix a37_broken_proc and confirm zero errors in USER_ERRORS
-------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE a37_broken_proc
IS
BEGIN
  DBMS_OUTPUT.PUT_LINE('A3: a37_broken_proc fixed and running.');
END a37_broken_proc;
/
BEGIN
  a37_broken_proc;

  DBMS_OUTPUT.PUT_LINE('A3: Checking for remaining errors (should be none).');
  FOR r IN (
    SELECT line, position, text
      FROM user_errors
     WHERE name = 'A37_BROKEN_PROC'
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('  ERROR still exists: ' || r.text);
  END LOOP;
END;
/
-------------------------------------------------------------------------------
-- A4: Create a pair of dependent procedures and call the top-level
-------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE a37_child
IS
BEGIN
  DBMS_OUTPUT.PUT_LINE('A4: a37_child executed.');
END a37_child;
/
CREATE OR REPLACE PROCEDURE a37_parent
IS
BEGIN
  DBMS_OUTPUT.PUT_LINE('A4: a37_parent calling child...');
  a37_child;
END a37_parent;
/
BEGIN
  a37_parent;
END;
/
-------------------------------------------------------------------------------
-- A5: Use ALTER PROCEDURE to recompile a37_parent
-------------------------------------------------------------------------------
ALTER PROCEDURE a37_parent COMPILE;
BEGIN
  DBMS_OUTPUT.PUT_LINE('A5: After ALTER, calling a37_parent again:');
  a37_parent;
END;
/
-------------------------------------------------------------------------------
-- A6: Introduce an invalid reference in a37_child and see how it affects parent
-------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE a37_child
IS
  v_dummy NUMBER;
BEGIN
  -- invalid column to create a compile error
  SELECT dummy_column INTO v_dummy FROM dual;
END a37_child;
/
BEGIN
  DBMS_OUTPUT.PUT_LINE('A6: Errors for A37_CHILD:');
  FOR r IN (
    SELECT line, position, text
      FROM user_errors
     WHERE name = 'A37_CHILD'
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('  ' || r.text);
  END LOOP;
END;
/
-------------------------------------------------------------------------------
-- A7: Fix a37_child and recompile a37_parent and a37_child
-------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE a37_child
IS
BEGIN
  DBMS_OUTPUT.PUT_LINE('A7: a37_child fixed and running.');
END a37_child;
/
ALTER PROCEDURE a37_child COMPILE;
ALTER PROCEDURE a37_parent COMPILE;

BEGIN
  a37_parent;
END;
/
-------------------------------------------------------------------------------
-- A8: Create a procedure that fails only at runtime (ZERO_DIVIDE) and handle it
-------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE a37_runtime_issue
IS
  v_num NUMBER := 10;
  v_den NUMBER := 0;
  v_res NUMBER;
BEGIN
  v_res := v_num / v_den;
  DBMS_OUTPUT.PUT_LINE('A8: result = ' || v_res);
EXCEPTION
  WHEN ZERO_DIVIDE THEN
    DBMS_OUTPUT.PUT_LINE('A8: ZERO_DIVIDE caught inside procedure.');
END a37_runtime_issue;
/
BEGIN
  a37_runtime_issue;
END;
/
-------------------------------------------------------------------------------
-- A9: Query USER_OBJECTS to list all procedures created in this session prefix a37
-------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('A9: Listing procedures with name like ''A37_%''');
  FOR r IN (
    SELECT object_name, status
      FROM user_objects
     WHERE object_type = 'PROCEDURE'
       AND object_name LIKE 'A37_%'
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('  ' || r.object_name || ' - ' || r.status);
  END LOOP;
END;
/
-------------------------------------------------------------------------------
-- A10: Practice manual recompilation of all A37 procedures
-------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('A10: Manually recompiling A37% procedures');
  FOR r IN (
    SELECT object_name
      FROM user_objects
     WHERE object_type = 'PROCEDURE'
       AND object_name LIKE 'A37_%'
  ) LOOP
    EXECUTE IMMEDIATE 'ALTER PROCEDURE ' || r.object_name || ' COMPILE';
    DBMS_OUTPUT.PUT_LINE('  Recompiled ' || r.object_name);
  END LOOP;
END;
/
-------------------------------------------------------------------------------
-- End of assignment_037_procedure_compilation_process.sql
-------------------------------------------------------------------------------
