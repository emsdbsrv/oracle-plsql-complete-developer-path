SET SERVEROUTPUT ON SIZE UNLIMITED;

--------------------------------------------------------------------------------
-- Assignment – Session 087 Trigger Schema Setup Scripts
-- 10 fully commented questions with solutions.
--------------------------------------------------------------------------------

/*********************************
 Q1 – Create tg_products table
*********************************/
-- SOLUTION:
-- CREATE TABLE tg_products(
--   id NUMBER PRIMARY KEY,
--   name VARCHAR2(50),
--   price NUMBER
-- );

/*********************************
 Q2 – Create tg_products_audit table
*********************************/
-- SOLUTION:
-- CREATE TABLE tg_products_audit(
--   audit_id NUMBER,
--   prod_id NUMBER,
--   old_price NUMBER,
--   new_price NUMBER,
--   action_type VARCHAR2(20),
--   action_by VARCHAR2(50),
--   action_date DATE
-- );

/*********************************
 Q3 – Create tg_products_audit_seq
*********************************/
-- SOLUTION:
-- CREATE SEQUENCE tg_products_audit_seq START WITH 1 INCREMENT BY 1;

/*********************************
 Q4 – Insert sample rows
*********************************/
-- SOLUTION:
-- INSERT INTO tg_products VALUES(1,'Pen',10);
-- INSERT INTO tg_products VALUES(2,'Book',50);
-- INSERT INTO tg_products VALUES(3,'Bag',500);
-- COMMIT;

/*********************************
 Q5 – Create tg_products_history
*********************************/
-- SOLUTION:
-- CREATE TABLE tg_products_history(
--   hist_id NUMBER,
--   prod_id NUMBER,
--   old_name VARCHAR2(50),
--   old_price NUMBER,
--   changed_on DATE
-- );

/*********************************
 Q6 – Create tg_products_errorlog
*********************************/
-- SOLUTION:
-- CREATE TABLE tg_products_errorlog(
--   err_id NUMBER,
--   prod_id NUMBER,
--   err_message VARCHAR2(4000),
--   created_on DATE
-- );

/*********************************
 Q7 – Validate tables using COUNT
*********************************/
-- SOLUTION:
-- SELECT COUNT(*) FROM tg_products;
-- SELECT COUNT(*) FROM tg_products_audit;
-- SELECT COUNT(*) FROM tg_products_history;
-- SELECT COUNT(*) FROM tg_products_errorlog;

/*********************************
 Q8 – Create tg_delete_target
*********************************/
-- SOLUTION:
-- CREATE TABLE tg_delete_target(
--   id NUMBER PRIMARY KEY,
--   description VARCHAR2(100)
-- );

/*********************************
 Q9 – Create tg_delete_audit
*********************************/
-- SOLUTION:
-- CREATE TABLE tg_delete_audit(
--   audit_id NUMBER,
--   row_id NUMBER,
--   deletion_date DATE
-- );

/*********************************
 Q10 – Create sequence and seed rows
*********************************/
-- SOLUTION:
-- CREATE SEQUENCE tg_delete_audit_seq START WITH 1;
-- INSERT INTO tg_delete_target VALUES(1,'Sample-1');
-- INSERT INTO tg_delete_target VALUES(2,'Sample-2');
-- COMMIT;

--------------------------------------------------------------------------------
-- End Assignment
--------------------------------------------------------------------------------
