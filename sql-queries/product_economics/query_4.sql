SELECT 
    date, 
    ROUND(running_revenue::DECIMAL / running_users, 2) AS running_arpu,
    ROUND(running_revenue::DECIMAL / running_paying_users, 2) AS running_arppu,
    ROUND(running_revenue::DECIMAL / running_orders_count, 2) AS running_aov
FROM (SELECT 
    date,
    SUM(revenue) OVER(ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) running_revenue
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
) t3 
    LEFT JOIN (
        SELECT
            date,
            SUM(users) OVER(ORDER BY date ROWS UNBOUNDED PRECEDING) AS running_users,
            SUM(paying_users) OVER(ORDER BY date ROWS UNBOUNDED PRECEDING) AS running_paying_users,
            SUM(orders_count) OVER(ORDER BY date ROWS UNBOUNDED PRECEDING) AS running_orders_count
        FROM (
            SELECT 
                time::DATE AS date,
                COUNT(DISTINCT user_id) FILTER(WHERE time::DATE = first_day) AS users,
                COUNT(DISTINCT user_id) FILTER(WHERE time::DATE = first_payed) AS paying_users,
                COUNT(DISTINCT order_id) FILTER(WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')) AS orders_count
            FROM user_actions
                LEFT JOIN (
                    SELECT 
                        user_id,
                        MIN(time::DATE) AS first_day,
                        MIN(time::DATE) FILTER(WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')) AS first_payed
                    FROM user_actions
                    GROUP BY user_id) new_users USING(user_id)
            GROUP BY date
        ) t2
    ) t4 USING (date)