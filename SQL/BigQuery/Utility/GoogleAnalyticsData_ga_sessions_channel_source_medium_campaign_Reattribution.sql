-- Reattribute conversions to the correct traffic source BigQuery
-- Third party payment gateway is breaking your sessions because it takes your user to a different domain. You find sessions with your payment provider as the source (Afterpay, PayPal etc) having extremely high conversion rates. 
-- Referral Exclusion List- Traffic that arrives to your site from the excluded domain doesn’t trigger a new session, If you exclude third-party domains(after pay) that refer traffic, a new session is still triggered by the referral, but the source/medium information for that referring domain appears as (direct/none) in your reports, site entered in the referral exclution list excludes its subdomains as well


-- Reference- https://support.google.com/analytics/answer/2795830?hl=en-GB#zippy=
SELECT 
fullvisitorid,
visitstarttime,
CONCAT(trafficSource.source,' / ',trafficSource.medium) AS sourceMedium,
totals.transactions,
totals.totalTransactionRevenue / 1000000 AS revenue,
LAST_VALUE(CASE WHEN trafficsource.source = 'afterpay' THEN NULL ELSE CONCAT(trafficSource.source,' / ',trafficSource.medium )END IGNORE NULLS) OVER ( PARTITION BY fullvisitorId ORDER BY visitStartTime ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS reattributed_source
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*` 

-- Potentail use case using one of the client data

--------------------Base Query------------------------------------------------------------------------
WITH
-- This subquery ranks the frequency of site country within session. This gets joined at the end based on the most frequent site country. 
site_country AS (
SELECT
UniqueSessionID,
Site_Country,
row_number() OVER (PARTITION BY UniqueSessionID ORDER BY rowcount DESC) AS mostfrequentcountry
FROM(
SELECT
CONCAT( fullVisitorId,"-",CAST( visitStartTime AS STRING)) AS UniqueSessionID,
REGEXP_EXTRACT(page.pagepath,'^(?:[^\\/]*\\/){1}([^\\/|\\?]*)') AS site_country,
COUNT(*) AS rowcount
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*` 
,UNNEST(hits) AS hits
WHERE _table_suffix = @run_date 
GROUP BY
UniqueSessionID,
site_country
ORDER BY rowcount DESC
)

-- This subquery pulls base data information about the session including funnel/checkoutsteps. Note this grouped by hitnumber so we can create the landing page.exit page window functions across both the transactionid row and non-transactionid row
,BaseData AS ( 

SELECT
PARSE_DATE("%Y%m%d",date) AS Date
,fullVisitorId
,clientId
,CONCAT( fullVisitorId,"-",CAST( visitStartTime AS STRING)) AS UniqueSessionID
,visitstarttime
,IFNULL(totals.visits,0) AS valid_session
,MAX(totals.bounces) AS Bounces
,MAX(IFNULL(totals.timeOnSite,0)) AS TimeOnSite
,MAX(totals.pageviews) AS Pageviews
,geoNetwork.country AS Country
,geoNetwork.city AS City
,channelGrouping AS Channel
,trafficSource.isTrueDirect
,trafficSource.source
,trafficSource.medium
,CONCAT(trafficSource.source,"/",trafficSource.medium) AS SourceMedium
,trafficSource.campaign AS Campaign
,device.deviceCategory AS DeviceType
,MAX((SELECT value FROM UNNEST(sessions.customDimensions) WHERE index=20)) AS fpsId
,MAX((SELECT value FROM UNNEST(sessions.customDimensions) WHERE index=2)) AS LoggedInUser
,MAX((SELECT value FROM UNNEST(sessions.customDimensions) WHERE index=9)) AS TimeSlot
,page.pagePath
,hitnumber
,MAX(CASE WHEN isEntrance = TRUE THEN page.pagePath ELSE NULL END) OVER (PARTITION BY fullvisitorid , visitstarttime) AS LandingPage
,FIRST_VALUE(page.pagePath) OVER (PARTITION BY fullvisitorid , visitstarttime ORDER BY hitnumber ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS FirstPage
,MAX(CASE WHEN isExit = TRUE THEN page.pagePath ELSE NULL END) OVER (PARTITION BY fullvisitorid , visitstarttime) AS ExitPage
,LAST_VALUE(page.pagePath) OVER (PARTITION BY fullvisitorid , visitstarttime ORDER BY hitnumber ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS LastPage

,hits.transaction.transactionId AS TransactionID
,hits.transaction.transactionRevenue/1000000 AS Revenue
,SUM((SELECT SUM(p.productQuantity) FROM UNNEST(hits.product) p WHERE hits.transaction.transactionId IS NOT NULL)) AS Units_Sold

,CASE WHEN hits.eCommerceAction.action_type = '2' THEN 1 ELSE 0 END AS ProductDetailView
,CASE WHEN hits.eCommerceAction.action_type = '3' THEN 1 ELSE 0 END AS ProductAddToCart
,CASE WHEN hits.eCommerceAction.action_type = '4' THEN 1 ELSE 0 END AS ProductRemoveFromCart
,CASE WHEN hits.eCommerceAction.action_type = '5' THEN 1 ELSE 0 END AS Checkout
,CASE WHEN hits.eCommerceAction.action_type = '6' THEN 1 ELSE 0 END AS CheckoutComplete

,MAX((SELECT COUNT(p.productsku) FROM UNNEST(hits.product) p WHERE hits.eCommerceAction.action_type = '2' )) AS Total_ProductDetailViews
,MAX((SELECT COUNT(p.productsku) FROM UNNEST(hits.product) p WHERE hits.eCommerceAction.action_type = '3' )) AS Total_ProductAddsToBasket
,MAX((SELECT COUNT(p.productsku) FROM UNNEST(hits.product) p WHERE hits.eCommerceAction.action_type = '4' )) AS Total_ProductRemovesFromBasket
,MAX((SELECT COUNT(p.productsku) FROM UNNEST(hits.product) p WHERE hits.eCommerceAction.action_type = '5' AND hits.eCommerceAction.step = 1 )) AS Total_ProductCheckouts 
,MAX((SELECT COUNT(p.productsku) FROM UNNEST(hits.product) p WHERE hits.transaction.transactionId is not null )) AS Total_UniquePurchases

,CASE WHEN eventInfo.eventCategory = 'Store Locator' AND REGEXP_CONTAINS(eventInfo.eventAction, r'(Open|Search|Results|Signature Stores|Department Stores|Stockists|Offers facial Treatments)') THEN 1 ELSE 0 END AS Store_Locator_Used
,CASE WHEN eventInfo.eventCategory = 'Store Locator' AND REGEXP_CONTAINS(eventInfo.eventAction, r'(Store View|Result Click)') THEN 1 ELSE 0 END AS Seen_Store_or_Clicked_Store_in_Menu

,CASE WHEN eventInfo.eventCategory = 'Ecommerce' AND eventInfo.eventAction= 'Cart' AND eventInfo.eventLabel = 'Open' THEN 1 ELSE 0 END AS Opened_Cart
,CASE WHEN eventInfo.eventCategory = 'Ecommerce' AND eventInfo.eventAction= 'Cart' AND eventInfo.eventLabel = 'Close' THEN 1 ELSE 0 END AS Closed_Cart

,CASE WHEN eCommerceAction.option = 'Member' THEN 1 ELSE 0 END AS Checkout_Logged_In
,CASE WHEN eCommerceAction.option = 'Guest' THEN 1 ELSE 0 END AS Checkout_Guest

,CASE WHEN eCommerceAction.option = 'Collect in-store' THEN 1 ELSE 0 END AS Checkout_Collect_In_Store

,CASE WHEN eCommerceAction.option = 'Delivery' THEN 1 ELSE 0 END AS Checkout_Deliver_to_Door

,CASE WHEN ecommerceAction.action_type = '5' AND ecommerceAction.step = 1 THEN 1 ELSE 0 END AS Checkout_Step_1
,CASE WHEN ecommerceAction.step = 2 THEN 1 ELSE 0 END AS Checkout_Step_2
,CASE WHEN ecommerceAction.step = 3 THEN 1 ELSE 0 END AS Checkout_Step_3
,CASE WHEN ecommerceAction.step = 4 THEN 1 ELSE 0 END AS Checkout_Step_4
,CASE WHEN ecommerceAction.step = 5 THEN 1 ELSE 0 END AS Checkout_Step_5
,CASE WHEN ecommerceAction.step = 6 THEN 1 ELSE 0 END AS Checkout_Step_6
,CASE WHEN ecommerceAction.step = 7 THEN 1 ELSE 0 END AS Checkout_Step_7
,CASE WHEN ecommerceAction.step = 8 THEN 1 ELSE 0 END AS Checkout_Step_8
,CASE WHEN ecommerceAction.step = 9 THEN 1 ELSE 0 END AS Checkout_Step_9

,CASE WHEN ecommerceAction.step = 1 AND eCommerceAction.option = 'Guest' THEN 1 ELSE 0 END AS Enter_Checkout_Guest   

FROM FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
,UNNEST(hits) AS hits 

WHERE _table_suffix = @run_date 

GROUP BY 
hits.transaction.transactionId
,Date
,fullVisitorId
,clientId
,UniqueSessionID
,visitstarttime
,totals.visits
,geoNetwork.country
,geoNetwork.city
,channelGrouping
,trafficSource.isTrueDirect
,trafficSource.source
,trafficSource.medium
,trafficSource.campaign
,device.deviceCategory
,isEntrance
,isExit
,page.pagePath
,hitnumber
,transaction.transactionRevenue
,hits.eCommerceAction.action_type
,ecommerceAction.step
,ecommerceAction.option
,eventInfo.eventCategory
,eventInfo.eventAction
,eventInfo.eventLabel 

))
-- This subquery aggregates to one row per session + one row for each transactionid (the dedupe will be handled with the transaction and session tables)
SELECT

TransactionID
,Date
,fullVisitorId
,clientId
,n.UniqueSessionID
,visitstarttime
,valid_session
,CASE WHEN LENGTH(s.Site_Country) = 2 THEN s.Site_Country ELSE 'Unknown' END AS Site_Country
,Bounces
,TimeOnSite
,Pageviews
,Country
,City
,SourceMedium
,Channel
,Campaign
,DeviceType
,fpsId
,LoggedInUser
,TimeSlot        
,isTrueDirect
,source
,medium
,MAX(CASE WHEN LandingPage IS NOT NULL THEN LandingPage ELSE FirstPage END) AS LandingPage
,MAX(CASE WHEN ExitPage IS NOT NULL THEN ExitPage ELSE LastPage END) AS ExitPage

,COUNT(DISTINCT(transactionId)) AS Transactions 
,SUM(Revenue) AS Revenue
,SUM(Units_Sold) AS Units_Sold

,SUM(Total_ProductDetailViews) AS Total_ProductDetailViews  
,SUM(Total_ProductAddsToBasket) AS Total_ProductAddsToBasket  
,SUM(Total_ProductRemovesFromBasket) AS Total_ProductRemovesFromBasket 
,SUM(Total_ProductCheckouts) AS Total_ProductCheckouts 
,SUM(Total_UniquePurchases) AS Total_UniquePurchases 

,MAX(ProductDetailView) AS Sessionwith_ProductViews
,MAX(ProductAddToCart) AS Sessionwith_AddtoBasket
,MAX(ProductRemoveFromCart) AS Sessionwith_ProductRemovesFromBasket
,MAX(Checkout) AS Sessionwith_Checkout
 
,MAX(Store_Locator_Used) AS Store_Locator_Used
,MAX(Seen_Store_or_Clicked_Store_in_Menu) AS Seen_Store_or_Clicked_Store_in_Menu

,MAX(Opened_Cart) AS Opened_Cart
,MAX(Closed_Cart) AS Closed_Cart
,MAX(Checkout_Logged_In) AS Checkout_Logged_In
,MAX(Checkout_Guest) AS Checkout_Guest
,MAX(Enter_Checkout_Guest) AS Enter_Checkout_Guest

,MAX(Checkout_Collect_In_Store) AS Checkout_Collect_In_Store
,MAX(Checkout_Deliver_to_Door) AS Checkout_Deliver_to_Door

,MAX(Checkout_Step_1) AS Sessionwith_Checkout_Step_1
,MAX(Checkout_Step_2) AS Sessionwith_Checkout_Step_2
,MAX(Checkout_Step_3) AS Sessionwith_Checkout_Step_3
,MAX(Checkout_Step_4) AS Sessionwith_Checkout_Step_4
,MAX(Checkout_Step_5) AS Sessionwith_Checkout_Step_5
,MAX(Checkout_Step_6) AS Sessionwith_Checkout_Step_6
,MAX(Checkout_Step_7) AS Sessionwith_Checkout_Step_7
,MAX(Checkout_Step_8) AS Sessionwith_Checkout_Step_8
,MAX(Checkout_Step_9) AS Sessionwith_Checkout_Step_9

FROM BaseData n

LEFT JOIN site_country s ON n.UniqueSessionID = s.UniqueSessionID AND s.mostfrequentcountry = 1

GROUP BY         
TransactionID
,Date
,fullVisitorId
,clientId
,n.UniqueSessionID
,valid_session
,visitstarttime
,Bounces
,TimeOnSite
,Pageviews
,Site_Country
,Country
,City
,SourceMedium
,Channel
,Campaign
,DeviceType
,fpsId
,LoggedInUser
,TimeSlot
,isTrueDirect
,source
,medium
)

-- ----------------------Ist Query Session level----------------------------
--------------------------------------------------------------------------
-- Session Table with reattribution of payment gateways and coupons --
--------------------------------------------------------------------------

INSERT INTO `aesop-ga360-analytics.EnhancedData_14346041.SessionsData` (
--CREATE OR REPLACE TABLE `aesop-ga360-analytics.EnhancedData_14346041.SessionsData` PARTITION BY Date  OPTIONS (description="
-- This dataset has one row per session. 
-- It contains funnel/checkout steps and store locator flags. 
-- There are landing/exit page fields which will differ slightly from GA. 
-- If the session does not have an 'entrance' hit than the landing page is taken from the very first hit of the session. This is necessary for the reattribution logic. 
-- There are reattributed traffic source columns for payment gateways and coupons based on the following rules. 
-- 1: If the session did not land on the checkout page, it has payment source but it has a true direct flag, then reattribute to the last non-payment source. 
-- 2: If the session starts on checkout page and has a payment source, then reattribute to the last non-payment source. 
-- 3: If less than 24hours have passed between the current session and last non-coupon source, then reattribute to the last non-coupon source. 
-- 4: If more than 24hours have passed since the current session and last non-coupon source and it has a true direct flag, then label as direct. 
-- 5: If it does not meet the aforementioned criteria, keep the exisiting source.") 
-- AS (


SELECT
*
FROM 
(
SELECT 
Date
,fullVisitorId
,clientId
,UniqueSessionID
,visitstarttime
,valid_session
,Site_Country
,Country
,City
,DeviceType
,Channel
,SourceMedium
,Campaign
,MAX(CASE WHEN enrich.fpsId IS NOT NULL THEN enrich.fpsId
          WHEN base.fpsId IS NOT NULL THEN base.fpsId
          ELSE NULL END) AS fpsID
,LoggedInUser
,TimeSlot
,isTrueDirect
,LandingPage
,ExitPage
,Bounces
,TimeOnSite
,Pageviews

,SUM(Total_ProductDetailViews) AS Total_ProductDetailViews 
,SUM(Total_ProductAddsToBasket) AS Total_ProductAddsToBasket
,SUM(Total_ProductRemovesFromBasket) AS Total_ProductRemovesFromBasket 
,SUM(Total_ProductCheckouts) AS Total_ProductCheckouts 
,SUM(Total_UniquePurchases) AS Total_UniquePurchases 

,MAX(Sessionwith_ProductViews) AS Sessionwith_ProductViews
,MAX(Sessionwith_AddtoBasket) AS Sessionwith_AddtoBasket
,MAX(Sessionwith_ProductRemovesFromBasket) AS Sessionwith_ProductRemovesFromBasket
,MAX(Sessionwith_Checkout) AS Sessionwith_Checkout
,COUNT(DISTINCT(CASE WHEN transactionid IS NOT NULL THEN uniquesessionid ELSE NULL END)) AS Sessionwith_Transaction 

,MAX(Opened_Cart) AS Opened_Cart
,MAX(Closed_Cart) AS Closed_Cart
,MAX(Checkout_Logged_In) AS Checkout_Logged_In
,MAX(Checkout_Guest) AS Checkout_Guest
,MAX(Enter_Checkout_Guest) AS Enter_Checkout_Guest

,MAX(Checkout_Collect_In_Store) AS Checkout_Collect_In_Store
,MAX(Checkout_Deliver_to_Door) AS Checkout_Deliver_to_Door

,MAX(Sessionwith_Checkout_Step_1) AS Sessionwith_Checkout_Step_1
,MAX(Sessionwith_Checkout_Step_2) AS Sessionwith_Checkout_Step_2
,MAX(Sessionwith_Checkout_Step_3) AS Sessionwith_Checkout_Step_3
,MAX(Sessionwith_Checkout_Step_4) AS Sessionwith_Checkout_Step_4
,MAX(Sessionwith_Checkout_Step_5) AS Sessionwith_Checkout_Step_5
,MAX(Sessionwith_Checkout_Step_6) AS Sessionwith_Checkout_Step_6
,MAX(Sessionwith_Checkout_Step_7) AS Sessionwith_Checkout_Step_7
,MAX(Sessionwith_Checkout_Step_8) AS Sessionwith_Checkout_Step_8
,MAX(Sessionwith_Checkout_Step_9) AS Sessionwith_Checkout_Step_9

,MAX(Store_Locator_Used) AS Store_Locator_Used
,MAX(Seen_Store_or_Clicked_Store_in_Menu) AS Seen_Store_or_Clicked_Store_in_Menu

-- Reattribution statement

,CASE
-- payment gateway reattribution
WHEN REGEXP_CONTAINS(base.source ,r'3d|acs|secure|bank|pay|cash|card') AND isTrueDirect = TRUE AND NOT REGEXP_CONTAINS(LandingPage,r'\/checkout\/')  -- if it is a payment source but is true direct and has non-checkout landing page
THEN LAST_VALUE(CASE WHEN REGEXP_CONTAINS(base.source ,r'3d|acs|secure|bank|pay|cash|card') THEN NULL ELSE base.Channel END IGNORE NULLS) OVER (PARTITION BY fullVisitorId ORDER BY visitStartTime ASC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 FOLLOWING) -- then take the last non-payment Channel
WHEN REGEXP_CONTAINS(base.source ,r'3d|acs|secure|bank|pay|cash|card') AND REGEXP_CONTAINS(LandingPage,r'\/checkout\/') -- if it is a payment source and session starts on checkout page
THEN LAST_VALUE(CASE WHEN REGEXP_CONTAINS(base.source ,r'3d|acs|secure|bank|pay|cash|card') THEN NULL ELSE base.Channel END IGNORE NULLS) OVER (PARTITION BY fullVisitorId ORDER BY visitStartTime ASC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 FOLLOWING)  -- then take the last non-payment Channel

-- coupon reattribution
WHEN coupon.source IS NULL THEN base.Channel -- if it's not a coupon site then keep existing Channel
WHEN (visitstarttime - LAST_VALUE(CASE WHEN coupon.source IS NOT NULL THEN NULL ELSE visitStartTime END IGNORE NULLS) OVER (PARTITION BY fullVisitorId ORDER BY visitStartTime ASC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 FOLLOWING))<=86400 -- when there is less than 24hours between the current session and last non-coupon source
THEN LAST_VALUE(CASE WHEN coupon.source IS NOT NULL THEN NULL ELSE base.Channel END IGNORE NULLS) OVER (PARTITION BY fullVisitorId ORDER BY visitStartTime ASC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 FOLLOWING) -- then take the last non-coupon Channel
WHEN coupon.source IS NOT NULL AND isTrueDirect = TRUE THEN "Direct" -- when it's over 24hours since the current session and last non-coupoon source AND it's a true direct, then label Direct

ELSE base.Channel -- otherwise keep the existing Channel
END AS Reattributed_Channel

,CASE
-- payment gateway reattribution
WHEN REGEXP_CONTAINS(base.source ,r'3d|acs|secure|bank|pay|cash|card') AND isTrueDirect = TRUE AND NOT REGEXP_CONTAINS(LandingPage,r'\/checkout\/')  -- if it is a payment source but is true direct and has non-checkout landing page
THEN LAST_VALUE(CASE WHEN REGEXP_CONTAINS(base.source ,r'3d|acs|secure|bank|pay|cash|card') THEN NULL ELSE base.sourceMedium END IGNORE NULLS) OVER (PARTITION BY fullVisitorId ORDER BY visitStartTime ASC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 FOLLOWING) -- then take the last non-payment source/medium
WHEN REGEXP_CONTAINS(base.source ,r'3d|acs|secure|bank|pay|cash|card') AND REGEXP_CONTAINS(LandingPage,r'\/checkout\/') -- if it is a payment source and session starts on checkout page
THEN LAST_VALUE(CASE WHEN REGEXP_CONTAINS(base.source ,r'3d|acs|secure|bank|pay|cash|card') THEN NULL ELSE base.sourceMedium END IGNORE NULLS) OVER (PARTITION BY fullVisitorId ORDER BY visitStartTime ASC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 FOLLOWING)  -- then take the last non-payment source/medium

-- coupon reattribution
WHEN coupon.source IS NULL THEN base.sourceMedium -- if it's not a coupon site then keep existing source/medium
WHEN (visitstarttime - LAST_VALUE(CASE WHEN coupon.source IS NOT NULL THEN NULL ELSE visitStartTime END IGNORE NULLS) OVER (PARTITION BY fullVisitorId ORDER BY visitStartTime ASC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 FOLLOWING))<=86400 -- when there is less than 24hours between the current session and last non-coupon source
THEN LAST_VALUE(CASE WHEN coupon.source IS NOT NULL THEN NULL ELSE base.sourceMedium END IGNORE NULLS) OVER (PARTITION BY fullVisitorId ORDER BY visitStartTime ASC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 FOLLOWING) -- then take the last non-coupon source/medium
WHEN coupon.source IS NOT NULL AND isTrueDirect = TRUE THEN "(direct)/(none)" -- when it's over 24hours since the current session and last non-coupoon source AND it's a true direct, then label (direct)/(none)

ELSE base.sourceMedium -- otherwise keep the existing source/medium
END AS Reattributed_SourceMedium

,CASE
-- payment gateway reattribution
WHEN REGEXP_CONTAINS(base.source ,r'3d|acs|secure|bank|pay|cash|card') AND isTrueDirect = TRUE AND NOT REGEXP_CONTAINS(LandingPage,r'\/checkout\/')  -- if it is a payment source but is true direct and has non-checkout landing page
THEN LAST_VALUE(CASE WHEN REGEXP_CONTAINS(base.source ,r'3d|acs|secure|bank|pay|cash|card') THEN NULL ELSE base.Campaign END IGNORE NULLS) OVER (PARTITION BY fullVisitorId ORDER BY visitStartTime ASC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 FOLLOWING) -- then take the last non-payment Campaign
WHEN REGEXP_CONTAINS(base.source ,r'3d|acs|secure|bank|pay|cash|card') AND REGEXP_CONTAINS(LandingPage,r'\/checkout\/') -- if it is a payment source and session starts on checkout page
THEN LAST_VALUE(CASE WHEN REGEXP_CONTAINS(base.source ,r'3d|acs|secure|bank|pay|cash|card') THEN NULL ELSE base.Campaign END IGNORE NULLS) OVER (PARTITION BY fullVisitorId ORDER BY visitStartTime ASC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 FOLLOWING)  -- then take the last non-payment Campaign

-- coupon reattribution
WHEN coupon.source IS NULL THEN base.Campaign -- if it's not a coupon site then keep existing Campaign
WHEN (visitstarttime - LAST_VALUE(CASE WHEN coupon.source IS NOT NULL THEN NULL ELSE visitStartTime END IGNORE NULLS) OVER (PARTITION BY fullVisitorId ORDER BY visitStartTime ASC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 FOLLOWING))<=86400 -- when there is less than 24hours between the current session and last non-coupon source
THEN LAST_VALUE(CASE WHEN coupon.source IS NOT NULL THEN NULL ELSE base.Campaign END IGNORE NULLS) OVER (PARTITION BY fullVisitorId ORDER BY visitStartTime ASC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 FOLLOWING) -- then take the last non-coupon Campaign
WHEN coupon.source IS NOT NULL AND isTrueDirect = TRUE THEN "(not set)" -- when it's over 24hours since the current session and last non-coupoon source AND it's a true direct, then label (not set)

ELSE base.Campaign -- otherwise keep the existing Campaign
END AS Reattributed_Campaign

FROM `aesop-ga360-analytics.EnhancedData_14346041.BaseTableForTransactionsandSessionsData` base 

LEFT JOIN `aesop-ga360-analytics.aesop_enrichment_au.coupon_referral_sites` coupon ON coupon.source = base.source

LEFT JOIN (SELECT customer_id AS fpsid, order_id FROM `aesop-ga360-analytics.aesop_enrichment_au.transaction_data_all_channel`) enrich ON enrich.order_id = base.transactionid 

--WHERE date BETWEEN '2020-09-20' AND '2020-10-03'
WHERE date BETWEEN DATE_SUB(@run_date, INTERVAL 14 DAY) AND @run_date 

GROUP BY 
Date
,fullVisitorId
,clientId
,UniqueSessionID
,visitstarttime
,valid_session
,Site_Country
,Country
,City
,DeviceType
,base.Channel
,base.SourceMedium
,base.Campaign
,LoggedInUser
,TimeSlot
,isTrueDirect
,LandingPage
,ExitPage
,base.source
,coupon.source
,Bounces
,TimeOnSite
,Pageviews
)
--WHERE date = '2020-10-03' 
WHERE date = @run_date 
)

-- ----------------------2nd Query Transaction level----------------------------
--------------------------------------------------------------------------
-- Transaction Table with reattribution of payment gateways and coupons --
--------------------------------------------------------------------------
INSERT INTO `aesop-ga360-analytics.EnhancedData_14346041.TransactionsData` (
--PARTITION BY Date  OPTIONS (description="This dataset has one row per transactionid with the associated revenue and units sold. Note: the number of transactions (e.g. COUNT(DISTINCT(transactionid)) ) will not match the 'Transactions' number in GA as there can be multiple transactions listed against a single transactionid. This is usually a tracking issue where a user reloads their confirmation page. The transaction count in this table will be approximately 0.5% less than GA but is more accurate. There are reattributed traffic source columns for payment gateways and coupons based on the following rules. 1: If the session did not land on the checkout page, it has payment source but it has a true direct flag, then reattribute to the last non-payment source. 2: If the session starts on checkout page and has a payment source, then reattribute to the last non-payment source. 3: If less than 24hours have passed between the current session and last non-coupon source, then reattribute to the last non-coupon source. 4: If more than 24hours have passed since the current session and last non-coupon source and it has a true direct flag, then label as direct. 5: If it does not meet the aforementioned criteria, keep the exisiting source.") AS (

SELECT
* 

FROM 
(
SELECT 
TransactionID
,Date
,fullVisitorId
,clientId
,UniqueSessionID
,visitstarttime
,valid_session
,Site_Country
,Country
,City 
,Channel
,SourceMedium
,Campaign
,DeviceType
,MAX(CASE WHEN enrich.fpsId IS NOT NULL THEN enrich.fpsId
          WHEN base.fpsId IS NOT NULL THEN base.fpsId
          ELSE NULL END) AS fpsID
,LoggedInUser
,TimeSlot
,isTrueDirect
,ROW_NUMBER () OVER (PARTITION BY fullvisitorid,date,transactionid ORDER BY visitstarttime ASC) AS transactionid_count

,SUM(Revenue) AS Revenue
,SUM(Units_Sold) AS Units_Sold

,CASE
-- payment gateway reattribution
WHEN REGEXP_CONTAINS(base.source ,r'3d|acs|secure|bank|pay|cash|card') AND isTrueDirect = TRUE AND NOT REGEXP_CONTAINS(LandingPage,r'\/checkout\/')  -- if it is a payment source but is true direct and has non-checkout landing page
THEN LAST_VALUE(CASE WHEN REGEXP_CONTAINS(base.source ,r'3d|acs|secure|bank|pay|cash|card') THEN NULL ELSE base.Channel END IGNORE NULLS) OVER (PARTITION BY fullVisitorId ORDER BY visitStartTime ASC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 FOLLOWING) -- then take the last non-payment Channel
WHEN REGEXP_CONTAINS(base.source ,r'3d|acs|secure|bank|pay|cash|card') AND REGEXP_CONTAINS(LandingPage,r'\/checkout\/') -- if it is a payment source and session starts on checkout page
THEN LAST_VALUE(CASE WHEN REGEXP_CONTAINS(base.source ,r'3d|acs|secure|bank|pay|cash|card') THEN NULL ELSE base.Channel END IGNORE NULLS) OVER (PARTITION BY fullVisitorId ORDER BY visitStartTime ASC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 FOLLOWING)  -- then take the last non-payment Channel

-- coupon reattribution
WHEN coupon.source IS NULL THEN base.Channel -- if it's not a coupon site then keep existing Channel
WHEN (visitstarttime - LAST_VALUE(CASE WHEN coupon.source IS NOT NULL THEN NULL ELSE visitStartTime END IGNORE NULLS) OVER (PARTITION BY fullVisitorId ORDER BY visitStartTime ASC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 FOLLOWING))<=86400 -- when there is less than 24hours between the current session and last non-coupon source
THEN LAST_VALUE(CASE WHEN coupon.source IS NOT NULL THEN NULL ELSE base.Channel END IGNORE NULLS) OVER (PARTITION BY fullVisitorId ORDER BY visitStartTime ASC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 FOLLOWING) -- then take the last non-coupon Channel
WHEN coupon.source IS NOT NULL AND isTrueDirect = TRUE THEN "Direct" -- when it's over 24hours since the current session and last non-coupoon source AND it's a true direct, then label Direct

ELSE base.Channel -- otherwise keep the existing Channel
END AS Reattributed_Channel

,CASE
-- payment gateway reattribution
WHEN REGEXP_CONTAINS(base.source ,r'3d|acs|secure|bank|pay|cash|card') AND isTrueDirect = TRUE AND NOT REGEXP_CONTAINS(LandingPage,r'\/checkout\/')  -- if it is a payment source but is true direct and has non-checkout landing page
THEN LAST_VALUE(CASE WHEN REGEXP_CONTAINS(base.source ,r'3d|acs|secure|bank|pay|cash|card') THEN NULL ELSE base.sourceMedium END IGNORE NULLS) OVER (PARTITION BY fullVisitorId ORDER BY visitStartTime ASC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 FOLLOWING) -- then take the last non-payment source/medium
WHEN REGEXP_CONTAINS(base.source ,r'3d|acs|secure|bank|pay|cash|card') AND REGEXP_CONTAINS(LandingPage,r'\/checkout\/') -- if it is a payment source and session starts on checkout page
THEN LAST_VALUE(CASE WHEN REGEXP_CONTAINS(base.source ,r'3d|acs|secure|bank|pay|cash|card') THEN NULL ELSE base.sourceMedium END IGNORE NULLS) OVER (PARTITION BY fullVisitorId ORDER BY visitStartTime ASC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 FOLLOWING)  -- then take the last non-payment source/medium

-- coupon reattribution
WHEN coupon.source IS NULL THEN base.sourceMedium -- if it's not a coupon site then keep existing source/medium
WHEN (visitstarttime - LAST_VALUE(CASE WHEN coupon.source IS NOT NULL THEN NULL ELSE visitStartTime END IGNORE NULLS) OVER (PARTITION BY fullVisitorId ORDER BY visitStartTime ASC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 FOLLOWING))<=86400 -- when there is less than 24hours between the current session and last non-coupon source
THEN LAST_VALUE(CASE WHEN coupon.source IS NOT NULL THEN NULL ELSE base.sourceMedium END IGNORE NULLS) OVER (PARTITION BY fullVisitorId ORDER BY visitStartTime ASC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 FOLLOWING) -- then take the last non-coupon source/medium
WHEN coupon.source IS NOT NULL AND isTrueDirect = TRUE THEN "(direct)/(none)" -- when it's over 24hours since the current session and last non-coupoon source AND it's a true direct, then label (direct)/(none)

ELSE base.sourceMedium -- otherwise keep the existing source/medium
END AS Reattributed_SourceMedium

,CASE
-- payment gateway reattribution
WHEN REGEXP_CONTAINS(base.source ,r'3d|acs|secure|bank|pay|cash|card') AND isTrueDirect = TRUE AND NOT REGEXP_CONTAINS(LandingPage,r'\/checkout\/')  -- if it is a payment source but is true direct and has non-checkout landing page
THEN LAST_VALUE(CASE WHEN REGEXP_CONTAINS(base.source ,r'3d|acs|secure|bank|pay|cash|card') THEN NULL ELSE base.Campaign END IGNORE NULLS) OVER (PARTITION BY fullVisitorId ORDER BY visitStartTime ASC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 FOLLOWING) -- then take the last non-payment Campaign
WHEN REGEXP_CONTAINS(base.source ,r'3d|acs|secure|bank|pay|cash|card') AND REGEXP_CONTAINS(LandingPage,r'\/checkout\/') -- if it is a payment source and session starts on checkout page
THEN LAST_VALUE(CASE WHEN REGEXP_CONTAINS(base.source ,r'3d|acs|secure|bank|pay|cash|card') THEN NULL ELSE base.Campaign END IGNORE NULLS) OVER (PARTITION BY fullVisitorId ORDER BY visitStartTime ASC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 FOLLOWING)  -- then take the last non-payment Campaign

-- coupon reattribution
WHEN coupon.source IS NULL THEN base.Campaign -- if it's not a coupon site then keep existing Campaign
WHEN (visitstarttime - LAST_VALUE(CASE WHEN coupon.source IS NOT NULL THEN NULL ELSE visitStartTime END IGNORE NULLS) OVER (PARTITION BY fullVisitorId ORDER BY visitStartTime ASC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 FOLLOWING))<=86400 -- when there is less than 24hours between the current session and last non-coupon source
THEN LAST_VALUE(CASE WHEN coupon.source IS NOT NULL THEN NULL ELSE base.Campaign END IGNORE NULLS) OVER (PARTITION BY fullVisitorId ORDER BY visitStartTime ASC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 FOLLOWING) -- then take the last non-coupon Campaign
WHEN coupon.source IS NOT NULL AND isTrueDirect = TRUE THEN "(not set)" -- when it's over 24hours since the current session and last non-coupoon source AND it's a true direct, then label (not set)

ELSE base.Campaign -- otherwise keep the existing Campaign
END AS Reattributed_Campaign

FROM `aesop-ga360-analytics.EnhancedData_14346041.BaseTableForTransactionsandSessionsData` base 

LEFT JOIN `aesop-ga360-analytics.aesop_enrichment_au.coupon_referral_sites` coupon ON coupon.source = base.source

LEFT JOIN (SELECT customer_id AS fpsid, order_id FROM `aesop-ga360-analytics.aesop_enrichment_au.transaction_data_all_channel`) enrich ON enrich.order_id = base.transactionid 

WHERE 1=1
--AND date BETWEEN '2020-09-19' AND '2020-10-02'
AND date BETWEEN DATE_SUB(@run_date, INTERVAL 14 DAY) AND @run_date

GROUP BY 
TransactionID
,Date
,fullVisitorId
,clientId
,UniqueSessionID
,visitstarttime
,valid_session
,Site_Country
,Country
,City 
,Channel
,SourceMedium
,Campaign
,DeviceType
,LoggedInUser
,TimeSlot
,isTrueDirect
,base.source
,coupon.source
,LandingPage
,ExitPage
) 
WHERE transactionid IS NOT NULL
--AND date = '2020-10-02'
AND date = @run_date
)
