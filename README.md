# ScaleUp — Aplikasi Pemantau Berat Badan & Kalori Harian

**ScaleUp** adalah aplikasi mobile **offline-first** berbasis **Flutter (Dart 3+, Material 3)** yang membantu pengguna memantau berat badan harian, menentukan tujuan sehat (turunkan, naikkan, atau jaga berat badan), serta mencatat asupan kalori dan makro harian menggunakan database lokal makanan umum Indonesia.

---

## Daftar Fitur Utama

1. **Onboarding 4 Langkah & Profil Pengguna**
   - Langkah interaktif dengan indikator progres: (1) Sambutan & Disclaimer Kesehatan, (2) Data Diri, (3) Tingkat Aktivitas beserta penjelasan tiap opsi, dan (4) Pilihan Tujuan dengan pratinjau kalori & estimasi tanggal tercapai.
   - Validasi ketat & suportif: tinggi `100–250 cm`, berat `25–300 kg`, tanggal lahir tidak di masa depan, serta batas usia minimal `18 tahun`.
   - Data profil dan tingkat aktivitas dapat diubah kapan saja melalui tab **Profil**.

2. **Manajemen Tujuan & Aturan Kesehatan Wajib**
   - Pilihan tujuan: **Turunkan Berat Badan** (aksen biru), **Naikkan Berat Badan** (aksen oranye), atau **Jaga Berat Badan** (aksen hijau).
   - Pilihan laju mingguan (`0,25` / `0,5` / `0,75 kg/minggu`) dengan batas keamanan otomatis **maksimal 1% berat badan per minggu**.
   - Penolakan berat target yang menyebabkan **BMI < 18,5** pada tujuan penurunan berat badan.
   - Batas bawah target kalori harian wajib: **1.200 kkal (wanita)** dan **1.500 kkal (pria)**.
   - Penyesuaian target kalori otomatis setiap kali berat badan berubah **>= 2,0 kg**, atau saat tujuan maupun tingkat aktivitas diganti.
   - Riwayat tujuan sebelumnya tetap tersimpan di database lokal (`isActive = false`), dengan tepat satu tujuan aktif.

3. **Pencatatan Berat Harian, Grafik Tren & Statistik**
   - Input cepat satu tangan melalui *bottom sheet*: angka besar bertabular (`tabularFigures`), tombol `-/+ 0,1`, *slider* presisi, pemilih tanggal (hari ini atau tanggal sebelumnya), serta catatan opsional.
   - Satu entri unik per hari kalender (*upsert* otomatis bila mencatat ulang pada tanggal yang sama), edit entri, dan *swipe-to-delete* dilengkapi tombol **Urungkan (Undo)**.
   - Grafik `fl_chart` interaktif dengan filter **7H / 30H / 90H / Semua**, gradien area lembut, sorotan titik terakhir, garis target putus-putus, serta garis tren **Moving Average 7 Hari**.
   - Statistik lengkap (Berat Awal, Berat Sekarang, Perubahan Total, Rata-rata/Minggu, Sisa ke Target, BMI & Kategori) dan pesan motivasi kontekstual yang positif tanpa menghakimi.

4. **Cek Kalori & Database Makanan Indonesia**
   - Dilengkapi **92 makanan & minuman umum Indonesia** bawaan (*seed* otomatis: nasi putih, nasi uduk, nasi goreng, bubur ayam, tempe/tahu, ayam bakar/goreng, telur, ikan, rendang, bakso, soto, gado-gado, pecel, sayur bening, buah lokal, kopi susu, es teh manis, dll.).
   - Pencarian makanan instan, filter **Semua / Favorit / Terakhir**, tambah **Makanan Custom** (nama, takaran saji, kalori, protein, karbohidrat, lemak), dan pengaturan porsi pecahan (`0,25`–`20` porsi).
   - Pencatatan per waktu makan (**Sarapan, Makan Siang, Makan Malam, Camilan**) pada kartu yang dapat dilipat (*collapsible*), fitur satu ketuk **Salin dari Kemarin**, ring progres kalori besar, bar makro, dan grafik batang riwayat kalori 7 hari.

5. **Dashboard Beranda, Pengingat & Pengaturan**
   - Dashboard satu layar (`CustomScrollView` + `SliverAppBar` mengecil saat digulir) dengan animasi *staggered* halus, kartu progres tujuan melingkar, kartu berat hari ini, kartu sisa kalori, kartu *streak* harian, dan tips harian sesuai tujuan.
   - Perayaan *confetti* ringan sekali per pencapaian (*streak* 7 hari, *streak* 30 hari, atau berat target tercapai).
   - Pengingat notifikasi lokal harian untuk timbang berat & catat makanan (jam dapat diatur dan dimatikan).
   - Pilihan tema (**Ikut Sistem / Terang / Gelap**), satuan berat (**kg / lb**), **Ekspor Data ke CSV**, dan **Hapus Semua Data** dengan konfirmasi aman.
   - Dukungan penuh aksesibilitas: ukuran sentuh minimum `48x48dp`, *semantic labels*, skala teks hingga `1,3x` bebas *overflow* mulai layar `360dp`, dan penghormatan terhadap preferensi sistem **Reduce Motion**.

---

## Cara Menjalankan Proyek

### Prasyarat
- **Flutter SDK** `>= 3.47.0` / stable terbaru (dikembangkan & diuji pada Flutter `3.50.0` • Dart `3.14.0`)
- Perangkat Android / iOS atau Emulator / Simulator aktif

### Langkah Menjalankan
```bash
# 1. Unduh seluruh dependensi paket
flutter pub get

# 2. (Opsional) Jalankan ulang code generation Drift & Riverpod bila mengubah skema/provider
dart run build_runner build

# 3. Jalankan analisis statis kode
flutter analyze

# 4. Jalankan seluruh unit test & widget test
flutter test

# 5. Jalankan aplikasi di perangkat/emulator
flutter run
```

---

## Struktur Proyek

Proyek menerapkan arsitektur **Feature-First + Repository Pattern** dengan pemisahan murni logika perhitungan pada lapisan `domain`:

```text
lib/
├── main.dart                          # Entry point, lokalisasi id_ID, ThemeMode & MediaQuery clamp
├── core/
│   ├── constants/                     # Konstanta bisnis, ukuran spacing 8dp, & string Bahasa Indonesia
│   ├── router/                        # Konfigurasi GoRouter (StatefulShellRoute 4 tab + FAB Catat Cepat)
│   ├── theme/                         # Palet Fresh Health (Light/Dark), tipografi Plus Jakarta Sans + Inter
│   ├── utils/                         # Formatter id_ID, konversi kg/lb, tanggal kalender, reduce motion
│   └── widgets/                       # Design system: AppCard, PrimaryButton, StatTile, ProgressRing,
│                                      # AppBottomNav, SkeletonBox, EmptyState, AnimatedCount, QuickAddSheet
├── data/
│   ├── database/                      # Skema 6 tabel Drift (SQLite), indeks tanggal, & strategi migrasi
│   └── seed/                          # Seed 92 makanan & minuman umum Indonesia
└── features/
    ├── onboarding/
    │   ├── domain/                    # Enum profil/tujuan & fungsi murni HealthCalculator
    │   └── presentation/              # Alur Onboarding 4 langkah
    ├── home/
    │   ├── data/                      # Provider agregasi tanggal aktif & streak
    │   ├── domain/                    # Kalkulator streak, milestone confetti, & tips harian
    │   └── presentation/              # Dashboard Beranda (CustomScrollView + SliverAppBar)
    ├── weight/
    │   ├── data/                      # WeightRepository (1 entri/hari + pemicu hitung ulang kalori >= 2 kg)
    │   ├── domain/                    # WeightAnalytics (filter grafik, statistik, pesan motivasi)
    │   └── presentation/              # Layar Berat, grafik fl_chart + tren 7H, & bottom sheet input berat
    ├── calories/
    │   ├── data/                      # CaloriesRepository (log makan, pencarian, favorit, custom, salin kemarin)
    │   ├── domain/                    # CalorieAnalytics (ringkasan kalori/makro & seri 7 hari)
    │   └── presentation/              # Layar Kalori, pemilih makanan, form custom food, & grafik 7 hari
    ├── profile/
    │   ├── data/                      # ProfileRepository & GoalRepository (riwayat tujuan tersimpan)
    │   ├── domain/                    # ActiveNutritionPlan terpadu
    │   └── presentation/              # Layar Profil + bottom sheet edit profil & ubah tujuan
    └── settings/
        ├── data/                      # SettingsRepository, NotificationService, & CsvExportService
        └── presentation/              # Komponen pengaturan tema, satuan, pengingat, CSV & reset data
```

---

## Rumus Perhitungan yang Dipakai

1. **Basal Metabolic Rate (BMR — Rumus Mifflin-St Jeor)**
   - **Pria**: $\text{BMR} = (10 \times \text{berat}_{\text{kg}}) + (6{,}25 \times \text{tinggi}_{\text{cm}}) - (5 \times \text{usia}_{\text{tahun}}) + 5$
   - **Wanita**: $\text{BMR} = (10 \times \text{berat}_{\text{kg}}) + (6{,}25 \times \text{tinggi}_{\text{cm}}) - (5 \times \text{usia}_{\text{tahun}}) - 161$

2. **Total Daily Energy Expenditure (TDEE)**
   $$\text{TDEE} = \text{BMR} \times \text{Faktor Aktivitas}$$
   dengan faktor aktivitas: Sedentari `1,2`, Ringan `1,375`, Sedang `1,55`, Berat `1,725`, Sangat Berat `1,9`.

3. **Target Kalori Harian & Batas Kesehatan**
   - Setara energi perubahan jaringan tubuh: $1\text{ kg} \approx 7.700\text{ kkal}$.
   - Laju mingguan aman dibatasi: $\text{laju}_{\text{aman}} = \min(\text{laju}_{\text{pilihan}},\ 0{,}01 \times \text{berat}_{\text{kg}})$.
   - Defisit / surplus harian: $\Delta E = \frac{\text{laju}_{\text{aman}} \times 7.700}{7}$.
   - Target kalori:
     - **Turun**: $\max(\text{Batas Minimum},\ \text{round}(\text{TDEE} - \Delta E))$
     - **Naik**: $\text{round}(\text{TDEE} + \Delta E)$
     - **Jaga**: $\text{round}(\text{TDEE})$
   - Batas minimum kalori harian: **1.200 kkal** (wanita) dan **1.500 kkal** (pria).

4. **Target Makronutrisi Default**
   - **Protein**: $1{,}6\text{ g} \times \text{berat}_{\text{kg}}$ ($4\text{ kkal/g}$)
   - **Lemak**: $25\%$ dari target kalori harian dibagi $9\text{ kkal/g}$
   - **Karbohidrat**: sisa kalori harian $\max(0,\ E_{\text{target}} - E_{\text{protein}} - E_{\text{lemak}})$ dibagi $4\text{ kkal/g}$

5. **Indeks Massa Tubuh (BMI) & Estimasi Tanggal Tercapai**
   - $\text{BMI} = \frac{\text{berat}_{\text{kg}}}{(\text{tinggi}_{\text{cm}} / 100)^2}$
   - $\text{Hari Estimasi} = \left\lceil \frac{|\text{berat}_{\text{sekarang}} - \text{berat}_{\text{target}}|}{\text{laju efektif}_{\text{kg/minggu}}} \times 7 \right\rceil$

6. **Garis Tren Moving Average 7 Hari**
   - Untuk setiap entri pada tanggal $t$, nilai tren dihitung dari rata-rata aritmetika seluruh catatan berat yang berada dalam rentang kalender $[t - 6\text{ hari},\ t]$.

---

## Asumsi Teknis & Produk yang Diambil

1. **Penyimpanan Tanggal Kalender (`YYYY-MM-DD`)**: Kolom tanggal pada SQLite disimpan sebagai teks ISO kalender lokal (`YYYY-MM-DD`) melalui `IsoDateConverter` agar *constraint* `UNIQUE` satu entri berat per hari dan pengurutan indeks tetap konsisten meskipun pengguna berpindah zona waktu atau mencatat pada jam berbeda.
2. **Penyimpanan Berat Internal dalam Kilogram (`kg`)**: Seluruh nilai berat di database disimpan dalam satuan metrik `kg` sebagai *single source of truth*; ketika pengguna memilih satuan `lb` di Pengaturan, konversi dilakukan secara murni pada lapisan tampilan dan input (`1 kg = 2,20462 lb`).
3. **Perhitungan Streak Pencatatan Harian**: Satu hari dihitung aktif dalam *streak* apabila pengguna memiliki minimal satu catatan berat badan **atau** minimal satu catatan makanan pada hari kalender tersebut. Jika pagi hari ini pengguna belum mencatat tetapi kemarin sudah mencatat, *streak* kemarin tetap ditampilkan aktif agar tidak terasa menghukum sebelum pengguna sempat mencatat.
4. **Baseline Penyesuaian Kalori Otomatis (`>= 2 kg`)**: Nilai berat dasar perhitungan kalori (`calorie_baseline_weight`) disimpan di tabel `Settings` saat selesai *onboarding*, saat profil/aktivitas diubah, atau saat tujuan diganti, lalu diperbarui otomatis begitu entri berat terbaru berselisih `>= 2,0 kg` dari *baseline* tersebut.
5. **Kompatibilitas Material UI Flutter 3.50+**: Pada Flutter `3.50.0` (Dart `3.14.0`), pustaka `package:flutter/material.dart` telah dideprekasi oleh SDK dan digantikan oleh paket resmi `package:material_ui/material_ui.dart` serta `package:cupertino_ui/cupertino_ui.dart`. Seluruh komponen aplikasi telah menggunakan paket terbaru tersebut sehingga `flutter analyze` bersih tanpa peringatan deprekrasi.

---

## Catatan Kesehatan (Disclaimer)
ScaleUp dirancang sebagai alat bantu pemantauan mandiri harian dan **bukan pengganti saran medis, diagnosis, atau konsultasi dokter maupun ahli gizi profesional**.
