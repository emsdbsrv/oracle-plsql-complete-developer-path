-- Demo Script: training_database_setup.sql
-- Objective: Initialize training schema for PL/SQL course

CONNECT sys/oracle@localhost:1521/xepdb1 AS SYSDBA;

-- Step 1: Create training user
CREATE USER training IDENTIFIED BY training123;
GRANT CONNECT, RESOURCE TO training;
ALTER USER training QUOTA UNLIMITED ON USERS;

-- Step 2: Create base tables
CONNECT training/training123@localhost:1521/xepdb1;

CREATE TABLE employees (
  emp_id NUMBER PRIMARY KEY,
  emp_name VARCHAR2(50),
  hire_date DATE,
  salary NUMBER(10,2)
);

CREATE SEQUENCE emp_seq START WITH 1001 INCREMENT BY 1;

-- Step 3: Insert sample data
INSERT INTO employees VALUES (emp_seq.NEXTVAL, 'John Doe', SYSDATE, 55000);
INSERT INTO employees VALUES (emp_seq.NEXTVAL, 'Jane Smith', SYSDATE, 62000);
COMMIT;

-- Step 4: Validate setup
SELECT COUNT(*) AS total_employees FROM employees;
SELECT * FROM employees FETCH FIRST 5 ROWS ONLY;
