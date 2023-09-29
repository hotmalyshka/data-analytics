SELECT 
    date,
    ROUND(revenue::DECIMAL / users, 2) AS arpu,
    ROUND(revenue::DECIMAL / paying_users, 2) AS arppu,
    ROUND(revenue::DECIMAL / orders_count, 2) AS aov
FROM (
    SELECT 
        date, 
        SUM(price) AS revenue
    FROM (
    SELECT 
        creation_time::DATE AS date,
        unnest(product_ids) AS product_id
    FROM orders
    WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
    ) t 
        LEFT JOIN products USING(product_id)
    GROUP BY date
) t1    
    LEFT JOIN (
            SELECT 
                time::DATE AS date,
                COUNT(DISTINCT user_id) AS users, 
                COUNT(DISTINCT user_id) FILTER(WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')) AS paying_users,
                COUNT(DISTINCT order_id) FILTER(WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')) AS orders_count
            FROM user_actions
            GROUP BY date
        ) a USING(date)
ORDER BY date
