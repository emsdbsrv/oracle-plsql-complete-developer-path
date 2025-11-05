-- Demo Script: environment_validation.sql
-- Objective: Verify runtime environment and connection

CONNECT plsql_lab/oracle123@localhost:1521/xepdb1;

SELECT sys_context('USERENV','SESSION_USER') AS user_name,
       sys_context('USERENV','HOST') AS host_name,
       sys_context('USERENV','DB_NAME') AS db_name,
       sys_context('USERENV','IP_ADDRESS') AS ip_address
FROM dual;

SELECT * FROM v$version WHERE rownum <= 2;
