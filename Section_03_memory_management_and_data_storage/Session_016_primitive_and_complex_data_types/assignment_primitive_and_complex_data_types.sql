-- assignment_primitive_and_complex_data_types.sql
-- Session : 016_primitive_and_complex_data_types
-- Topic   : Practice - Primitive and Complex Types

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Assignment 1: Basic primitive types example
--------------------------------------------------------------------------------
DECLARE
  v_emp_id   NUMBER       := 200;
  v_emp_name VARCHAR2(50) := 'Primitive Test';
  v_joined   DATE         := DATE '2024-04-01';
BEGIN
  DBMS_OUTPUT.PUT_LINE('A1: Emp ID   = ' || v_emp_id);
  DBMS_OUTPUT.PUT_LINE('A1: Emp Name = ' || v_emp_name);
  DBMS_OUTPUT.PUT_LINE('A1: Joined   = ' || TO_CHAR(v_joined, 'YYYY-MM-DD'));
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 2: BOOLEAN usage for status check
--------------------------------------------------------------------------------
DECLARE
  v_is_active BOOLEAN := TRUE;
BEGIN
  IF v_is_active THEN
    DBMS_OUTPUT.PUT_LINE('A2: Record is active.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('A2: Record is inactive.');
  END IF;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 3: %ROWTYPE record based on table
--------------------------------------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE s016_assign_employees';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN RAISE; END IF;
END;
/
CREATE TABLE s016_assign_employees
(
  emp_id      NUMBER PRIMARY KEY,
  emp_name    VARCHAR2(50),
  department  VARCHAR2(30)
);
/
INSERT INTO s016_assign_employees VALUES (1, 'Avi', 'IT');
INSERT INTO s016_assign_employees VALUES (2, 'John', 'HR');
COMMIT;
--------------------------------------------------------------------------------
DECLARE
  r_emp s016_assign_employees%ROWTYPE;
BEGIN
  SELECT *
    INTO r_emp
    FROM s016_assign_employees
   WHERE emp_id = 1;

  DBMS_OUTPUT.PUT_LINE('A3: Emp ID   = ' || r_emp.emp_id);
  DBMS_OUTPUT.PUT_LINE('A3: Emp Name = ' || r_emp.emp_name);
  DBMS_OUTPUT.PUT_LINE('A3: Dept     = ' || r_emp.department);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 4: User-defined RECORD type for product
--------------------------------------------------------------------------------
DECLARE
  TYPE t_product IS RECORD
  (
    product_id   NUMBER,
    product_name VARCHAR2(50),
    price        NUMBER
  );

  r_prod t_product;
BEGIN
  r_prod.product_id   := 501;
  r_prod.product_name := 'Laptop';
  r_prod.price        := 75000;

  DBMS_OUTPUT.PUT_LINE('A4: Product ID   = ' || r_prod.product_id);
  DBMS_OUTPUT.PUT_LINE('A4: Product Name = ' || r_prod.product_name);
  DBMS_OUTPUT.PUT_LINE('A4: Price        = ' || r_prod.price);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 5: Associative array for storing city codes
--------------------------------------------------------------------------------
DECLARE
  TYPE t_city_tab IS TABLE OF VARCHAR2(30) INDEX BY PLS_INTEGER;
  v_cities t_city_tab;
  i PLS_INTEGER;
BEGIN
  v_cities(1) := 'Bangalore';
  v_cities(2) := 'Chennai';
  v_cities(3) := 'Mumbai';

  i := v_cities.FIRST;
  WHILE i IS NOT NULL LOOP
    DBMS_OUTPUT.PUT_LINE('A5: Index ' || i || ' => City ' || v_cities(i));
    i := v_cities.NEXT(i);
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 6: Nested table of numbers and loop through it
--------------------------------------------------------------------------------
DECLARE
  TYPE t_num_list IS TABLE OF NUMBER;
  v_numbers t_num_list := t_num_list(10, 20, 30, 40);
BEGIN
  FOR i IN 1 .. v_numbers.COUNT LOOP
    DBMS_OUTPUT.PUT_LINE('A6: Element ' || i || ' = ' || v_numbers(i));
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 7: VARRAY type example
--------------------------------------------------------------------------------
DECLARE
  TYPE t_code_array IS VARRAY(3) OF VARCHAR2(10);
  v_codes t_code_array := t_code_array('P1', 'P2', 'P3');
BEGIN
  FOR i IN 1 .. v_codes.COUNT LOOP
    DBMS_OUTPUT.PUT_LINE('A7: Code ' || i || ' = ' || v_codes(i));
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 8: Combination of primitive and complex type
--------------------------------------------------------------------------------
DECLARE
  TYPE t_task IS RECORD
  (
    task_id    NUMBER,
    task_name  VARCHAR2(50),
    done       BOOLEAN
  );

  TYPE t_task_table IS TABLE OF t_task INDEX BY PLS_INTEGER;

  v_tasks t_task_table;
BEGIN
  v_tasks(1).task_id   := 1;
  v_tasks(1).task_name := 'Design';
  v_tasks(1).done      := TRUE;

  v_tasks(2).task_id   := 2;
  v_tasks(2).task_name := 'Coding';
  v_tasks(2).done      := FALSE;

  FOR i IN 1 .. 2 LOOP
    DBMS_OUTPUT.PUT_LINE('A8: Task ' || v_tasks(i).task_id ||
                          ' - ' || v_tasks(i).task_name);
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 9: Record plus nested table usage
--------------------------------------------------------------------------------
DECLARE
  TYPE t_marks IS TABLE OF NUMBER;
  TYPE t_student IS RECORD
  (
    name  VARCHAR2(50),
    marks t_marks
  );

  v_student t_student;
BEGIN
  v_student.name  := 'Student One';
  v_student.marks := t_marks(80, 85, 90);

  DBMS_OUTPUT.PUT_LINE('A9: ' || v_student.name || ' Marks:');
  FOR i IN 1 .. v_student.marks.COUNT LOOP
    DBMS_OUTPUT.PUT_LINE('     ' || v_student.marks(i));
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Assignment 10: Use %ROWTYPE and modify values before update
--------------------------------------------------------------------------------
DECLARE
  r_emp s016_assign_employees%ROWTYPE;
BEGIN
  SELECT *
    INTO r_emp
    FROM s016_assign_employees
   WHERE emp_id = 2;

  r_emp.department := 'ADMIN';

  UPDATE s016_assign_employees
     SET department = r_emp.department
   WHERE emp_id = r_emp.emp_id;

  DBMS_OUTPUT.PUT_LINE('A10: Updated emp_id 2 department to ' || r_emp.department);
END;
/
--------------------------------------------------------------------------------
