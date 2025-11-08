-- Script: plsql_named_procedure_architecture.sql
-- Session: 036 - Named Procedure Architecture
-- Purpose: Compile and run robust named procedures (7 examples).

SET SERVEROUTPUT ON;

BEGIN EXECUTE IMMEDIATE 'DROP TABLE proc_orders PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE TABLE proc_orders (
  order_id NUMBER PRIMARY KEY,
  customer VARCHAR2(50) NOT NULL,
  amount   NUMBER(10,2) NOT NULL,
  status   VARCHAR2(20) DEFAULT 'NEW',
  created_on DATE DEFAULT SYSDATE
);

INSERT INTO proc_orders VALUES (101,'Avi',500,'NEW',SYSDATE-2);
INSERT INTO proc_orders VALUES (102,'Raj',1200,'NEW',SYSDATE-1);
COMMIT;

CREATE OR REPLACE PROCEDURE p_hello IS BEGIN DBMS_OUTPUT.PUT_LINE('p_hello ok'); END p_hello; /
BEGIN p_hello; END; /

CREATE OR REPLACE PROCEDURE p_add_order(p_id IN proc_orders.order_id%TYPE, p_cust IN proc_orders.customer%TYPE, p_amt IN proc_orders.amount%TYPE) IS
BEGIN IF p_amt<=0 THEN RAISE_APPLICATION_ERROR(-20001,'Amount must be > 0'); END IF;
  INSERT INTO proc_orders(order_id,customer,amount,status) VALUES (p_id,p_cust,p_amt,'NEW');
  DBMS_OUTPUT.PUT_LINE('ins rows='||SQL%ROWCOUNT);
EXCEPTION WHEN DUP_VAL_ON_INDEX THEN DBMS_OUTPUT.PUT_LINE('dup id'); RAISE; END p_add_order; /
BEGIN p_add_order(103,'Mani',300); END; /

CREATE OR REPLACE PROCEDURE p_get_total(p_status IN proc_orders.status%TYPE, p_total OUT NUMBER) IS
BEGIN SELECT NVL(SUM(amount),0) INTO p_total FROM proc_orders WHERE status=p_status; END p_get_total; /
DECLARE v NUMBER; BEGIN p_get_total('NEW',v); DBMS_OUTPUT.PUT_LINE('total='||v); END; /

CREATE OR REPLACE PROCEDURE p_apply_discount(p_amt IN OUT NUMBER, p_pct IN NUMBER) IS
BEGIN IF p_pct<0 OR p_pct>50 THEN RAISE_APPLICATION_ERROR(-20002,'range 0..50'); END IF;
  p_amt := ROUND(p_amt*(1-(p_pct/100)),2);
END p_apply_discount; /
DECLARE v NUMBER:=1000; BEGIN p_apply_discount(v,10); DBMS_OUTPUT.PUT_LINE('v='||v); END; /

CREATE OR REPLACE PROCEDURE p_mark_status(p_id IN proc_orders.order_id%TYPE, p_status IN proc_orders.status%TYPE DEFAULT 'APPROVED') IS
BEGIN UPDATE proc_orders SET status=p_status WHERE order_id=p_id; DBMS_OUTPUT.PUT_LINE('upd='||SQL%ROWCOUNT); END p_mark_status; /
BEGIN p_mark_status(101); p_mark_status(102,'CANCELLED'); END; /

CREATE OR REPLACE PROCEDURE p_close_order(p_id IN proc_orders.order_id%TYPE) IS v NUMBER; BEGIN
  SELECT COUNT(*) INTO v FROM proc_orders WHERE order_id=p_id;
  IF v=0 THEN RAISE_APPLICATION_ERROR(-20003,'Missing order'); END IF;
  UPDATE proc_orders SET status='CLOSED' WHERE order_id=p_id AND status<>'CLOSED';
  IF SQL%ROWCOUNT=0 THEN RAISE_APPLICATION_ERROR(-20004,'Already closed'); END IF;
  DBMS_OUTPUT.PUT_LINE('closed '||p_id);
END p_close_order; /
BEGIN p_close_order(103); END; /

BEGIN p_add_order(104,'Neha',700); p_mark_status(104,'APPROVED'); COMMIT; END; /
