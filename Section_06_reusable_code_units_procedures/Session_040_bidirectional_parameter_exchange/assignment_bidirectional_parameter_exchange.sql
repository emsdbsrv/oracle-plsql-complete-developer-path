-- Script: assignment_bidirectional_parameter_exchange.sql
-- Session: 040 - Bidirectional Parameter Exchange (IN OUT)
-- Format: 10 questions with commented solutions.

SET SERVEROUTPUT ON;

-- Q1
-- CREATE OR REPLACE PROCEDURE io_round_2(p IN OUT NUMBER) IS BEGIN p := ROUND(p,2); END; /

-- Q2
-- CREATE OR REPLACE PROCEDURE io_apply_tax(p_amt IN OUT NUMBER, p_rate IN NUMBER DEFAULT 0.18) IS
-- BEGIN IF p_rate<0 OR p_rate>1 THEN RAISE_APPLICATION_ERROR(-20560,'invalid rate'); END IF; p_amt := ROUND(p_amt*(1+p_rate),2); END; /

-- Q3
-- CREATE OR REPLACE PROCEDURE io_titlecase_name(p_name IN OUT VARCHAR2) IS
-- BEGIN p_name := INITCAP(TRIM(REGEXP_REPLACE(p_name,'\s+',' '))); IF p_name IS NULL THEN RAISE_APPLICATION_ERROR(-20561,'empty'); END IF; END; /

-- Q4
-- CREATE OR REPLACE PROCEDURE io_cap_discount(p_disc IN OUT NUMBER, p_cap IN NUMBER DEFAULT 50) IS
-- BEGIN p_disc := ROUND(NVL(p_disc,0),2); IF p_disc<0 THEN p_disc:=0; ELSIF p_disc>p_cap THEN p_disc:=p_cap; END IF; END; /

-- Q5
-- CREATE OR REPLACE PROCEDURE io_price_floor(p IN OUT inout_items.price%TYPE, p_floor IN NUMBER DEFAULT 99) IS
-- BEGIN p := ROUND(NVL(p,0),2); IF p < p_floor THEN p := p_floor; END IF; END; /

-- Q6
-- -- Use io_negotiate_price from main script.

-- Q7
-- -- Use io_adjust_item from main script.

-- Q8
-- -- Use io_bump_discount from main script.

-- Q9
-- DECLARE nm VARCHAR2(80):='  abc   pro  '; pr NUMBER:=1000; d NUMBER:=45;
-- BEGIN io_normalize_name(nm); io_cap_discount(d,30); io_apply_discount(pr,d); DBMS_OUTPUT.PUT_LINE(nm||' -> '||pr||' @ '||d||'%'); END; /

-- Q10
-- DECLARE p NUMBER:=500; BEGIN BEGIN io_set_price(-1,p); EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('err='||SQLERRM); END; END; /
