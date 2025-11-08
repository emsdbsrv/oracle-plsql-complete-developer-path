-- Script: assignment_default_parameter_values.sql
-- Session: 041 - DEFAULT Parameter Values
-- Format:
--   • 10 detailed questions with complete solutions provided as COMMENTED hints.
--   • To run a solution: copy the commented block and remove leading '--'.
-- Guidance:
--   • Prefer defaults for optional IN arguments; use named notation to skip.
--   • Use constants/functions (e.g., dp_consts) to centralize defaults.
--   • Avoid ambiguity with overloads by distinct signatures.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Q1 (Basic default): Procedure with p_status defaulting to 'PENDING'.
-- Answer (commented):
-- CREATE OR REPLACE PROCEDURE q1_set_status(p_id IN dp_orders.order_id%TYPE, p_status IN VARCHAR2 := 'PENDING') IS
-- BEGIN UPDATE dp_orders SET status=p_status WHERE order_id=p_id; END; /
-- BEGIN q1_set_status(1); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q2 (Package constant): Default from dp_consts.c_currency.
-- Answer (commented):
-- CREATE OR REPLACE PROCEDURE q2_currency(p_id IN NUMBER, p_curr IN CHAR := dp_consts.c_currency) IS
-- BEGIN DBMS_OUTPUT.PUT_LINE('id='||p_id||' curr='||p_curr); END; /
-- BEGIN q2_currency(1); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q3 (Function default): Use SYSDATE as default timestamp.
-- Answer (commented):
-- CREATE OR REPLACE PROCEDURE q3_stamp(p_when IN DATE := SYSDATE) IS
-- BEGIN DBMS_OUTPUT.PUT_LINE('when='||TO_CHAR(p_when,'YYYY-MM-DD HH24:MI:SS')); END; /
-- BEGIN q3_stamp; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q4 (Number defaults): Tax and discount defaults both 0; compute final price.
-- Answer (commented):
-- CREATE OR REPLACE PROCEDURE q4_price(p_base IN NUMBER, p_tax IN NUMBER := 0, p_disc IN NUMBER := 0) IS
--   v NUMBER(12,2);
-- BEGIN v := ROUND(p_base*(1+NVL(p_tax,0))*(1-NVL(p_disc,0)/100),2);
-- DBMS_OUTPUT.PUT_LINE('price='||TO_CHAR(v,'FM9999999990.00')); END; /
-- BEGIN q4_price(1000); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q5 (BOOLEAN default): Toggle behavior; when TRUE prints 'verbose'.
-- Answer (commented):
-- CREATE OR REPLACE PROCEDURE q5_verbose(p_verbose IN BOOLEAN := TRUE) IS
-- BEGIN IF p_verbose THEN DBMS_OUTPUT.PUT_LINE('verbose'); ELSE DBMS_OUTPUT.PUT_LINE('quiet'); END IF; END; /
-- BEGIN q5_verbose; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q6 (Named notation): Call a 3-arg proc overriding only the last argument.
-- Answer (commented):
-- CREATE OR REPLACE PROCEDURE q6_three(a IN NUMBER, b IN NUMBER := 10, c IN NUMBER := 20) IS
-- BEGIN DBMS_OUTPUT.PUT_LINE('a='||a||' b='||b||' c='||c); END; /
-- BEGIN q6_three(a=>5, c=>99); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q7 (Overload safety): Provide two overloads, one defaulted; show unambiguous call.
-- Answer (commented):
-- CREATE OR REPLACE PACKAGE q7_pkg AS
--   PROCEDURE p(x IN NUMBER := 5);
--   PROCEDURE p(x IN VARCHAR2);
-- END q7_pkg; /
-- CREATE OR REPLACE PACKAGE BODY q7_pkg AS
--   PROCEDURE p(x IN NUMBER) IS BEGIN DBMS_OUTPUT.PUT_LINE('num='||x); END;
--   PROCEDURE p(x IN VARCHAR2) IS BEGIN DBMS_OUTPUT.PUT_LINE('str='||x); END;
-- END q7_pkg; /
-- BEGIN q7_pkg.p(TO_NUMBER('7')); q7_pkg.p('abc'); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q8 (Default middle): Show skipping a middle parameter via named notation.
-- Answer (commented):
-- CREATE OR REPLACE PROCEDURE q8_mid(a IN NUMBER, b IN NUMBER := 2, c IN NUMBER := 3) IS
-- BEGIN DBMS_OUTPUT.PUT_LINE('a='||a||' b='||b||' c='||c); END; /
-- BEGIN q8_mid(a=>1, c=>30); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q9 (Package constant + expression): Default p_note using 'no-note' || TO_CHAR(SYSDATE,'DD-MON').
-- Answer (commented):
-- CREATE OR REPLACE PROCEDURE q9_note(p_note IN VARCHAR2 := 'no-note '||TO_CHAR(SYSDATE,'DD-MON')) IS
-- BEGIN DBMS_OUTPUT.PUT_LINE(p_note); END; /
-- BEGIN q9_note; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q10 (OUT cannot default): Demonstrate correct declaration with OUT lacking default.
-- Answer (commented):
-- CREATE OR REPLACE PROCEDURE q10_ok(p_in IN NUMBER := 1, p_out OUT NUMBER) IS BEGIN p_out := p_in*2; END; /
-- DECLARE v NUMBER; BEGIN q10_ok(p_out=>v); DBMS_OUTPUT.PUT_LINE('v='||v); END; /
--------------------------------------------------------------------------------
-- End of Assignment
--------------------------------------------------------------------------------
