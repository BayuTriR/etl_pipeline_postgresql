# Laporan Insight: Jumlah total trip valid pada Januari 2026

## 1. Metrik Utama
Berdasarkan hasil eksekusi query pada database, berikut adalah jumlah total trip valid pada Januari 2026:

* **Total Trip Valid:** `[total_trip_valid]`

---

## 2. Parameter & Spesifikasi Query
Laporan ini mengisolasi data spesifik dengan kondisi logika SQL sebagai berikut:

* **Sumber Tabel:** `gold.vw_trip_enriched`
* **Kriteria Validasi & Filter:**
  * `pickup_month = 1` : Membatasi pencarian hanya pada bulan **Januari**.
  * `fare_amount <> -999` : Mengeliminasi data anomali atau gagal sistem, di mana nilai tarif terekam sebagai `-999`/ `null`.

---

# Data Insight & Performance Report: Trip Analytics (Januari 2026)

Laporan ini dirancang untuk memberikan pemahaman mendalam mengenai kinerja operasional, pendapatan (*revenue*), perilaku pelanggan, serta kualitas data (*data quality*) berdasarkan serangkaian query analitik yang dijalankan pada layer data **Silver** dan **Gold**.

---

## 1. Executive Summary & Ringkasan Metrik Utama
Bagian ini menggabungkan hasil analitik dari **Query 1** dan **Query 2** untuk memberikan gambaran mengenai performa bisnis pada bulan Januari 2026.

* **Total Trip Valid:** `3724882` trip yang sukses dan bebas dari data rusak.
* **Total Revenue:** `108686483.69` total pendapatan yang berhasil dibukukan.
* **Metrik Rata-rata per Trip:**
    * **Average Revenue (Pendapatan per Trip):** `$ 29.18`
    * **Average Fare (Tarif Dasar per Trip):** `$ 20.80`
    * **Average Tip (Tip dari Pelanggan):** `$ 2.61`

> **💡 Rekomendasi Bisnis:** Selisih antara *Average Revenue* dan *Average Fare + Tip* menunjukkan komponen biaya tambahan (seperti *surcharge* atau pajak). Jika *Average Tip* rendah dibandingkan tarif dasar, perusahaan bisa mendorong sistem *default tipping* pada aplikasi untuk menaikkan kesejahteraan pengemudi.

---

## 2. Analisis Waktu Operasional & Pola Perjalanan
Memahami kapan permintaan (*demand*) memuncak membantu dalam alokasi armada pengemudi secara efisien (**Query 3, 4, dan 9**).

### A. Jam Sibuk (Peak Hour)
Berdasarkan **Query 3**, jam dengan jumlah trip tertinggi adalah pada **Jam `18`**. Ini menandakan waktu krusial di mana sistem harus siap menangani lonjakan beban data dan pengemudi harus di-insentifkan untuk *online*.

### B. Perbandingan Hari Kerja vs Akhir Pekan
Dari **Query 4**, diperoleh perbandingan distribusi trip:
* **Weekday:** `2679086`
* **Weekend:** `1045803`

### C. Kinerja Berdasarkan Periode Waktu (*Time Period*)
**Query 9** mengelompokkan perjalanan ke dalam segmen waktu spesifik (misal: *Morning, Afternoon, Evening, Night*). 

| Time Period | Total Trip | Total Revenue | Average Duration (Minutes) |
| :--- | :---: | :---: | :---: |
| *Night* | 1007392 | $ 29575952.14 | 15.42 mnt |
| *Afternoon* | 984056 | $ 27791045.32 | 18.22 mnt |
| *Evening* | 745640 | $ 22404665.12 | 17.99 mnt |
| *Morning* | 643778 | $ 18780144.01 | 18.67 mnt |
| *Late Night* | 344023 | $ 10134962.14 | 14.94 mnt |

> **💡 Rekomendasi Bisnis:** Jika durasi rata-rata pada periode tertentu sangat tinggi namun *revenue* tidak sebanding, hal tersebut mengindikasikan kemacetan parah. Penerapan *dynamic pricing* (tarif batas atas) pada jam-jam sibuk ini direkomendasikan.

---

## 3. Preferensi Pembayaran Pelanggan
Berdasarkan hasil **Query 5**, tipe pembayaran yang paling mendominasi adalah:
* **Metode Terpopuler:** `Credit Card` dengan total penggunaan sebanyak `2249747` kali.

> **💡 Rekomendasi Bisnis:** Optimalkan jalur integrasi (*payment gateway*) untuk metode terpopuler ini agar tidak terjadi kegagalan transaksi, dan berikan promo untuk metode pembayaran non-tunai yang kurang populer guna mengurangi risiko pengelolaan uang tunai oleh pengemudi.

---

## 4. Analisis Spasial & Geo-Spasial (Wilayah/Zona)
Mengidentifikasi area potensial dan area yang membutuhkan efisiensi (**Query 14 dan 18**).

### A. Zona Potensial Tinggi dengan Tip Rendah (Query 14)
Query ini menyaring zona yang memiliki tingkat penjemputan (*pickup*) **di atas rata-rata global**, namun memberikan tip **di bawah rata-rata global**.
* **Kegunaan:** Menemukan wilayah komuter padat (seperti stasiun atau area perkantoran padat) di mana penumpang ingin perjalanan cepat dan ekonomis tanpa memberi tips besar.
* **Aksi:** Alokasikan armada yang lebih hemat energi atau pengemudi baru di area ini karena volume ordernya tinggi dan stabil.

### B. Ranking Zona Berdasarkan Kontribusi Pendapatan (Query 18)
Menggunakan fungsi *Windowing* (`RANK() OVER`), query ini mengurutkan wilayah dari kontributor pendapatan terbesar hingga terkecil.

| Rank | Borough (Wilayah) | Pickup Zone (Zona) | Total Revenue |
| :---: | :--- | :--- | :--- |
| **1** | `Queens` | `JFK Airport` | $ 11063083.51 |
| **2** | `Queens` | `LaGuardia Airport` | $ 5654486.54 |
| **3** | `Manhattan` | `Midtown Center` | $ 3860074.9 |
| **4** | `Manhattan` | `Upper East Side North` | $ 3439390.36 |
| **5** | `Manhattan` | `Upper East Side South` | $ 3430062.18 |
| **6** | `Manhattan` | `Times Sq/Theatre District` | $ 3065312.64 |
| **7** | `Manhattan` | `Penn Station/Madison Sq West` | $ 2788087.26 |
| **8** | `Manhattan` | `Midtown East` | $ 2756837.56 |
| **9** | `Manhattan` | `Lincoln Square East` | $ 2537406.59 |
| **10** | `Manhattan` | `East Village` | $ 2520088.46 |
| **...** | `...` | `...` | `...` |
| **251** | `Queens` | `Breezy Point/Fort Tilden/Riis Beach` | $ 683.09 |
| **252** | `Staten Island` | `Port Richmond` | $ 594.95 |
| **253** | `Brooklyn` | `Green-Wood Cemetery` | $ 491.59 |
| **254** | `Staten Island` | `Eltingville/Annadale/Prince's Bay` | $ 435.8 |
| **255** | `Bronx` | `Rikers Island` | $ 251.39 |
| **256** | `Staten Island` | `Arden Heights` | $ 203.5 |
| **257** | `Queens` | `Jamaica Bay` | $ 193.81 |
| **258** | `Staten Island` | `Rossville/Woodrow` | $ 162.19 |
| **259** | `Staten Island` | `Freshkills Park` | $ 124 |
| **260** | `Manhattan` | `Governor's Island/Ellis Island/Liberty Island` | $ 120.84 |
| **261** | `Staten Island` | `Charleston/Tottenville` | $ 86.65 |
---

## 5. Analisis Tren Harian & Deviasi Revenue
Melalui **Query 15**, kita dapat melihat performa harian dibandingkan dengan rata-rata harian sepanjang masa (*Global Daily Average*).

* **Metric Fokus:** `deviation` (selisih realisasi dengan rata-rata) dan `performance_percentage` (persentase performa terhadap rata-rata).
* **Analisis Gejala:** * Jika `performance_percentage > 100%`, hari tersebut berada di atas target/rata-rata (biasanya terjadi saat hari gajian atau cuaca buruk).
    * Jika `performance_percentage < 100%`, perlu dievaluasi apakah terjadi gangguan sistem atau penurunan demand makro.

---

## 6. Audit Kualitas Data (*Data Quality Issues*)
Menjaga kesehatan pipa data (*data pipeline*) sangat penting sebelum menyajikan laporan ke level eksekutif. Berdasarkan **Query 10** dari tabel `silver.data_quality_issues`:

* **Daftar Isu Terbanyak:** Diurutkan dari yang paling sedikit hingga yang paling krusial (`ORDER BY total_cases ASC`).
* **Pembersihan Data:** Adanya kondisi `fare_amount <> -999` di hampir semua query emas (*gold*) membuktikan bahwa nilai `-999` merupakan data anomali/rusak yang berhasil diisolasi pada proses ETL/DQ.

---