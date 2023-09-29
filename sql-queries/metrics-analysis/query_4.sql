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
)

SELECT 
    date,
    new_users,
    new_couriers,
    total_users,
    total_couriers,
    ROUND((new_users - LAG(new_users, 1) OVER())::DECIMAL / LAG(new_users, 1) OVER() * 100, 2) AS new_users_change,
    ROUND((new_couriers - LAG(new_couriers, 1) OVER())::DECIMAL / LAG(new_couriers, 1) OVER() * 100, 2) AS new_couriers_change,
    ROUND((total_users - LAG(total_users, 1) OVER())::DECIMAL / LAG(total_users, 1) OVER() * 100, 2) AS total_users_growth,
    ROUND((total_couriers - LAG(total_couriers, 1) OVER())::DECIMAL / LAG(total_couriers, 1) OVER() * 100, 2) AS total_couriers_growth
FROM total_users
    LEFT JOIN total_couriers USING(date)