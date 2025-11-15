-- demo_primitive_and_complex_data_types.sql
-- Session : 016_primitive_and_complex_data_types
-- Topic   : Primitive (scalar) and complex data types in PL/SQL.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Demo 1: Primitive Types - NUMBER, VARCHAR2, DATE, BOOLEAN
--------------------------------------------------------------------------------
DECLARE
  v_id       NUMBER        := 1;
  v_name     VARCHAR2(50)  := 'Primitive Example';
  v_created  DATE          := SYSDATE;
  v_enabled  BOOLEAN       := TRUE;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 1: Primitive types');
  DBMS_OUTPUT.PUT_LINE('  ID      = ' || v_id);
  DBMS_OUTPUT.PUT_LINE('  Name    = ' || v_name);
  DBMS_OUTPUT.PUT_LINE('  Created = ' || TO_CHAR(v_created, 'YYYY-MM-DD HH24:MI:SS'));

  IF v_enabled THEN
    DBMS_OUTPUT.PUT_LINE('  Enabled = YES');
  ELSE
    DBMS_OUTPUT.PUT_LINE('  Enabled = NO');
  END IF;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 2: RECORD Type Based on Table Structure (%ROWTYPE)
--------------------------------------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE s016_demo_projects';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN RAISE; END IF;
END;
/
CREATE TABLE s016_demo_projects
(
  project_id   NUMBER PRIMARY KEY,
  project_name VARCHAR2(100),
  budget       NUMBER(12,2)
);
/
INSERT INTO s016_demo_projects VALUES (1, 'Migration Project', 250000);
COMMIT;
--------------------------------------------------------------------------------
DECLARE
  r_proj s016_demo_projects%ROWTYPE;
BEGIN
  SELECT *
    INTO r_proj
    FROM s016_demo_projects
   WHERE project_id = 1;

  DBMS_OUTPUT.PUT_LINE('Demo 2: RECORD from %ROWTYPE');
  DBMS_OUTPUT.PUT_LINE('  Project ID   = ' || r_proj.project_id);
  DBMS_OUTPUT.PUT_LINE('  Project Name = ' || r_proj.project_name);
  DBMS_OUTPUT.PUT_LINE('  Budget       = ' || r_proj.budget);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 3: User-Defined RECORD Type
--------------------------------------------------------------------------------
DECLARE
  TYPE t_employee IS RECORD
  (
    emp_id   NUMBER,
    emp_name VARCHAR2(50),
    salary   NUMBER
  );

  r_emp t_employee;
BEGIN
  r_emp.emp_id   := 101;
  r_emp.emp_name := 'Record Employee';
  r_emp.salary   := 90000;

  DBMS_OUTPUT.PUT_LINE('Demo 3: User-defined RECORD');
  DBMS_OUTPUT.PUT_LINE('  Emp ID   = ' || r_emp.emp_id);
  DBMS_OUTPUT.PUT_LINE('  Emp Name = ' || r_emp.emp_name);
  DBMS_OUTPUT.PUT_LINE('  Salary   = ' || r_emp.salary);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 4: Associative Array (Index-by Table) for Simple Lookup
--------------------------------------------------------------------------------
DECLARE
  TYPE t_score_tab IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
  v_scores t_score_tab;

  i PLS_INTEGER;
BEGIN
  v_scores(1) := 80;
  v_scores(2) := 90;
  v_scores(3) := 75;

  DBMS_OUTPUT.PUT_LINE('Demo 4: Associative array values');
  i := v_scores.FIRST;
  WHILE i IS NOT NULL LOOP
    DBMS_OUTPUT.PUT_LINE('  Index ' || i || ' => Score ' || v_scores(i));
    i := v_scores.NEXT(i);
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 5: Nested Table for Collection of Strings
--------------------------------------------------------------------------------
DECLARE
  TYPE t_string_list IS TABLE OF VARCHAR2(50);
  v_list t_string_list := t_string_list('Alpha', 'Beta', 'Gamma');

BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 5: Nested table of strings');

  FOR i IN 1 .. v_list.COUNT LOOP
    DBMS_OUTPUT.PUT_LINE('  Element ' || i || ' = ' || v_list(i));
  END LOOP;
END;
/
--------------------------------------------------------------------------------
