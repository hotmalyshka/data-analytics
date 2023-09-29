WITH
users_count AS (
    SELECT 
        time::DATE AS date, 
        COUNT(DISTINCT user_id) FILTER(WHERE order_id NOT IN (SELECT order_id FROM user_Actions WHERE action = 'cancel_order')) AS paying_users
    FROM user_actions
    GROUP BY date
),
couriers_count AS (
    SELECT 
        time::DATE AS date,
        COUNT(DISTINCT courier_id) 
            FILTER(WHERE (action = 'accept_order' AND order_id NOT IN (SELECT order_id FROM user_Actions WHERE action = 'cancel_order'))
            OR action = 'deliver_order') AS active_couriers
    FROM courier_actions 
    GROUP BY date
),
orders_count AS (
    SELECT 
        time::DATE AS date,
        COUNT(DISTINCT order_id) FILTER(WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')) AS orders_count
    FROM user_actions
    GROUP BY date
)

SELECT 
    date,
    ROUND(paying_users::DECIMAL / active_couriers, 2) AS users_per_courier,
    ROUND(orders_count::DECIMAL / active_couriers, 2) AS orders_per_courier
FROM users_count
    LEFT JOIN couriers_count USING(date)
        LEFT JOIN orders_count USING(date)
ORDER BY date
    