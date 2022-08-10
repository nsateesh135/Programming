
-- Resource : https://cloud.google.com/bigquery/docs/information-schema-intro
-- Resource : https://towardsdatascience.com/a-simple-way-to-query-table-metadata-in-google-bigquery-92dc7f1edec1

-- What is metadata?
-- 'data about data'
-- Underlying contextual information about a dataset that is stored alongside with the data
-- use case: Purpose, Content, Author, Data created/latupdated, Quality, Access rights, File size, Location



-- BigQuery dataset metadata
-- Returns one row per dataset in a GCP project
-- [PROJECT_ID.]INFORMATION_SCHEMA.SCHEMATA : For all regions
-- [PROJECT_ID.]`region-REGION`.INFORMATION_SCHEMA.SCHEMATA : For specific regions

-- Returns metadata for datasets in a region.
SELECT * FROM region-us.INFORMATION_SCHEMA.SCHEMATA;


SELECT * EXCEPT (schema_owner) FROM INFORMATION_SCHEMA.SCHEMATA;

-- BigQuery Job metadata
-- Realtime metadata about all BigQuery jobs in the current project
-- Change the region based on the requirement
-- job_type can be Query, Load
SELECT
  SUM(total_slot_ms) / (1000 * 60 * 60 * 24 * 7) AS avg_slots
FROM
  `region-us`.INFORMATION_SCHEMA.JOBS
WHERE
  -- Filter by the partition column first to limit the amount of data scanned.
  -- Eight days allows for jobs created before the 7 day end_time filter.
  creation_time BETWEEN TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 8 DAY) AND CURRENT_TIMESTAMP()
  AND job_type = 'QUERY'
  AND end_time BETWEEN TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY) AND CURRENT_TIMESTAMP();


  SELECT
    job_id,
    creation_time,
    query
  FROM
    `region-us`.INFORMATION_SCHEMA.JOBS_BY_USER
  WHERE
    state != 'DONE';



-- BigQuery table metadata
-- Returns one row for each table/view in the dataset
-- List all tables and their creation time from a single dataset

-- Returns metadata for tables in a single dataset.
SELECT * FROM myDataset.INFORMATION_SCHEMA.TABLES;

-- Returns last modified date for all BigQuery tables in a GCP project

SELECT *, TIMESTAMP_MILLIS(last_modified_time)
FROM `dataset.__TABLES__` where table_id = 'table_id'


SELECT dataset_id, table_id,
-- Convert size in bytes to GB
ROUND(size_bytes/POW(10,9),2) AS size_gb,
-- Convert creation_time and last_modified_time from UNIX EPOCH format to a timestamp
TIMESTAMP_MILLIS(creation_time) AS creation_time, TIMESTAMP_MILLIS(last_modified_time) AS last_modified_time,
row_count,
-- Convert table type from numerical value to description
CASE
WHEN type = 1 THEN 'table'
WHEN type = 2 THEN 'view'
ELSE NULL
END AS type
FROM `bigquery-public-data.ethereum_blockchain`.__TABLES__
ORDER BY size_gb DESC;

-- BigQuery Columns
-- Returns one row for each column in the table
-- [PROJECT_ID.]`region-REGION`.INFORMATION_SCHEMA.COLUMNS
-- [PROJECT_ID.]DATASET_ID.INFORMATION_SCHEMA.COLUMNS

SELECT
  * EXCEPT(is_generated, generation_expression, is_stored, is_updatable)
FROM
  `bigquery-public-data`.census_bureau_usa.INFORMATION_SCHEMA.COLUMNS
WHERE
  table_name = 'population_by_zip_2010';
