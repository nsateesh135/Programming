-- Verify the validity of your sql scripts using ASSERT EXISTS / ASSERT
-- We call assert and follow it with a sql statement that returns TRUE or FALSE, if it returns False then the script fails.
-- We can also conduct data quality checks E.g - Check for values which cannot exist in the table
-- Reference: https://medium.com/google-cloud/validating-successful-execution-of-bigquery-scripts-using-assert-c82f7ff9cfa8

-- Pre-Condition(Check data exists in base table)[Expected_Output: This assertion was successful]
ASSERT EXISTS (
   SELECT name
   FROM `bigquery-public-data`.london_bicycles.cycle_stations
   WHERE name LIKE '%Hyde%'
);

-- Create base table if the assert above returns true
CREATE OR REPLACE TABLE ch07eu.hydepark_rides AS
SELECT
  start_station_name,
  AVG(duration) AS duration
FROM `bigquery-public-data`.london_bicycles.cycle_hire
WHERE
  start_station_name LIKE '%Hyde%'
GROUP BY start_station_name;

-- Post-Condition(Check if data exists in created table)
ASSERT EXISTS(
   SELECT duration FROM ch07eu.hydepark_rides
   WHERE start_station_name = 'Park Lane , Hyde Park'
);

-- Use ASSERT EXISTS to evalaute results in a table. Use ASSERT to evaluate a condition.
ASSERT (SELECT min(duration) FROM ch07eu.hydepark_rides) > 60;


-- Use Case check PII in the table
