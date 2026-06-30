-- ==============================================================================
-- PROSES TRANSFORM CLEAN
-- ==============================================================================

DROP TABLE IF EXISTS silver.taxi_trips_cleaned;

CREATE TABLE silver.taxi_trips_cleaned AS
WITH temp_taxi_trips AS (
SELECT 
    t.*,
    (t.tpep_dropoff_datetime::timestamp - t.tpep_pickup_datetime::timestamp) AS trip_duration_minutes,
    t.tpep_pickup_datetime::date AS pickup_date,
    TO_CHAR(t.tpep_pickup_datetime::timestamp, 'Day') AS pickup_day_name,
    CASE 
        WHEN EXTRACT(ISODOW FROM t.tpep_pickup_datetime::timestamp) IN (6, 7) THEN true 
        ELSE false 
    END AS is_weekend,
    CASE 
        WHEN EXTRACT(HOUR FROM tpep_pickup_datetime::timestamp) BETWEEN 0 AND 5 THEN 'Late Night'
        WHEN EXTRACT(HOUR FROM tpep_pickup_datetime::timestamp) BETWEEN 6 AND 10 THEN 'Morning'
        WHEN EXTRACT(HOUR FROM tpep_pickup_datetime::timestamp) BETWEEN 11 AND 15 THEN 'Afternoon'
        WHEN EXTRACT(HOUR FROM tpep_pickup_datetime::timestamp) BETWEEN 16 AND 18 THEN 'Evening'
        ELSE 'Night'
    END AS time_periode,
    l_pu.borough AS pickup_borough,
    l_pu.zone AS pickup_zone,
    l_pu.service_zone AS pickup_service_zone,
    l_do.borough AS dropoff_borough,
    l_do.zone AS dropoff_zone,
    l_do.service_zone AS dropoff_service_zone
FROM silver.temp_taxi_trips t
LEFT JOIN silver.taxi_zones l_pu ON t.pulocation_id = l_pu.location_id
LEFT JOIN silver.taxi_zones l_do ON t.dolocation_id = l_do.location_id
)
SELECT 
    vendor_id, 
    tpep_pickup_datetime, 
    tpep_dropoff_datetime, 
    passenger_count, 
    trip_distance, 
    ratecode_id,
    CASE TRIM(store_and_fwd_flag::text)
        WHEN 'Y' THEN 'Store and Forward'
        WHEN 'N' THEN 'Normal'
        ELSE COALESCE(store_and_fwd_flag::text, 'Unknown')
    END AS store_and_fwd_flag, 
    pulocation_id, 
    dolocation_id,
    CASE TRIM(payment_type::text)
        WHEN '1' THEN 'Credit Card'
        WHEN '2' THEN 'Cash'
        WHEN '3' THEN 'No Charge'
        WHEN '4' THEN 'Dispute'
        WHEN '5' THEN 'Unknown'
        WHEN '6' THEN 'Voided Trip'
        ELSE COALESCE(payment_type::text, 'Unknown')
    END AS payment_type, 
    fare_amount, 
    extra, 
    mta_tax, 
    tip_amount, 
    tolls_amount, 
    improvement_surcharge, 
    total_amount, 
    congestion_surcharge, 
    airport_fee,
    trip_duration_minutes, 
    pickup_date, 
    pickup_day_name, 
    is_weekend, 
    time_periode,
    pickup_borough, 
    pickup_zone, 
    pickup_service_zone, 
    dropoff_borough, 
    dropoff_zone, 
    dropoff_service_zone
FROM temp_taxi_trips;

DROP TABLE IF EXISTS silver.temp_taxi_trips CASCADE;

UPDATE silver.taxi_trips_cleaned
SET 
    vendor_id       = COALESCE(vendor_id, -999),
    passenger_count = COALESCE(passenger_count, -999),
    trip_distance   = COALESCE(trip_distance, -999),
    fare_amount     = COALESCE(fare_amount, -999),
    tip_amount      = COALESCE(tip_amount, -999),
    total_amount    = COALESCE(total_amount, -999),
    pickup_borough  = COALESCE(pickup_borough, 'Unknown'),
    dropoff_borough = COALESCE(dropoff_borough, 'Unknown');

ALTER TABLE silver.taxi_trips_cleaned 
ALTER COLUMN vendor_id SET NOT NULL,
ALTER COLUMN tpep_pickup_datetime SET NOT NULL,
ALTER COLUMN tpep_dropoff_datetime SET NOT NULL,
ALTER COLUMN pickup_borough SET NOT NULL,
ALTER COLUMN dropoff_borough SET NOT NULL;

ALTER TABLE silver.taxi_trips_cleaned 
ADD CONSTRAINT chk_passenger_count CHECK (passenger_count >= 0 OR passenger_count = -999),
ADD CONSTRAINT chk_trip_distance   CHECK (trip_distance >= 0 OR trip_distance = -999),
ADD CONSTRAINT chk_fare_amount     CHECK (fare_amount >= 0 OR fare_amount = -999),
ADD CONSTRAINT chk_tip_amount      CHECK (tip_amount >= 0 OR tip_amount = -999),
ADD CONSTRAINT chk_total_amount    CHECK (total_amount >= 0 OR total_amount = -999);

ALTER TABLE silver.taxi_trips_cleaned
ADD CONSTRAINT fk_pickup_location 
FOREIGN KEY (pulocation_id) REFERENCES silver.taxi_zones(location_id);

ALTER TABLE silver.taxi_trips_cleaned
ADD CONSTRAINT fk_dropoff_location 
FOREIGN KEY (dolocation_id) REFERENCES silver.taxi_zones(location_id);

-- ==============================================================================
-- PROSES TRANSFORM DATA QUALITY
-- ==============================================================================

CREATE TABLE silver.data_quality_issues AS
WITH temp_issues AS (
SELECT
    *,
    CASE
        WHEN t.tpep_pickup_datetime >= t.tpep_dropoff_datetime THEN 'duration invalid'
        WHEN t.trip_distance <= 0 THEN 'distance invalid'
        ELSE 'valid'
    END AS error_type
FROM silver.taxi_trips_cleaned t
)
SELECT * FROM temp_issues
WHERE error_type <> 'valid';d

