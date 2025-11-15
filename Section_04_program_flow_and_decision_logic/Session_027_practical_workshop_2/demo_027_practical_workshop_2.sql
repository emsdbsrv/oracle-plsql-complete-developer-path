-- demo_027_practical_workshop_2.sql
-- Session : 027_practical_workshop_2
-- Topic   : Practical Workshop 2 - Control Structures in Action
-- Purpose : Combine branching, CASE, loops, labels into realistic mini-scenarios.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Demo 1: Student grading report using IF + FOR loop
--------------------------------------------------------------------------------
DECLARE
  TYPE t_mark_tab IS TABLE OF NUMBER;
  v_marks t_mark_tab := t_mark_tab(92, 76, 58, 43);
  v_grade VARCHAR2(2);
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 1: Student grading report');

  FOR i IN 1 .. v_marks.COUNT LOOP
    IF v_marks(i) >= 80 THEN
      v_grade := 'A';
    ELSIF v_marks(i) >= 60 THEN
      v_grade := 'B';
    ELSIF v_marks(i) >= 50 THEN
      v_grade := 'C';
    ELSE
      v_grade := 'D';
    END IF;

    DBMS_OUTPUT.PUT_LINE('  Student ' || i || ' | Marks=' || v_marks(i) ||
                         ' | Grade=' || v_grade);
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 2: Order processing with CASE and LOOP
--------------------------------------------------------------------------------
DECLARE
  TYPE t_amount_tab IS TABLE OF NUMBER;
  v_amounts t_amount_tab := t_amount_tab(800, 2500, 5200);
  v_category VARCHAR2(20);
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 2: Order discount category');

  FOR i IN 1 .. v_amounts.COUNT LOOP
    v_category := CASE
                    WHEN v_amounts(i) >= 5000 THEN 'Platinum'
                    WHEN v_amounts(i) >= 3000 THEN 'Gold'
                    WHEN v_amounts(i) >= 1000 THEN 'Silver'
                    ELSE 'Regular'
                  END;

    DBMS_OUTPUT.PUT_LINE('  Order ' || i ||
                         ' | Amount=' || v_amounts(i) ||
                         ' | Category=' || v_category);
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 3: Attendance summary using WHILE loop
--------------------------------------------------------------------------------
DECLARE
  v_day NUMBER := 1;
  v_total_days NUMBER := 5;
  v_present_days NUMBER := 0;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 3: Attendance summary over ' ||
                       v_total_days || ' days');

  WHILE v_day <= v_total_days LOOP
    -- For demo: mark every 3rd day as absent.
    IF MOD(v_day, 3) = 0 THEN
      DBMS_OUTPUT.PUT_LINE('  Day ' || v_day || ': Absent');
    ELSE
      DBMS_OUTPUT.PUT_LINE('  Day ' || v_day || ': Present');
      v_present_days := v_present_days + 1;
    END IF;

    v_day := v_day + 1;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('  Present days = ' || v_present_days);
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 4: Nested loops for simple seating allocation
--------------------------------------------------------------------------------
DECLARE
  v_seat_label VARCHAR2(10);
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 4: Seating plan (Rows A-C, Seats 1-4)');

  FOR v_row IN 1 .. 3 LOOP
    FOR v_seat IN 1 .. 4 LOOP
      v_seat_label := CHR(64 + v_row) || v_seat; -- 65='A'
      DBMS_OUTPUT.PUT_LINE('  Seat ' || v_seat_label || ' allocated.');
    END LOOP;
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Demo 5: Mini login attempt workflow using LOOP, EXIT, and flags
--------------------------------------------------------------------------------
DECLARE
  v_attempts      NUMBER := 0;
  v_max_attempts  CONSTANT NUMBER := 3;
  v_entered_pwd   VARCHAR2(20);
  v_actual_pwd    VARCHAR2(20) := 'plsql123';
  v_authenticated BOOLEAN := FALSE;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Demo 5: Login attempt workflow');

  LOOP
    v_attempts := v_attempts + 1;

    -- For demonstration we simulate user entry.
    IF v_attempts = 1 THEN
      v_entered_pwd := 'wrong';
    ELSE
      v_entered_pwd := 'plsql123';
    END IF;

    DBMS_OUTPUT.PUT_LINE('  Attempt ' || v_attempts ||
                         ', Entered = ' || v_entered_pwd);

    IF v_entered_pwd = v_actual_pwd THEN
      v_authenticated := TRUE;
      DBMS_OUTPUT.PUT_LINE('  Authentication successful.');
      EXIT;
    ELSE
      DBMS_OUTPUT.PUT_LINE('  Incorrect password.');
    END IF;

    EXIT WHEN v_attempts >= v_max_attempts;
  END LOOP;

  IF NOT v_authenticated THEN
    DBMS_OUTPUT.PUT_LINE('  Account locked after ' ||
                         v_attempts || ' failed attempts.');
  END IF;
END;
/
--------------------------------------------------------------------------------
