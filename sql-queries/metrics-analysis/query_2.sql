SELECT 
    date, 
    orders,
    first_orders,
    new_users_orders,
    ROUND(first_orders::DECIMAL / orders * 100, 2) AS first_orders_share,
    ROUND(new_users_orders::DECIMAL / orders * 100, 2) AS new_users_orders_share
FROM (
SELECT 
    time::DATE AS date,
    COUNT(DISTINCT order_id) FILTER(WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')) AS orders,
    COUNT(DISTINCT order_id) 
        FILTER(WHERE order_id IN (SELECT FIRST_VALUE(order_id) OVER(PARTITION BY user_id ORDER BY time) 
            FROM user_actions 
                WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order'))) AS first_orders
FROM user_actions 
GROUP BY date
) t
    LEFT JOIN (
        SELECT 
            first_day,
            COUNT(order_id) FILTER(WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')) new_users_orders
        FROM (SELECT user_id, MIN(time::DATE) AS first_day FROM user_actions GROUP BY user_id) t
            LEFT JOIN user_actions USING(user_id) 
        WHERE time::DATE = first_day
        GROUP BY first_day) b ON t.date = b.first_day
ORDER BY date