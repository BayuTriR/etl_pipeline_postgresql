import os
import time
from src.database import DatabaseConnection, SchemaManager
from src.load_to_db import BronzeLoader
from datetime import datetime
from sqlalchemy import text

def log_message(message):
    current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"{current_time} - {message}")

def get_file_config():
    url_taxi_zone = os.environ.get("DATA_URL_ZONE", "https://d37ci6vzurychx.cloudfront.net/misc/taxi_zone_lookup.csv")
    url_yellow_trip = os.environ.get("DATA_URL_TRIP", "https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2026-01.parquet")

    file_config = [
        {
            "nama": "Data Yellow Tripdata 2026-01",
            "path": url_yellow_trip,
            "output_path": "data/extraction/yellow_tripdata_2026-01.parquet",
            "type": "parquet",
            "target_table": "raw_taxi_trips",
        },
        {
            "nama": "Data Taxi Zone Lookup",
            "path": url_taxi_zone,
            "output_path": "data/extraction/taxi_zone_lookup.csv",
            "type": "csv",
            "target_table": "raw_taxi_zones",
        },
    ]
    return file_config

log_message("Starting DB pipeline\n\n")

if __name__ == "__main__":
    start_time_seconds = time.time() # Untuk mencatat durasi total
    run_id = None

    DB_CONNECTION =  os.environ.get("DB_CONNECTION", "postgresql+psycopg2://etl_postgres_user:etl_postgres_pass@localhost:5433/db_etl_postgres")
    time.sleep(5)
    connection = DatabaseConnection(DB_CONNECTION)
    engine = connection.get_engine()
    file_config = get_file_config()
    loader = BronzeLoader(engine)
    
    schema_manager = SchemaManager(engine)
    schema_manager.execute_sql_file("db/init/01_schema.sql")
    
    try:
        with engine.begin() as conn:
            res_audit = conn.execute(text("""
                INSERT INTO audit.pipeline_run (status) VALUES ('RUNNING') RETURNING run_id;
            """))
            run_id = res_audit.fetchone()[0]
    except Exception as audit_err:
        print(f"Gagal menginisialisasi tabel audit: {audit_err}")

    try:
        # # ==============================================================================
        # # PROSES EXTRACT & LOAD TO DB
        # # ==============================================================================
        print("--- MEMULAI PROSES EXTRACT & LOAD TO DB ---\n")

        log_message("Running extract & load to DB")

        for config in file_config:
            try:
                if config["type"] == "csv":
                    loader_zone = BronzeLoader(
                        path = config["path"], 
                        output_path = config["output_path"], 
                        engine = engine
                    )
                    loader_zone.loadCSV("db/init/02_bronze_load.sql")
                elif config["type"] == "parquet":
                    loader.loadParquet(config["output_path"], config["target_table"], path=config["path"])
                else:
                    print(f"Format {config['type']} belum tersedia")
                    continue
            except Exception as e:
                print(f"Gagal mengekstrak {config['path']}. Error: {e}\n")
                raise e

        if run_id:
            with engine.connect() as conn:
                # Menggunakan tabel utama taksi di layer bronze (sesuai 'target_table' parquet kamu)
                res_bronze = conn.execute(text("SELECT COUNT(*) FROM bronze.raw_taxi_trips;"))
                bronze_count = res_bronze.fetchone()[0]
                
                conn.execute(text("""
                    UPDATE audit.pipeline_run SET bronze_row_count = :count WHERE run_id = :run_id;
                """), {"count": bronze_count, "run_id": run_id})
                conn.commit()
                print(f"Audit: {bronze_count:,} baris terdeteksi di layer Bronze.")

        log_message("Extract & load to DB completed\n")

        print("--- PROSES EXTRACT & LOAD TO DB SELESAI ---\n\n")
        
        # ==============================================================================
        # PROSES TRANSFORM
        # ==============================================================================
        print("--- MEMULAI PROSES TRANSFORM MELALUI QUERY---\n")

        log_message("Running transform")

        print("Mengubah CamelCase ke SnakeCase")
        schema_manager.execute_sql_file("db/init/06_function_procedur.sql")

        print("Membuat kolom turunan")
        schema_manager.execute_sql_file("db/init/03_silver_transform.sql")

        if run_id:
            with engine.connect() as conn:
                # Sesuai nama tabel tujuan CTAS di 03_silver_transform.sql kamu sebelumnya
                res_silver = conn.execute(text("SELECT COUNT(*) FROM silver.taxi_trips_cleaned;"))
                silver_count = res_silver.fetchone()[0]
                
                conn.execute(text("""
                    UPDATE audit.pipeline_run SET silver_row_count = :count WHERE run_id = :run_id;
                """), {"count": silver_count, "run_id": run_id})
                conn.commit()
                print(f"Audit: {silver_count:,} baris sukses dimuat ke layer Silver (Final).")

        log_message("Transform completed")

        print("\n--- PROSES TRANSFORM SELESAI ---\n\n")

        if run_id:
            duration = round(time.time() - start_time_seconds, 2)
            with engine.begin() as conn:
                conn.execute(text("""
                    UPDATE audit.pipeline_run 
                    SET status = 'SUCCESS', end_time = CURRENT_TIMESTAMP, execution_time_seconds = :duration 
                    WHERE run_id = :run_id;
                """), {"duration": duration, "run_id": run_id})

    except Exception as main_error:
        # ---- AUDIT: REKAM ERROR JIKA CRASH ----
        if run_id:
            duration = round(time.time() - start_time_seconds, 2)
            error_msg = str(main_error)[:500] # Batasi 500 karakter pesan error
            with engine.begin() as conn:
                conn.execute(text("""
                    UPDATE audit.pipeline_run 
                    SET status = 'FAILED', end_time = CURRENT_TIMESTAMP, error_message = :error, execution_time_seconds = :duration 
                    WHERE run_id = :run_id;
                """), {"error": error_msg, "duration": duration, "run_id": run_id})
        raise main_error