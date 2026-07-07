-- ==============================================================================
-- 1. Berapa jumlah total trip valid pada Januari 2026?
-- ==============================================================================

SELECT 
    COUNT(*) AS total_trip_valid
FROM gold.vw_trip_enriched
WHERE pickup_month = 1 AND fare_amount <> -999;

-- ==============================================================================
-- 2. Berapa total revenue, average revenue, average fare, dan average tip? 
-- ==============================================================================

SELECT
    ROUND(SUM(total_amount)::numeric, 2) AS total_revenue,
    ROUND(AVG(total_amount)::numeric, 2) AS average_revenue,
    ROUND(AVG(fare_amount)::numeric, 2) AS average_fare,
    ROUND(AVG(tip_amount)::numeric, 2) AS average_tip
FROM gold.vw_trip_enriched
WHERE pickup_month = 1 AND fare_amount <> -999;

-- ==============================================================================
-- 3. Tanggal atau jam apa yang memiliki jumlah trip tertinggi?
-- ==============================================================================

SELECT 
    pickup_hour, 
    COUNT(*) AS total_trip 
FROM gold.vw_trip_enriched 
GROUP BY pickup_hour 
ORDER BY total_trip DESC LIMIT 1;

-- ==============================================================================
-- 4. Bandingkan jumlah trip weekday dan weekend.
-- ==============================================================================

SELECT 
    CASE 
        WHEN is_weekend THEN 'Weekend' 
        ELSE 'Weekday' 
    END AS day_type,
    COUNT(*) AS total_trip
FROM gold.vw_trip_enriched 
GROUP BY is_weekend;

-- ==============================================================================
-- 5. Payment type apa yang paling sering digunakan? 
-- ==============================================================================

SELECT 
    payment_label, 
    COUNT(*) AS total_usage 
FROM gold.vw_trip_enriched 
GROUP BY payment_label 
ORDER BY total_usage DESC LIMIT 1;

-- ==============================================================================
-- 9. Hitung jumlah trip, revenue, dan average duration untuk setiap time period. 
-- ==============================================================================

SELECT 
    time_periode,
    COUNT(*) AS total_trip,
    ROUND(SUM(total_amount)::numeric, 2) AS total_revenue,
    ROUND(AVG(duration_minutes)::numeric, 2) AS average_duration_minutes
FROM base_enriched
WHERE fare_amount <> -999
GROUP BY time_periode
ORDER BY total_trip DESC;

-- ==============================================================================
-- 10. Tampilkan data quality issue terbanyak berdasarkan error_type. 
-- ==============================================================================

SELECT 
    error_type,
    COUNT(*) AS total_cases
FROM silver.data_quality_issues
GROUP BY error_type
ORDER BY total_cases;

-- ==============================================================================
-- 14. Zone yang memiliki pickup tinggi tetapi average tip rendah.
-- ==============================================================================

WITH zone_stats AS (
    SELECT 
        pickup_zone,
        COUNT(*) AS total_pickup,
        AVG(tip_amount) AS avg_tip_zone
    FROM gold.vw_trip_enriched
    WHERE pickup_zone IS NOT NULL AND fare_amount <> -999
    GROUP BY pickup_zone
)
SELECT 
    pickup_zone,
    total_pickup,
    ROUND(avg_tip_zone::numeric, 2) AS avg_tip_zone
FROM zone_stats
WHERE total_pickup > (SELECT AVG(total_pickup) FROM zone_stats)
  AND avg_tip_zone < (SELECT AVG(avg_tip_zone) FROM zone_stats)
ORDER BY total_pickup DESC, avg_tip_zone ASC;

-- ==============================================================================
-- 15. Perbandingan revenue setiap hari terhadap rata-rata revenue harian. 
-- ==============================================================================

WITH daily_revenue AS (
    SELECT 
        pickup_date,
        SUM(total_amount) AS daily_total
    FROM gold.vw_trip_enriched
    WHERE fare_amount <> -999
    GROUP BY pickup_date
),
global_daily_avg AS (
    SELECT 
        AVG(daily_total) AS avg_daily_revenue
    FROM daily_revenue
)
SELECT 
    dr.pickup_date,
    ROUND(dr.daily_total::numeric, 2) AS daily_total,
    ROUND(gda.avg_daily_revenue::numeric, 2) AS avg_daily_revenue,
    ROUND((dr.daily_total - gda.avg_daily_revenue)::numeric, 2) AS deviation,
    ROUND(((dr.daily_total / gda.avg_daily_revenue) * 100)::numeric, 2) AS performance_percentage
FROM daily_revenue dr
CROSS JOIN global_daily_avg gda
ORDER BY dr.pickup_date;
