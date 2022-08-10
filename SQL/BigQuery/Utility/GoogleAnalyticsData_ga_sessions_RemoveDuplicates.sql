--  Navigational Window functions

-- Rank()- RANK will give duplicates the same number and then skip the next number or numbers. Example A:1, B:1 Then there would be no rank 2 for C 
-- DENSE_RANK()- DENSE_RANK will give duplicates the same value and will not skip the next number. Example A:1, B:1 Then there would be rank 2 for C 
-- ROW_NUMBER()- does not double up at all and gives a unique number to each row.

-- Remove duplicate transcations from reporting 
-- When the customer reloads the order confirmation in a new session potentially on a new day and potentially even new user
-- The issue is often present when the order/receipt page can be revisited or re-viewed by the user, and this inadvertently triggers the transaction tracking again. That’s the most common cause, though note that some mobile browsers can also store the current website pages in memory when it’s closed/minimized, when loading the browser back up it reloads previous pages and therefore can trigger the order confirmation page again. A scenario that your development time might not be able to assist with

--  How to eliminate duplicate transactions
--  Step-1 : After succesful transcation save the transaction ID in the browsers cookie
--  Step-2 :Before tracking a transaction perform a quick check to see if the id alreadt exsists.

-- Note- As the solution requires cookies it will work on same device and browser.

-- Reference- https://datarunsdeep.com.au/blog/preventing-duplicate-transactions-google-analytics

WITH base AS (
SELECT
h.transaction.transactionid,
fullvisitorid,
visitstarttime,
date
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170801` 
,UNNEST(hits) AS h
WHERE h.transaction.transactionid IS NOT NULL
GROUP BY
1,2,3,4
),

transactioncounter AS (
SELECT 
base.*,
ROW_NUMBER() OVER (PARTITION BY transactionid ORDER BY visitstarttime ASC) AS transaction_counter
FROM base
)

SELECT
transactioncounter.*
FROM transactioncounter
WHERE transaction_counter = 1 