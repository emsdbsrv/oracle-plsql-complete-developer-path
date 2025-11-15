-- assignment_plsql_language_overview.sql
-- Topic   : PL/SQL Language Overview - Practice Assignments
-- Purpose : Practice basic PL/SQL concepts:
--           - Anonymous blocks
--           - DECLARE section
--           - Variables and constants
--           - Expressions and arithmetic
--           - BOOLEAN and IF conditions
-- Style   : Each assignment includes:
--           1. A problem statement.
--           2. A sample solution block.
--           3. Detailed comments explaining each step.
-- Note    : You can first try to write your own solution, then compare
--           with the sample solution below each assignment.



/**************************************************************************
 Assignment 1:
 ------------
 Problem:
   1. Declare a variable v_city of type VARCHAR2(50).
   2. Assign your favourite city name to it.
   3. Print the value using DBMS_OUTPUT in a meaningful sentence.
**************************************************************************/
DECLARE
  v_city VARCHAR2(50);  -- Variable to store the name of a city
BEGIN
  -- Assigning a value to the variable.
  v_city := 'Bangalore';

  -- Printing a descriptive message.
  DBMS_OUTPUT.PUT_LINE('Assignment 1: My favourite city is ' || v_city || '.');
END;
/
-------------------------------------------------------------------------------



/**************************************************************************
 Assignment 2:
 ------------
 Problem:
   1. Declare two NUMBER variables: v_length and v_width.
   2. Assign any numeric values to represent the sides of a rectangle.
   3. Compute the area = length * width.
   4. Print length, width, and area using DBMS_OUTPUT.
**************************************************************************/
DECLARE
  v_length NUMBER := 10;  -- Length of rectangle
  v_width  NUMBER := 5;   -- Width of rectangle
  v_area   NUMBER;        -- To hold computed area
BEGIN
  -- Calculating the area using multiplication.
  v_area := v_length * v_width;

  -- Printing all values in a readable format.
  DBMS_OUTPUT.PUT_LINE('Assignment 2: Length  = ' || v_length);
  DBMS_OUTPUT.PUT_LINE('Assignment 2: Width   = ' || v_width);
  DBMS_OUTPUT.PUT_LINE('Assignment 2: Area    = ' || v_area);
END;
/
-------------------------------------------------------------------------------



/**************************************************************************
 Assignment 3:
 ------------
 Problem:
   1. Declare a constant c_gst_rate (for example 0.18).
   2. Declare v_base_price to represent the product price.
   3. Compute:
        v_gst_amount = v_base_price * c_gst_rate
        v_total_price = v_base_price + v_gst_amount
   4. Print base price, GST amount, and total price.
**************************************************************************/
DECLARE
  c_gst_rate   CONSTANT NUMBER := 0.18;  -- Constant GST rate (18%)
  v_base_price NUMBER := 2000;           -- Original product price
  v_gst_amount NUMBER;                   -- Calculated GST amount
  v_total_price NUMBER;                  -- Final price including GST
BEGIN
  -- Step 1: Calculate GST amount.
  v_gst_amount := v_base_price * c_gst_rate;

  -- Step 2: Calculate total price including GST.
  v_total_price := v_base_price + v_gst_amount;

  -- Step 3: Print all the details.
  DBMS_OUTPUT.PUT_LINE('Assignment 3: Base Price      = ' || v_base_price);
  DBMS_OUTPUT.PUT_LINE('Assignment 3: GST Rate        = ' || c_gst_rate);
  DBMS_OUTPUT.PUT_LINE('Assignment 3: GST Amount      = ' || v_gst_amount);
  DBMS_OUTPUT.PUT_LINE('Assignment 3: Total Price     = ' || v_total_price);
END;
/
-------------------------------------------------------------------------------



/**************************************************************************
 Assignment 4:
 ------------
 Problem:
   1. Declare a BOOLEAN variable v_has_access.
   2. Assign TRUE or FALSE to it.
   3. If TRUE, print 'Access Granted'.
      Otherwise, print 'Access Denied'.
**************************************************************************/
DECLARE
  v_has_access BOOLEAN := TRUE;  -- Represents whether user has access
BEGIN
  -- IF condition checks the BOOLEAN flag.
  IF v_has_access THEN
    DBMS_OUTPUT.PUT_LINE('Assignment 4: Access Granted');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Assignment 4: Access Denied');
  END IF;
END;
/
-------------------------------------------------------------------------------



/**************************************************************************
 Assignment 5:
 ------------
 Problem:
   1. Declare a NUMBER variable v_marks.
   2. Assign any value between 0 and 100.
   3. If v_marks is >= 50, print 'Passed'.
      Else print 'Failed'.
   4. Also print the actual marks obtained.
**************************************************************************/
DECLARE
  v_marks NUMBER := 72;  -- Marks obtained by the student
BEGIN
  DBMS_OUTPUT.PUT_LINE('Assignment 5: Marks Obtained = ' || v_marks);

  IF v_marks >= 50 THEN
    DBMS_OUTPUT.PUT_LINE('Assignment 5: Result = Passed');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Assignment 5: Result = Failed');
  END IF;
END;
/
-------------------------------------------------------------------------------



/**************************************************************************
 Assignment 6:
 ------------
 Problem:
   1. Declare two NUMBER variables v_num1 and v_num2.
   2. Assign some numeric values.
   3. Perform:
        addition       = v_num1 + v_num2
        subtraction    = v_num1 - v_num2
        multiplication = v_num1 * v_num2
        division       = v_num1 / v_num2
   4. Print all computed results separately.
**************************************************************************/
DECLARE
  v_num1 NUMBER := 40;
  v_num2 NUMBER := 8;

  v_addition       NUMBER;
  v_subtraction    NUMBER;
  v_multiplication NUMBER;
  v_division       NUMBER;
BEGIN
  -- Performing basic arithmetic operations.
  v_addition       := v_num1 + v_num2;
  v_subtraction    := v_num1 - v_num2;
  v_multiplication := v_num1 * v_num2;
  v_division       := v_num1 / v_num2;

  -- Printing each result clearly.
  DBMS_OUTPUT.PUT_LINE('Assignment 6: Num1 = ' || v_num1 || ', Num2 = ' || v_num2);
  DBMS_OUTPUT.PUT_LINE('Assignment 6: Addition       = ' || v_addition);
  DBMS_OUTPUT.PUT_LINE('Assignment 6: Subtraction    = ' || v_subtraction);
  DBMS_OUTPUT.PUT_LINE('Assignment 6: Multiplication = ' || v_multiplication);
  DBMS_OUTPUT.PUT_LINE('Assignment 6: Division       = ' || v_division);
END;
/
-------------------------------------------------------------------------------



/**************************************************************************
 Assignment 7:
 ------------
 Problem:
   1. Declare v_name (VARCHAR2) and v_age (NUMBER).
   2. Assign values representing a student's name and age.
   3. Print a formatted message:
      "Student Name: <name>, Age: <age>"
**************************************************************************/
DECLARE
  v_name VARCHAR2(50) := 'Avi Jha';
  v_age  NUMBER       := 30;
BEGIN
  -- Concatenating both name and age into one string.
  DBMS_OUTPUT.PUT_LINE(
    'Assignment 7: Student Name: ' || v_name || ', Age: ' || v_age
  );
END;
/
-------------------------------------------------------------------------------



/**************************************************************************
 Assignment 8:
 ------------
 Problem:
   1. Declare v_salary (base salary) and v_increment_percentage.
   2. Compute:
        v_increment_amount = v_salary * (v_increment_percentage / 100)
        v_new_salary       = v_salary + v_increment_amount
   3. Print salary before and after increment along with increment amount.
**************************************************************************/
DECLARE
  v_salary               NUMBER := 50000;  -- Base monthly salary
  v_increment_percentage NUMBER := 10;     -- Increment percentage
  v_increment_amount     NUMBER;           -- Amount increased
  v_new_salary           NUMBER;           -- Final salary after increment
BEGIN
  -- Step 1: Calculate increment amount.
  v_increment_amount := v_salary * (v_increment_percentage / 100);

  -- Step 2: Calculate new salary after increment.
  v_new_salary := v_salary + v_increment_amount;

  -- Step 3: Print all salary details.
  DBMS_OUTPUT.PUT_LINE('Assignment 8: Original Salary      = ' || v_salary);
  DBMS_OUTPUT.PUT_LINE('Assignment 8: Increment Percentage = ' || v_increment_percentage || '%');
  DBMS_OUTPUT.PUT_LINE('Assignment 8: Increment Amount     = ' || v_increment_amount);
  DBMS_OUTPUT.PUT_LINE('Assignment 8: New Salary           = ' || v_new_salary);
END;
/
-------------------------------------------------------------------------------



/**************************************************************************
 Assignment 9:
 ------------
 Problem:
   1. Declare v_temperature (NUMBER).
   2. Assign a temperature value in degrees Celsius.
   3. If v_temperature > 30, print 'Hot'.
      Else print 'Normal'.
   4. Also print the actual temperature value.
**************************************************************************/
DECLARE
  v_temperature NUMBER := 34;  -- Current temperature
BEGIN
  -- Print the raw temperature value.
  DBMS_OUTPUT.PUT_LINE('Assignment 9: Temperature = ' || v_temperature || ' °C');

  -- Print a message based on condition.
  IF v_temperature > 30 THEN
    DBMS_OUTPUT.PUT_LINE('Assignment 9: Weather Status = Hot');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Assignment 9: Weather Status = Normal');
  END IF;
END;
/
-------------------------------------------------------------------------------



/**************************************************************************
 Assignment 10:
 -------------
 Problem:
   1. Declare variables for:
        v_principal (P), v_rate (R), v_time (T in years).
   2. Compute Simple Interest (SI) = (P * R * T) / 100.
   3. Print principal, rate, time and calculated simple interest.
**************************************************************************/
DECLARE
  v_principal NUMBER := 100000; -- Principal amount
  v_rate      NUMBER := 7.5;    -- Annual interest rate in percent
  v_time      NUMBER := 3;      -- Time in years
  v_simple_interest NUMBER;     -- Resulting interest
BEGIN
  -- Step 1: Calculate Simple Interest.
  v_simple_interest := (v_principal * v_rate * v_time) / 100;

  -- Step 2: Print all values and result.
  DBMS_OUTPUT.PUT_LINE('Assignment 10: Principal        = ' || v_principal);
  DBMS_OUTPUT.PUT_LINE('Assignment 10: Rate (per year)  = ' || v_rate || '%');
  DBMS_OUTPUT.PUT_LINE('Assignment 10: Time (years)     = ' || v_time);
  DBMS_OUTPUT.PUT_LINE('Assignment 10: Simple Interest  = ' || v_simple_interest);
END;
/
-------------------------------------------------------------------------------
