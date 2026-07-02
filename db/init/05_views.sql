-- ==============================================================================
-- PROSES GOLD MART - VIEW TRIP ENRICHED
-- ==============================================================================

CREATE OR REPLACE VIEW gold.vw_trip_enriched AS
SELECT 
    ttc.vendor_id,
    ttc.tpep_pickup_datetime,
    ttc.tpep_dropoff_datetime,
    ttc.pickup_date,
    ttc.tpep_dropoff_datetime::date AS dropoff_date,
    EXTRACT(HOUR FROM ttc.tpep_pickup_datetime) AS pickup_hour,
    EXTRACT(MONTH FROM ttc.tpep_pickup_datetime) AS pickup_month,
    ttc.pickup_day_name,
    ttc.is_weekend,
    ttc.time_periode,   
    ttc.pulocation_id AS pickup_location_id,
    pz.borough AS pickup_borough,
    pz.zone AS pickup_zone,
    pz.service_zone AS pickup_service_zone,
    ttc.dolocation_id AS dropoff_location_id,
    dz.borough AS dropoff_borough,
    dz.zone AS dropoff_zone,
    dz.service_zone AS dropoff_service_zone,
    ttc.passenger_count,
    ttc.trip_distance,
    ROUND(
        EXTRACT(EPOCH FROM (ttc.tpep_dropoff_datetime - ttc.tpep_pickup_datetime)) / 60 ::numeric, 
        2
    ) AS duration_minutes,
    ttc.fare_amount,
    ttc.tip_amount,
    ttc.total_amount,
    ttc.payment_type AS payment_label
FROM silver.taxi_trips_cleaned ttc
LEFT JOIN silver.taxi_zones pz ON ttc.pulocation_id = pz.location_id
LEFT JOIN silver.taxi_zones dz ON ttc.dolocation_id = dz.location_id;

-- ==============================================================================
-- PROSES GOLD MART - VIEW DAILY TRIP SUMMARY
-- ==============================================================================

CREATE OR REPLACE VIEW gold.vw_daily_trip_summary AS
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
-- PROSES GOLD MART - VIEW Zone Performance
-- ==============================================================================

CREATE OR REPLACE VIEW gold.vw_zone_performance AS
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
    z.borough,
    z.zone,
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
