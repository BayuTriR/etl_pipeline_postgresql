-- ==============================================================================
-- PROSES GOLD MART - TABLE DAILY TRIP SUMMARY
-- ==============================================================================

DROP TABLE IF EXISTS gold.daily_trip_summary;

CREATE TABLE gold.daily_trip_summary AS
SELECT 
	ttc.tpep_pickup_datetime::date as pickup_date,
	count(*) as total_trip,
	ROUND(SUM(ttc.total_amount)::numeric, 2) as total_revenue,
	ROUND(AVG(ttc.fare_amount)::numeric, 2) as average_fare,
	ROUND(AVG(ttc.trip_distance)::numeric, 2) as average_distance,
	ROUND(AVG(EXTRACT(EPOCH from (ttc.tpep_dropoff_datetime - ttc.tpep_pickup_datetime))/60)::numeric, 2) as average_duration
FROM silver.taxi_trips_cleaned ttc
WHERE ttc.trip_distance <> -999 AND ttc.fare_amount <> -999
GROUP BY ttc.tpep_pickup_datetime::date
ORDER BY ttc.tpep_pickup_datetime::date;

-- ==============================================================================
-- PROSES GOLD MART - TABLE ZONE PERFORMANCE SUMMARY
-- ==============================================================================

DROP TABLE IF EXISTS gold.zone_performance_summary;

CREATE TABLE gold.zone_performance_summary AS
WITH pickup_stats AS (
    SELECT 
        pulocation_id AS zone_id,
        COUNT(*) AS total_pickup_trip,
        SUM(total_amount) AS total_revenue,
        AVG(fare_amount) AS average_fare,
        AVG(tip_amount) AS average_tip
    FROM silver.taxi_trips_cleaned
    WHERE pulocation_id IS NOT NULL
    GROUP BY pulocation_id
),
dropoff_stats AS (
    SELECT 
        dolocation_id AS zone_id,
        COUNT(*) AS total_dropoff_trip
    FROM silver.taxi_trips_cleaned
    WHERE dolocation_id IS NOT NULL
    GROUP BY dolocation_id
)
SELECT 
    z.*,
    COALESCE(p.total_pickup_trip, 0) AS total_pickup_trip,
    COALESCE(d.total_dropoff_trip, 0) AS total_dropoff_trip,
    ROUND(COALESCE(p.total_revenue, 0)::numeric, 2) AS total_revenue,
    ROUND(COALESCE(p.average_fare, 0)::numeric, 2) AS average_fare,
    ROUND(COALESCE(p.average_tip, 0)::numeric, 2) AS average_tip,
    (COALESCE(p.total_pickup_trip, 0) - COALESCE(d.total_dropoff_trip, 0)) AS trip_imbalance
FROM silver.taxi_zones z
LEFT JOIN pickup_stats p ON z.location_id = p.zone_id
LEFT JOIN dropoff_stats d ON z.location_id = d.zone_id
WHERE p.total_pickup_trip IS NOT NULL OR d.total_dropoff_trip IS NOT NULL
ORDER BY total_revenue DESC;

-- ==============================================================================
-- PROSES GOLD MART - TABLE HOURLY DEMAND SUMMARY
-- ==============================================================================

DROP TABLE IF EXISTS gold.hourly_demand_summary;

CREATE TABLE gold.hourly_demand_summary AS
SELECT 
    pickup_date,
    pickup_hour::int AS pickup_hour,
    pickup_borough AS borough,
    COUNT(*) AS total_trips,
    ROUND(SUM(total_amount)::numeric, 2) AS total_revenue,
    ROUND(AVG(trip_duration_minutes)::numeric, 2) AS average_duration_minutes,
    ROUND(AVG(trip_distance)::numeric, 2) AS average_distance_miles
FROM silver.taxi_trips_cleaned
WHERE pickup_borough IS NOT NULL AND pickup_borough != 'Unknown'
GROUP BY pickup_date, pickup_hour, pickup_borough
ORDER BY pickup_date DESC, pickup_hour ASC, total_trips DESC;

-- ==============================================================================
-- PROSES GOLD MART - TABLE PAYMENT BEHAVIOR SUMMARY
-- ==============================================================================

CREATE TABLE gold.payment_behavior_summary AS
SELECT 
    pickup_date,
    payment_type,
    COUNT(*) AS total_transactions,
    ROUND(SUM(total_amount)::numeric, 2) AS total_revenue,
    ROUND(SUM(tip_amount)::numeric, 2) AS total_tips,
    ROUND(
        (SUM(tip_amount) / NULLIF(SUM(fare_amount), 0) * 100)::numeric, 
        2
    ) AS average_tip_percentage
FROM silver.taxi_trips_cleaned
WHERE payment_type IS NOT NULL
GROUP BY pickup_date, payment_type
ORDER BY pickup_date DESC, total_transactions DESC;