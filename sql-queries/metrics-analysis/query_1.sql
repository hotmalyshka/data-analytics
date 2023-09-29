SELECT 
    hour,
    successful_orders,
    canceled_orders,
    ROUND(canceled_orders::DECIMAL / orders_count, 3) AS cancel_rate
FROM (
SELECT 
    DATE_PART('hour', creation_time)::INTEGER AS hour,
    COUNT(order_id) FILTER(WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')) AS successful_orders,
    COUNT(order_id) FILTER(WHERE order_id IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')) AS canceled_orders,
    COUNT(order_id) AS orders_count
FROM orders
GROUP BY hour
) t
ORDER BY hour
