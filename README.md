# Automated Database Data Pipeline (Medallion Architecture) with Docker Compose

Proyek ini adalah sebuah pipeline data berbasis database relasional yang dirancang dengan arsitektur **Medallion (Bronze, Silver, Gold)**. Proyek ini mengotomatisasi proses pembuatan skema, pembersihan, transformasi, hingga penyajian data mart siap analisis, yang diintegrasikan menggunakan **PostgreSQL**, **Python**, dan **Docker Compose**.

Proyek ini telah dikontainerisasi penuh untuk memastikan seluruh tahapan inisialisasi database dan eksekusi skrip ETL dapat berjalan secara konsisten di lingkungan (*environment*) mana saja tanpa kendala dependensi lokal.

## Daftar Isi
- [Fitur Utama](#fitur-utama)
- [Struktur Proyek](#struktur-proyek)
- [Teknologi & Dependensi](#teknologi--dependensi)
- [Prasyarat Sistem](#prasyarat-sistem)
- [Cara Penggunaan (Docker & Python)](#cara-penggunaan-docker--python)
- [Detail Alur Kerja Medallion Pipeline](#detail-alur-kerja-medallion-pipeline)

## Fitur Utama
* **Kontainerisasi Database Penuh:** Menggunakan Docker Compose untuk menyediakan instans PostgreSQL yang siap pakai secara instan tanpa instalasi manual di OS lokal.
* **Otomatisasi Inisialisasi Database (Initialization Scripts):** Memanfaatkan fitur entri poin Docker PostgreSQL untuk mengeksekusi file-file `.sql` di dalam folder `init/` secara berurutan saat kontainer pertama kali dibuat.
* **Automasi Run Script & Logging:** Dilengkapi dengan Shell Script (`run_db_pipeline.sh`) untuk memantau, menggerakkan pipeline database, serta mengelola berkas catatan aktivitas ke dalam folder `logs/`.
* **Pemisahan Lapisan Data Terstruktur (Medallion Architecture):** 
  * **Bronze:** Menampung data mentah (*raw load*).
  * **Silver:** Melakukan transformasi, pembersihan kualitas data, dan standardisasi.
  * **Gold:** Menyusun data ke dalam bentuk tabel dimensi/fakta (*Data Mart*) yang siap dikonsumsi untuk kebutuhan bisnis.
* **Implementasi Fungsi Advanced Database:** Menggunakan *SQL Views*, fungsi kustom (*functions*), dan *stored procedures* pada database untuk enkapsulasi logika bisnis langsung di layer data.
* **Analisis Data Terintegrasi:** Menyediakan file query khusus untuk menjawab pertanyaan bisnis nyata (*business questions*) yang hasilnya didokumentasikan ke dalam laporan insight terstruktur (`insight_report.md`).

## Struktur Proyek
```text
TUGAS_2/
├── data/                               # Penyimpanan data lokal/sumber (jika ada)
├── db/                                 # Direktori utama konfigurasi database
│   ├── init/                           # Skrip SQL inisialisasi awal (dieksekusi berurutan)
│   │   ├── 01_schema.sql               # Pembuatan skema awal database
│   │   ├── 02_bronze_load.sql          # Pengisian data mentah ke Bronze layer
│   │   ├── 03_silver_transform.sql     # Skrip transformasi & cleansing ke Silver layer
│   │   ├── 04_gold_mart.sql            # Pembuatan Data Mart untuk analisis bisnis (Gold layer)
│   │   ├── 05_views.sql                # Pembuatan SQL Views pelaporan
│   │   └── 06_function_procedur.sql    # Stored Procedure & kustom fungsi SQL
│   └── queries/
│       └── 01_business_questions.sql   # Kumpulan query analitis untuk business question
├── docs/                               # Dokumentasi analisis proyek
│   └── insight_report.md               # Laporan hasil temuan insight bisnis
├── logs/                               # Berkas catatan automasi pipeline (Log files)
├── src/                                # Modul logika kode Python utama
│   ├── database.py                     # Pengaturan koneksi dan sesi ke database PostgreSQL
│   └── load_to_db.py                   # Logika eksekusi data loading ke database
├── .dockerignore                       # Daftar berkas/folder yang diabaikan oleh Docker
├── .gitignore                          # Daftar berkas/folder yang diabaikan oleh Git
├── docker-compose.yaml                 # Orkestrasi kontainer database PostgreSQL & env variable
├── Dockerfile                          # Cetakan dasar untuk lingkungan runtime aplikasi
├── main.py                             # Berkas utama penggerak seluruh alur pipeline
├── requirement.txt                     # Kebutuhan library Python (e.g., psycopg2, SQLAlchemy)
└── run_db_pipeline.sh                  # Shell script untuk mengotomatisasi jalannya pipeline
```

## Teknologi & Dependensi
Core Runtime & Driver: Python 3.x, PostgreSQL  
Orchestration & Infrastructure: Docker, Docker Compose, Linux Bash Shell Script  
Database Connector: psycopg2-binary atau SQLAlchemy

## Prasyarat Sistem
Sebelum menjalankan proyek ini, pastikan komputer Anda sudah terinstal:  
Docker Desktop (Termasuk Docker Compose)  
Python 3.x  
Git Bash (Jika menggunakan OS Windows untuk eksekusi terminal shell script)

## Cara Penggunaan (Docker & Python)
1. Klon Repositori Ini
    ```bash
    git clone [https://github.com/BayuTriR/etl_pipeline_postgresql](https://github.com/BayuTriR/etl_pipeline_postgresql)
    cd etl_pipeline_postgresql
2. Jalankan Menggunakan Docker Compose  
    ```bash
    docker compose up --build
3. Memeriksa Hasil Output  
    Setelah kontainer selesai dieksekusi (exited with code 0):  
    File Log: Periksa folder ./logs/ di laptop Anda untuk melihat rekam jejak jalannya pipa data secara mendetail.  
    Database: Periksa table audit.pipeline_run untuk melihat jumlah row yang terinput ke masing-masing table & view.

## Detail Alur Kerja Medallion Pipeline
1. Inisialisasi & Skema (01_schema.sql)  
    Membangun pondasi tabel dan batasan (constraints) di database.
2. Tahap Bronze (02_bronze_load.sql)  
    Melakukan ekstraksi awal dan memuat data ke dalam tabel penampungan tanpa manipulasi struktur (schema bronze)
3. Tahap Silver (03_silver_transform.sql)  
    Mengubah skema seluruh kolom menjadi huruf kecil dengan pemisah garis bawah (snake_case).
    Melakukan operasi cleaning, menangani nilai kosong (handling nulls), pembersihan tipe data, deduping, dan transformasi standar.
4. Tahap Gold & Analytical Views (04_gold_mart, 05_views)  
    Menyusun data hasil transformasi ke format Data Mart teragregasi yang optimal untuk kebutuhan pembuatan laporan.
5. Business Query & Reporting (01_business_questions.sql)  
    Mengambil metrik performa bisnis dari layer Gold, yang kemudian dirangkum menjadi dokumen laporan insight pada berkas docs/insight_report.md.