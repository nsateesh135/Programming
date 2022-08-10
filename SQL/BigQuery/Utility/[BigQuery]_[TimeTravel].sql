-- Resource : https://medium.com/mlearning-ai/how-to-access-historical-data-using-time-travel-in-bigquery-eb00f508b8fb
-- BigQuery time travel : Lets us restore deleted or changed data from BigQuery tables
-- We can access data only within last 7 days
-- The table must be natively stored in BigQuery and can't be external
-- Make sure the Timestamp is in UTC rather than local timezone

SELECT *
 FROM bigquery-public-data.samples.shakespeare FOR SYSTEM_TIME AS OF TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR);
