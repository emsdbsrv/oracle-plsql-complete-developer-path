-- Script: plsql_conditional_branching_fundamentals.sql
SET SERVEROUTPUT ON;

-- Example 1: IF
DECLARE v nUMBER := 85; BEGIN IF v>=80 THEN DBMS_OUTPUT.PUT_LINE('Excellent'); END IF; END; /

-- Example 2: IF ELSE
DECLARE v_active BOOLEAN := TRUE; BEGIN IF v_active THEN DBMS_OUTPUT.PUT_LINE('ACTIVE'); ELSE DBMS_OUTPUT.PUT_LINE('INACTIVE'); END IF; END; /

-- Example 3: ELSIF
DECLARE v_score NUMBER := 67; v_grade VARCHAR2(2); BEGIN
  IF v_score >= 90 THEN v_grade := 'A';
  ELSIF v_score >= 75 THEN v_grade := 'B';
  ELSIF v_score >= 60 THEN v_grade := 'C';
  ELSIF v_score >= 40 THEN v_grade := 'D';
  ELSE v_grade := 'F'; END IF;
  DBMS_OUTPUT.PUT_LINE('Grade='||v_grade);
END; /

-- Example 4: CASE (simple)
DECLARE v_day NUMBER := 6; v_name VARCHAR2(10);
BEGIN
  CASE v_day WHEN 6 THEN v_name := 'Sat' ELSE v_name := 'Other' END CASE;
  DBMS_OUTPUT.PUT_LINE(v_name);
END; /

-- Example 5: CASE (searched)
DECLARE v_amt NUMBER := NULL; v_label VARCHAR2(20);
BEGIN
  CASE WHEN v_amt IS NULL THEN v_label := 'No Amount'
       WHEN v_amt < 0 THEN v_label := 'Negative'
       WHEN v_amt = 0 THEN v_label := 'Zero'
       WHEN v_amt BETWEEN 1 AND 999 THEN v_label := 'Small'
       ELSE v_label := 'Large' END CASE;
  DBMS_OUTPUT.PUT_LINE(v_label);
END; /

-- Example 6: AND/OR/NOT + Exception
DECLARE v_balance NUMBER := 1200; v_kyc BOOLEAN := TRUE; v_allowed BOOLEAN := FALSE; BEGIN
  IF (v_balance >= 1000) AND v_kyc THEN v_allowed := TRUE; END IF;
  IF NOT v_allowed THEN RAISE_APPLICATION_ERROR(-20001,'Not allowed'); ELSE DBMS_OUTPUT.PUT_LINE('Permitted'); END IF;
EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Error: '||SQLERRM); END; /
