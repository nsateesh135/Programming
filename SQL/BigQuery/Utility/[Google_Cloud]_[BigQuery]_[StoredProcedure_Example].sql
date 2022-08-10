-- Stored_Procedure
-- The following example attempts to find a correlation between precipitation and number of births or birth weight in 1988 with the natality public data using temporary tables. (Spoiler alert: It initially looks like there is no correlation!)

-- Day-level natality data is not available after 1988, and
-- state-level data is not available after 2004.
DECLARE target_year INT64 DEFAULT 1988;

CREATE TEMP TABLE SampledNatality AS
SELECT 
DATE(year, month, day) AS date, 
state, 
AVG(weight_pounds) AS avg_weight, 
COUNT(*) AS num_births
FROM `bigquery-public-data.samples.natality`
WHERE year = target_year AND SAFE.DATE(year, month, day) IS NOT NULL  -- Skip invalid dates
GROUP BY date, state;

IF (SELECT COUNT(*) FROM SampledNatality) = 0 THEN
  SELECT FORMAT("The year %d doesn't have day-level data", target_year);
  RETURN;
END IF;

CREATE TEMP TABLE StationsAndStates AS
SELECT 
wban, 
MAX(state) AS state
FROM `bigquery-public-data.noaa_gsod.stations`
GROUP BY wban;

CREATE TEMP TABLE PrecipitationByDateAndState AS
SELECT
DATE(CAST(year AS INT64), 
CAST(mo AS INT64), 
CAST(da AS INT64)) AS date,
(SELECT state FROM StationsAndStates AS stations WHERE stations.wban = gsod.wban) AS state,
  -- 99.99 indicates that precipitation was unknown
  AVG(NULLIF(prcp, 99.99)) AS avg_prcp
FROM `bigquery-public-data.noaa_gsod.gsod*` AS gsod
WHERE _TABLE_SUFFIX = CAST(target_year AS STRING)
GROUP BY date, state;

SELECT
CORR(avg_weight, avg_prcp) AS weight_correlation,
CORR(num_births, avg_prcp) AS num_births_correlation
FROM SampledNatality AS avg_weights
JOIN PrecipitationByDateAndState AS precipitation
USING (date, state);