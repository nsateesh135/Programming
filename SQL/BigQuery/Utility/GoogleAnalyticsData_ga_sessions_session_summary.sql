CREATE TEMP FUNCTION chan(source string,medium string,channelgrouping string) AS (

CASE WHEN channelgrouping = 'Direct' THEN 'Direct'
WHEN channelgrouping = 'OrganicSearch' OR source = 'search' THEN 'OrganicSearch'
WHEN REGEXP_CONTAINS(source,r'paidsocial|affiliate|linkshare|social_influencer') OR (source='youtube' AND REGEXP_CONTAINS(medium,r'cpm|cpv|masthead|paid_feat|\(notset\)'))OR(source = 'facebook' AND REGEXP_CONTAINS(medium,r'cpm|cpc'))OR(REGEXP_CONTAINS(source,r'(I|i)nstagram') AND REGEXP_CONTAINS(medium,r'cpm|CPV|paid_story|cpc'))OR(source IN ('facebook.com','m.facebook.com','l.facebook.com',
'lm.facebook.com','instagram.com','l.instagram.com') AND medium='referral') OR(REGEXP_CONTAINS(source,r'social') AND medium='cpc') OR (source='IGShopping' AND medium='Social')OR(source='dashhudson' AND medium='instagram')THEN 'PaidSocial'
WHEN channelgrouping='Social'OR(source='Facebook' AND medium='(notset)') OR REGEXP_CONTAINS(medium,r'(O|o)rganic.*social')OR REGEXP_CONTAINS(source,r'(O|o)rganic.*social')OR(source='organicsocia' AND medium='facebook')OR(source='facebook' AND medium='kol') OR source LIKE'social%'OR(source='instagram+story' AND medium='Organic+social')THEN'OrganicSocial'
WHEN channelgrouping='Display'OR(source='nunnprogrammatic' AND medium='whitelist')OR(source='rtbhouse' AND medium IN('retargeting','(notset)'))OR(source='rtbhouse' AND medium='kol')THEN'Display'
WHEN channelgrouping='PaidSearch' THEN 'PaidSearch'
WHEN channelgrouping='Email' OR REGEXP_CONTAINS(medium,r'email')OR REGEXP_CONTAINS(source,r'email')THEN'Email'
WHEN channelgrouping='Referral' OR REGEXP_CONTAINS(medium,r'article|app|zalo|RatingsAndReviews')
#<<<mismatchduetoGAregexnotworkingORREGEXP_CONTAINS(source,r'insider|zalo|RatingsAndReviews')#
 OR(REGEXP_CONTAINS(source,r'After(P|p)ay') AND medium='Referral')THEN'Referral'
WHEN channelgrouping='OtherAdvertising' OR(source='PDP' AND medium='(notset)')OR(source='google' AND medium='website')OR(source='4885886' AND medium='video')OR REGEXP_CONTAINS(medium,r'print|sms|sfmc') OR REGEXP_CONTAINS(source,r'print|sms|sfmc')THEN'OtherAdvertising' ELSE 'Other'END);



SELECT
clientId,
CONCAT(fullVisitorId,CAST(visitStartTime AS string)) AS uniqueVisitId,
MAX(IF(h.hitNumber=1,h.hour,0))AS visitStartHour,
date,
device.deviceCategory AS device,
chan(trafficSource.source,trafficSource.medium,trafficSource.campaign) as channel,
IF(totals.newVisits=1,'NewUser','ReturningUser') AS userType,
totals.sessionQualityDim AS sessionquality,
MAX((select MAX(h_cd.value)from unnest(h.customDimensions)as h_cd where h_cd.index=11)) AS paymentmethod_checkout,
MAX((select MAX(h_cd.value)from unnest(h.customDimensions)as h_cd where h_cd.index=12))AS URLquery,
MAX(IF(('PAGE'=h.type)AND(REGEXP_CONTAINS(h.page.pagePath,'^.new.*')=true),1,0))AS browsed_new,
MAX(IF(('PAGE'=h.type)AND(REGEXP_CONTAINS(h.page.pagePath,'^.brands.*')=true),1,0))AS browsed_brands,
MAX(IF(('PAGE'=h.type)AND(REGEXP_CONTAINS(h.page.pagePath,'^.makeup.*')=true),1,0))AS browsed_makeup,
MAX(IF(('PAGE'=h.type)AND(REGEXP_CONTAINS(h.page.pagePath,'^.skin-care.*')=true),1,0))AS browsed_skincare,
MAX(IF(('PAGE'=h.type)AND(REGEXP_CONTAINS(h.page.pagePath,'^.fragrance.*')=true),1,0))AS browsed_fragrance,
MAX(IF(('PAGE'=h.type)AND(REGEXP_CONTAINS(h.page.pagePath,'^.hair.*')=true),1,0))AS browsed_hair,
MAX(IF(('PAGE'=h.type)AND(REGEXP_CONTAINS(h.page.pagePath,'^.body.*')=true),1,0))AS browsed_body,
MAX(IF(('PAGE'=h.type)AND(REGEXP_CONTAINS(h.page.pagePath,'^.accessories.*')=true),1,0))AS browsed_accessories,
MAX(IF(('PAGE'=h.type)AND(REGEXP_CONTAINS(h.page.pagePath,'^.men.*')=true),1,0))AS browsed_men,
MAX(IF(('PAGE'=h.type)AND(REGEXP_CONTAINS(h.page.pagePath,'^.edits.*')=true),1,0))AS browsed_edits,
MAX(IF(('PAGE'=h.type)AND(REGEXP_CONTAINS(h.page.pagePath,'^.gifts.*')=true),1,0))AS browsed_gifts,
MAX(IF(('PAGE'=h.type)AND(REGEXP_CONTAINS(h.page.pagePath,'^.booking.*')=true),1,0))AS browsed_booking,
MAX(IF(('PAGE'=h.type)AND(REGEXP_CONTAINS(h.page.pagePath,'^.the-mecca-memo.*')=true),1,0))AS browsed_memo,
MAX(IF(h.page.pagePath LIKE '%account%',1,0)) AS used_account,
MAX(IF(h.page.pagePath LIKE'%#start=%',1,0))AS used_pagination,
MAX(IF(h.page.pagePath LIKE'%#prefn1=%',1,0))AS used_filter,
MAX(IF(h.eventInfo.eventCategory='Ecommerce'AND h.eventInfo.eventAction='ProductView',1,0))AS productdetailview,
MAX(IF(h.eventInfo.eventCategory='Ecommerce'AND h.eventInfo.eventAction='AddtoCart',1,0))AS addtocart,
MAX(IF(h.eventInfo.eventCategory='Ecommerce'AND h.eventInfo.eventAction='Checkout',1,0))AS checkouts,
MAX(IF(h.eventInfo.eventCategory='Ecommerce'AND h.eventInfo.eventAction='Checkout'AND h.eventInfo.eventLabel='Step|1',1,0))AS proceedtocheckout,
MAX(IF(h.eventInfo.eventCategory='Ecommerce'AND h.eventInfo.eventAction='Checkout'AND h.eventInfo.eventLabel='Step|2',1,0))AS continuetopayment,
MAX(IF(h.eventInfo.eventCategory='Ecommerce'AND h.eventInfo.eventAction='Checkout'AND h.eventInfo.eventLabel='Step|3',1,0))AS placeorder,
MAX(IF(h.eventInfo.eventCategory='ecommerce'AND h.eventInfo.eventAction='purchase',1,0))AS transactionpresent,
SUM(IF(h.transaction.transactionId IS NOT NULL,1,0))AS transactions,
SUM(h.transaction.transactionRevenue/1000000)* MAX(IF(h.eventInfo.eventCategory='ecommerce'AND h.eventInfo.eventAction='purchase',1,0))AS revenue
FROM`{project_id}.{dataset_id}.ga_sessions_{date}`
,unnest(hits)as h
WHERE 1=1 AND totals.visits=1 and date between '20200607'and '20200613'
GROUP BY
clientId,
visitStartTime,
fullVisitorId,
date,
device,
userType,
sessionquality,
channel
