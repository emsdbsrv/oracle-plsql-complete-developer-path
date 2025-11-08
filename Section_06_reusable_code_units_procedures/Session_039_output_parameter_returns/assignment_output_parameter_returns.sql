-- Script: assignment_output_parameter_returns.sql
-- Session: 039 - Output Parameter Returns
-- Format:
--   • 10 detailed questions with complete solutions provided as COMMENTED hints.
--   • To run a solution: copy the commented block and remove leading '--'.
-- Guidance:
--   • Always assign OUT parameters on all paths; initialize early and in EXCEPTION blocks.
--   • Use %TYPE/%ROWTYPE anchors; consider SYS_REFCURSOR for multi-row results.

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- Q1 (Scalar OUT): Write opr_get_name(p_id IN, p_name OUT %TYPE) returning acct_name.
-- Answer (commented):
-- CREATE OR REPLACE PROCEDURE opr_get_name(p_id IN opr_accounts.acct_id%TYPE, p_name OUT opr_accounts.acct_name%TYPE) IS
-- BEGIN SELECT acct_name INTO p_name FROM opr_accounts WHERE acct_id=p_id;
-- EXCEPTION WHEN NO_DATA_FOUND THEN p_name := NULL; END; /
-- DECLARE v VARCHAR2(80); BEGIN opr_get_name(1,v); DBMS_OUTPUT.PUT_LINE(NVL(v,'<NULL>')); END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q2 (Multiple OUTs): Build opr_balance_info(p_id IN, p_ok OUT, p_msg OUT, p_bal OUT).
-- Answer (commented):
-- CREATE OR REPLACE PROCEDURE opr_balance_info(p_id IN opr_accounts.acct_id%TYPE, p_ok OUT NUMBER, p_msg OUT VARCHAR2, p_bal OUT NUMBER) IS
-- BEGIN p_ok:=0; p_msg:=NULL; p_bal:=NULL;
--   SELECT balance INTO p_bal FROM opr_accounts WHERE acct_id=p_id; p_ok:=1; p_msg:='OK';
-- EXCEPTION WHEN NO_DATA_FOUND THEN p_ok:=0; p_msg:='not found'; p_bal:=0; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q3 (%ROWTYPE OUT): Return an entire row for a given id.
-- Answer (commented):
-- CREATE OR REPLACE PROCEDURE opr_get_row(p_id IN opr_accounts.acct_id%TYPE, p_row OUT opr_accounts%ROWTYPE) IS
-- BEGIN SELECT * INTO p_row FROM opr_accounts WHERE acct_id=p_id;
-- EXCEPTION WHEN NO_DATA_FOUND THEN p_row.acct_id:=p_id; p_row.acct_name:=NULL; p_row.balance:=NULL; p_row.opened_on:=NULL; p_row.status:=NULL; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q4 (SYS_REFCURSOR): Return all ACTIVE accounts.
-- Answer (commented):
-- CREATE OR REPLACE PROCEDURE opr_active_rc(p_rc OUT SYS_REFCURSOR) IS
-- BEGIN OPEN p_rc FOR SELECT acct_id, acct_name, balance FROM opr_accounts WHERE status='ACTIVE' ORDER BY acct_id; END; /
-- DECLARE c SYS_REFCURSOR; id NUMBER; nm VARCHAR2(80); bal NUMBER; BEGIN opr_active_rc(c); LOOP FETCH c INTO id,nm,bal; EXIT WHEN c%NOTFOUND; DBMS_OUTPUT.PUT_LINE(id||':'||nm); END LOOP; CLOSE c; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q5 (Status code + message): Implement opr_set_status(p_id IN, p_status IN, p_ok OUT, p_msg OUT).
-- Answer (commented):
-- CREATE OR REPLACE PROCEDURE opr_set_status(p_id IN opr_accounts.acct_id%TYPE, p_status IN opr_accounts.status%TYPE, p_ok OUT NUMBER, p_msg OUT VARCHAR2) IS
--   v VARCHAR2(20):=UPPER(TRIM(p_status));
-- BEGIN p_ok:=0; p_msg:=NULL;
--   IF v NOT IN ('ACTIVE','INACTIVE','SUSPENDED') THEN p_msg:='bad status'; RETURN; END IF;
--   UPDATE opr_accounts SET status=v WHERE acct_id=p_id;
--   IF SQL%ROWCOUNT=0 THEN p_msg:='not found'; RETURN; END IF;
--   p_ok:=1; p_msg:='updated';
-- END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q6 (Transfer OUTs): Implement opr_transfer with p_from_bal and p_to_bal OUTs (see main script Example 5).
-- Answer (commented):
-- -- Reuse the pattern: initialize OUTs, validate amount, update both rows, query balances, set p_ok/p_msg.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q7 (Derived metric OUT): opr_days_open(p_id IN, p_days OUT).
-- Answer (commented):
-- CREATE OR REPLACE PROCEDURE opr_days_open(p_id IN opr_accounts.acct_id%TYPE, p_days OUT NUMBER) IS v DATE; BEGIN
--   SELECT opened_on INTO v FROM opr_accounts WHERE acct_id=p_id; p_days := TRUNC(SYSDATE)-TRUNC(v);
-- EXCEPTION WHEN NO_DATA_FOUND THEN p_days := 0; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q8 (OUT defaults on error): Ensure OUTs have safe defaults in EXCEPTION.
-- Answer (commented):
-- CREATE OR REPLACE PROCEDURE opr_safe_example(p_id IN NUMBER, p_val OUT NUMBER) IS BEGIN
--   SELECT 1/(p_id-1) INTO p_val FROM dual;
-- EXCEPTION WHEN OTHERS THEN p_val := 0; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q9 (Message composition): opr_get_summary(p_id IN, p_msg OUT) that prints name+balance.
-- Answer (commented):
-- CREATE OR REPLACE PROCEDURE opr_get_summary(p_id IN opr_accounts.acct_id%TYPE, p_msg OUT VARCHAR2) IS n VARCHAR2(80); b NUMBER;
-- BEGIN SELECT acct_name,balance INTO n,b FROM opr_accounts WHERE acct_id=p_id; p_msg:=n||' has '||TO_CHAR(b,'FM9999999990.00');
-- EXCEPTION WHEN NO_DATA_FOUND THEN p_msg:='not found'; END; /
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Q10 (Refcursor with filter): opr_accounts_by_min_balance(p_min IN NUMBER, p_rc OUT SYS_REFCURSOR).
-- Answer (commented):
-- CREATE OR REPLACE PROCEDURE opr_accounts_by_min_balance(p_min IN NUMBER, p_rc OUT SYS_REFCURSOR) IS
-- BEGIN OPEN p_rc FOR SELECT acct_id,acct_name,balance FROM opr_accounts WHERE balance>=ROUND(p_min,2) ORDER BY balance DESC; END; /
--------------------------------------------------------------------------------
-- End of Assignment
--------------------------------------------------------------------------------
