date,
hits.TRANSACTION.transactionId AS transactionID,
fullVisitorId,
CONCAT(fullVisitorId, CAST(visitStartTime AS STRING)) AS uniqueVisitId,
device.deviceCategory AS device,
COUNT(DISTINCT hits.TRANSACTION.transactionId) AS transactions,
SUM(hits.TRANSACTION.transactionRevenue)/1000000 AS revenue,
SUM(hits.TRANSACTION.transactionShipping)/1000000 AS shipping,
SUM(hits.TRANSACTION.transactionTax)/1000000 AS tax,
MAX((SELECT MAX(hits_cd.value) FROM UNNEST(hits.customDimensions) AS hits_cd WHERE hits_cd.INDEX = 11)) AS paymentMethodCheckout
FROM
  `{project_id}.{dataset_id}.ga_sessions_{date}`,
  UNNEST(hits) AS hits
WHERE
  totals.visits = 1
GROUP BY
  date,
  TransactionID,
  fullVisitorId,
  device,
  visitStartTime,
  fullVisitorId
HAVING
  hits.TRANSACTION.transactionId IS NOT NULL
ORDER BY
  1 DESC
