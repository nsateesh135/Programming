-- GA4 Queries

-- Resource:
-- Google
-- https://developers.google.com/analytics/bigquery/basic-queries
-- https://developers.google.com/analytics/bigquery/advanced-queries
-- https://support.google.com/analytics/answer/9037342?hl=en#

-- Unique events by date
SELECT
PARSE_DATE("%Y%m%d",event_date) AS event_date,
event_name,
COUNT(*) AS event_count
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201202'
GROUP BY 1,2
ORDER BY 3 DESC;

-- User count and new user count
WITH
UserInfo AS (
SELECT
user_pseudo_id,
MAX(IF(event_name IN ('first_visit', 'first_open'), 1, 0)) AS is_new_user
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201202'
GROUP BY 1)
SELECT
COUNT(*) AS user_count,
SUM(is_new_user) AS new_user_count
FROM UserInfo;

-- Average number of transactions per purchaser/user

SELECT
COUNT(*) / COUNT(DISTINCT user_pseudo_id) AS avg_transaction_per_purchaser
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE event_name IN ('in_app_purchase', 'purchase')
AND _TABLE_SUFFIX BETWEEN '20201201' AND '20201231';

-- Timestamp when purchase event occured
SELECT
event_timestamp,
TIMESTAMP_MICROS(event_timestamp) as event_timestamp_utc,
DATETIME(TIMESTAMP_MICROS(event_timestamp),"Australia/Melbourne") AS event_timestamp_aest,
(SELECT COALESCE(value.int_value, value.float_value, value.double_value)FROM UNNEST(event_params)WHERE key = 'value') AS event_value
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE event_name = 'purchase' AND _TABLE_SUFFIX BETWEEN '20201201' AND '20201202';

-- Top 10 items added to cart by users
SELECT
item_id,
item_name,
COUNT(DISTINCT user_pseudo_id) AS user_count
FROM `bigquery-public-data.ga4_obfuscated_web_ecommerce.events_*`,UNNEST(items)
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131' AND event_name IN ('add_to_cart')
GROUP BY
1, 2
ORDER BY
user_count DESC
LIMIT 10;

-- Purchasers versus Non -Purchasers Stats

WITH
UserInfo AS (
SELECT
user_pseudo_id,
COUNTIF(event_name = 'page_view') AS page_view_count,
COUNTIF(event_name IN ('in_app_purchase', 'purchase')) AS purchase_event_count
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201202'
GROUP BY 1)
SELECT
(purchase_event_count > 0) AS purchaser,
COUNT(*) AS user_count,
SUM(page_view_count) AS total_page_views,
SUM(page_view_count) / COUNT(*) AS avg_page_views,
FROM UserInfo
GROUP BY 1;

-- Sequence: page views for analysis
SELECT
user_pseudo_id,
event_timestamp,
(SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS visit_start_time,
(SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') AS page_location,
(SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_title') AS page_title
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE event_name = 'page_view' AND _TABLE_SUFFIX BETWEEN '20201201' AND '20201202'
ORDER BY
user_pseudo_id,
ga_session_id,
event_timestamp ASC;

-- Products purchased by customers who purchased a certain product(Products recommendation)

WITH Params AS ( SELECT 'Google Navy Speckled Tee' AS selected_product),
PurchaseEvents AS (
SELECT
user_pseudo_id,
items
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131' AND event_name = 'purchase'),
ProductABuyers AS (
SELECT DISTINCT user_pseudo_id FROM Params,PurchaseEvents,UNNEST(items) AS items WHERE items.item_name = selected_product
)

SELECT
items.item_name AS item_name,
SUM(items.quantity) AS item_quantity
FROM
Params,
PurchaseEvents,
UNNEST(items) AS items
WHERE user_pseudo_id IN (SELECT user_pseudo_id FROM ProductABuyers) AND items.item_name != selected_product
GROUP BY 1
ORDER BY item_quantity DESC;

-- Avg amt of purchases per session per user
-- Check session calculation
SELECT
user_pseudo_id,
COUNT(DISTINCT(SELECT EP.value.int_value FROM UNNEST(event_params) AS EP WHERE key = 'ga_session_id')) AS session_count,
AVG((SELECT COALESCE(EP.value.int_value, EP.value.float_value, EP.value.double_value)FROM UNNEST(event_params) AS EP WHERE key = 'value')) AS avg_spend_per_session_by_user,
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE event_name = 'purchase' AND _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
GROUP BY
  1;

-- Get the latest ga_session_id and ga_session_number for specific users during last 4 days.

DECLARE REPORTING_TIMEZONE STRING DEFAULT 'Australia/Melbourne';
DECLARE USER_PSEUDO_ID_LIST ARRAY<STRING> DEFAULT ['1005355938.1632145814', '979622592.1632496588', '1101478530.1632831095'];

CREATE TEMP FUNCTION GetParamValue(params ANY TYPE, target_key STRING)
AS ((SELECT `value` FROM UNNEST(params) WHERE key = target_key LIMIT 1));

CREATE TEMP FUNCTION GetDateSuffix(date_shift INT64, timezone STRING)
AS (
  (SELECT FORMAT_DATE('%Y%m%d', DATE_ADD(CURRENT_DATE(timezone), INTERVAL date_shift DAY)))
);

SELECT DISTINCT
  user_pseudo_id,
  FIRST_VALUE(GetParamValue(event_params, 'ga_session_id').int_value)
    OVER (UserWindow) AS ga_session_id,
  FIRST_VALUE(GetParamValue(event_params, 'ga_session_number').int_value)
    OVER (UserWindow) AS ga_session_number
FROM
  -- Replace table name.
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE
  user_pseudo_id IN UNNEST(USER_PSEUDO_ID_LIST)
  AND RIGHT(_TABLE_SUFFIX, 8)
    BETWEEN GetDateSuffix(-3, REPORTING_TIMEZONE)
    AND GetDateSuffix(0, REPORTING_TIMEZONE)
WINDOW UserWindow AS (PARTITION BY user_pseudo_id ORDER BY event_timestamp DESC);

-- Query Audience data

-- Purchasers
/**
 * Computes the audience of purchasers.
 *
 * Purchasers = users who have logged either in_app_purchase or
 * purchase.
 */
SELECT COUNT(DISTINCT user_id) AS purchasers_count FROM `YOUR_TABLE.events_*`
WHERE event_name IN ('in_app_purchase', 'purchase') AND _TABLE_SUFFIX BETWEEN '20180501' AND '20240131';


-- N-day active users
/**
 * Builds an audience of N-Day Active Users.
 *
 * N-day active users = users who have logged at least one event with event param
 * engagement_time_msec > 0 in the last N days.
*/

SELECT COUNT(DISTINCT user_id) AS n_day_active_users_count FROM `YOUR_TABLE.events_*` AS T,T.event_params
WHERE event_params.key = 'engagement_time_msec' AND event_params.value.int_value > 0
 AND event_timestamp > UNIX_MICROS(TIMESTAMP_SUB(CURRENT_TIMESTAMP, INTERVAL 20 DAY))
 AND _TABLE_SUFFIX BETWEEN '20180521' AND '20240131';

 N-day inactive users
/**
 * Builds an audience of N-Day Inactive Users.
 *
 * N-Day inactive users = users in the last M days who have not logged one
 * event with event param engagement_time_msec > 0 in the last N days
 *  where M > N.
 */
SELECT COUNT(DISTINCT MDaysUsers.user_id) AS n_day_inactive_users_count
FROM(
SELECT
user_id FROM `YOUR_TABLE.events_*` AS T,T.event_params
WHERE event_params.key = 'engagement_time_msec' AND event_params.value.int_value > 0
AND event_timestamp >UNIX_MICROS(TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY))
AND _TABLE_SUFFIX BETWEEN '20180521' AND '20240131'
) AS MDaysUsers
-- EXCEPT ALL is not yet implemented in BigQuery. Use LEFT JOIN in the interim.
LEFT JOIN
(SELECT user_id FROM `YOUR_TABLE.events_*`AS T,T.event_params
  WHERE event_params.key = 'engagement_time_msec' AND event_params.value.int_value > 0
  AND event_timestamp > UNIX_MICROS(TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 2 DAY))
  AND _TABLE_SUFFIX BETWEEN '20180521' AND '20240131'
  ) AS NDaysUsers
  ON MDaysUsers.user_id = NDaysUsers.user_id
WHERE
  NDaysUsers.user_id IS NULL;

-- Frequently active users
  /**
   * Builds an audience of Frequently Active Users.
   *
   * Frequently Active Users = users who have logged at least one
   * event with event param engagement_time_msec > 0 on N of
   * the last M days where M > N.
   */
SELECT COUNT(DISTINCT user_id) AS frequent_active_users_count
FROM(SELECT user_id, COUNT(DISTINCT event_date) FROM `YOUR_TABLE.events_*` AS T,T.event_params
WHERE event_params.key = 'engagement_time_msec' AND event_params.value.int_value > 0
AND event_timestamp >UNIX_MICROS(TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 10 DAY))
AND _TABLE_SUFFIX BETWEEN '20180521' AND '20240131'
GROUP BY 1
HAVING COUNT(event_date) >= 4);

-- Highly active users
/**
 * Builds an audience of Highly Active Users.
 *
 * Highly Active Users = users who have been active for more than N minutes
 * in the last M days where M > N.
*/
SELECT COUNT(DISTINCT user_id) AS high_active_users_count
FROM(SELECT
user_id,
event_params.key,
SUM(event_params.value.int_value)
FROM `YOUR_TABLE.events_*` AS T,T.event_params
WHERE event_timestamp > UNIX_MICROS(TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 10 DAY))
AND event_params.key = 'engagement_time_msec'
AND _TABLE_SUFFIX BETWEEN '20180521' AND '20240131'
GROUP BY 1, 2
HAVING SUM(event_params.value.int_value) > 0.1 * 60 * 1000000);

-- Acquired users
/**
 * Builds an audience of Acquired Users.
 *
 * Acquired Users = users who were acquired via some Source/Medium/Campaign.
 */

SELECT COUNT(DISTINCT user_id) AS acquired_users_count
FROM `YOUR_TABLE.events_*`
WHERE
traffic_source.source = 'google'
AND traffic_source.medium = 'cpc'
AND traffic_source.name = 'VTA-Test-Android'
  AND _TABLE_SUFFIX BETWEEN '20180521' AND '20240131';

  -- Cohorts with filters
  /**
   * Builds an audience composed of users acquired last week
   * through Google campaigns, i.e., cohorts with filters.
   *
   * Cohort is defined as users acquired last week, i.e. between 7 - 14
   * days ago. The cohort filter is for users acquired through a direct
   * campaign.
   */

  SELECT COUNT(DISTINCT user_id) AS users_acquired_through_google_count
  FROM `YOUR_TABLE.events_*`
  WHERE event_name = 'first_open'
    -- Cohort: opened app 1-2 weeks ago. One week of cohort, aka. weekly.
    AND event_timestamp > UNIX_MICROS(TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 14 DAY))
    AND event_timestamp < UNIX_MICROS(TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY))
    -- Cohort filter: users acquired through 'google' source.
    AND traffic_source.source = 'google'
    -- PLEASE REPLACE YOUR DESIRED DATE RANGE.
    AND _TABLE_SUFFIX BETWEEN '20180501' AND '20240131';
    
