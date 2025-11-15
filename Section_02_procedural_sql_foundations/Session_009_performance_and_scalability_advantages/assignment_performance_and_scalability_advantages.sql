-- assignment_performance_and_scalability_advantages.sql
-- Session : 009_performance_and_scalability_advantages
-- Topic   : Practice exercises on PL/SQL performance and scalability benefits
-- Purpose : Reinforce key ideas:
--           - Reducing network round-trips
--           - Grouping related work into a single block
--           - Using loops for batch operations
--           - Reusing computed values
--           - Encapsulating logic for reuse
-- Style   : Each assignment has a clear problem statement and a fully
--           commented sample solution so the learner can follow step by step.

SET SERVEROUTPUT ON;



--------------------------------------------------------------------------------
-- Common Setup for Assignments
-- We will use a simple table to practice batch operations and updates.
-- This setup can be run safely multiple times.
--------------------------------------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE s009_assign_accounts';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
/
CREATE TABLE s009_assign_accounts
(
  account_id   NUMBER PRIMARY KEY,
  account_name VARCHAR2(50),
  balance      NUMBER
);
/
--------------------------------------------------------------------------------



/**************************************************************************
 Assignment 1:
 -------------
 Problem:
   1. Insert three rows into s009_assign_accounts in a single PL/SQL block.
   2. Each row should have:
        - a unique account_id,
        - an account_name like 'Account-1', 'Account-2', etc.,
        - an initial balance of 1000.
   3. Print a message indicating that the initialization is complete.
**************************************************************************/
BEGIN
  INSERT INTO s009_assign_accounts (account_id, account_name, balance)
  VALUES (1, 'Account-1', 1000);

  INSERT INTO s009_assign_accounts (account_id, account_name, balance)
  VALUES (2, 'Account-2', 1000);

  INSERT INTO s009_assign_accounts (account_id, account_name, balance)
  VALUES (3, 'Account-3', 1000);

  DBMS_OUTPUT.PUT_LINE('Assignment 1: Inserted 3 starter accounts in one PL/SQL block.');
END;
/
-------------------------------------------------------------------------------



/**************************************************************************
 Assignment 2:
 -------------
 Problem:
   1. Use a FOR loop to insert 5 more accounts with IDs 4 to 8.
   2. The account_name should be 'Loop-Account-' || account_id.
   3. The balance should be 2000 for all these accounts.
   4. Print how many accounts were inserted in the loop.
**************************************************************************/
DECLARE
  v_count_inserted NUMBER := 0;
BEGIN
  FOR v_id IN 4 .. 8 LOOP
    INSERT INTO s009_assign_accounts (account_id, account_name, balance)
    VALUES (v_id, 'Loop-Account-' || TO_CHAR(v_id), 2000);

    v_count_inserted := v_count_inserted + 1;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('Assignment 2: Inserted ' || v_count_inserted || ' accounts using a loop.');
END;
/
-------------------------------------------------------------------------------



/**************************************************************************
 Assignment 3:
 -------------
 Problem:
   1. Declare a constant v_bonus_rate (for example 0.05 = 5 percent).
   2. Apply this bonus to the balance of account_id = 1.
   3. Update the row and print old and new balance.
   4. Emphasize that the constant is used to avoid hard-coding the rate
      in multiple places.
**************************************************************************/
DECLARE
  c_bonus_rate CONSTANT NUMBER := 0.05; -- 5 percent bonus
  v_old_balance NUMBER;
  v_new_balance NUMBER;
BEGIN
  SELECT balance
    INTO v_old_balance
    FROM s009_assign_accounts
   WHERE account_id = 1;

  v_new_balance := v_old_balance * (1 + c_bonus_rate);

  UPDATE s009_assign_accounts
     SET balance = v_new_balance
   WHERE account_id = 1;

  DBMS_OUTPUT.PUT_LINE('Assignment 3: Old balance = ' || v_old_balance);
  DBMS_OUTPUT.PUT_LINE('Assignment 3: New balance = ' || v_new_balance ||
                       ' after applying bonus rate ' || c_bonus_rate);
END;
/
-------------------------------------------------------------------------------



/**************************************************************************
 Assignment 4:
 -------------
 Problem:
   1. Write a PL/SQL block that simulates a small batch of deposits.
   2. For account IDs 1, 2, and 3, add 250 to their balance inside a loop.
   3. Only one PL/SQL block should be used.
   4. Print the final balance of each account after the deposit.
**************************************************************************/
DECLARE
  v_id          NUMBER;
  v_old_balance NUMBER;
  v_new_balance NUMBER;
BEGIN
  FOR v_id IN 1 .. 3 LOOP
    SELECT balance
      INTO v_old_balance
      FROM s009_assign_accounts
     WHERE account_id = v_id;

    v_new_balance := v_old_balance + 250;

    UPDATE s009_assign_accounts
       SET balance = v_new_balance
     WHERE account_id = v_id;

    DBMS_OUTPUT.PUT_LINE(
      'Assignment 4: Account ' || v_id || ' updated from ' ||
      v_old_balance || ' to ' || v_new_balance
    );
  END LOOP;
END;
/
-------------------------------------------------------------------------------



/**************************************************************************
 Assignment 5:
 -------------
 Problem:
   1. Use a SELECT with COUNT(*) to find the total number of accounts.
   2. Store the count in a variable v_account_count.
   3. Reuse v_account_count for printing a status message instead of
      calling COUNT(*) multiple times.
**************************************************************************/
DECLARE
  v_account_count NUMBER;
BEGIN
  SELECT COUNT(*)
    INTO v_account_count
    FROM s009_assign_accounts;

  DBMS_OUTPUT.PUT_LINE('Assignment 5: Total accounts in table = ' || v_account_count);
  DBMS_OUTPUT.PUT_LINE('Assignment 5: No need to recompute COUNT(*); value reused from variable.');
END;
/
-------------------------------------------------------------------------------



/**************************************************************************
 Assignment 6:
 -------------
 Problem:
   1. Create a procedure s009_add_interest that:
        - accepts p_account_id and p_interest_rate parameters,
        - reads existing balance,
        - applies interest,
        - updates the account and prints before and after values.
   2. Then call this procedure for account_id 2 with rate 10 percent.
**************************************************************************/
CREATE OR REPLACE PROCEDURE s009_add_interest
(
  p_account_id    IN NUMBER,
  p_interest_rate IN NUMBER
)
AS
  v_old_balance NUMBER;
  v_new_balance NUMBER;
BEGIN
  SELECT balance
    INTO v_old_balance
    FROM s009_assign_accounts
   WHERE account_id = p_account_id;

  v_new_balance := v_old_balance * (1 + (p_interest_rate / 100));

  UPDATE s009_assign_accounts
     SET balance = v_new_balance
   WHERE account_id = p_account_id;

  DBMS_OUTPUT.PUT_LINE(
    'Assignment 6 procedure: Account ' || p_account_id ||
    ' balance changed from ' || v_old_balance ||
    ' to ' || v_new_balance ||
    ' using interest rate ' || p_interest_rate || '%.'
  );
END s009_add_interest;
/
BEGIN
  DBMS_OUTPUT.PUT_LINE('Assignment 6: Applying 10% interest to account 2...');
  s009_add_interest(p_account_id => 2, p_interest_rate => 10);
END;
/
-------------------------------------------------------------------------------



/**************************************************************************
 Assignment 7:
 -------------
 Problem:
   1. Use a single PL/SQL block to transfer 300 from account_id 1 to
      account_id 3.
   2. Read the starting balances once into variables.
   3. Perform update statements for both accounts.
   4. Print balances before and after the transfer.
**************************************************************************/
DECLARE
  v_from_id       NUMBER := 1;
  v_to_id         NUMBER := 3;
  v_amount        NUMBER := 300;
  v_from_before   NUMBER;
  v_to_before     NUMBER;
  v_from_after    NUMBER;
  v_to_after      NUMBER;
BEGIN
  SELECT balance
    INTO v_from_before
    FROM s009_assign_accounts
   WHERE account_id = v_from_id;

  SELECT balance
    INTO v_to_before
    FROM s009_assign_accounts
   WHERE account_id = v_to_id;

  v_from_after := v_from_before - v_amount;
  v_to_after   := v_to_before + v_amount;

  UPDATE s009_assign_accounts
     SET balance = v_from_after
   WHERE account_id = v_from_id;

  UPDATE s009_assign_accounts
     SET balance = v_to_after
   WHERE account_id = v_to_id;

  DBMS_OUTPUT.PUT_LINE('Assignment 7: Transfer ' || v_amount ||
                       ' from account ' || v_from_id || ' to account ' || v_to_id);
  DBMS_OUTPUT.PUT_LINE('  From-account balance: ' ||
                       v_from_before || ' -> ' || v_from_after);
  DBMS_OUTPUT.PUT_LINE('  To-account balance  : ' ||
                       v_to_before || ' -> ' || v_to_after);
END;
/
-------------------------------------------------------------------------------



/**************************************************************************
 Assignment 8:
 -------------
 Problem:
   1. Use a loop to apply a 2 percent service charge to all accounts whose
      balance is greater than 2500.
   2. For each affected account, reduce the balance and print old and new
      values.
   3. Keep the logic inside a single block.
**************************************************************************/
DECLARE
  CURSOR c_accounts IS
    SELECT account_id, balance
      FROM s009_assign_accounts
     WHERE balance > 2500;

  v_new_balance NUMBER;
BEGIN
  FOR rec IN c_accounts LOOP
    v_new_balance := rec.balance * 0.98; -- apply 2% charge

    UPDATE s009_assign_accounts
       SET balance = v_new_balance
     WHERE account_id = rec.account_id;

    DBMS_OUTPUT.PUT_LINE(
      'Assignment 8: Account ' || rec.account_id ||
      ' balance reduced from ' || rec.balance ||
      ' to ' || v_new_balance ||
      ' due to 2% service charge.'
    );
  END LOOP;
END;
/
-------------------------------------------------------------------------------



/**************************************************************************
 Assignment 9:
 -------------
 Problem:
   1. Calculate total, minimum, maximum, and average balance across all
      accounts.
   2. Store these values in variables.
   3. Print a small summary report using DBMS_OUTPUT.
**************************************************************************/
DECLARE
  v_total_balance NUMBER;
  v_min_balance   NUMBER;
  v_max_balance   NUMBER;
  v_avg_balance   NUMBER;
BEGIN
  SELECT SUM(balance),
         MIN(balance),
         MAX(balance),
         AVG(balance)
    INTO v_total_balance,
         v_min_balance,
         v_max_balance,
         v_avg_balance
    FROM s009_assign_accounts;

  DBMS_OUTPUT.PUT_LINE('Assignment 9: Account balance summary');
  DBMS_OUTPUT.PUT_LINE('  Total balance = ' || v_total_balance);
  DBMS_OUTPUT.PUT_LINE('  Minimum       = ' || v_min_balance);
  DBMS_OUTPUT.PUT_LINE('  Maximum       = ' || v_max_balance);
  DBMS_OUTPUT.PUT_LINE('  Average       = ' || v_avg_balance);
END;
/
-------------------------------------------------------------------------------



/**************************************************************************
 Assignment 10:
 --------------
 Problem:
   1. Write a PL/SQL block that checks if the total balance across all
      accounts is greater than 20000.
   2. If yes, print 'System is healthy from liquidity perspective.'
      Otherwise, print 'System liquidity is low.'
   3. Use a variable to store SUM(balance) and avoid repeating the SUM
      expression.
**************************************************************************/
DECLARE
  v_total_balance NUMBER;
BEGIN
  SELECT SUM(balance)
    INTO v_total_balance
    FROM s009_assign_accounts;

  DBMS_OUTPUT.PUT_LINE('Assignment 10: Total balance across all accounts = ' || v_total_balance);

  IF v_total_balance > 20000 THEN
    DBMS_OUTPUT.PUT_LINE('Assignment 10: System is healthy from liquidity perspective.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Assignment 10: System liquidity is low.');
  END IF;
END;
/
-------------------------------------------------------------------------------
