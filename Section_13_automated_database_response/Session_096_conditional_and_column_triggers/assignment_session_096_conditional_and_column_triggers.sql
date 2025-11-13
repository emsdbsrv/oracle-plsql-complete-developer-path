SET SERVEROUTPUT ON SIZE UNLIMITED;

--------------------------------------------------------------------------------
-- Assignment – Session 096: Conditional and Column Triggers
-- 10 Questions • Complete answers included as commented solutions.
--------------------------------------------------------------------------------

/*********************************
Q1 AFTER UPDATE – Fire only when name changes.
*********************************/
-- SOLUTION:
-- WHEN (OLD.emp_name <> NEW.emp_name)

/*********************************
Q2 BEFORE UPDATE OF salary – Block salary decrease.
*********************************/
-- SOLUTION:
-- IF :NEW.salary < :OLD.salary THEN
--   RAISE_APPLICATION_ERROR(-36002,'Salary cannot decrease.');
-- END IF;

/*********************************
Q3 AFTER UPDATE – Fire only when dept changes using WHEN.
*********************************/
-- SOLUTION:
-- WHEN (OLD.dept_id <> NEW.dept_id)

/*********************************
Q4 BEFORE UPDATE OF salary – Allow raise only up to 15%.
*********************************/
-- SOLUTION:
-- IF :NEW.salary > :OLD.salary * 1.15 THEN
--   RAISE_APPLICATION_ERROR(-36003,'Raise exceeds 15%.');
-- END IF;

/*********************************
Q5 AFTER INSERT – Notify only if salary > 100000.
*********************************/
-- SOLUTION:
-- WHEN (NEW.salary > 100000)

/*********************************
Q6 BEFORE UPDATE OF dept_id – Block move to dept 30.
*********************************/
-- SOLUTION:
-- IF :NEW.dept_id = 30 THEN
--   RAISE_APPLICATION_ERROR(-36004,'Dept 30 restricted.');
-- END IF;

/*********************************
Q7 AFTER DELETE – Fire only when deleted row belonged to dept 20.
*********************************/
-- SOLUTION:
-- WHEN (OLD.dept_id = 20)

/*********************************
Q8 BEFORE UPDATE – Block change if BOTH name and salary change.
*********************************/
-- SOLUTION:
-- IF (:OLD.emp_name <> :NEW.emp_name) AND (:OLD.salary <> :NEW.salary) THEN
--   RAISE_APPLICATION_ERROR(-36005,'Cannot modify name and salary together.');
-- END IF;

/*********************************
Q9 AFTER INSERT – Fire when dept_id IN (10,20).
*********************************/
-- SOLUTION:
-- WHEN (NEW.dept_id IN (10,20))

/*********************************
Q10 BEFORE UPDATE – Trigger only when salary OR dept changes.
*********************************/
-- SOLUTION:
-- BEFORE UPDATE OF salary, dept_id ON tg_employees
-- FOR EACH ROW
-- BEGIN
--   DBMS_OUTPUT.PUT_LINE('Salary or dept changed.');
-- END;
-- /

--------------------------------------------------------------------------------
-- End of Assignment
--------------------------------------------------------------------------------
