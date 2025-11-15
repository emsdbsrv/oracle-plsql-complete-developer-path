-- demo_021_multicondition_selection_statements.sql
-- Session : 021_multicondition_selection_statements
-- Topic   : Multicondition Selection Statements (CASE, searched CASE)
-- Purpose : Show how CASE can simplify complex IF-ELSIF chains.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Demo 1: Simple CASE expression based on a grade letter
--------------------------------------------------------------------------------
DECLARE
  v_grade CHAR(1) := 'B';
  v_message VARCHAR2(50);
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 1: Simple CASE on grade');
  DBMS_OUTPUT.PUT_LINE('  Grade = ' || v_grade);

  v_message := CASE v_grade
                 WHEN 'A' THEN 'Excellent performance'
                 WHEN 'B' THEN 'Very good performance'
                 WHEN 'C' THEN 'Good performance'
                 ELSE 'Needs improvement'
               END;

  DBMS_OUTPUT.PUT_LINE('  Message = ' || v_message);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 2: Searched CASE with numeric ranges
--------------------------------------------------------------------------------
DECLARE
  v_score NUMBER := 73;
  v_label VARCHAR2(30);
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 2: Searched CASE using ranges');
  DBMS_OUTPUT.PUT_LINE('  Score = ' || v_score);

  v_label := CASE
               WHEN v_score >= 90 THEN 'Outstanding'
               WHEN v_score >= 75 THEN 'Very Good'
               WHEN v_score >= 60 THEN 'Good'
               WHEN v_score >= 50 THEN 'Average'
               ELSE 'Below Average'
             END;

  DBMS_OUTPUT.PUT_LINE('  Label  = ' || v_label);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 3: CASE inside SELECT for derived columns
--------------------------------------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE s021_demo_orders';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN RAISE; END IF;
END;
/
CREATE TABLE s021_demo_orders
(
  order_id   NUMBER PRIMARY KEY,
  amount     NUMBER,
  status     VARCHAR2(10)
);
/
INSERT INTO s021_demo_orders VALUES (1,  800, 'NEW');
INSERT INTO s021_demo_orders VALUES (2, 4200, 'NEW');
INSERT INTO s021_demo_orders VALUES (3, 1500, 'CLOSED');
COMMIT;
--------------------------------------------------------------------------------
DECLARE
  v_discount_label VARCHAR2(20);
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 3: CASE inside SELECT');
  SELECT CASE
           WHEN amount >= 4000 THEN 'High'
           WHEN amount >= 1000 THEN 'Medium'
           ELSE 'Low'
         END
    INTO v_discount_label
    FROM s021_demo_orders
   WHERE order_id = 2;

  DBMS_OUTPUT.PUT_LINE('  Order 2 discount label = ' || v_discount_label);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 4: CASE expression in ORDER BY (concept demonstration)
--------------------------------------------------------------------------------
DECLARE
  CURSOR c_orders IS
    SELECT order_id,
           amount,
           status,
           CASE status
             WHEN 'NEW'    THEN 1
             WHEN 'CLOSED' THEN 2
             ELSE 3
           END AS status_rank
      FROM s021_demo_orders
     ORDER BY status_rank, amount DESC;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 4: CASE used to define sorting priority');

  FOR r IN c_orders LOOP
    DBMS_OUTPUT.PUT_LINE('  Order ' || r.order_id ||
                         ' | Status=' || r.status ||
                         ' | Amount=' || r.amount ||
                         ' | Rank='   || r.status_rank);
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 5: CASE for mapping error codes to messages
--------------------------------------------------------------------------------
DECLARE
  v_error_code NUMBER := 2;
  v_msg        VARCHAR2(100);
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 5: Mapping error codes to text using CASE');

  v_msg := CASE v_error_code
             WHEN 1 THEN 'Invalid input data'
             WHEN 2 THEN 'Record not found'
             WHEN 3 THEN 'Operation not allowed'
             ELSE 'Unknown error'
           END;

  DBMS_OUTPUT.PUT_LINE('  Error code = ' || v_error_code);
  DBMS_OUTPUT.PUT_LINE('  Message    = ' || v_msg);
END;
/
--------------------------------------------------------------------------------
