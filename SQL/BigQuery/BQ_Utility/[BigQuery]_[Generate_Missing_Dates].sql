--  Arrays
--  Arrays are data structures which could hold multiple data types


-- Array with one field
-- SELECT 
-- ARRAY(SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 ) AS new_array;

-- Array with multiple fileds
-- Array of struct
-- SELECT
-- ARRAY(SELECT AS STRUCT 1, 2, 3 UNION ALL SELECT AS STRUCT 4, 5, 6) AS new_array1;

-- Nested Arrays
-- SELECT 
-- ARRAY (SELECT AS STRUCT [1, 2, 3],[4,5,6] UNION ALL SELECT AS STRUCT [4, 5, 6],[7,8,9]) AS new_array2;


-- Array Concat
-- Concatenates one or more arrays with the same element type into a single array.

-- SELECT ARRAY_CONCAT([1, 2], [3, 4], [5, 6]) as count_to_six;



-- Array length and ARRAY_TO_STRING
-- Returns the size of the array. Returns 0 for an empty array. Returns NULL if the array_expression is NULL.
-- WITH items AS
--   (SELECT ["coffee", NULL, "milk" ] as list
--   UNION ALL
--   SELECT ["cake", "pie"] as list)
-- SELECT ARRAY_TO_STRING(list, ', ', 'NULL'), ARRAY_LENGTH(list) AS size
-- FROM items
-- ORDER BY size DESC;


-- Generate ARRAY
-- Return array of values
-- INT64,NUMERIC,BIGNUMERIC,FLOAT64
-- GENERATE_ARRAY(start_expression, end_expression[, step_expression])

-- SELECT GENERATE_ARRAY(1, 5) AS example_array;= [1,2,3,4,5]
-- SELECT GENERATE_ARRAY(0, 10, 3) AS example_array;=[0,3,6,9]
-- SELECT GENERATE_ARRAY(10, 0, -3) AS example_array;=[10,7,4,1]
-- SELECT GENERATE_ARRAY(4, 4, 10) AS example_array;=[4]
-- SELECT GENERATE_ARRAY(10, 0, 3) AS example_array;=[]
-- SELECT GENERATE_ARRAY(5, NULL, 1) AS example_array;=NULL
-- SELECT GENERATE_ARRAY(start, 5) AS example_array FROM UNNEST([3, 4, 5]) AS start;=[3,4,5][4,5][5]



-- Generate date array

-- SELECT GENERATE_DATE_ARRAY('2016-10-05', '2016-10-08') AS example;

-- SELECT GENERATE_DATE_ARRAY('2016-10-05', '2016-10-09', INTERVAL 2 DAY) AS example;=[2016-10-05, 2016-10-07, 2016-10-09]

-- SELECT GENERATE_DATE_ARRAY('2016-10-05','2016-10-01', INTERVAL -3 DAY) AS example;=[2016-10-05, 2016-10-02]

-- SELECT GENERATE_DATE_ARRAY('2016-10-05','2016-10-05', INTERVAL 8 DAY) AS example;=['2016-10-05']

-- SELECT GENERATE_DATE_ARRAY('2016-10-05','2016-10-01', INTERVAL 1 DAY) AS example;=[]

-- SELECT GENERATE_DATE_ARRAY('2016-10-05', NULL) AS example;= NULL

-- SELECT GENERATE_DATE_ARRAY('2016-01-01','2016-12-31', INTERVAL 2 MONTH) AS example;=[[2016-01-01, 2016-03-01, 2016-05-01, 2016-07-01, 2016-09-01, 2016-11-01]]

-- SELECT GENERATE_DATE_ARRAY(date_start, date_end, INTERVAL 1 WEEK) AS date_range
-- FROM (
--   SELECT DATE '2016-01-01' AS date_start, DATE '2016-01-31' AS date_end
--   UNION ALL SELECT DATE "2016-04-01", DATE "2016-04-30"
--   UNION ALL SELECT DATE "2016-07-01", DATE "2016-07-31"
--   UNION ALL SELECT DATE "2016-10-01", DATE "2016-10-31"
-- ) AS items;




-- Example
-- WITH your_current_result AS (
--   SELECT '2021-07-21T00:00:00Z' ProgressDate, 0.125 EstMin, 0.25 EstMax UNION ALL
--   SELECT '2021-07-24T00:00:00Z', 5.125, 5.375 UNION ALL
--   SELECT '2021-07-25T00:00:00Z', 8.75, 10.25 UNION ALL
--   SELECT '2021-07-26T00:00:00Z', 10.0, 12.0 UNION ALL
--   SELECT '2021-07-27T00:00:00Z', 10.5, 12.75 UNION ALL
--   SELECT '2021-08-01T00:00:00Z', 15.25, 19.125 UNION ALL
--   SELECT '2021-08-02T00:00:00Z', 15.5, 19.375 UNION ALL
--   SELECT '2021-08-05T00:00:00Z', 16.25, 20.625 
-- )

-- , days AS (
--   SELECT day
--   FROM (
--     SELECT 
--       MIN(DATE(TIMESTAMP(ProgressDate))) min_dt, 
--       MAX(DATE(TIMESTAMP(ProgressDate))) max_dt
--     FROM your_current_result
--   ), UNNEST(GENERATE_DATE_ARRAY(min_dt, max_dt)) day
-- )


-- SELECT 
-- day,
-- LAST_VALUE(EstMin IGNORE NULLS) OVER (ORDER BY day) AS EstMin,
-- LAST_VALUE(EstMax IGNORE NULLS) OVER (ORDER BY day) AS EstMax
-- FROM 
-- days AS n
-- LEFT JOIN 
-- your_current_result AS e
-- ON(DATE(TIMESTAMP(e.ProgressDate))=n.day)


-- Example2
--  Row1 which has no preceeding value returns current_value
-- IGNORE NULLS considers last filled value
WITH product_prices AS (
SELECT 'apple' AS product, 2.3 AS price,'20210205' AS date UNION ALL
SELECT 'apple' AS product, NULL AS price,'20210206' AS date UNION ALL
SELECT 'apple' AS product, 2.1 AS price,'20210207' AS date UNION ALL
SELECT 'apple' AS product, NULL AS price,'20210208' AS date UNION ALL
SELECT 'apple' AS product, 2.4 AS price,'20210209' AS date UNION ALL
SELECT 'apple' AS product, 1.0 AS price,'20210210' AS date UNION ALL
SELECT 'mango' AS product, 2.05 AS price,'20210204' AS date UNION ALL
SELECT 'mango' AS product, NULL AS price,'20210205' AS date UNION ALL
SELECT 'mango' AS product, 2.15 AS price,'20210206' AS date UNION ALL
SELECT 'mango' AS product, 2.2 AS price,'20210207' AS date UNION ALL
SELECT 'mango' AS product, NULL AS price,'20210208' AS date UNION ALL
SELECT 'mango' AS product, 2.3 AS price,'20210209' AS date 
)

SELECT
*
FROM (
SELECT
product,
date,
price,
LAST_VALUE(price IGNORE NULLS) OVER (PARTITION BY product ORDER BY date RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW ) AS last_value
FROM product_prices
GROUP BY 1,2,3
ORDER BY
product,
date DESC)