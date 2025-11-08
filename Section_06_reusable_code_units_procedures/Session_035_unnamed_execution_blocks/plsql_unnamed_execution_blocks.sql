-- Script: plsql_unnamed_execution_blocks.sql
-- Session: 035 - Unnamed Execution Blocks (Anonymous Blocks)
-- Purpose:
--   Seven concise but thorough anonymous block examples with commentary.
-- How to run:
--   SET SERVEROUTPUT ON; Execute each block separately (terminated by '/').

SET SERVEROUTPUT ON;

-- 1) Hello
BEGIN
  DBMS_OUTPUT.PUT_LINE('Hello, PL/SQL');
END;
/
-- 2) Variables
DECLARE
  v_qty PLS_INTEGER := 3; v_price NUMBER(10,2):=199.99; v_total NUMBER(10,2);
BEGIN
  v_total := v_qty*v_price;
  DBMS_OUTPUT.PUT_LINE('total='||v_total);
END;
/
-- 3) Constants/NOT NULL
DECLARE
  c_rate CONSTANT NUMBER := 0.18; v_sub NUMBER:=1000; v_tot NUMBER NOT NULL :=0;
BEGIN
  v_tot := v_sub + v_sub*c_rate; DBMS_OUTPUT.PUT_LINE('total='||v_tot);
END;
/
-- 4) SELECT INTO + exceptions
BEGIN
  DECLARE v_cnt NUMBER; BEGIN SELECT COUNT(*) INTO v_cnt FROM dual; DBMS_OUTPUT.PUT_LINE('dual='||v_cnt);
  EXCEPTION WHEN NO_DATA_FOUND THEN DBMS_OUTPUT.PUT_LINE('no rows'); WHEN TOO_MANY_ROWS THEN DBMS_OUTPUT.PUT_LINE('too many'); END;
END;
/
-- 5) Nested scope
DECLARE v VARCHAR2(10):='outer'; BEGIN
  DBMS_OUTPUT.PUT_LINE('outer='||v);
  DECLARE v VARCHAR2(10):='inner'; BEGIN DBMS_OUTPUT.PUT_LINE('inner='||v); END;
  DBMS_OUTPUT.PUT_LINE('outer again='||v);
END;
/
-- 6) PRAGMA EXCEPTION_INIT mapping
BEGIN
  DECLARE e_dup EXCEPTION; PRAGMA EXCEPTION_INIT(e_dup, -1);
  BEGIN
    EXECUTE IMMEDIATE 'BEGIN EXECUTE IMMEDIATE ''DROP TABLE u_tmp PURGE''; EXCEPTION WHEN OTHERS THEN NULL; END;';
    EXECUTE IMMEDIATE 'CREATE TABLE u_tmp(id NUMBER CONSTRAINT u_tmp_pk PRIMARY KEY)';
    EXECUTE IMMEDIATE 'INSERT INTO u_tmp VALUES (1)';
    EXECUTE IMMEDIATE 'INSERT INTO u_tmp VALUES (1)';
  EXCEPTION WHEN e_dup THEN DBMS_OUTPUT.PUT_LINE('dup key caught'); WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE(SQLERRM); END;
END;
/
-- 7) Simple timing
DECLARE s TIMESTAMP:=SYSTIMESTAMP; e TIMESTAMP; secs NUMBER; BEGIN
  FOR i IN 1..5000 LOOP NULL; END LOOP;
  e:=SYSTIMESTAMP;
  secs := EXTRACT(SECOND FROM (e-s)) + EXTRACT(MINUTE FROM (e-s))*60 + EXTRACT(HOUR FROM (e-s))*3600;
  DBMS_OUTPUT.PUT_LINE('secs='||TO_CHAR(secs,'FM9990D999'));
EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('err='||SQLERRM);
END;
/
