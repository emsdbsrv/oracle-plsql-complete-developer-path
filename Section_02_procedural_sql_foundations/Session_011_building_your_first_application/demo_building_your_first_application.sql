-- demo_building_your_first_application.sql
-- Session : 011_building_your_first_application
-- Topic   : Building Your First PL/SQL Application
-- Purpose : Show how to combine tables + PL/SQL blocks to form a tiny,
--           end-to-end application workflow.
-- Focus   : Table creation, INSERT, UPDATE, DELETE, simple validation,
--           basic reporting using DBMS_OUTPUT.

SET SERVEROUTPUT ON;



--------------------------------------------------------------------------------
-- Demo 0: Clean Up If Rerun
-- Goal:
--   Make the script rerunnable by dropping the demo tables if they exist.
--------------------------------------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE s011_app_customers';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
/
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Demo 1: Create a Simple Table for the Application
-- Goal:
--   Define the core table for our mini-application.
--   We will model a very simple "customers" table.
--------------------------------------------------------------------------------
CREATE TABLE s011_app_customers
(
  customer_id   NUMBER        PRIMARY KEY,
  customer_name VARCHAR2(50)  NOT NULL,
  email         VARCHAR2(100),
  status        VARCHAR2(10)  DEFAULT 'ACTIVE'  -- ACTIVE / INACTIVE
);
/
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Demo 2: Insert Data Using a PL/SQL Block
-- Goal:
--   Insert multiple rows into the application table inside a single
--   PL/SQL block (not just pure SQL). This simulates an application step
--   where an initialization routine loads seed data.
--------------------------------------------------------------------------------
DECLARE
  v_counter NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 2: Inserting initial customers into s011_app_customers.');

  FOR v_counter IN 1 .. 3 LOOP
    INSERT INTO s011_app_customers (customer_id, customer_name, email, status)
    VALUES (
      v_counter,
      'Customer-' || TO_CHAR(v_counter),
      'customer' || TO_CHAR(v_counter) || '@example.com',
      'ACTIVE'
    );
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('Demo 2: Seed data insert completed.');
END;
/
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Demo 3: Simple Business Operation - Update Customer Status
-- Goal:
--   Simulate a small business rule: mark a specific customer as INACTIVE.
--   This could represent actions like "deactivate account" in an app.
--------------------------------------------------------------------------------
DECLARE
  v_target_customer_id NUMBER := 2;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 3: Deactivating customer with ID = ' || v_target_customer_id);

  UPDATE s011_app_customers
     SET status = 'INACTIVE'
   WHERE customer_id = v_target_customer_id;

  DBMS_OUTPUT.PUT_LINE('Demo 3: Customer ' || v_target_customer_id || ' marked as INACTIVE.');
END;
/
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Demo 4: Simple Validation Before Update
-- Goal:
--   Perform a check before applying an operation.
--   If the customer does not exist, print a message instead of updating.
--------------------------------------------------------------------------------
DECLARE
  v_target_customer_id NUMBER := 99; -- deliberately using an ID that does not exist
  v_count              NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 4: Attempting to deactivate customer with ID = ' || v_target_customer_id);

  SELECT COUNT(*)
    INTO v_count
    FROM s011_app_customers
   WHERE customer_id = v_target_customer_id;

  IF v_count = 0 THEN
    DBMS_OUTPUT.PUT_LINE('Demo 4: No such customer found. No update performed.');
  ELSE
    UPDATE s011_app_customers
       SET status = 'INACTIVE'
     WHERE customer_id = v_target_customer_id;

    DBMS_OUTPUT.PUT_LINE('Demo 4: Customer ' || v_target_customer_id || ' deactivated.');
  END IF;
END;
/
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Demo 5: Simple Reporting Block (Application Summary)
-- Goal:
--   Produce a small application-style report using DBMS_OUTPUT.
--   This is a common pattern in early prototypes before a UI exists.
--------------------------------------------------------------------------------
DECLARE
  v_total_customers    NUMBER;
  v_active_customers   NUMBER;
  v_inactive_customers NUMBER;
BEGIN
  SELECT COUNT(*),
         SUM(CASE WHEN status = 'ACTIVE' THEN 1 ELSE 0 END),
         SUM(CASE WHEN status = 'INACTIVE' THEN 1 ELSE 0 END)
    INTO v_total_customers,
         v_active_customers,
         v_inactive_customers
    FROM s011_app_customers;

  DBMS_OUTPUT.PUT_LINE('Demo 5: Customer Summary Report');
  DBMS_OUTPUT.PUT_LINE('  Total customers    = ' || v_total_customers);
  DBMS_OUTPUT.PUT_LINE('  Active customers   = ' || v_active_customers);
  DBMS_OUTPUT.PUT_LINE('  Inactive customers = ' || v_inactive_customers);

  DBMS_OUTPUT.PUT_LINE('Demo 5: End of simple application report.');
END;
/
--------------------------------------------------------------------------------
