--  Identify data misisng in the ga_sessions
WITH ga_data AS (
SELECT 
PARSE_DATE("%Y%m%d",REGEXP_EXTRACT(table_id,r'20[0-9]{6,6}')) AS ga_date
FROM `projectID.dataset.__TABLES__` 
),

-- Use GENERATE_DATE_ARRAY() BQ function to generate date
generate_date AS (
SELECT 
generate_date
FROM
UNNEST(GENERATE_DATE_ARRAY(DATE_SUB(CURRENT_DATE(), INTERVAL 1 YEAR), CURRENT_DATE(), INTERVAL 1 DAY)) AS generate_date
)

SELECT 
*
FROM 
generate_date
LEFT JOIN
ga_data
ON(generate_date.generate_date=ga_data.ga_date)
