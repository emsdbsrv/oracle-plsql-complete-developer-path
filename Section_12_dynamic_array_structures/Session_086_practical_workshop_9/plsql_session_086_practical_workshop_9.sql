SET SERVEROUTPUT ON;
--------------------------------------------------------------------------------
-- Session 086 – Practical Workshop #9
-- 7 exercises demonstrating real-world usage of collection APIs.
--------------------------------------------------------------------------------

/******************************************************************************
EX1: Normalize sparse nested table by removing NULL entries
******************************************************************************/
DECLARE
  TYPE t_nt IS TABLE OF VARCHAR2(50);
  v t_nt := t_nt('A',NULL,'B',NULL,'C');
BEGIN
  FOR i IN v.FIRST..v.LAST LOOP
    IF v.EXISTS(i) AND v(i) IS NULL THEN
      v.DELETE(i);
    END IF;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('After cleanup:');
  FOR i IN v.FIRST..v.LAST LOOP
    IF v.EXISTS(i) THEN DBMS_OUTPUT.PUT_LINE(v(i)); END IF;
  END LOOP;
END;
/
--------------------------------------------------------------------------------

/******************************************************************************
EX2: Merge two nested tables into one (preserve gaps)
******************************************************************************/
DECLARE
  TYPE t_nt IS TABLE OF VARCHAR2(30);
  a t_nt := t_nt('X','Y',NULL,'Z');
  b t_nt := t_nt('A','B','C','D');
BEGIN
  FOR i IN b.FIRST..b.LAST LOOP
    IF b.EXISTS(i) THEN
      a.EXTEND;
      a(a.LAST) := b(i);
    END IF;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('Merged:');
  FOR i IN a.FIRST..a.LAST LOOP
    IF a.EXISTS(i) THEN DBMS_OUTPUT.PUT_LINE(a(i)); END IF;
  END LOOP;
END;
/
--------------------------------------------------------------------------------

/******************************************************************************
EX3: Reverse traversal using PRIOR for summary computation
******************************************************************************/
DECLARE
  TYPE t_map IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
  v t_map;
  k PLS_INTEGER;
  sum_back NUMBER:=0;
BEGIN
  v(10):=5; v(20):=7; v(30):=9;
  k:=v.LAST;

  WHILE k IS NOT NULL LOOP
    sum_back := sum_back + v(k);
    k := v.PRIOR(k);
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('Reverse sum='||sum_back);
END;
/
--------------------------------------------------------------------------------

/******************************************************************************
EX4: Delete multiples of 3 from BULK COLLECT results
******************************************************************************/
DECLARE
  TYPE t_nums IS TABLE OF NUMBER;
  v t_nums;
BEGIN
  SELECT LEVEL BULK COLLECT INTO v FROM dual CONNECT BY LEVEL<=12;

  FOR i IN v.FIRST..v.LAST LOOP
    IF v.EXISTS(i) AND MOD(v(i),3)=0 THEN v.DELETE(i); END IF;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('Remaining:');
  FOR i IN v.FIRST..v.LAST LOOP IF v.EXISTS(i) THEN DBMS_OUTPUT.PUT_LINE(v(i)); END IF; END LOOP;
END;
/
--------------------------------------------------------------------------------

/******************************************************************************
EX5: Demonstrate sparsity impact on COUNT vs LAST
******************************************************************************/
DECLARE
  TYPE t_nt IS TABLE OF VARCHAR2(20);
  v t_nt := t_nt('One','Two','Three','Four','Five');
BEGIN
  v.DELETE(2); v.DELETE(4);

  DBMS_OUTPUT.PUT_LINE('COUNT='||v.COUNT||' LAST='||v.LAST);
END;
/
--------------------------------------------------------------------------------

/******************************************************************************
EX6: Build associative array index chain and print sequence
******************************************************************************/
DECLARE
  TYPE t_map IS TABLE OF VARCHAR2(30) INDEX BY PLS_INTEGER;
  v t_map; k PLS_INTEGER;
BEGIN
  v(5):='A'; v(15):='B'; v(25):='C';

  k:=v.FIRST;
  WHILE k IS NOT NULL LOOP
    DBMS_OUTPUT.PUT_LINE('Key='||k||' -> '||v(k));
    k:=v.NEXT(k);
  END LOOP;
END;
/
--------------------------------------------------------------------------------

/******************************************************************************
EX7: Collapse sparse table into dense form using fresh constructor
******************************************************************************/
DECLARE
  TYPE t_nt IS TABLE OF NUMBER;
  v t_nt := t_nt(1,NULL,3,NULL,5);
  r t_nt := t_nt();
BEGIN
  FOR i IN v.FIRST..v.LAST LOOP
    IF v.EXISTS(i) AND v(i) IS NOT NULL THEN
      r.EXTEND;
      r(r.LAST):=v(i);
    END IF;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('Dense result:');
  FOR i IN r.FIRST..r.LAST LOOP DBMS_OUTPUT.PUT_LINE(r(i)); END LOOP;
END;
/
--------------------------------------------------------------------------------
-- End Lesson
