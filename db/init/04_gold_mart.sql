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