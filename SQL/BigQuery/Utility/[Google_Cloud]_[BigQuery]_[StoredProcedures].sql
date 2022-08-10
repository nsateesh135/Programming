-- Stored Procedures and Scripting (Beta)
-- Scripting- running a sequence of complex queries,multi_step tasks with control flow
-- Stored Procedure - save scripts and run them in BigQuery in future. Similar to views we can share stored procedures across an organization.

-- The result identifies the reporting hierarchy of an employee.


-- Step-1: Create a dummy table to work with data.
-- CREATE TABLE employee_data.Employees AS
-- SELECT 1 AS employee_id, NULL AS manager_id UNION ALL  -- CEO
-- SELECT 2, 1 UNION ALL  -- VP
-- SELECT 3, 2 UNION ALL  -- Manager
-- SELECT 4, 2 UNION ALL  -- Manager
-- SELECT 5, 3 UNION ALL  -- Engineer
-- SELECT 6, 3 UNION ALL  -- Engineer
-- SELECT 7, 3 UNION ALL  -- Engineer
-- SELECT 8, 3 UNION ALL  -- Engineer
-- SELECT 9, 4 UNION ALL  -- Engineer
-- SELECT 10, 4 UNION ALL  -- Engineer
-- SELECT 11, 4 UNION ALL  -- Engineer
-- SELECT 12, 7  -- Intern
-- ;


-- Step-2 :Create a stored procedure
-- The input variable is employee’s employee_id (target_employee_id)
  -- The output variable (OUT) is employee_hierarchy which lists
  --      the employee_id of the employee’s manager
-- CREATE PROCEDURE employee_data.GetEmployeeHierarchy(
--   target_employee_id INT64, OUT employee_hierarchy ARRAY<INT64>)
-- BEGIN
--   -- Iteratively search for this employee's manager, then the manager's
--   -- manager, etc. until reaching the CEO, who has no manager.
--   DECLARE current_employee_id INT64 DEFAULT target_employee_id;
--   SET employee_hierarchy = [];
--   WHILE current_employee_id IS NOT NULL DO
--     -- Add the current ID to the array.
--     SET employee_hierarchy =
--       ARRAY_CONCAT(employee_hierarchy, [current_employee_id]);
--     -- Get the next employee ID by querying the Employees table.
--     SET current_employee_id = (
--       SELECT manager_id FROM dataset.Employees
--       WHERE employee_id = current_employee_id
--     );
--   END WHILE;
-- END;

-- Step3: Call the stored procedure

-- Change 9 to any other ID to see the hierarchy for that employee.
DECLARE target_employee_id INT64 DEFAULT 9;
DECLARE employee_hierarchy ARRAY<INT64>;

-- Call the stored procedure to get the hierarchy for this employee ID.
CALL employee_data.GetEmployeeHierarchy(target_employee_id, employee_hierarchy);

-- Show the hierarchy for the employee.
SELECT target_employee_id, employee_hierarchy;
