WITH 
revenue_table AS (
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
),
revenue_new_users AS (
    SELECT 
        date,
        SUM(price) AS new_users_revenue
    FROM (
        SELECT 
            time::DATE AS date,
            user_id,
            first_time,
            unnest(product_ids) AS product_id
        FROM user_actions
            LEFT JOIN (
                SELECT 
                    user_id,
                    MIN(time::DATE) AS first_time
                FROM user_actions
                GROUP BY user_id
                ) t1 USING(user_id)
                LEFT JOIN orders USING(order_id)
        WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
    ) t2 
        LEFT JOIN products USING(product_id)
    WHERE date = first_time
    GROUP BY date
)
    
SELECT 
    date,
    revenue,
    new_users_revenue,
    ROUND(new_users_revenue::DECIMAL / revenue * 100, 2) AS new_users_revenue_share,
    ROUND((revenue - new_users_revenue) / revenue * 100, 2) AS old_users_revenue_share
FROM revenue_table
    LEFT JOIN revenue_new_users USING(date)
ORDER BY date