-- Script: plsql_return_statement_mechanics.sql
-- Session: 043 - RETURN Statement Mechanics
SET SERVEROUTPUT ON;

BEGIN EXECUTE IMMEDIATE 'DROP TABLE rs_orders PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE TABLE rs_orders (
  order_id   NUMBER CONSTRAINT rs_orders_pk PRIMARY KEY,
  cust_name  VARCHAR2(100) NOT NULL,
  amount     NUMBER(12,2)   NOT NULL,
  status     VARCHAR2(20)   DEFAULT 'NEW',
  created_on DATE           DEFAULT SYSDATE
);

INSERT INTO rs_orders VALUES (1,'Avi',  1500.00,'NEW',SYSDATE-2);
INSERT INTO rs_orders VALUES (2,'Neha',  250.00,'PAID',SYSDATE-1);
COMMIT;
/

CREATE OR REPLACE FUNCTION rs_tax(p_amount IN NUMBER) RETURN NUMBER IS
  v_tax NUMBER(12,2);
BEGIN
  v_tax := ROUND(NVL(p_amount,0) * 0.10, 2);
  RETURN v_tax;
END rs_tax;
/

BEGIN DBMS_OUTPUT.PUT_LINE('tax='||rs_tax(1000)); END;
/

CREATE OR REPLACE FUNCTION rs_safe_tax(p_amount IN NUMBER) RETURN NUMBER IS
BEGIN
  IF p_amount IS NULL OR p_amount < 0 THEN
    RETURN 0;
  END IF;
  RETURN ROUND(p_amount * 0.10, 2);
END rs_safe_tax;
/

BEGIN
  DBMS_OUTPUT.PUT_LINE('safe_tax=NULL -> '||rs_safe_tax(NULL));
  DBMS_OUTPUT.PUT_LINE('safe_tax=-5   -> '||rs_safe_tax(-5));
  DBMS_OUTPUT.PUT_LINE('safe_tax=500  -> '||rs_safe_tax(500));
END;
/

CREATE OR REPLACE FUNCTION rs_status_score(p_status IN rs_orders.status%TYPE) RETURN PLS_INTEGER IS
BEGIN
  IF p_status = 'PAID' THEN
    RETURN 100;
  ELSIF p_status = 'NEW' THEN
    RETURN 50;
  ELSE
    RETURN 10;
  END IF;
END rs_status_score;
/

BEGIN
  DBMS_OUTPUT.PUT_LINE('score(PAID)='||rs_status_score('PAID'));
  DBMS_OUTPUT.PUT_LINE('score(NEW)=' ||rs_status_score('NEW'));
  DBMS_OUTPUT.PUT_LINE('score(ETC)=' ||rs_status_score('ETC'));
END;
/

CREATE OR REPLACE FUNCTION rs_amount_or_default(p_order_id IN rs_orders.order_id%TYPE, p_default IN NUMBER := 0)
RETURN NUMBER IS
  v_amount rs_orders.amount%TYPE;
BEGIN
  SELECT amount INTO v_amount FROM rs_orders WHERE order_id = p_order_id;
  RETURN v_amount;
EXCEPTION WHEN NO_DATA_FOUND THEN
  RETURN p_default;
END rs_amount_or_default;
/

BEGIN
  DBMS_OUTPUT.PUT_LINE('amount(1)='||rs_amount_or_default(1, p_default=>-1));
  DBMS_OUTPUT.PUT_LINE('amount(99)='||rs_amount_or_default(99, p_default=>-1));
END;
/

CREATE OR REPLACE FUNCTION rs_payable(p_amount IN rs_orders.amount%TYPE, p_tax_rate IN NUMBER := 0.10, p_disc_pct IN NUMBER := 0)
RETURN rs_orders.amount%TYPE IS
  v_tax   NUMBER(12,2);
  v_disc  NUMBER(12,2);
  v_final NUMBER(12,2);
BEGIN
  v_tax   := ROUND(NVL(p_amount,0) * NVL(p_tax_rate,0), 2);
  v_disc  := ROUND(NVL(p_amount,0) * NVL(p_disc_pct,0) / 100, 2);
  v_final := ROUND(NVL(p_amount,0) + v_tax - v_disc, 2);
  RETURN v_final;
END rs_payable;
/

BEGIN
  DBMS_OUTPUT.PUT_LINE('payable='||rs_payable(1000, p_tax_rate=>0.18, p_disc_pct=>5));
END;
/

CREATE OR REPLACE FUNCTION rs_inner_guard(p_flag IN BOOLEAN) RETURN VARCHAR2 IS
  v_msg VARCHAR2(50);
BEGIN
  v_msg := 'start';
  DECLARE
    v_inner VARCHAR2(50) := 'inner-work';
  BEGIN
    IF p_flag THEN
      RETURN 'early-exit';
    END IF;
    v_msg := v_inner;
  END;
  RETURN v_msg;
END rs_inner_guard;
/

BEGIN
  DBMS_OUTPUT.PUT_LINE('inner_guard(TRUE)='||rs_inner_guard(TRUE));
  DBMS_OUTPUT.PUT_LINE('inner_guard(FALSE)='||rs_inner_guard(FALSE));
END;
/

CREATE OR REPLACE PROCEDURE rs_procedure_example(p_quit IN BOOLEAN) IS
BEGIN
  IF p_quit THEN
    RETURN;
  END IF;
  DBMS_OUTPUT.PUT_LINE('work finished');
END rs_procedure_example;
/

BEGIN
  rs_procedure_example(TRUE);
  rs_procedure_example(FALSE);
END;
/
