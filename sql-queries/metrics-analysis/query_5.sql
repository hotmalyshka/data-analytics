WITH 
new_users AS (
    SELECT 
        time::DATE AS date,
        COUNT(DISTINCT user_id) FILTER(WHERE first_time = time::DATE) AS new_users
    FROM user_actions
        LEFT JOIN (
    SELECT 
        user_id,
        MIN(time::DATE) AS first_time
    FROM user_actions
    GROUP BY user_id
    ) t USING(user_id)
    GROUP BY date
),
total_users AS (
    SELECT 
        date,
        new_users,
        (SUM(new_users) OVER(ORDER BY date RANGE UNBOUNDED PRECEDING))::INTEGER AS total_users
    FROM new_users
),
new_couriers AS (
    SELECT 
            time::DATE AS date,
            COUNT(DISTINCT courier_id) FILTER(WHERE first_time = time::DATE) AS new_couriers
    FROM courier_actions
        LEFT JOIN (
        SELECT 
            courier_id,
            MIN(time::DATE) AS first_time
        FROM courier_actions
        GROUP BY courier_id
    ) t USING(courier_id)
    GROUP BY date
),
total_couriers AS (
    SELECT 
        date,
        new_couriers,
        (SUM(new_couriers) OVER(ORDER BY date RANGE UNBOUNDED PRECEDING))::INTEGER AS total_couriers
    FROM new_couriers
),
active_paying AS (
    SELECT 
        date,
        paying_users,
        active_couriers
    FROM (
    SELECT 
        time::DATE AS date,
        COUNT(DISTINCT user_id) FILTER(WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')) AS paying_users
    FROM user_actions
    GROUP BY date
    ) t 
        LEFT JOIN (
        SELECT 
            time::DATE AS date,
            COUNT(DISTINCT courier_id) FILTER(WHERE (action = 'accept_order' AND order_id IN (SELECT order_id FROM courier_actions WHERE action = 'deliver_order')) OR action = 'deliver_order') AS active_couriers
        FROM courier_actions
        GROUP BY date
    ) t1 USING(date)
),
    total_new AS (
    SELECT date,
           new_users,
           new_couriers,
           total_users,
           total_couriers
    FROM   total_users
        LEFT JOIN total_couriers using(date)
)

SELECT 
    date,
    paying_users,
    active_couriers,
    ROUND(paying_users::DECIMAL / total_users * 100, 2) AS paying_users_share,
    ROUND(active_couriers::DECIMAL / total_couriers * 100, 2) AS active_couriers_share
FROM active_paying
    LEFT JOIN total_new USING(date)
ORDER BY date