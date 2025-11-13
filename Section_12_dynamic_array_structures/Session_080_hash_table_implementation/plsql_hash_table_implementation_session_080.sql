SET SERVEROUTPUT ON;
--------------------------------------------------------------------------------
-- Session 080 – Hash Table Implementation Using Associative Arrays
-- Detailed examples demonstrating:
--   1) Integer-key hash table
--   2) String-key hash table
--   3) Search, insert, delete operations
--   4) Iteration using FIRST/NEXT
--   5) Hash-table API using procedures
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 1: Integer-key hash table
--------------------------------------------------------------------------------
DECLARE
  TYPE t_hash IS TABLE OF VARCHAR2(100) INDEX BY PLS_INTEGER;
  v_map t_hash;
BEGIN
  v_map(101) := 'Laptop';
  v_map(205) := 'Mouse';
  v_map(309) := 'Keyboard';

  IF v_map.EXISTS(205) THEN
    DBMS_OUTPUT.PUT_LINE('Found key 205 -> '||v_map(205));
  END IF;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 2: String-key hash table
--------------------------------------------------------------------------------
DECLARE
  TYPE t_hash IS TABLE OF NUMBER INDEX BY VARCHAR2(50);
  v_price t_hash;
BEGIN
  v_price('SSD') := 3500;
  v_price('Monitor') := 12000;

  DBMS_OUTPUT.PUT_LINE('SSD price='||v_price('SSD'));
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 3: Delete operation
--------------------------------------------------------------------------------
DECLARE
  TYPE t_hash IS TABLE OF VARCHAR2(50) INDEX BY VARCHAR2(30);
  v_map t_hash;
BEGIN
  v_map('A') := 'Alpha';
  v_map('B') := 'Bravo';

  v_map.DELETE('A'); -- remove key 'A'

  IF NOT v_map.EXISTS('A') THEN
    DBMS_OUTPUT.PUT_LINE('Key A removed from hash table');
  END IF;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 4: Iteration using FIRST/NEXT
--------------------------------------------------------------------------------
DECLARE
  TYPE t_hash IS TABLE OF VARCHAR2(20) INDEX BY VARCHAR2(20);
  v_map t_hash;
  k VARCHAR2(20);
BEGIN
  v_map('India') := 'IN';
  v_map('USA') := 'US';
  v_map('Japan') := 'JP';

  k := v_map.FIRST;
  WHILE k IS NOT NULL LOOP
    DBMS_OUTPUT.PUT_LINE(k||' -> '||v_map(k));
    k := v_map.NEXT(k);
  END LOOP;
END;
/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Example 5: Hash table API (Insert, Get, Delete)
--------------------------------------------------------------------------------
DECLARE
  TYPE t_hash IS TABLE OF VARCHAR2(100) INDEX BY VARCHAR2(100);
  v_map t_hash;

  PROCEDURE put(p_key VARCHAR2, p_val VARCHAR2) IS
  BEGIN
    v_map(p_key) := p_val;
  END;

  FUNCTION get(p_key VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN v_map(p_key);
  END;

  PROCEDURE del(p_key VARCHAR2) IS
  BEGIN
    v_map.DELETE(p_key);
  END;

BEGIN
  put('K1','Value-1');
  put('K2','Value-2');

  DBMS_OUTPUT.PUT_LINE('K1='||get('K1'));

  del('K1');
  IF NOT v_map.EXISTS('K1') THEN
    DBMS_OUTPUT.PUT_LINE('K1 deleted');
  END IF;
END;
/
--------------------------------------------------------------------------------

-- End Lesson
