-- ==============================================================================
-- PROSES CREATE NEW SCHEMA, TABLE LOG, TABLE RAW
-- ==============================================================================

CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;
CREATE SCHEMA IF NOT EXISTS audit;

CREATE TABLE IF NOT EXISTS bronze.raw_taxi_zones (
    "LocationID" INT PRIMARY KEY,
    "Borough" VARCHAR(255) NOT NULL,
    "Zone" VARCHAR(255) NOT NULL,
    "service_zone" VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS audit.pipeline_run (
    run_id SERIAL PRIMARY KEY,
    pipeline_name VARCHAR(100) DEFAULT 'NYC Taxi ETL',
    start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP,
    status VARCHAR(50),
    raw_taxi_trips_row_count INT DEFAULT 0,
    raw_taxi_zones_row_count INT DEFAULT 0,
    taxi_trips_cleaned_row_count INT DEFAULT 0,
    taxi_zones_row_count INT DEFAULT 0,
    data_quality_issues_row_count INT DEFAULT 0,
    daily_trip_row_count INT DEFAULT 0,
    hourly_demand_row_count INT DEFAULT 0,
    zone_performance_row_count INT DEFAULT 0,
    payment_behavior_row_count INT DEFAULT 0,
    route_performance_row_count INT DEFAULT 0,
    vw_trip_enriched_row_count INT DEFAULT 0,
    vw_daily_trip_row_count INT DEFAULT 0,
    vw_zone_performance_row_count INT DEFAULT 0,
    error_message TEXT,
    execution_time_seconds NUMERIC
);