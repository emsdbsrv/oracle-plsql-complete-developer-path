-- Script: plsql_multi_condition_selection_statements.sql
-- Session: 021 - Multi-Condition Selection Statements
-- Purpose :
--   Show clear patterns for multi-branch decision logic using IF/ELSIF and CASE.
--   Emphasis on readability, NULL-safety, and order-of-conditions.
-- Notes   :
--   • Each example prints output via DBMS_OUTPUT for easy verification.
--   • Use this as a template for production code by replacing literals with variables.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Example 1: IF-ELSIF Ladder for Numeric Ranges (ordered from specific to general)
-- Rationale:
--   When mapping a score to grade buckets, put the highest thresholds first to
--   avoid earlier branches swallowing later ones. This prevents unreachable code.
--------------------------------------------------------------------------------
DECLARE
  v_score NUMBER := 77;
  v_grade VARCHAR2(2);
BEGIN
  IF     v_score >= 90 THEN v_grade := 'A';   -- most specific
  ELSIF  v_score >= 75 THEN v_grade := 'B';
  ELSIF  v_score >= 60 THEN v_grade := 'C';
  ELSIF  v_score >= 40 THEN v_grade := 'D';
  ELSE                         v_grade := 'F'; -- least specific / default
  END IF;

  DBMS_OUTPUT.PUT_LINE('Score='||v_score||' -> Grade='||v_grade);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 2: Simple CASE for Discrete Codes
-- Rationale:
--   Use simple CASE when switching on a single variable against known constants.
--   It is more readable than multiple IF comparisons for exact-value checks.
--------------------------------------------------------------------------------
DECLARE
  v_code VARCHAR2(2) := 'XL';
  v_desc VARCHAR2(20);
BEGIN
  CASE v_code
    WHEN 'XS' THEN v_desc := 'Extra Small';
    WHEN 'S'  THEN v_desc := 'Small';
    WHEN 'M'  THEN v_desc := 'Medium';
    WHEN 'L'  THEN v_desc := 'Large';
    WHEN 'XL' THEN v_desc := 'Extra Large';
    ELSE v_desc := 'Unknown Size';
  END CASE;

  DBMS_OUTPUT.PUT_LINE('Code='||v_code||' -> '||v_desc);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 3: Searched CASE for Mixed Predicates (with NULL-safe logic)
-- Rationale:
--   When decision depends on complex expressions or multiple variables, use
--   searched CASE. Include explicit NULL checks to avoid UNKNOWN results.
--------------------------------------------------------------------------------
DECLARE
  v_amt   NUMBER := NULL;
  v_tier  VARCHAR2(10);
BEGIN
  CASE
    WHEN v_amt IS NULL         THEN v_tier := 'NA'     -- explicit NULL handling
    WHEN v_amt < 0             THEN v_tier := 'NEG'
    WHEN v_amt = 0             THEN v_tier := 'ZERO'
    WHEN v_amt BETWEEN 1 AND 999  THEN v_tier := 'LOW'
    WHEN v_amt BETWEEN 1000 AND 99999 THEN v_tier := 'MID'
    ELSE v_tier := 'HIGH'
  END CASE;

  DBMS_OUTPUT.PUT_LINE('Amount='||NVL(TO_CHAR(v_amt),'NULL')||' -> Tier='||v_tier);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 4: Combining Conditions with AND/OR/NOT + Guard Clause
-- Rationale:
--   Evaluate eligibility via multiple flags. Use a "guard clause" to exit early
--   when a required precondition fails, reducing nesting and improving clarity.
--------------------------------------------------------------------------------
DECLARE
  v_balance NUMBER := 800;
  v_kyc_ok  BOOLEAN := TRUE;
  v_active  BOOLEAN := FALSE;
BEGIN
  -- Guard: account must be active
  IF NOT v_active THEN
    DBMS_OUTPUT.PUT_LINE('Inactive account. Operation denied (guard clause).');
    RETURN;
  END IF;

  -- Core conditions
  IF (v_balance >= 1000) AND v_kyc_ok THEN
    DBMS_OUTPUT.PUT_LINE('Operation permitted');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Operation NOT permitted');
  END IF;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 5: CASE vs Nested IF (readability comparison)
-- Rationale:
--   CASE eliminates deep nesting when mapping to discrete results.
--------------------------------------------------------------------------------
DECLARE
  v_status VARCHAR2(1) := 'H'; -- H=Hold, A=Approved, R=Rejected
  v_text   VARCHAR2(15);
BEGIN
  -- Prefer CASE for clarity:
  CASE v_status
    WHEN 'A' THEN v_text := 'Approved';
    WHEN 'R' THEN v_text := 'Rejected';
    WHEN 'H' THEN v_text := 'On Hold';
    ELSE        v_text := 'Unknown';
  END CASE;

  DBMS_OUTPUT.PUT_LINE('Status='||v_status||' -> '||v_text);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 6: NULL-Safe Booleans (3-valued logic)
-- Rationale:
--   BOOLEAN in PL/SQL can be TRUE/FALSE/NULL. Always handle NULL explicitly.
--------------------------------------------------------------------------------
DECLARE
  v_flag BOOLEAN := NULL;
  v_msg  VARCHAR2(10);
BEGIN
  IF v_flag IS NULL THEN
    v_msg := 'UNKNOWN';
  ELSIF v_flag THEN
    v_msg := 'TRUE';
  ELSE
    v_msg := 'FALSE';
  END IF;

  DBMS_OUTPUT.PUT_LINE('Flag -> '||v_msg);
END;
/
--------------------------------------------------------------------------------
-- End of File
--------------------------------------------------------------------------------
