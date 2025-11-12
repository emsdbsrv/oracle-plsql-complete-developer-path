SET SERVEROUTPUT ON SIZE UNLIMITED;
--------------------------------------------------------------------------------
-- Session: 059 – Subprogram Overloading Techniques
-- Topic: Designing clean, predictable overloads for maintainable PL/SQL APIs.
--
-- Purpose:
--   (1) Build a compact, orthogonal overload set
--   (2) Show arity-, type-, and subtype-based separation
--   (3) Demonstrate named/positional/mixed calls and default interactions
--   (4) Prevent ambiguity with careful signature design
--   (5) Provide ≥ 5 worked examples with expected outputs
--
-- How to Run:
--   • Execute each block (terminated by '/') one at a time.
--   • Ensure SERVEROUTPUT is ON to see explanations.
--
-- Notes:
--   • Oracle resolves overloads by parameter count (arity), then by type,
--     preferring exact matches over convertible ones. Defaults are applied
--     AFTER candidate selection. Named notation must still be unambiguous.
--   • Use subtypes (e.g., PLS_INTEGER) to steer resolution when helpful.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 0) Cleanup (idempotent): drop prior package if this is a re-run
--------------------------------------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE 'DROP PACKAGE math_ops_pkg';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1) Package SPEC: math_ops_pkg — public overload set
--    Design choices:
--      • Canonical function: sum_list(NUMBER_TAB [, p_multiply])
--      • Overloads (arity/type based): (NUMBER, NUMBER), (PLS_INTEGER, PLS_INTEGER),
--        (VARCHAR2 CSV parser), and sum3(NUMBER, NUMBER, NUMBER)
--      • p_multiply defaults to 1, applied after overload selection
--      • Subtypes ensure PLS_INTEGER overload is chosen when possible
--------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE math_ops_pkg AS
  -- Subtypes to steer resolution
  SUBTYPE t_int IS PLS_INTEGER;  -- more specific than NUMBER
  SUBTYPE t_num IS NUMBER;

  -- Collection type for list-based sum
  TYPE t_num_tab IS TABLE OF NUMBER;

  -- Canonical: sum a list (preferred entrypoint used by thin wrappers)
  FUNCTION sum_list(p_vals IN t_num_tab, p_multiply IN NUMBER DEFAULT 1)
    RETURN NUMBER;

  -- Overloads (arity/type based)
  FUNCTION sum_vals(p_a IN t_num, p_b IN t_num, p_multiply IN NUMBER DEFAULT 1)
    RETURN NUMBER;
  FUNCTION sum_vals(p_a IN t_int, p_b IN t_int, p_multiply IN NUMBER DEFAULT 1)
    RETURN NUMBER;

  -- Parse-and-sum overload: accepts a CSV string like '10,20,30'
  FUNCTION sum_vals(p_csv IN VARCHAR2, p_multiply IN NUMBER DEFAULT 1)
    RETURN NUMBER;

  -- Named example: accept three values with an optional multiplier
  FUNCTION sum3(p_a IN t_num, p_b IN t_num, p_c IN t_num, p_multiply IN NUMBER DEFAULT 1)
    RETURN NUMBER;

  -- Introspection helper
  FUNCTION version RETURN VARCHAR2;
END math_ops_pkg;
/
SHOW ERRORS
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 2) Package BODY: math_ops_pkg
--    Implementation notes:
--      • Canonical routine: sum_list(…) – all others reuse its logic or parallel it
--      • CSV overload parses safely and raises a clear error on bad tokens
--      • Subtype overload (PLS_INTEGER) remains behaviorally identical but can be
--        chosen preferentially during resolution
--------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE BODY math_ops_pkg AS
  g_version CONSTANT VARCHAR2(10) := '1.0.0';

  FUNCTION version RETURN VARCHAR2 IS
  BEGIN
    RETURN g_version;
  END;

  FUNCTION sum_list(p_vals IN t_num_tab, p_multiply IN NUMBER DEFAULT 1)
    RETURN NUMBER
  IS
    v_sum NUMBER := 0;
  BEGIN
    -- Accumulate, treating NULL as 0 to be forgiving to callers
    IF p_vals IS NOT NULL THEN
      FOR i IN 1 .. p_vals.COUNT LOOP
        v_sum := v_sum + NVL(p_vals(i), 0);
      END LOOP;
    END IF;
    RETURN v_sum * NVL(p_multiply, 1);
  END;

  FUNCTION sum_vals(p_a IN t_num, p_b IN t_num, p_multiply IN NUMBER DEFAULT 1)
    RETURN NUMBER
  IS
  BEGIN
    -- NUMBER, NUMBER overload (generic)
    RETURN (NVL(p_a,0) + NVL(p_b,0)) * NVL(p_multiply,1);
  END;

  FUNCTION sum_vals(p_a IN t_int, p_b IN t_int, p_multiply IN NUMBER DEFAULT 1)
    RETURN NUMBER
  IS
  BEGIN
    -- PLS_INTEGER, PLS_INTEGER overload (preferred when exact match)
    RETURN (NVL(p_a,0) + NVL(p_b,0)) * NVL(p_multiply,1);
  END;

  FUNCTION sum_vals(p_csv IN VARCHAR2, p_multiply IN NUMBER DEFAULT 1)
    RETURN NUMBER
  IS
    v_sum NUMBER := 0;
    v_str VARCHAR2(32767) := NVL(p_csv, '');
    v_pos PLS_INTEGER;
    v_tok VARCHAR2(4000);
  BEGIN
    -- Simple streaming CSV parser: split on ',' and TO_NUMBER each token
    LOOP
      v_pos := INSTR(v_str, ',');
      IF v_pos = 0 THEN
        v_tok := v_str;
      ELSE
        v_tok := SUBSTR(v_str, 1, v_pos-1);
      END IF;

      IF TRIM(v_tok) IS NOT NULL THEN
        v_sum := v_sum + TO_NUMBER(TRIM(v_tok));
      END IF;

      EXIT WHEN v_pos = 0;
      v_str := SUBSTR(v_str, v_pos+1);
    END LOOP;
    RETURN v_sum * NVL(p_multiply,1);
  EXCEPTION
    WHEN VALUE_ERROR THEN
      -- Provide an actionable message including the token that failed
      RAISE_APPLICATION_ERROR(-20590, 'Invalid number in CSV: '||v_tok);
  END;

  FUNCTION sum3(p_a IN t_num, p_b IN t_num, p_c IN t_num, p_multiply IN NUMBER DEFAULT 1)
    RETURN NUMBER
  IS
  BEGIN
    RETURN (NVL(p_a,0) + NVL(p_b,0) + NVL(p_c,0)) * NVL(p_multiply,1);
  END;

END math_ops_pkg;
/
SHOW ERRORS
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 3) WORKED EXAMPLES (≥5) — resolution, named, defaults, subtype rules
--    Each example prints the result and includes an "Expected" note.
--------------------------------------------------------------------------------

-- Example 1: Version and simple number overload (NUMBER, NUMBER)
BEGIN
  DBMS_OUTPUT.PUT_LINE('v='||math_ops_pkg.version);
  DBMS_OUTPUT.PUT_LINE('sum(10,20) = '||math_ops_pkg.sum_vals(10, 20));
END;
/
-- Expected:
--   v=1.0.0
--   sum(10,20)=30

-- Example 2: Integer-specific overload chosen (PLS_INTEGER arguments)
DECLARE
  a PLS_INTEGER := 7;
  b PLS_INTEGER := 13;
BEGIN
  DBMS_OUTPUT.PUT_LINE('sum(PLS_INT,PLS_INT) = '||math_ops_pkg.sum_vals(a,b));
END;
/
-- Expected:
--   20 (int overload selected)

-- Example 3: Named parameters and default multiplier for three values
BEGIN
  DBMS_OUTPUT.PUT_LINE('sum3 named = '||math_ops_pkg.sum3(p_c=>5, p_a=>2, p_b=>3, p_multiply=>2));
END;
/
-- Expected:
--   (2+3+5)*2 = 20

-- Example 4: List-based canonical via nested table
DECLARE
  l math_ops_pkg.t_num_tab := math_ops_pkg.t_num_tab(1,2,3,4);
BEGIN
  DBMS_OUTPUT.PUT_LINE('sum_list = '||math_ops_pkg.sum_list(l));
  DBMS_OUTPUT.PUT_LINE('sum_list *3 = '||math_ops_pkg.sum_list(l, 3));
END;
/
-- Expected:
--   10 then 30

-- Example 5: CSV parsing overload
BEGIN
  DBMS_OUTPUT.PUT_LINE('sum(csv) = '||math_ops_pkg.sum_vals('10, 20, 30'));
  DBMS_OUTPUT.PUT_LINE('sum(csv)*0.5 = '||math_ops_pkg.sum_vals('10,20,30', 0.5));
END;
/
-- Expected:
--   60 then 30

-- Example 6: Ambiguity avoidance — use subtype to force resolution
DECLARE
  a NUMBER := 5;
  b PLS_INTEGER := 8;
BEGIN
  -- Mixed types force NUMBER,NUMBER overload; specify cast or named params if needed
  DBMS_OUTPUT.PUT_LINE('sum(mixed) = '||math_ops_pkg.sum_vals(a, b));
END;
/
-- Expected:
--   13 (NUMBER overload used)

-- Example 7: Negative test — CSV contains non-numeric
BEGIN
  BEGIN
    DBMS_OUTPUT.PUT_LINE(math_ops_pkg.sum_vals('10, XX, 5'));
  EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('caught: '||SQLERRM);
  END;
END;
/
-- Expected:
--   Error message containing -20590 and 'XX'

-- End of Lesson File
