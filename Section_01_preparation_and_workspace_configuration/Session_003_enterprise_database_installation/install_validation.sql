-- Demo Script: install_validation.sql
-- Objective: Validate Oracle Database Installation

CONNECT sys/oracle@localhost:1521/xepdb1 AS SYSDBA;

SELECT instance_name, status FROM v$instance;
SELECT name, open_mode FROM v$database;
SHOW con_name;

CREATE USER plsql_lab IDENTIFIED BY oracle123;
GRANT CONNECT, RESOURCE TO plsql_lab;
ALTER USER plsql_lab QUOTA UNLIMITED ON USERS;

SELECT username, account_status FROM dba_users WHERE username='PLSQL_LAB';
