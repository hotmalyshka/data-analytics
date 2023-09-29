SELECT 
    date, 
    AVG((EXTRACT(epoch FROM time_delivered - time_accepted) / 60))::INTEGER AS minutes_to_deliver
FROM (
SELECT
    DISTINCT 
    time::DATE AS date,
    MAX(time) FILTER(WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')) OVER(PARTITION BY order_id) AS time_delivered,
    MIN(time) FILTER(WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')) OVER(PARTITION BY order_id) AS time_accepted
FROM courier_actions
) t
GROUP BY date
ORDER BY date