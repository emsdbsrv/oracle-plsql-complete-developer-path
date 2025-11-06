-- Script: assignment_conditional_branching_fundamentals.sql
SET SERVEROUTPUT ON;

-- Q1 (age check) Answer:
-- DECLARE v_age NUMBER := 21; BEGIN IF v_age>=18 THEN DBMS_OUTPUT.PUT_LINE('ELIGIBLE'); ELSE DBMS_OUTPUT.PUT_LINE('NOT ELIGIBLE'); END IF; END; /

-- Q2 (temperature) Answer:
-- DECLARE v_t NUMBER := 28; BEGIN IF v_t>=35 THEN DBMS_OUTPUT.PUT_LINE('HOT'); ELSIF v_t>=20 THEN DBMS_OUTPUT.PUT_LINE('WARM'); ELSE DBMS_OUTPUT.PUT_LINE('COLD'); END IF; END; /

-- Q3 (month->name) Answer:
-- DECLARE v_m NUMBER := 11; v_n VARCHAR2(3); BEGIN CASE v_m WHEN 11 THEN v_n:='NOV'; ELSE v_n:='NA'; END CASE; DBMS_OUTPUT.PUT_LINE(v_n); END; /

-- Q4 (amount label) Answer:
-- DECLARE v_amt NUMBER := NULL; v_lab VARCHAR2(10); BEGIN CASE WHEN v_amt IS NULL THEN v_lab:='NA' WHEN v_amt<0 THEN v_lab:='NEG' WHEN v_amt=0 THEN v_lab:='ZERO' WHEN v_amt BETWEEN 1 AND 999 THEN v_lab:='LOW' ELSE v_lab:='HIGH' END CASE; DBMS_OUTPUT.PUT_LINE(v_lab); END; /

-- Q5 (auth) Answer:
-- DECLARE v_balance NUMBER := 1000; v_kyc BOOLEAN := TRUE; BEGIN IF (v_balance>=1000) AND v_kyc THEN DBMS_OUTPUT.PUT_LINE('AUTHORIZED'); ELSE DBMS_OUTPUT.PUT_LINE('DENIED'); END IF; END; /

-- Q6 (NULL flag) Answer:
-- DECLARE v_flag BOOLEAN := NULL; BEGIN IF v_flag IS NULL THEN DBMS_OUTPUT.PUT_LINE('UNKNOWN'); ELSIF v_flag THEN DBMS_OUTPUT.PUT_LINE('YES'); ELSE DBMS_OUTPUT.PUT_LINE('NO'); END IF; END; /

-- Q7 (nested) Answer:
-- DECLARE v_marks NUMBER := 82; BEGIN IF v_marks>=40 THEN IF v_marks>=75 THEN DBMS_OUTPUT.PUT_LINE('PASS (DIST)'); ELSE DBMS_OUTPUT.PUT_LINE('PASS'); END IF; ELSE DBMS_OUTPUT.PUT_LINE('FAIL'); END IF; END; /

-- Q8 (color) Answer:
-- DECLARE v_c VARCHAR2(1) := 'G'; v_out VARCHAR2(10); BEGIN CASE v_c WHEN 'R' THEN v_out:='Red' WHEN 'G' THEN v_out:='Green' WHEN 'B' THEN v_out:='Blue' ELSE v_out:='Unknown' END CASE; DBMS_OUTPUT.PUT_LINE(v_out); END; /

-- Q9 (age category) Answer:
-- DECLARE v_age NUMBER := 60; v_cat VARCHAR2(10); BEGIN CASE WHEN v_age<13 THEN v_cat:='Child' WHEN v_age BETWEEN 13 AND 19 THEN v_cat:='Teen' WHEN v_age BETWEEN 20 AND 59 THEN v_cat:='Adult' ELSE v_cat:='Senior' END CASE; DBMS_OUTPUT.PUT_LINE(v_cat); END; /

-- Q10 (limit check) Answer:
-- DECLARE v_limit NUMBER := 100; v_used NUMBER := 25; BEGIN IF NOT (v_limit>0 AND v_used<v_limit) THEN RAISE_APPLICATION_ERROR(-20001,'Limit check failed'); ELSE DBMS_OUTPUT.PUT_LINE('OK'); END IF; EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Error: '||SQLERRM); END; /
