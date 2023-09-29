WITH 
revenue_by_weekday AS (
    SELECT
        weekday,
        weekday_number,
        SUM(price) AS revenue
    FROM (
    SELECT
        to_char(creation_time, 'Day') AS weekday,
        DATE_PART('isodow', creation_time) AS weekday_number,
        unnest(product_ids) AS product_id
    FROM orders
    WHERE creation_time BETWEEN '2022-08-26' AND '2022-09-09' AND order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
    ) t 
        LEFT JOIN products USING(product_id)
    GROUP BY weekday, weekday_number
),
users_orders_by_weekday AS (
    SELECT 
        to_char(time, 'Day') AS weekday,
        DATE_PART('isodow', time) AS weekday_number,
        COUNT(DISTINCT user_id) AS users,
        COUNT(DISTINCT user_id) FILTER(WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')) AS paying_users,
        COUNT(DISTINCT order_id) FILTER(WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')) AS orders_count
    FROM user_actions 
    WHERE time BETWEEN '2022-08-26' AND '2022-09-09'
    GROUP BY weekday, weekday_number
)

SELECT  
    r.weekday,
    r.weekday_number,
    ROUND(revenue::DECIMAL / users, 2) AS arpu,
    ROUND(revenue::DECIMAL / paying_users, 2) AS arppu,
    ROUND(revenue::DECIMAL / orders_count, 2) AS aov
FROM revenue_by_weekday r
    LEFT JOIN users_orders_by_weekday u USING(weekday_number)
ORDER BY weekday_number