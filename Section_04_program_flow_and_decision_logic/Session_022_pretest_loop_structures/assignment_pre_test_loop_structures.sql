-- Script: assignment_pre_test_loop_structures.sql
SET SERVEROUTPUT ON;

-- Q1 counter 1..10
-- DECLARE v_i PLS_INTEGER := 1; BEGIN WHILE v_i<=10 LOOP DBMS_OUTPUT.PUT_LINE(v_i); v_i:=v_i+1; END LOOP; END; /

-- Q2 multiples of 3
-- DECLARE v_i PLS_INTEGER := 0; BEGIN WHILE v_i<18 LOOP v_i:=v_i+1; CONTINUE WHEN MOD(v_i,3)<>0; DBMS_OUTPUT.PUT_LINE('3x -> '||v_i); END LOOP; END; /

-- Q3 exit when sum>=25
-- DECLARE v_sum NUMBER := 0; v_i NUMBER := 1; BEGIN WHILE v_sum<25 LOOP v_sum:=v_sum+v_i; v_i:=v_i+1; EXIT WHEN v_sum>=25; END LOOP; DBMS_OUTPUT.PUT_LINE('sum='||v_sum); END; /

-- Q4 guard max iters
-- DECLARE v_go BOOLEAN := TRUE; v_iter PLS_INTEGER := 0; c_max CONSTANT PLS_INTEGER := 6; BEGIN WHILE v_go LOOP v_iter:=v_iter+1; IF v_iter=4 THEN v_go:=FALSE; END IF; IF v_iter>=c_max THEN EXIT; END IF; END LOOP; END; /

-- Q5 null skip + fixed
-- DECLARE v_flag BOOLEAN := NULL; BEGIN WHILE v_flag LOOP DBMS_OUTPUT.PUT_LINE('no'); END LOOP; DBMS_OUTPUT.PUT_LINE('skipped'); END; /
-- DECLARE v_flag BOOLEAN := TRUE; v_n PLS_INTEGER := 0; BEGIN WHILE v_flag LOOP v_n:=v_n+1; IF v_n>=2 THEN v_flag:=FALSE; END IF; END LOOP; DBMS_OUTPUT.PUT_LINE('Iterations='||v_n); END; /

-- Q6 remaining work 5..0
-- DECLARE v_remaining PLS_INTEGER := 5; BEGIN WHILE v_remaining>0 LOOP DBMS_OUTPUT.PUT_LINE('Remaining='||v_remaining); v_remaining:=v_remaining-1; END LOOP; END; /

-- Q7 skip 5,9
-- DECLARE v_i PLS_INTEGER := 0; BEGIN WHILE v_i<12 LOOP v_i:=v_i+1; CONTINUE WHEN v_i IN (5,9); DBMS_OUTPUT.PUT_LINE(v_i); END LOOP; END; /

-- Q8 nested pairs
-- DECLARE i PLS_INTEGER := 1; j PLS_INTEGER; BEGIN WHILE i<=3 LOOP j:=1; WHILE j<=2 LOOP DBMS_OUTPUT.PUT_LINE('('||i||','||j||')'); j:=j+1; END LOOP; i:=i+1; END LOOP; END; /

-- Q9 boolean driver to >=50
-- DECLARE v_run BOOLEAN := TRUE; v_sum NUMBER := 0; v_i NUMBER := 1; BEGIN WHILE v_run LOOP v_sum:=v_sum+v_i; v_i:=v_i+1; IF v_sum>=50 THEN v_run:=FALSE; END IF; END LOOP; DBMS_OUTPUT.PUT_LINE('Sum='||v_sum); END; /

-- Q10 continue + exit
-- DECLARE v_i PLS_INTEGER := 0; BEGIN WHILE v_i<20 LOOP v_i:=v_i+1; CONTINUE WHEN MOD(v_i,4)=0; EXIT WHEN v_i>=11; DBMS_OUTPUT.PUT_LINE('Val='||v_i); END LOOP; END; /
