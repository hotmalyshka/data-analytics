WITH
revenue_table AS (
    SELECT  
        CASE
            WHEN ROUND(revenue::DECIMAL / SUM(revenue) OVER() * 100, 2) < 0.5 THEN 'OTHER'
            ELSE product_name
        END AS product_name,
        revenue,
        ROUND(revenue::DECIMAL / SUM(revenue) OVER() * 100, 2) AS share_in_revenue
    FROM (
        SELECT
            name AS product_name,
            SUM(price) revenue
        FROM products
            LEFT JOIN (
                SELECT
                    unnest(product_ids) AS product_id
                FROM orders
                WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
            ) t USING (product_id)
        GROUP BY product_name
    ) t1
)

SELECT
    product_name,
    SUM(revenue) AS revenue,
    SUM(share_in_revenue) AS share_in_revenue
FROM revenue_table
GROUP BY product_name
ORDER BY revenue DESC