-- Script: plsql_pre_test_loop_structures.sql
SET SERVEROUTPUT ON;

-- Example 1: 1..5
DECLARE v_i PLS_INTEGER := 1; BEGIN WHILE v_i<=5 LOOP DBMS_OUTPUT.PUT_LINE('i='||v_i); v_i:=v_i+1; END LOOP; END; /

-- Example 2: CONTINUE WHEN + EXIT WHEN
DECLARE v_i PLS_INTEGER := 0; BEGIN WHILE v_i<10 LOOP v_i:=v_i+1; CONTINUE WHEN MOD(v_i,2)=0; DBMS_OUTPUT.PUT_LINE('Odd -> '||v_i); EXIT WHEN v_i>=7; END LOOP; END; /

-- Example 3: NULL safety (skip) + fixed
DECLARE v_ok BOOLEAN := NULL; BEGIN WHILE v_ok LOOP DBMS_OUTPUT.PUT_LINE('no'); END LOOP; DBMS_OUTPUT.PUT_LINE('Skipped'); END; /
DECLARE v_ok BOOLEAN := TRUE; v_c PLS_INTEGER := 0; BEGIN WHILE v_ok LOOP v_c:=v_c+1; EXIT WHEN v_c>=2; END LOOP; END; /

-- Example 4: Safety cap
DECLARE v_poll BOOLEAN := TRUE; v_i PLS_INTEGER := 0; c_max CONSTANT PLS_INTEGER := 5; BEGIN WHILE v_poll LOOP v_i:=v_i+1; IF v_i=3 THEN v_poll:=FALSE; END IF; IF v_i>=c_max THEN EXIT; END IF; END LOOP; END; /

-- Example 5: Remaining work
DECLARE v_remaining PLS_INTEGER := 3; BEGIN WHILE v_remaining>0 LOOP DBMS_OUTPUT.PUT_LINE('Rem='||v_remaining); v_remaining:=v_remaining-1; END LOOP; END; /

-- Example 6: Dynamic limit
DECLARE v_i PLS_INTEGER := 1; v_limit PLS_INTEGER := 4; BEGIN WHILE v_i<=v_limit LOOP DBMS_OUTPUT.PUT_LINE('i='||v_i); v_i:=v_i+1; END LOOP; END; /
