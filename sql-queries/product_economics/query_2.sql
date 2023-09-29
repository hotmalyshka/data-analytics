SELECT 
    date,
    revenue,
    SUM(revenue) OVER(ORDER BY date ROWS UNBOUNDED PRECEDING) AS total_revenue,
    ROUND((revenue - LAG(revenue, 1) OVER(ORDER BY date))::DECIMAL / LAG(revenue, 1) OVER(ORDER BY date) * 100, 2) AS revenue_change
FROM (SELECT
    date,
    SUM(price) AS revenue
FROM (
SELECT 
    creation_time::DATE AS date,
    order_id,
    unnest(product_ids) AS product_id
FROM orders
WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
) t 
    LEFT JOIN products USING(product_id)
GROUP BY date) t1
ORDER BY date