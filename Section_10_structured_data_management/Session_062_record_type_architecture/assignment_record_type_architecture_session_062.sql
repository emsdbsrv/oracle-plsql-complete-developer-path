SET SERVEROUTPUT ON SIZE UNLIMITED;
--------------------------------------------------------------------------------
-- Assignment: Session 062 – Record Type Architecture
-- Format:
--   • 10 detailed questions with complete solutions provided as COMMENTED hints.
--   • To run a solution: copy the commented block and remove leading '--'.
-- Guidance:
--   • Choose %ROWTYPE when schema-driven; use custom RECORD for decoupling.
--   • Initialize records explicitly; prefer field-by-field prints for clarity.
--   • Keep IN/OUT/IN OUT intent clear in signatures and comments.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q1 (User-defined record): Create t_emp(id, name, dept) and print values.
-- Answer (commented):
-- DECLARE
--   TYPE t_emp IS RECORD(id NUMBER, name VARCHAR2(30), dept VARCHAR2(30));
--   v t_emp; BEGIN v.id:=1; v.name:='A'; v.dept:='IT';
--   DBMS_OUTPUT.PUT_LINE(v.id||' '||v.name||' '||v.dept); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q2 (%ROWTYPE table): Select * into a rt_customers%ROWTYPE for id=2 and print.
-- Answer (commented):
-- DECLARE r rt_customers%ROWTYPE; BEGIN SELECT * INTO r FROM rt_customers WHERE customer_id=2;
-- DBMS_OUTPUT.PUT_LINE(r.customer_id||' '||r.full_name||' '||NVL(r.email,'-')); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q3 (%ROWTYPE cursor): Define cursor projecting id,name; fetch one row and print.
-- Answer (commented):
-- DECLARE CURSOR c IS SELECT customer_id id, full_name name FROM rt_customers ORDER BY 1;
-- r c%ROWTYPE; BEGIN OPEN c; FETCH c INTO r; CLOSE c; DBMS_OUTPUT.PUT_LINE(r.id||' '||r.name); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q4 (Nested record): Build name(first,last) inside employee record and print full name.
-- Answer (commented):
-- DECLARE TYPE t_name IS RECORD(first VARCHAR2(20), last VARCHAR2(20));
-- TYPE t_emp IS RECORD(id NUMBER, name t_name);
-- v t_emp; BEGIN v.id:=10; v.name.first:='Ria'; v.name.last:='Sharma';
-- DBMS_OUTPUT.PUT_LINE(v.id||' '||v.name.first||' '||v.name.last); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q5 (Assignment): Copy one record to another and verify equality by fields.
-- Answer (commented):
-- DECLARE TYPE t_c IS RECORD(id NUMBER, n VARCHAR2(10));
-- a t_c; b t_c; same BOOLEAN;
-- BEGIN a.id:=1; a.n:='X'; b:=a; same:=(a.id=b.id AND a.n=b.n);
-- DBMS_OUTPUT.PUT_LINE('same='||CASE WHEN same THEN 'TRUE' ELSE 'FALSE' END); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q6 (IN param): Write print_customer(p IN rt_customers%ROWTYPE) and call it for id=1.
-- Answer (commented):
-- DECLARE PROCEDURE print_customer(p IN rt_customers%ROWTYPE) IS BEGIN DBMS_OUTPUT.PUT_LINE(p.customer_id||' '||p.full_name); END;
-- r rt_customers%ROWTYPE; BEGIN SELECT * INTO r FROM rt_customers WHERE customer_id=1; print_customer(r); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q7 (OUT param): Write load_by_id(p_id IN NUMBER, p OUT rt_customers%ROWTYPE) and print.
-- Answer (commented):
-- DECLARE PROCEDURE load_by_id(p_id IN NUMBER, p OUT rt_customers%ROWTYPE) IS BEGIN SELECT * INTO p FROM rt_customers WHERE customer_id=p_id; END;
-- r rt_customers%ROWTYPE; BEGIN load_by_id(3, r); DBMS_OUTPUT.PUT_LINE(r.customer_id||' '||r.full_name||' '||r.is_active); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q8 (IN OUT param): Toggle active flag in a custom record and print before/after.
-- Answer (commented):
-- DECLARE TYPE t_rec IS RECORD(id NUMBER, active CHAR(1)); PROCEDURE flip(p IN OUT t_rec) IS BEGIN p.active:=CASE p.active WHEN 'Y' THEN 'N' ELSE 'Y' END; END;
-- v t_rec; BEGIN v.id:=1; v.active:='N'; DBMS_OUTPUT.PUT_LINE('before='||v.active); flip(v); DBMS_OUTPUT.PUT_LINE('after='||v.active); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q9 (Cursor%ROWTYPE safety): Show that adding a column alias changes record field names.
-- Answer (commented):
-- DECLARE CURSOR c IS SELECT customer_id id_alias, full_name name_alias FROM rt_customers WHERE customer_id=1;
-- r c%ROWTYPE; BEGIN OPEN c; FETCH c INTO r; CLOSE c; DBMS_OUTPUT.PUT_LINE(r.id_alias||' '||r.name_alias); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q10 (Design choice): When to prefer %ROWTYPE vs custom RECORD? Write a brief answer.
-- Answer (commented):
-- -- Prefer %ROWTYPE when you want automatic coupling to a table/cursor shape and less mapping code.
-- -- Prefer custom RECORD when you need decoupling, renamed fields, or a stable API despite schema changes.
--------------------------------------------------------------------------------

-- End of Assignment
