SELECT
date,
hits.TRANSACTION.transactionId AS transactionID,
productSku AS productSKU,
v2ProductName AS product,
v2ProductCategory AS productCategory,
productBrand AS productBrand,
productVariant AS productVariant,
COUNT(CASE WHEN hits.eCommerceAction.action_type = '2' THEN fullVisitorId ELSE NULL END) AS productDetailViews,
COUNT(CASE WHEN hits.eCommerceAction.action_type = '3' THEN fullVisitorId ELSE NULL END) AS addsToBag,
COUNT(CASE WHEN hits.eCommerceAction.action_type = '5' THEN fullVisitorId ELSE NULL END) AS checkouts,
COUNT(CASE WHEN productSKU IS NOT NULL THEN hits.TRANSACTION.transactionId ELSE NULL END) AS uniquePurchases,
SUM(CASE WHEN hits.eCommerceAction.action_type = '6' THEN localProductRevenue/1000000 ELSE NULL END) AS productRevenue,
productQuantity AS productQuantity
FROM
  `{project_id}.{dataset_id}.ga_sessions_{date}`,
  UNNEST(hits) AS hits LEFT JOIN
  UNNEST(product) AS product
WHERE
  totals.visits = 1
GROUP BY
 date,
 ProductSKU,
 TransactionID,
 Product,
 ProductCategory,
 productBrand,
 productVariant,
 productQuantity
HAVING
  ProductSKU IS NOT NULL
ORDER BY
  ProductSKU DESC
