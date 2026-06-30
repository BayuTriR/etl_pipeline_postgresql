-- ==============================================================================
-- PROSES EXTRACT & LOAD TO DB
-- ==============================================================================

COPY bronze.raw_taxi_zones
FROM '/var/lib/postgresql/data_raw/extraction/taxi_zone_lookup.csv' 
DELIMITER ',' 
CSV HEADER;

ALTER TABLE bronze.raw_taxi_trips
ADD CONSTRAINT fk_pickup_location 
FOREIGN KEY ("PULocationID") REFERENCES bronze.raw_taxi_zones("LocationID");

ALTER TABLE bronze.raw_taxi_trips
ADD CONSTRAINT fk_dropoff_location 
FOREIGN KEY ("DOLocationID") REFERENCES bronze.raw_taxi_zones("LocationID");