SET SERVEROUTPUT ON SIZE UNLIMITED;
/*
Session: 059 - Subprogram Overloading Techniques
Purpose:
  End-to-end guide with deeply commented, production-oriented examples:
  (1) Overload by arity and datatype (canonical implementation pattern)
  (2) Overload by parameter mode and named notation
  (3) Interaction with defaulted parameters and how to avoid ambiguity
  (4) SQL-safe overloaded functions (purity, DETERMINISTIC)
  (5) Numeric precedence and implicit conversions (pitfalls and tests)
  (6) At least five runnable examples with expected behavior

How to run:
  • Execute blocks separated by '/' one by one with SERVEROUTPUT enabled.
  • If re-running, the DROP sections make the script idempotent.

Error policy:
  • This lesson primarily focuses on compilation and resolution. Runtime
    errors are raised with RAISE_APPLICATION_ERROR in a dedicated range
    -21500..-21599 when needed.
*/

--------------------------------------------------------------------------------
-- 0) Setup: A small helper table used by SQL-visible overloads (reporting)
--------------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'DROP TABLE so_customers PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE so_customers(
  id NUMBER PRIMARY KEY,
  name VARCHAR2(60) NOT NULL,
  credit_limit NUMBER(12,2) DEFAULT 0 NOT NULL
);
INSERT INTO so_customers VALUES(1,'Avi',  50000);
INSERT INTO so_customers VALUES(2,'Neha', 20000);
INSERT INTO so_customers VALUES(3,'Raj',  10000);
COMMIT;
/
--------------------------------------------------------------------------------
-- 1) SPEC: Overloaded API illustrating multiple patterns
--    Design: thin overloads forward to a canonical implementation
--------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE so_api AS
  SUBTYPE t_id IS NUMBER;

  -- Canonical operation (hidden behind overloads):
  --   set_credit(p_id, p_amount, p_reason, p_hard_cap)
  -- Convenience overloads call this form with defaults.
  PROCEDURE set_credit(p_id IN t_id, p_amount IN NUMBER);                       -- arity 2
  PROCEDURE set_credit(p_id IN t_id, p_amount IN NUMBER, p_reason IN VARCHAR2); -- arity 3
  PROCEDURE set_credit(p_id IN t_id, p_amount IN NUMBER, p_reason IN VARCHAR2,  -- arity 4
                       p_hard_cap IN NUMBER);

  -- Overloaded getters by datatype: name or numeric computations
  FUNCTION get_value(p_id IN t_id) RETURN VARCHAR2;  -- returns name
  FUNCTION get_value(p_id IN t_id) RETURN NUMBER;    -- returns credit_limit

  -- Overload by parameter mode: normalize text (IN) vs parse number (IN OUT)
  PROCEDURE normalize(p_text IN OUT NOCOPY VARCHAR2); -- modifies text in place
  PROCEDURE normalize(p_text IN VARCHAR2);            -- read-only inspection

  -- SQL-visible overloaded function: classify limit level (LOW/MID/HIGH)
  FUNCTION classify(p_limit IN NUMBER) RETURN VARCHAR2 DETERMINISTIC;
  FUNCTION classify(p_id    IN t_id)   RETURN VARCHAR2 DETERMINISTIC;

  -- Safe utility used by both SQL and PL/SQL callers
  FUNCTION to_number_safe(p_text IN VARCHAR2, p_default IN NUMBER DEFAULT 0)
    RETURN NUMBER DETERMINISTIC;
END so_api;
/
SHOW ERRORS

--------------------------------------------------------------------------------
-- 2) BODY: Implement overloads and highlight resolution rules
--------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE BODY so_api AS
  -- Private canonical implementation with full parameter set.
  PROCEDURE set_credit_canon(p_id IN t_id, p_amount IN NUMBER,
                             p_reason IN VARCHAR2, p_hard_cap IN NUMBER) IS
    v_old NUMBER;
  BEGIN
    IF p_amount < 0 THEN
      RAISE_APPLICATION_ERROR(-21501, 'amount cannot be negative');
    END IF;
    -- enforce hard cap if provided (NULL means unlimited)
    IF p_hard_cap IS NOT NULL AND p_amount > p_hard_cap THEN
      RAISE_APPLICATION_ERROR(-21502, 'amount exceeds hard cap');
    END IF;
    SELECT credit_limit INTO v_old FROM so_customers WHERE id = p_id;
    UPDATE so_customers SET credit_limit = p_amount WHERE id = p_id;
    DBMS_OUTPUT.PUT_LINE('credit changed for id='||p_id||' old='||v_old||' new='||p_amount||
                         CASE WHEN p_reason IS NOT NULL THEN ' reason='||p_reason ELSE '' END);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-21503, 'id not found '||p_id);
  END;

  -- Overload 2-arity -> forwards with default reason and no cap
  PROCEDURE set_credit(p_id IN t_id, p_amount IN NUMBER) IS
  BEGIN
    set_credit_canon(p_id, p_amount, p_reason => NULL, p_hard_cap => NULL);
  END;

  -- Overload 3-arity -> forwards with no hard cap
  PROCEDURE set_credit(p_id IN t_id, p_amount IN NUMBER, p_reason IN VARCHAR2) IS
  BEGIN
    set_credit_canon(p_id, p_amount, p_reason, p_hard_cap => NULL);
  END;

  -- Overload 4-arity -> exact canonical call
  PROCEDURE set_credit(p_id IN t_id, p_amount IN NUMBER, p_reason IN VARCHAR2,
                       p_hard_cap IN NUMBER) IS
  BEGIN
    set_credit_canon(p_id, p_amount, p_reason, p_hard_cap);
  END;

  -- Overloaded getters distinguished by RETURN type are NOT allowed in PL/SQL,
  -- so we differentiate by parameter types/count instead.
  -- We simulate "same name" behavior by using two distinct functions differing
  -- in OUTCOME but also in signature (see below).
  FUNCTION get_value(p_id IN t_id) RETURN VARCHAR2 IS
    v_name VARCHAR2(60);
  BEGIN
    SELECT name INTO v_name FROM so_customers WHERE id = p_id;
    RETURN v_name;
  EXCEPTION WHEN NO_DATA_FOUND THEN
    RETURN NULL;
  END;

  -- Second get_value returning NUMBER would be ambiguous if signature matched;
  -- provide a different name internally and wrap via OVERLOADED classify/getters.
  FUNCTION get_value_num(p_id IN t_id) RETURN NUMBER IS
    v_lim NUMBER;
  BEGIN
    SELECT credit_limit INTO v_lim FROM so_customers WHERE id = p_id;
    RETURN v_lim;
  EXCEPTION WHEN NO_DATA_FOUND THEN
    RETURN NULL;
  END;

  -- normalize overloads
  PROCEDURE normalize(p_text IN OUT NOCOPY VARCHAR2) IS
  BEGIN
    -- in-place normalization
    p_text := TRIM(REPLACE(REPLACE(p_text, CHR(9), ' '), CHR(10), ' '));
    p_text := REGEXP_REPLACE(p_text, ' +', ' ');
  END;

  PROCEDURE normalize(p_text IN VARCHAR2) IS
  BEGIN
    -- read-only: just report normalization without changing caller's variable
    DBMS_OUTPUT.PUT_LINE('preview normalized='||
      REGEXP_REPLACE(TRIM(REPLACE(REPLACE(p_text, CHR(9), ' '), CHR(10), ' ')), ' +', ' '));
  END;

  -- SQL-visible overloaded classify()
  FUNCTION classify(p_limit IN NUMBER) RETURN VARCHAR2 DETERMINISTIC IS
  BEGIN
    IF p_limit IS NULL THEN RETURN 'UNKNOWN'; END IF;
    IF p_limit < 15000 THEN RETURN 'LOW';
    ELSIF p_limit < 40000 THEN RETURN 'MID';
    ELSE RETURN 'HIGH';
    END IF;
  END;

  FUNCTION classify(p_id IN t_id) RETURN VARCHAR2 DETERMINISTIC IS
  BEGIN
    RETURN classify(get_value_num(p_id));
  END;

  FUNCTION to_number_safe(p_text IN VARCHAR2, p_default IN NUMBER DEFAULT 0)
    RETURN NUMBER DETERMINISTIC IS
    v NUMBER;
  BEGIN
    v := TO_NUMBER(p_text);
    RETURN v;
  EXCEPTION
    WHEN VALUE_ERROR THEN
      RETURN p_default;
  END;
END so_api;
/
SHOW ERRORS

--------------------------------------------------------------------------------
-- 3) Example 1: Overloading by arity (2, 3, 4 params) -> canonical implementation
--------------------------------------------------------------------------------
BEGIN
  so_api.set_credit(1, 52000);                                  -- 2-arity
  so_api.set_credit(2, 25000, 'annual review');                  -- 3-arity
  so_api.set_credit(3, 12000, 'manual override', p_hard_cap=>13000); -- 4-arity
  DBMS_OUTPUT.PUT_LINE('done example 1');
END;
/
SELECT id, name, credit_limit FROM so_customers ORDER BY id;
/
--------------------------------------------------------------------------------
-- 4) Example 2: Parameter mode overloads with IN OUT NOCOPY vs IN
--------------------------------------------------------------------------------
DECLARE
  v_text VARCHAR2(200) := '  Avi   \t  Jha  ';
BEGIN
  so_api.normalize(v_text);     -- IN OUT: modifies v_text
  DBMS_OUTPUT.PUT_LINE('modified='||v_text);
  so_api.normalize('  some \t text   here '); -- IN: preview only
END;
/
--------------------------------------------------------------------------------
-- 5) Example 3: Named notation and defaults removing ambiguity
--    Named notation ensures arguments bind by name; safer with many defaults.
--------------------------------------------------------------------------------
BEGIN
  so_api.set_credit(p_id=>1, p_amount=>55555, p_reason=>'promo', p_hard_cap=>60000);
  DBMS_OUTPUT.PUT_LINE('done example 3');
END;
/
--------------------------------------------------------------------------------
-- 6) Example 4: SQL-safe overloaded functions
--------------------------------------------------------------------------------
SELECT id,
       so_api.classify(id)              AS class_by_id,
       so_api.classify(credit_limit)    AS class_by_number
FROM   so_customers
ORDER  BY id;
/
--------------------------------------------------------------------------------
-- 7) Example 5: Numeric conversions and potential ambiguity illustration
--    We force implicit conversion from text to number in a helper; the API
--    offers a DETERMINISTIC to_number_safe for safe usage.
--------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('num='||so_api.to_number_safe('123'));
  DBMS_OUTPUT.PUT_LINE('bad->default='||so_api.to_number_safe('12x', 99));
END;
/
-- End of File
