CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;
CREATE SCHEMA IF NOT EXISTS audit;

DROP TABLE IF EXISTS bronze.raw_taxi_trips CASCADE;

DROP TABLE IF EXISTS bronze.raw_taxi_zones CASCADE;
CREATE TABLE bronze.raw_taxi_zones (
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
    bronze_row_count INT DEFAULT 0,
    silver_row_count INT DEFAULT 0,
    error_message TEXT,
    execution_time_seconds NUMERIC
);