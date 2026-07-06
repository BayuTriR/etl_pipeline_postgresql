import os
import io
import pandas as pd
import requests
import pyarrow.parquet as pq
from abc import ABC, abstractmethod
from sqlalchemy import text, inspect

class DataExtraction(ABC):
    def __init__(self, path: str, output_path: str):
        self.path = path
        self.path_data = output_path

    def checking_output_folder(self):
        if self.path_data:
            folder_path = os.path.dirname(self.path_data)
            if folder_path and not os.path.exists(folder_path):
                print(f"Folder '{folder_path}' tidak ditemukan. Membuat folder baru...")
                os.makedirs(folder_path, exist_ok=True)

    def download_file(self):
        if not self.path or not self.path_data:
            raise ValueError("Path unduhan atau output_path belum dikonfigurasi.")
        self.checking_output_folder()
        
        if os.path.exists(self.path_data):
            print(f"--> [SKIPPED] File sudah ada di lokal: {self.path_data}")
            return
        
        response = requests.get(self.path, stream=True)
        if response.status_code != 200:
            raise ConnectionError(
                f"Gagal download FILE. Status: {response.status_code}"
            )

        with open(self.path_data, "wb") as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        print(f"File berhasil disimpan di: {self.path_data}")

    @abstractmethod
    def loadCSV(self, sql_script_path: str):
        pass

    @abstractmethod
    def loadParquet(self, path_data: str):
        pass

class BronzeLoader(DataExtraction):
    def __init__(self, engine, path: str = None, output_path: str = None):
        super().__init__(path, output_path)
        self.engine = engine

    def _table_exists_with_data(self, schema: str, table_name: str) -> bool:
        """Fungsi pembantu untuk cek apakah tabel sudah ada dan ada isinya"""
        inspector = inspect(self.engine)
        if inspector.has_table(table_name, schema=schema):
            with self.engine.connect() as conn:
                result = conn.execute(text(f"SELECT EXISTS (SELECT 1 FROM {schema}.{table_name} LIMIT 1)"))
                return result.scalar()
        return False

    def loadCSV(self, sql_script_path: str):
        if self._table_exists_with_data("bronze", "raw_taxi_zones"):
            print(f"--> [SKIPPED] Tabel bronze.raw_taxi_zones sudah terisi data.")
            return
        self.download_file()
        self.execute_sql(sql_script_path)

    def loadParquet(self, output_path: str, table_name: str, path: str):
        if path:
            self.path = path
        self.path_data = output_path
        if self._table_exists_with_data("bronze", table_name):
            print(f"--> [SKIPPED] Tabel bronze.{table_name} sudah terisi data. Melewati proses load Parquet.")
            return
        self.download_file()

        # Menggunakan PyArrow Parquet File Reader
        parquet_file = pq.ParquetFile(self.path_data)
        
        is_first_chunk = True
        total_rows = 0

        raw_conn = self.engine.raw_connection()
        try:
            with raw_conn.cursor() as cursor:
                # Ambil batch per 500k baris (sangat aman untuk RAM dengan metode COPY)
                for batch in parquet_file.iter_batches(batch_size=500000):
                    df_chunk = batch.to_pandas()
                    for col in df_chunk.select_dtypes(include=['float64', 'float32']).columns:
                        if col in ['VendorID',  'passenger_count', 'RatecodeID', 'payment_type']:
                            df_chunk[col] = df_chunk[col].astype('Int64')
                            
                    if is_first_chunk:
                        df_chunk.head(0).to_sql(
                            table_name, 
                            self.engine, 
                            schema="bronze", 
                            if_exists="replace", 
                            index=False
                        )
                        is_first_chunk = False
                    
                    # Convert dataframe menjadi buffer teks di dalam memori RAM (tanpa bikin file baru)
                    output = io.StringIO()
                    df_chunk.to_csv(output, sep='\t', header=False, index=False, na_rep='\\N')
                    output.seek(0)
                    
                    # Load data teks ke tabel menggunakan command COPY Postgres
                    cursor.copy_expert(
                        f"COPY bronze.{table_name} FROM STDIN WITH (FORMAT CSV, DELIMITER '\t', NULL '\\N')", 
                        output
                    )
                    
                    total_rows += len(df_chunk)
                    print(f"⚡ [COPY SUCCESS] Total {total_rows} baris masuk ke database...")
                
                raw_conn.commit()
                
        except Exception as e:
            raw_conn.rollback()
            raise e
        finally:
            raw_conn.close()
    
    def execute_sql(self, target_path: str):
        """Fungsi internal untuk membaca file .sql dan mengeksekusinya"""
        with self.engine.begin() as conn:
            with open(target_path, "r", encoding="utf-8") as file:
                sql_script = file.read()
            
            if sql_script.strip():
                conn.execute(text(sql_script))