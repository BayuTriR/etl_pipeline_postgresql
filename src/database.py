import os
from sqlalchemy import create_engine, text

class DatabaseConnection:
    def __init__(self,url):
        self.url = url

    def get_engine(self):
        return create_engine(self.url)
    
class SchemaManager:
    def __init__(self, db_engine):
        self.engine = db_engine

    def execute_sql_file(self, file_path: str):
        if not os.path.exists(file_path):
            raise FileNotFoundError(f"[SchemaManager] File SQL tidak ditemukan di: {file_path}")

        print(f"[SchemaManager] Membaca dan mengeksekusi file: {file_path}")
        
        # Baca isi file SQL
        with open(file_path, "r", encoding="utf-8") as file:
            sql_script = file.read()
        if "CREATE OR REPLACE FUNCTION" in sql_script or "DO $$" in sql_script:
            queries = [sql_script.strip()]
        else:
            queries = [q.strip() for q in sql_script.split(';') if q.strip()]

        # Eksekusi script ke database
        with self.engine.begin() as conn:
            for query in queries:
                try:
                    exec_query = query if query.endswith(';') else query + ";"
                    conn.execute(text(exec_query))
                except Exception as query_error:
                    print(f"[Postgres Error] Gagal pada perintah: {query[:60]}... -> {query_error}")
                    raise query_error