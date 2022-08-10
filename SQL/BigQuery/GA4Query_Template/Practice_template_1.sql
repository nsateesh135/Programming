WITH base AS (
SELECT 
user_pseudo_id,
SELECT p.value.int_value   FROM UNNEST(event_params) AS p WHERE p.key = 'ga_session_id')  AS ga_session_id
event_name,
MAX((SELECT p.value.string_value FROM UNNEST(event_params) AS p WHERE p.key = 'level' AND event_name = '<brand_level>')) AS brand_level,
MAX(IF(event_name = 'view_item',1,0)) AS viewed_product,
MAX(IF(event_name = 'search',1,0)) AS used_search,
MAX(IF(event_name = 'purchase',1,0)) AS purchased_item,
MAX((SELECT IF(p.value.string_value = 'READ ARTICLES',1,0) FROM UNNEST(event_params) AS p WHERE p.key = 'click_text' AND event_name = 'button_click')) AS clicked_review_article_button

FROM `<project_id>.<dataset_id>.events_*`

GROUP BY
1,2,3
HAVING viewed_product = 1
)

SELECT 
brand_level
COUNT(DISTINCT CONCAT(user_pseudo_id,ga_session_id)) AS sessions,
SUM(viewed_product) / COUNT(DISTINCT CONCAT(user_pseudo_id,ga_session_id)) AS viewed_product,
SUM(used_search) / COUNT(DISTINCT CONCAT(user_pseudo_id,ga_session_id)) AS used_search,
SUM(purchased_item) /COUNT(DISTINCT CONCAT(user_pseudo_id,ga_session_id)) AS purchased_item,
SUM(clicked_review_article_button) /COUNT(DISTINCT CONCAT(user_pseudo_id,ga_session_id)) AS clicked_review_article_button

FROM base

GROUP BY 1
ORDER BY 1