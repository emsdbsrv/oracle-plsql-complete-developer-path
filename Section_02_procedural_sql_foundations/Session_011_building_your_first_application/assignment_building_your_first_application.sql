-- assignment_building_your_first_application.sql
-- Session : 011_building_your_first_application
-- Topic   : Practice - Build a Tiny PL/SQL-Based Application
-- Purpose : Reinforce how to:
--           - Create and use tables
--           - Insert, update, delete data via PL/SQL
--           - Apply simple business rules
--           - Produce small reports using DBMS_OUTPUT
-- Style   : 10 step-by-step assignments with full example solutions
--           and detailed comments.

SET SERVEROUTPUT ON;



--------------------------------------------------------------------------------
-- Common Setup for Assignments
-- We create a simple "tasks" table to model a to-do style application.
-- This setup can be safely rerun.
--------------------------------------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE s011_assign_tasks';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
/
CREATE TABLE s011_assign_tasks
(
  task_id      NUMBER        PRIMARY KEY,
  task_name    VARCHAR2(100) NOT NULL,
  status       VARCHAR2(20)  DEFAULT 'PENDING', -- PENDING / DONE / CANCELLED
  priority     NUMBER        DEFAULT 3,         -- 1 = High, 2 = Medium, 3 = Low
  created_on   DATE          DEFAULT SYSDATE
);
/
--------------------------------------------------------------------------------



/**************************************************************************
 Assignment 1:
 -------------
 Problem:
   1. Insert one new task into s011_assign_tasks using a PL/SQL block.
   2. Use task_id = 1, task_name = 'Create PL/SQL project skeleton'.
   3. Keep default values for status, priority, and created_on.
   4. Print a confirmation message once inserted.
**************************************************************************/
BEGIN
  INSERT INTO s011_assign_tasks (task_id, task_name)
  VALUES (1, 'Create PL/SQL project skeleton');

  DBMS_OUTPUT.PUT_LINE('Assignment 1: Inserted task 1 - Create PL/SQL project skeleton.');
END;
/
-------------------------------------------------------------------------------



/**************************************************************************
 Assignment 2:
 -------------
 Problem:
   1. Insert three more tasks (IDs 2, 3, 4) using a FOR loop.
   2. The task_name should be 'Task-' || task_id.
   3. Set priority = 2 for all these tasks.
   4. Print how many tasks were inserted by the loop.
**************************************************************************/
DECLARE
  v_inserted_count NUMBER := 0;
BEGIN
  FOR v_id IN 2 .. 4 LOOP
    INSERT INTO s011_assign_tasks (task_id, task_name, priority)
    VALUES (v_id, 'Task-' || TO_CHAR(v_id), 2);

    v_inserted_count := v_inserted_count + 1;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('Assignment 2: Inserted ' || v_inserted_count || ' tasks using a loop.');
END;
/
-------------------------------------------------------------------------------



/**************************************************************************
 Assignment 3:
 -------------
 Problem:
   1. Update the status of a single task to 'DONE'.
   2. Use task_id = 1.
   3. Print a message before and after the update to indicate progress.
**************************************************************************/
DECLARE
  v_target_task_id NUMBER := 1;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Assignment 3: Marking task ' || v_target_task_id || ' as DONE.');

  UPDATE s011_assign_tasks
     SET status = 'DONE'
   WHERE task_id = v_target_task_id;

  DBMS_OUTPUT.PUT_LINE('Assignment 3: Task ' || v_target_task_id || ' updated to DONE.');
END;
/
-------------------------------------------------------------------------------



/**************************************************************************
 Assignment 4:
 -------------
 Problem:
   1. Update all tasks with priority = 2 to status = 'PENDING REVIEW'.
   2. Use a single UPDATE statement inside a PL/SQL block.
   3. After the update, print how many rows were affected using SQL%ROWCOUNT.
**************************************************************************/
BEGIN
  DBMS_OUTPUT.PUT_LINE('Assignment 4: Updating tasks with priority = 2 to PENDING REVIEW.');

  UPDATE s011_assign_tasks
     SET status = 'PENDING REVIEW'
   WHERE priority = 2;

  DBMS_OUTPUT.PUT_LINE('Assignment 4: Rows updated = ' || SQL%ROWCOUNT);
END;
/
-------------------------------------------------------------------------------



/**************************************************************************
 Assignment 5:
 -------------
 Problem:
   1. Implement simple validation before deleting a task.
   2. Choose task_id = 4.
   3. Check if the task exists:
        - If exists, delete it and print a message.
        - If not, print 'No such task to delete.'
**************************************************************************/
DECLARE
  v_target_task_id NUMBER := 4;
  v_count          NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Assignment 5: Trying to delete task ' || v_target_task_id || '.');

  SELECT COUNT(*)
    INTO v_count
    FROM s011_assign_tasks
   WHERE task_id = v_target_task_id;

  IF v_count = 0 THEN
    DBMS_OUTPUT.PUT_LINE('Assignment 5: No such task found. Nothing deleted.');
  ELSE
    DELETE FROM s011_assign_tasks
     WHERE task_id = v_target_task_id;

    DBMS_OUTPUT.PUT_LINE('Assignment 5: Task ' || v_target_task_id || ' deleted successfully.');
  END IF;
END;
/
-------------------------------------------------------------------------------



/**************************************************************************
 Assignment 6:
 -------------
 Problem:
   1. Write a small "application report" block.
   2. Calculate:
        - total tasks,
        - number of tasks with status = 'DONE',
        - number of tasks with status = 'PENDING'.
   3. Print a formatted mini-report using DBMS_OUTPUT.
**************************************************************************/
DECLARE
  v_total_tasks   NUMBER;
  v_done_tasks    NUMBER;
  v_pending_tasks NUMBER;
BEGIN
  SELECT COUNT(*),
         SUM(CASE WHEN status = 'DONE' THEN 1 ELSE 0 END),
         SUM(CASE WHEN status = 'PENDING' THEN 1 ELSE 0 END)
    INTO v_total_tasks,
         v_done_tasks,
         v_pending_tasks
    FROM s011_assign_tasks;

  DBMS_OUTPUT.PUT_LINE('Assignment 6: Task Summary Report');
  DBMS_OUTPUT.PUT_LINE('  Total tasks  = ' || v_total_tasks);
  DBMS_OUTPUT.PUT_LINE('  Done         = ' || v_done_tasks);
  DBMS_OUTPUT.PUT_LINE('  Pending      = ' || v_pending_tasks);
END;
/
-------------------------------------------------------------------------------



/**************************************************************************
 Assignment 7:
 -------------
 Problem:
   1. Demonstrate use of a user-defined exception for "high priority" rules.
   2. If a task has priority = 1 and status <> 'DONE', raise e_high_priority_open.
   3. Use task_id = 2 for the check.
   4. Handle the exception and print a friendly warning.
**************************************************************************/
DECLARE
  v_task_id   NUMBER := 2;
  v_priority  NUMBER;
  v_status    VARCHAR2(20);
  e_high_priority_open EXCEPTION;
BEGIN
  SELECT priority, status
    INTO v_priority, v_status
    FROM s011_assign_tasks
   WHERE task_id = v_task_id;

  DBMS_OUTPUT.PUT_LINE('Assignment 7: Checking task ' || v_task_id ||
                       ' (priority=' || v_priority || ', status=' || v_status || ').');

  IF v_priority = 1 AND v_status <> 'DONE' THEN
    RAISE e_high_priority_open;
  END IF;

  DBMS_OUTPUT.PUT_LINE('Assignment 7: No high-priority open task found for ID ' || v_task_id || '.');

EXCEPTION
  WHEN e_high_priority_open THEN
    DBMS_OUTPUT.PUT_LINE('Assignment 7: Warning - High priority task ' || v_task_id ||
                         ' is not DONE yet.');
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('Assignment 7: Task ' || v_task_id || ' not found.');
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Assignment 7: Unexpected error: ' || SQLERRM);
END;
/
-------------------------------------------------------------------------------



/**************************************************************************
 Assignment 8:
 -------------
 Problem:
   1. Create a small reusable procedure s011_mark_task_done.
   2. Parameters: p_task_id.
   3. Inside the procedure:
        - Update the task status to 'DONE'.
        - Print a message with the task id.
   4. Call this procedure for task_id 3 from a separate block.
**************************************************************************/
CREATE OR REPLACE PROCEDURE s011_mark_task_done
(
  p_task_id IN NUMBER
)
AS
BEGIN
  UPDATE s011_assign_tasks
     SET status = 'DONE'
   WHERE task_id = p_task_id;

  DBMS_OUTPUT.PUT_LINE('Assignment 8 procedure: Task ' || p_task_id || ' marked as DONE.');
END s011_mark_task_done;
/
BEGIN
  DBMS_OUTPUT.PUT_LINE('Assignment 8: Calling procedure to mark task 3 as DONE.');
  s011_mark_task_done(3);
END;
/
-------------------------------------------------------------------------------



/**************************************************************************
 Assignment 9:
 -------------
 Problem:
   1. Write a nested block where the inner block attempts to insert a task
      with a duplicate primary key (for example task_id = 1).
   2. Handle DUP_VAL_ON_INDEX in the inner block and print a message.
   3. Outer block should print messages before and after the inner block
      to show control flow.
**************************************************************************/
BEGIN
  DBMS_OUTPUT.PUT_LINE('Assignment 9 (outer): Starting outer block.');

  DECLARE
  BEGIN
    DBMS_OUTPUT.PUT_LINE('Assignment 9 (inner): Attempting to insert duplicate task_id = 1.');

    INSERT INTO s011_assign_tasks (task_id, task_name)
    VALUES (1, 'Duplicate task id 1');

    DBMS_OUTPUT.PUT_LINE('Assignment 9 (inner): Insert completed (this line should not run).');

  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      DBMS_OUTPUT.PUT_LINE('Assignment 9 (inner): Caught DUP_VAL_ON_INDEX - duplicate task id.');
  END;

  DBMS_OUTPUT.PUT_LINE('Assignment 9 (outer): Inner block finished.');
END;
/
-------------------------------------------------------------------------------



/**************************************************************************
 Assignment 10:
 --------------
 Problem:
   1. Create a final "application summary" block.
   2. For each task in s011_assign_tasks, print:
        - task_id, task_name, status, priority.
   3. At the end, also print the total number of tasks processed.
**************************************************************************/
DECLARE
  CURSOR c_tasks IS
    SELECT task_id, task_name, status, priority
      FROM s011_assign_tasks
     ORDER BY task_id;

  v_count NUMBER := 0;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Assignment 10: Detailed Task Listing');

  FOR rec IN c_tasks LOOP
    v_count := v_count + 1;

    DBMS_OUTPUT.PUT_LINE(
      '  Task ' || rec.task_id ||
      ' | Name=' || rec.task_name ||
      ' | Status=' || rec.status ||
      ' | Priority=' || rec.priority
    );
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('Assignment 10: Total tasks printed = ' || v_count);
END;
/
-------------------------------------------------------------------------------
