--- Identify potential session breakage
--- Impacts:Inflated sessions,pages/session and session dusration understated, attributing conversions to the wrong source.
-- When: User inactivity(30 min), Change in campaign source mid session, midnight, UTM tags on internal links, GCLID getting dropped  
--  with redirects or virtual pages, cross domain tracking issues

-- Idea:Isolate sessions that start 10 seconds of the previous session
WITH 
base_data AS (
SELECT 
fullvisitorid,
clientid,
CONCAT(fullvisitorid,visitstarttime) AS uniqueVisitID,
visitnumber,
CONCAT(trafficsource.source,' / ',trafficsource.medium) AS sourceMedium,
MAX(IF(h.isentrance IS TRUE, page.pagePath,NULL)) AS landingPage,
MAX(IF(h.isexit IS TRUE, page.pagePath,NULL)) AS exitPage,
visitstarttime,
visitstarttime + IFNULL(totals.timeonsite,0) as visitendtime,
DATETIME(TIMESTAMP_SECONDS(visitStartTime), "Australia/Melbourne") AS starttime_local,
DATETIME(TIMESTAMP_SECONDS(visitstarttime + IFNULL(totals.timeonsite,0)), "Australia/Melbourne") AS endtime_local
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
,UNNEST(hits) AS h
WHERE totals.visits = 1 # Sessions start with interactive hits.
-- AND _table_suffix BETWEEN '20200401' AND '20200430'
GROUP BY 
1,2,3,4,5,8,9,10,11
)
,nextsession_section AS (

SELECT
base_data.*,
LEAD (visitnumber) OVER (PARTITION BY fullvisitorid ORDER BY visitstarttime ASC) AS nextsession_visitnumber,
LEAD (SourceMedium) OVER (PARTITION BY fullvisitorid ORDER BY visitstarttime ASC) AS nextsession_sourceMedium,
LEAD (LandingPage) OVER (PARTITION BY fullvisitorid ORDER BY visitstarttime ASC) AS nextsession_landingPage,
LEAD (visitstarttime) OVER (PARTITION BY fullvisitorid ORDER BY visitstarttime ASC) AS nextsession_starttime,
LEAD (starttime_LOCAL) OVER (PARTITION BY fullvisitorid ORDER BY visitstarttime ASC) AS nextsession_starttime_local,
CASE WHEN LEAD (visitnumber) OVER (PARTITION BY fullvisitorid ORDER BY visitstarttime ASC) =  visitnumber THEN 'Yes' ELSE 'No' END AS midnightsession
FROM base_data
)
SELECT 
fullvisitorid,
clientid,
uniqueVisitID,
visitnumber,
(visitendtime - visitstarttime) AS sessiondurationsec,
sourceMedium,
nextsession_sourceMedium,
landingpage,
exitPage,
nextsession_landingPage,
starttime_local,
endtime_local,
nextsession_starttime_local,
CAST(nextsession_starttime AS INT64) - visitendtime AS timebetweensessions
FROM nextsession_section

WHERE nextsession_visitnumber IS NOT NULL  -- only show sessions with a "next" session
AND midnightsession = 'No'  -- ignore sessions that break at midnight
AND CAST(nextsession_starttime AS INT64) - visitendtime  <= 10 -- the next session starts within 10sec of the current session, this depends on the page load for the website

ORDER BY fullvisitorid ASC,visitnumber ASC

-- Test
-- The source/medium changes from google/cpc to google/organic and then back to google/cpc within a few seconds of each other- gclid is getting dropped overstating paid and organic sessions.
-- The next session source/medium contains your domain name- UTM tags on internal links
-- The next session landing page is not a page you could enter from on an external source- cross domain tracking 