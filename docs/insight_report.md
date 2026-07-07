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
Menggunakan fungsi *Windowing* (`DENSE_RANK() OVER (ORDER BY SUM(total_amount) DESC)`), query ini mengurutkan wilayah dari kontributor pendapatan terbesar hingga terkecil.

| Rank | Zone ID | Borough | Zone Name | Total Trips | Total Revenue |
| :---: | :--- | :---: | :--- | :---: | :--- |
| **1** | **132** | `Queens` | `JFK Airport` | 152589 | $ 11063083.51 |
| **2** | **138** | `Queens` | `LaGuardia Airport` | 85190 | $ 5654486.54 |
| **3** | **161** | `Manhattan` | `Midtown Center` | 146641 | $ 3860074.9 |
| **4** | **236** | `Manhattan` | `Upper East Side North` | 153640 | $ 3439390.36 |
| **5** | **237** | `Manhattan` | `Upper East Side South` | 160343 | $ 3430062.18 |
| **...** | **...** | `...` | `...` | `...` | [...] | [$ ...] |
---

### C. Ranking Zona Berdasarkan Wilayah Lokal / Borough (Query 19)
Melalui fungsi Windowing `DENSE_RANK() OVER (PARTITION BY borough ORDER BY total_revenue DESC)`, kita memecah kompetisi pendapatan ke tingkat regional masing-masing wilayah. Ini membantu kita melihat zona mana yang menjadi "Raja" di wilayahnya sendiri.

| Rank in Borough | Borough | Zone ID | Zone Name | Total Trips | Total Revenue |
| :---: | :--- | :---: | :--- | :---: | :--- |
| **1** | `Bronx` | **168** | `Mott Haven/Port Morris` | 2837 | $ 90314.93 |
| **2** | `Bronx` | **51** | `Co-Op City` | 1493 | $ 64485.65 |
| **3** | `Bronx` | **69** | `East Concourse/Concourse Village` | 1837 | $ 60554.54 |
| **4** | `Bronx` | **254** | `Williamsbridge/Olinville` | 1413 | $ 57080.55 |
| **5** | `Bronx` | **213** | `Soundview/Castle Hill` | 1566 | $ 55559.69 |
| **...** | **...** | `...` | `...` | `...` | [...] | [$ ...] |

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