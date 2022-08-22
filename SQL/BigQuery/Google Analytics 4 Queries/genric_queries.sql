-- Reference
--  https://infotrust.com/articles/3-queries-to-get-started-with-ga4-in-bigquery/
-- https://www.meliorum.com.au/blog/the-ga4-update-matching-big-query-data-with-google-analytics
-- https://towardsdatascience.com/how-to-query-and-calculate-ga-app-web-event-data-in-bigquery-a77931176d3

-- Engaged Session : The number of sessions that lasted longer than 10s or had a conversion event, or had 2 or more screen/pageviews
-- Engagement Rate : Engaged Sessions/Sessions

-- Users
SELECT count(DISTINCT user_pseudo_id) AS user_count,
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where _table_suffix BETWEEN "20210101" and "20210131"

--New Users
SELECT count(DISTINCT  case when event_name = "first_visit" then user_pseudo_id end) as new_users
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where _table_suffix BETWEEN "20210101" and "20210131"

-- Sessions
SELECT count(distinct case when event_name = "session_start" then  concat(user_pseudo_id,event_timestamp) end) as sessions
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where _table_suffix BETWEEN "20210101" and "20210131"

-- Pageviews
SELECT count(distinct case when event_name = "page_view" then  concat(user_pseudo_id,event_timestamp) end) as page_views
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where _table_suffix BETWEEN "20210101" and "20210131"

-- Bounce and Bouce Rate
SELECT count(distinct case when page_views = 1 then ga_session_id end) /count(distinct concat(user_pseudo_id, ga_session_id)) as session_bounce_rate
from(
SELECT
user_pseudo_id,
(select value.int_value from unnest(event_params) where key = 'ga_session_id') as ga_session_id,
count(distinct case when event_name = "page_view" then concat(user_pseudo_id,event_timestamp) end) as page_views
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where _table_suffix BETWEEN "20210101" and "20210131"
group by 1,2)

-- Engagement Rate
SELECT sum(cast(session_engaged as int))/count(distinct concat(user_pseudo_id, ga_session_id)) as session_engagement_rate
from(
SELECT
user_pseudo_id,
(select value.int_value from unnest(event_params) where key = 'ga_session_id') as ga_session_id,
max((select value.string_value from unnest(event_params) where key = 'session_engaged')) as session_engaged,
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where _table_suffix BETWEEN "20210101" and "20210131"
group by 1,2)

-- Average Session Duration
SELECT
sum(engagement_time_msec)/1000 #in milliseconds/count(distinct concat(user_pseudo_id,ga_session_id)) as ga4_session_duration,
sum(end_time-start_time)/1000000 #timestamp in microseconds/count(distinct concat(user_pseudo_id,ga_session_id)) as ua_session_duration,

from(
SELECT
user_pseudo_id,
(select value.int_value from unnest(event_params) where key = 'ga_session_id') as ga_session_id,
max((select value.int_value from unnest(event_params) where key = 'engagement_time_msec')) as engagement_time_msec,
min(event_timestamp) as start_time,
max(event_timestamp) as end_time
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where _table_suffix BETWEEN "20210101" and "20210131"
group by 1,2)

-- Number of Session/User
SELECT
count(distinct case when event_name = "session_start" then concat(user_pseudo_id,event_timestamp) end)/ count(distinct user_pseudo_id) as sessions_per_user
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where _table_suffix BETWEEN "20210101" and "20210131"

-- Pages per session
SELECT
count(distinct case when event_name = "page_view" then 
concat(user_pseudo_id,event_timestamp) end)/count(distinct case when event_name = "session_start" then concat(user_pseudo_id,event_timestamp) end) as page_per_session
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where _table_suffix BETWEEN "20210101" and "20210131"

-- Page Path/Screen Class

WITH pages AS (
SELECT 
user_pseudo_id,
event_name,
MAX (CASE WHEN params.key = "ga_session_id" THEN params.value.int_value ELSE 0 END) AS sessionId,
MAX(CASE WHEN key = "page_title" THEN value.string_value ELSE NULL END) AS page,
MAX(CASE WHEN event_name = 'page_view' and key = 'page_title' THEN value.string_value ELSE NULL END) AS pageTitle,
CASE WHEN event_name = "first_visit" then 1 else 0 END AS newUsers,
MAX((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'session_engaged')) as sessionEngaged,
MAX(CASE WHEN key =  "engagement_time_msec" then value.int_value else 0 END) AS engagementTimeMsec,
MAX(CASE WHEN event_name = "scroll" AND params.key = "percent_scrolled" THEN params.value.int_value ELSE 0 END) AS percentageScroll,
 -- Change event_name to include any/all conversion event(s) to show the count
COUNTIF(event_name = 'select_content' AND key = "page_title") AS conversions,
SUM(ecommerce.purchase_revenue) AS totalRevenue
FROM
  --- Update the below dataset to match your GA4 dataset and project
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`, UNNEST (event_params) AS params
WHERE _table_suffix BETWEEN '20210101' AND '20210131'
GROUP BY 
user_pseudo_id,
event_name),

-- Extract engagement time,pageCount and eventCount data
pageTop AS (
SELECT
user_pseudo_id, 
event_date, 
event_timestamp, 
event_name, 
MAX(CASE WHEN event_name = 'page_view' AND params.key = "page_title" THEN params.value.string_value END) AS pageCount,
MAX(CASE WHEN params.key = "page_title" THEN params.value.string_value ELSE NULL END) AS page,
MAX(CASE WHEN params.key = "engagement_time_msec" THEN params.value.int_value/1000 ELSE 0 END) AS engagementTimeMsec
FROM
  --- Update the below dataset to match your GA4 dataset and project
`bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`, unnest(event_params) as params

WHERE _table_suffix BETWEEN '20210101' AND '20210131'
GROUP BY user_pseudo_id, event_date, event_timestamp, event_name
),
--Summarize data for average engagement time, Views, Users, viewsPerUser and eventCount
pageTopSummary AS (
SELECT 
page, 
ROUND (SAFE_DIVIDE(SUM(engagementTimeMsec),COUNT(DISTINCT user_pseudo_id)),2) AS avgEngagementTime,
COUNT (pageCount) AS Views,
COUNT (DISTINCT user_pseudo_id) AS Users,
ROUND(COUNT (pageCount)/COUNT (DISTINCT user_pseudo_id),2) AS viewsPerUser
FROM 
pageTop
GROUP BY 
page)


-- MAIN QUERY
SELECT 
sub.page,
Views,
Users,
newUser,
viewsPerUser,
avgEngagementTime,
uniqueUserscrolls,
conversions,
totalRevenue
FROM (
SELECT 
page,
SUM (newUsers) as newUser,
COUNT(CASE WHEN percentageScroll = 90 THEN user_pseudo_id END) AS uniqueUserscrolls,
SUM(conversions) AS conversions,
CONCAT('$', IFNULL(SUM(totalRevenue),0)) AS totalRevenue
FROM pages
WHERE page IS NOT NULL
GROUP BY page)
-- Sub query to joining summary reports together 
sub
LEFT JOIN  pageTopSummary
ON 
pageTopSummary.page = sub.page
ORDER BY 
Users  DESC

-- Onsite Events – Pageviews

WITH events AS (
SELECT
event_name,
(select value.string_value from unnest(event_params) where key = 'page_title') as page_title,
SUM((select COUNT(value.string_value) from unnest(event_params) where key = 'page_title')) as event_count,
COUNT(DISTINCT user_pseudo_id) AS user,
count(distinct case when event_name = 'page_view' then concat(user_pseudo_id, cast(event_timestamp as string)) end) / count(distinct user_pseudo_id) as event_count_per_user,
SUM(ecommerce.purchase_revenue) AS total_revenue
FROM
    --- Update the below dataset to match your GA4 dataset and project
`bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE
    _table_suffix between '20210101' and '20210131'
    -- change event_name to select another event
    and event_name = 'page_view'
GROUP BY 
    event_name, 
    page_title
ORDER BY event_count DESC)
SELECT event_name, page_title, event_count, user, round(event_count_per_user, 2)as event_count_per_user, total_revenue
FROM events
ORDER BY event_count  DESC

-- Ecommerce Product Reporting 
WITH ecommerceProducts AS(
SELECT 
--Item name
item_name AS itemName,
--Item views
COUNT(CASE WHEN event_name = 'view_item' THEN CONCAT(event_timestamp, CAST(user_pseudo_id AS STRING)) ELSE NULL END) AS itemViews,
--Add-to-carts
COUNT(CASE WHEN event_name = 'add_to_cart' THEN CONCAT(event_timestamp, CAST(user_pseudo_id AS STRING)) ELSE NULL END) AS addToCarts,
--Cart-to-view-rate,
(CASE WHEN COUNT(CASE WHEN event_name = 'view_item' THEN  user_pseudo_id ELSE NULL END) = 0 THEN 0
ELSE COUNT(DISTINCT CASE WHEN event_name = 'add_to_cart' THEN user_pseudo_id  ELSE NULL END) /
COUNT(DISTINCT CASE WHEN event_name = 'view_item' THEN user_pseudo_id  ELSE NULL END) END  * 100)AS cartToViewRate,
--Ecommerce Purchases
COUNT(CASE WHEN event_name = 'purchase' THEN ecommerce.transaction_id ELSE NULL END) AS ecommercePurchases, 
--Purchase-to-view-rate
(CASE WHEN COUNT(CASE WHEN event_name = 'view_item' THEN  user_pseudo_id ELSE NULL END) = 0 THEN 0
ELSE COUNT(DISTINCT CASE WHEN event_name = 'purchase' THEN user_pseudo_id  ELSE NULL END) /
COUNT(DISTINCT CASE WHEN event_name = 'view_item' THEN user_pseudo_id  ELSE NULL END) END  * 100) AS purchaseToViewRate,
--Item purchase quantity
SUM(CASE WHEN event_name = 'purchase' THEN items.quantity  ELSE NULL END) AS itemPurchaseQuantity,
--Item revenue
SUM(item_revenue) AS itemRevenue
FROM 
--- Update the below dataset to match your GA4 dataset and project
`bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
UNNEST(items) AS items
WHERE _table_suffix BETWEEN '20210101' AND '20210131'
GROUP BY itemName) 

SELECT itemName, itemViews, addToCarts,
cartToViewRate, ecommercePurchases,  purchaseToViewRate, itemPurchaseQuantity, itemRevenue
FROM ecommerceProducts
WHERE itemViews > 0 OR itemRevenue > 0
ORDER BY itemViews DESC

-- Ecommerce Reporting
select
-- transaction id (dimension | the transaction id of the ecommerce transaction)
ecommerce.transaction_id,
-- total item quantity (metric | total number of items in this event, which is the sum of items.quantity)
sum(ecommerce.total_item_quantity) as total_item_quantity,
-- purchase revenue in usd (metric | purchase revenue of this event, represented in usd with standard unit, populated for purchase event only)
sum(ecommerce.purchase_revenue_in_usd) as purchase_revenue_in_usd,
-- purchase revenue (metric | purchase revenue of this event, represented in local currency with standard unit, populated for purchase event only)
sum(ecommerce.purchase_revenue) as purchase_revenue,
-- refund value in usd (metric | the amount of refund in this event, represented in usd with standard unit, populated for refund event only)
sum(ecommerce.refund_value_in_usd) as refund_value_in_usd,
-- refund value (metric | the amount of refund in this event, represented in local currency with standard unit, populated for refund event only)
sum(ecommerce.refund_value) as refund_value,
-- shipping value in usd (metric | the shipping cost in this event, represented in usd with standard unit)
sum(ecommerce.shipping_value_in_usd) as shipping_value_in_usd,
-- shipping value (metric | the shipping cost in this event, represented in local currency)
sum(ecommerce.shipping_value) as shipping_value,
-- tax value in usd (metric | the tax value in this event, represented in usd with standard unit)
sum(ecommerce.tax_value_in_usd) as tax_value_in_usd,
-- tax value (metric | the tax value in this event, represented in local currency with standard unit)
sum(ecommerce.tax_value) as tax_value,
-- unique items (metric | the number of unique items in this event, based on item_id, item_name, and item_brand)
sum(ecommerce.unique_items) as unique_items
from
-- change this to your google analytics 4 export location in bigquery
`ga4bigquery.analytics_250794857.events_*`
where
-- define static and/or dynamic start and end date
_table_suffix between '20201101' and format_date('%Y%m%d',date_sub(current_date(), interval 1 day))
and ecommerce.transaction_id is not null
group by transaction_id


-- Page Tracking 
-- subquery to define static and/or dynamic start and end date for the whole query
with date_range as (
select '20201101' as start_date, format_date('%Y%m%d',date_sub(current_date(), interval 1 day)) as end_date),
-- subquery to prepare and calculate page view data
pages as (
select
user_pseudo_id,
(select value.int_value from unnest(event_params) where event_name = 'page_view' and key = 'ga_session_id') as session_id,
event_timestamp,
event_name,
(select device.web_info.hostname from unnest(event_params) where event_name = 'page_view' and key = 'page_location') as hostname,
(select value.string_value from unnest(event_params) where event_name = 'page_view' and key = 'page_location') as page,
lag((select value.string_value from unnest(event_params) where event_name = 'page_view' and key = 'page_location'), 1) over (partition by user_pseudo_id,(select value.int_value from unnest(event_params) where event_name = 'page_view' and key = 'ga_session_id') order by event_timestamp asc) as previous_page,
case when split(split((select value.string_value from unnest(event_params) where event_name = 'page_view' and key = 'page_location'),'/')[safe_ordinal(4)],'?')[safe_ordinal(1)] = '' then null else concat('/',split(split((select value.string_value from unnest(event_params) where event_name = 'page_view' and key = 'page_location'),'/')[safe_ordinal(4)],'?')[safe_ordinal(1)]) end as pagepath_level_1,
case when split(split((select value.string_value from unnest(event_params) where event_name = 'page_view' and key = 'page_location'),'/')[safe_ordinal(5)],'?')[safe_ordinal(1)] = '' then null else concat('/',split(split((select value.string_value from unnest(event_params) where event_name = 'page_view' and key = 'page_location'),'/')[safe_ordinal(5)],'?')[safe_ordinal(1)]) end as pagepath_level_2,
case when split(split((select value.string_value from unnest(event_params) where event_name = 'page_view' and key = 'page_location'),'/')[safe_ordinal(6)],'?')[safe_ordinal(1)] = '' then null else concat('/',split(split((select value.string_value from unnest(event_params) where event_name = 'page_view' and key = 'page_location'),'/')[safe_ordinal(6)],'?')[safe_ordinal(1)]) end as pagepath_level_3,
case when split(split((select value.string_value from unnest(event_params) where event_name = 'page_view' and key = 'page_location'),'/')[safe_ordinal(7)],'?')[safe_ordinal(1)] = '' then null else concat('/',split(split((select value.string_value from unnest(event_params) where event_name = 'page_view' and key = 'page_location'),'/')[safe_ordinal(7)],'?')[safe_ordinal(1)]) end as pagepath_level_4,
(select value.string_value from unnest(event_params) where event_name = 'page_view' and key = 'page_title') as page_title,
case when (select value.int_value from unnest(event_params) where event_name = 'page_view' and key = 'entrances') = 1 then (select value.string_value from unnest(event_params) where event_name = 'page_view' and key = 'page_location') end as landing_page,
case when (select value.int_value from unnest(event_params) where event_name = 'page_view' and key = 'entrances') = 1 then lead((select value.string_value from unnest(event_params) where event_name = 'page_view' and key = 'page_location'), 1) over (partition by user_pseudo_id,(select value.int_value from unnest(event_params) where event_name = 'page_view' and key = 'ga_session_id') order by event_timestamp asc) else null end as second_page,
case when (select value.string_value from unnest(event_params) where event_name = 'page_view' and key = 'page_location') = first_value((select value.string_value from unnest(event_params) where event_name = 'page_view' and key = 'page_location')) over (partition by user_pseudo_id,(select value.int_value from unnest(event_params) where event_name = 'page_view' and key = 'ga_session_id') order by event_timestamp desc) then ( select value.string_value from unnest(event_params) where event_name = 'page_view' and key = 'page_location') else null end as exit_page
from
-- change this to your google analytics 4 export location in bigquery
`ga4bigquery.analytics_250794857.events_*`,
date_range
where _table_suffix between date_range.start_date and date_range.end_date and event_name = 'page_view')

-- main query
select
-- hostname (dimension | the hostname from which the tracking request was made)
hostname,
-- page (dimension | a page on the website specified by path and/or query parameters)
page,
-- previous page path (dimension | a page visited before another page on the same property)
previous_page,
-- page path level 1 (dimension | this dimension rolls up all the page paths in the first hierarchical level)
pagepath_level_1,
-- page path level 2 (dimension | this dimension rolls up all the page paths in the second hierarchical level)
pagepath_level_2,
-- page path level 3 (dimension | this dimension rolls up all the page paths in the third hierarchical level)
pagepath_level_3,
-- page path level 4 (dimension | this dimension rolls up all the page paths in the fourth hierarchical level)
pagepath_level_4,
-- page title (dimension | the web page's title, multiple pages might have the same page title)
page_title,
-- landing page (dimension | the first page in users' sessions)
landing_page,
-- second page (dimension | the second page in users' sessions)
second_page,
-- exit page (dimension | the last page in users' sessions)
exit_page,
-- entrances (metric | the number of entrances to the property measured as the first pageview in a session)
count(landing_page) as entrances,
-- pageviews (metric | the total number of pageviews for the property)
count(page) as pageviews,
-- unique pageviews (metric | the number of sessions during which the specified page was viewed at least once, a unique pageview is counted for each page url + page title combination)
count(distinct concat(page,page_title,session_id)) as unique_pageviews,
-- pages / session (metric | the average number of pages viewed during a session, including repeated views of a single page)
count(page) / count(distinct session_id) as pages_per_session,
-- exits (metric | the number of exits from the property)
count(exit_page) as exits,
-- exit % (metric | the percentage of exits from the property that occurred out of the total pageviews)
count(exit_page) / count(page) as exit_rate
from
pages,
date_range
group by
hostname,
page,
previous_page,
pagepath_level_1,
pagepath_level_2,
pagepath_level_3,
pagepath_level_4,
page_title,
landing_page,
second_page,
exit_page
