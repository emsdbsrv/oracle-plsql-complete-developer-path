-- Script: plsql_data_types_examples.sql
-- Session: 016 - Primitive and Complex Data Types
-- Purpose : Demonstrate PL/SQL scalar and composite data types with examples.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Example 1: Declaring Primitive (Scalar) Variables
-- Concept : Simple variable declarations with initialization and output.
--------------------------------------------------------------------------------
DECLARE
  v_name VARCHAR2(30) := 'Avishesh';
  v_age  NUMBER := 35;
  v_active BOOLEAN := TRUE;
  v_join_date DATE := SYSDATE;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Name: ' || v_name);
  DBMS_OUTPUT.PUT_LINE('Age: ' || v_age);
  DBMS_OUTPUT.PUT_LINE('Active: ' || CASE WHEN v_active THEN 'Yes' ELSE 'No' END);
  DBMS_OUTPUT.PUT_LINE('Join Date: ' || TO_CHAR(v_join_date, 'DD-MON-YYYY'));
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 2: Using Expressions and Type Conversion
-- Concept : Implicit and explicit data conversions.
--------------------------------------------------------------------------------
DECLARE
  v_price NUMBER := 1500.75;
  v_text VARCHAR2(20);
BEGIN
  -- Implicit conversion: NUMBER → VARCHAR2
  v_text := v_price;
  DBMS_OUTPUT.PUT_LINE('Implicit conversion: ' || v_text);

  -- Explicit conversion: VARCHAR2 → NUMBER
  v_price := TO_NUMBER('2000.50');
  DBMS_OUTPUT.PUT_LINE('Explicit conversion: ' || v_price);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 3: Using %TYPE for Consistency with Table Column
-- Concept : Tie variable data type to a column dynamically.
--------------------------------------------------------------------------------
DECLARE
  v_sal employees.salary%TYPE;
BEGIN
  SELECT salary INTO v_sal FROM employees WHERE ROWNUM = 1;
  DBMS_OUTPUT.PUT_LINE('Employee salary = ' || v_sal);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('No employees found.');
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 4: RECORD Type for Structured Data
-- Concept : Group multiple fields into a custom structure.
--------------------------------------------------------------------------------
DECLARE
  TYPE emp_rec IS RECORD (
    id     NUMBER,
    name   VARCHAR2(50),
    salary NUMBER
  );
  v_emp emp_rec;
BEGIN
  v_emp.id := 101;
  v_emp.name := 'John';
  v_emp.salary := 55000;
  DBMS_OUTPUT.PUT_LINE('Employee -> ID: ' || v_emp.id || ', Name: ' || v_emp.name || ', Salary: ' || v_emp.salary);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 5: Nested RECORD and Initialization
-- Concept : RECORD inside RECORD to represent complex structures.
--------------------------------------------------------------------------------
DECLARE
  TYPE dept_rec IS RECORD (
    dept_id NUMBER,
    dept_name VARCHAR2(30)
  );
  TYPE emp_details IS RECORD (
    emp_id NUMBER,
    emp_name VARCHAR2(30),
    department dept_rec
  );
  v_emp emp_details;
BEGIN
  v_emp.emp_id := 201;
  v_emp.emp_name := 'Maria';
  v_emp.department.dept_id := 10;
  v_emp.department.dept_name := 'Finance';

  DBMS_OUTPUT.PUT_LINE('Emp: ' || v_emp.emp_name || ' | Dept: ' || v_emp.department.dept_name);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 6: TABLE and VARRAY (Collections)
-- Concept : Define and use associative arrays and varrays.
--------------------------------------------------------------------------------
DECLARE
  TYPE num_table IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
  TYPE name_varray IS VARRAY(3) OF VARCHAR2(20);

  v_nums num_table;
  v_names name_varray := name_varray('Asha', 'Raj', 'Neha');
BEGIN
  -- Populate associative array
  FOR i IN 1..3 LOOP
    v_nums(i) := i * 100;
  END LOOP;

  -- Print associative array
  FOR i IN 1..3 LOOP
    DBMS_OUTPUT.PUT_LINE('Num[' || i || '] = ' || v_nums(i));
  END LOOP;

  -- Print VARRAY
  FOR i IN 1..v_names.COUNT LOOP
    DBMS_OUTPUT.PUT_LINE('Name[' || i || '] = ' || v_names(i));
  END LOOP;
END;
/
--------------------------------------------------------------------------------
-- End of File
--------------------------------------------------------------------------------
