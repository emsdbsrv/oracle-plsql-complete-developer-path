SET SERVEROUTPUT ON SIZE UNLIMITED;
/*
Assignment: Session 059 - Subprogram Overloading Techniques
Format:
  • 10 tasks with fully commented solutions. Copy, uncomment, run.
Guidance:
  • Prefer thin overloads calling a canonical implementation.
  • Use named notation liberally when defaults are present.
  • Keep SQL-visible functions side-effect free and DETERMINISTIC.
*/

--------------------------------------------------------------------------------
-- Q1 (Arity): Provide 2- and 3-arity overloads that call a 4-arity canonical proc.
-- Answer (commented):
-- CREATE OR REPLACE PACKAGE a1_so AS
--   PROCEDURE run(p_a NUMBER, p_b NUMBER);
--   PROCEDURE run(p_a NUMBER, p_b NUMBER, p_note VARCHAR2);
--   PROCEDURE run(p_a NUMBER, p_b NUMBER, p_note VARCHAR2, p_flag BOOLEAN);
-- END a1_so; /
-- CREATE OR REPLACE PACKAGE BODY a1_so AS
--   PROCEDURE canon(p_a NUMBER, p_b NUMBER, p_note VARCHAR2, p_flag BOOLEAN) IS
--   BEGIN DBMS_OUTPUT.PUT_LINE('a='||p_a||' b='||p_b||' note='||NVL(p_note,'-')||' flag='||CASE WHEN p_flag THEN 'T' ELSE 'F' END); END;
--   PROCEDURE run(p_a NUMBER, p_b NUMBER) IS BEGIN canon(p_a,p_b,NULL,FALSE); END;
--   PROCEDURE run(p_a NUMBER, p_b NUMBER, p_note VARCHAR2) IS BEGIN canon(p_a,p_b,p_note,FALSE); END;
--   PROCEDURE run(p_a NUMBER, p_b NUMBER, p_note VARCHAR2, p_flag BOOLEAN) IS BEGIN canon(p_a,p_b,p_note,p_flag); END;
-- END a1_so; /
-- BEGIN a1_so.run(1,2); a1_so.run(1,2,'x'); a1_so.run(1,2,'x',TRUE); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q2 (Datatype): Overload sum() for NUMBER and PLS_INTEGER; show calls.
-- Answer (commented):
-- CREATE OR REPLACE PACKAGE a2_so AS FUNCTION sum2(a NUMBER, b NUMBER) RETURN NUMBER; FUNCTION sum2(a PLS_INTEGER, b PLS_INTEGER) RETURN PLS_INTEGER; END; /
-- CREATE OR REPLACE PACKAGE BODY a2_so AS FUNCTION sum2(a NUMBER,b NUMBER) RETURN NUMBER IS BEGIN RETURN a+b; END; FUNCTION sum2(a PLS_INTEGER,b PLS_INTEGER) RETURN PLS_INTEGER IS BEGIN RETURN a+b; END; END; /
-- BEGIN DBMS_OUTPUT.PUT_LINE(a2_so.sum2(1,2)); DBMS_OUTPUT.PUT_LINE(a2_so.sum2(PLS_INTEGER(1),PLS_INTEGER(2))); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q3 (Modes): Overload normalize for IN vs IN OUT.
-- Answer (commented):
-- CREATE OR REPLACE PACKAGE a3_so AS PROCEDURE normalize(p IN OUT NOCOPY VARCHAR2); PROCEDURE normalize(p IN VARCHAR2); END; /
-- CREATE OR REPLACE PACKAGE BODY a3_so AS PROCEDURE normalize(p IN OUT NOCOPY VARCHAR2) IS BEGIN p:=TRIM(p); END; PROCEDURE normalize(p IN VARCHAR2) IS BEGIN DBMS_OUTPUT.PUT_LINE('preview='||TRIM(p)); END; END; /
-- DECLARE t VARCHAR2(50):='  x '; BEGIN a3_so.normalize(t); DBMS_OUTPUT.PUT_LINE('t='||t); a3_so.normalize('  y  '); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q4 (Defaults): Show an ambiguous pair and then fix it using named notation or explicit overload.
-- Answer (commented):
-- -- Ambiguous designs should be avoided; demonstrate resolution by adding an explicit overload
-- -- or by using named actuals when calling a wide-arity version.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q5 (Named notation): Call a 4-arity overload but supply only 2 using names (others default).
-- Answer (commented):
-- -- Example: a1_so.run(p_a=>5, p_b=>7); -- remaining defaulted by canonical wrapper
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q6 (SQL visibility): Build two classify() overloads (NUMBER and ID) with DETERMINISTIC.
-- Answer (commented):
-- CREATE OR REPLACE PACKAGE a6_so AS FUNCTION classify(p NUMBER) RETURN VARCHAR2 DETERMINISTIC; FUNCTION classify_by_id(p NUMBER) RETURN VARCHAR2 DETERMINISTIC; END; /
-- CREATE OR REPLACE PACKAGE BODY a6_so AS FUNCTION classify(p NUMBER) RETURN VARCHAR2 IS BEGIN RETURN CASE WHEN p<10 THEN 'LOW' WHEN p<20 THEN 'MID' ELSE 'HIGH' END; END; FUNCTION classify_by_id(p NUMBER) RETURN VARCHAR2 IS BEGIN RETURN classify(p); END; END; /
-- SELECT level AS n, a6_so.classify(level) AS cls FROM dual CONNECT BY level<=5;
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q7 (Numeric precedence): Show that NUMBER + PLS_INTEGER chooses the NUMBER overload.
-- Answer (commented):
-- -- Build a test pair and print which overload fired by emitting a marker message.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q8 (Canonical forwarding): Implement a convenience overload that performs parameter reshaping and forwards.
-- Answer (commented):
-- -- Thin wrapper: converts short form to the canonical long form and delegates.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q9 (Error range): On invalid inputs, raise errors in -21700..-21799; demonstrate two paths.
-- Answer (commented):
-- -- Add validation in your canonical proc and show two distinct codes/messages.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q10 (End-to-end test): Overload a function price_of(p_id) and price_of(p_code VARCHAR2) that both delegate to a canonical lookup by ID.
-- Answer (commented):
-- CREATE OR REPLACE PACKAGE a10_so AS FUNCTION price_of(p_id NUMBER) RETURN NUMBER DETERMINISTIC; FUNCTION price_of(p_code VARCHAR2) RETURN NUMBER DETERMINISTIC; END; /
-- CREATE OR REPLACE PACKAGE BODY a10_so AS FUNCTION price_of(p_id NUMBER) RETURN NUMBER IS BEGIN RETURN p_id*10; END; FUNCTION price_of(p_code VARCHAR2) RETURN NUMBER IS BEGIN RETURN price_of(TO_NUMBER(REGEXP_SUBSTR(p_code,'\d+'))); END; END; /
-- BEGIN DBMS_OUTPUT.PUT_LINE(a10_so.price_of(7)); DBMS_OUTPUT.PUT_LINE(a10_so.price_of('SKU-007')); END; /
--------------------------------------------------------------------------------

-- End of Assignment
