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
    ) t LEFT JOIN products USING(product_id)
    GROUP BY date
),
variable_costs_table AS (
    SELECT 
        date,
        SUM(courier_costs) AS costs,
        SUM(bonus) AS bonus
    FROM (
        SELECT
            date,
            150 * today_orders AS courier_costs,
            CASE 
                WHEN DATE_PART('month', date) = 8 AND today_orders >= 5 THEN 400
                WHEN DATE_PART('month', date) = 9 AND today_orders >= 5 THEN 500
                ELSE 0
            END AS bonus
        FROM (
            SELECT 
                time::DATE AS date,
                courier_id,
                COUNT(order_id) AS today_orders
            FROM courier_actions
            WHERE action = 'deliver_order' 
            GROUP BY date, courier_id
        ) t1
    ) t2
    GROUP BY date
),
pucking_table AS (
    SELECT
        date,
        CASE 
            WHEN DATE_PART('month', date) = 8 THEN 140 * orders_to_puck
            WHEN DATE_PART('month', date) = 9 THEN 115 * orders_to_puck
            ELSE 0
        END AS pucking_costs
    FROM (
        SELECT 
            time::DATE AS date,
            COUNT(order_id) AS orders_to_puck
        FROM courier_actions
        WHERE action = 'accept_order' AND order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
        GROUP BY date
    ) t2
),
costs_table AS (
    SELECT
        date,
        CASE
            WHEN DATE_PART('month', date) = 8 THEN 120000 + pucking_costs + costs + bonus
            WHEN DATE_PART('month', date) = 9 THEN 150000 + pucking_costs + costs + bonus
        END AS costs
    FROM variable_costs_table
        LEFT JOIN pucking_table USING(date)
),
taxes AS (
SELECT 
    product_id,
    CASE 
        WHEN name IN (
                        'сахар', 'сухарики', 'сушки', 'семечки', 
                        'масло льняное', 'виноград', 'масло оливковое', 
                        'арбуз', 'батон', 'йогурт', 'сливки', 'гречка', 
                        'овсянка', 'макароны', 'баранина', 'апельсины', 
                        'бублики', 'хлеб', 'горох', 'сметана', 'рыба копченая', 
                        'мука', 'шпроты', 'сосиски', 'свинина', 'рис', 
                        'масло кунжутное', 'сгущенка', 'ананас', 'говядина', 
                        'соль', 'рыба вяленая', 'масло подсолнечное', 'яблоки', 
                        'груши', 'лепешка', 'молоко', 'курица', 'лаваш', 'вафли', 'мандарины'
                            ) THEN ROUND(price / 110 * 10, 2)
        ELSE ROUND(price / 120 * 20, 2)
    END AS tax
FROM products
),
taxes_table AS (
    SELECT
        date,
        SUM(tax) AS tax
    FROM (
        SELECT 
            creation_time::DATE AS date,
            unnest(product_ids) AS product_id
        FROM orders
        WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
    ) t3 LEFT JOIN taxes USING(product_id)
    GROUP BY date
),
result_table AS (
    SELECT
        date,
        revenue,
        costs,
        tax,
        revenue - (costs + tax) AS gross_profit
    FROM revenue_table
        LEFT JOIN costs_table USING(date)
            LEFT JOIN taxes_table USING(date)
)

SELECT 
    date,
    revenue,
    costs,
    tax,
    gross_profit,
    SUM(revenue) OVER(ORDER BY date ROWS UNBOUNDED PRECEDING) AS total_revenue,
    SUM(costs) OVER(ORDER BY date ROWS UNBOUNDED PRECEDING) AS total_costs,
    SUM(tax) OVER(ORDER BY date ROWS UNBOUNDED PRECEDING) AS total_tax,
    SUM(gross_profit) OVER(ORDER BY date ROWS UNBOUNDED PRECEDING) AS total_gross_profit,
    ROUND(gross_profit / revenue * 100, 2) AS gross_profit_ratio,
    ROUND(SUM(gross_profit) OVER(ORDER BY date ROWS UNBOUNDED PRECEDING) / SUM(revenue) OVER(ORDER BY date ROWS UNBOUNDED PRECEDING) * 100, 2) AS total_gross_profit_ratio 
FROM result_table
ORDER BY date