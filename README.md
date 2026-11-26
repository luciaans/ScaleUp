<div align="center">

<h1>
  <img src="assets/branding/scaleup_logo.png" width="56" alt="Logo Kucing ScaleUp" align="absmiddle" />
  ScaleUp
</h1>

**Pelacak berat badan & kalori harian dengan teman kucing meme.**

![Version](https://img.shields.io/badge/version-1.0.0-2563EB)
![Platform](https://img.shields.io/badge/platform-Android%20%C2%B7%20iOS%20%C2%B7%20Web-16A34A)
![Flutter](https://img.shields.io/badge/Flutter-3.50%2B-02569B)
![Dart](https://img.shields.io/badge/Dart-%5E3.14.0-F59E0B)

[Instalasi](#instalasi) · [Fitur](#fitur) · [Foto Makanan AI](#foto-makanan-ai) · [Rumus Kesehatan](#rumus-kesehatan) · [Arsitektur](#arsitektur) · [Pengembangan](#pengembangan)

</div>

---

ScaleUp adalah aplikasi pemantau berat badan dan asupan kalori harian **offline-first** berbasis **Flutter (Material 3)**. Catat berat badan satu tangan, pantau tren grafik 7 hari, hitung target kalori otomatis dengan pagar kesehatan aman, dan log makanan dari database lokal berisi **92 makanan & minuman khas Indonesia**.

- **Offline-first & privat.** Seluruh catatan berat, log makanan, profil, dan riwayat tujuan tersimpan lokal di SQLite ([Drift](https://drift.simonbinder.eu/)). Ekspor seluruh data kapan saja ke format CSV.
- **Target sehat otomatis.** Menghitung BMR/TDEE dengan batas laju mingguan maksimal `1%` berat badan, batas kalori minimum (`1.200 kkal` wanita / `1.500 kkal` pria), dan kalibrasi ulang otomatis setiap berat berubah `>= 2,0 kg`.
- **Didampingi Mochi Neko.** Stiker kucing meme PNG transparan interaktif menemani alur onboarding, dashboard harian, hingga selebrasi milestone *streak*.

## Instalasi

1. Pastikan **Flutter SDK** (`>= 3.47.0`, diuji pada Flutter `3.50.0` / Dart `3.14.0`) sudah terpasang.
2. Clone repositori dan unduh dependensi:

```bash
git clone https://github.com/luciaans/scale-up.git
cd scale-up
flutter pub get
```

3. Jalankan di emulator/perangkat Android atau iOS, atau via browser:

```bash
# Android / iOS
flutter run

# Web preview lokal
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080
```

## Fitur

### Onboarding & Profil Pengguna
- Alur 4 langkah interaktif: sambutan & disclaimer kesehatan, data diri, tingkat aktivitas, serta pilih tujuan dengan pratinjau target kalori dan estimasi tanggal tercapai.
- Validasi suportif untuk tinggi (`100–250 cm`), berat (`25–300 kg`), tanggal lahir, dan usia minimal `18 tahun`.
- Riwayat tujuan sebelumnya tersimpan lokal (`isActive = false`) dengan tepat satu tujuan aktif.

### Pencatatan Berat & Grafik Tren
- Input cepat lewat *bottom sheet* satu tangan: tombol `-/+ 0,1`, *slider* presisi, pemilih tanggal, dan catatan opsional.
- Satu entri unik per hari kalender (*upsert* otomatis di tanggal sama) serta *swipe-to-delete* dengan tombol **Urungkan (Undo)**.
- Grafik `fl_chart` interaktif dengan filter **7H / 30H / 90H / Semua**, garis target putus-putus, dan garis tren **Moving Average 7 Hari**.

### Cek Kalori & Database Makanan Indonesia
- **92 makanan & minuman Indonesia** bawaan (*seed* otomatis: nasi putih, nasi goreng, bubur ayam, tempe/tahu, ayam bakar, rendang, bakso, soto, gado-gado, kopi susu, es teh manis, dll.).
- Pencarian instan, filter **Semua / Favorit / Terakhir**, tambah **Makanan Custom**, dan porsi pecahan (`0,25–20` porsi).
- Log per waktu makan (**Sarapan, Makan Siang, Makan Malam, Camilan**), fitur satu ketuk **Salin dari Kemarin**, bar makro, dan grafik kalori 7 hari.

### Dashboard, Pengingat & Aksesibilitas
- Dashboard `CustomScrollView` + `SliverAppBar` dengan ring progres tujuan, kartu berat, sisa kalori, *streak* harian, tips harian, dan *confetti* milestone (`streak` 7/30 hari atau target tercapai).
- Pengingat notifikasi lokal harian yang dapat diatur jamnya, tema (**Ikut Sistem / Terang / Gelap**), satuan berat (`kg` / `lb`), ekspor CSV, dan reset data aman.
- Ukuran sentuh minimum `48x48dp`, *semantic labels*, aman skala teks hingga `1,35x`, dan mendukung preferensi **Reduce Motion**.

## Foto Makanan AI

ScaleUp menyediakan fitur estimasi nutrisi dari foto makanan melalui `backend/analyze_server.py` menggunakan model `gemini-2.5-flash` (atau baca konfigurasi alternatif Firebase AI Logic di [docs/food-photo-setup.md](docs/food-photo-setup.md)).

```powershell
# Jalankan server lokal untuk analisis foto makanan
$env:GEMINI_API_KEY="YOUR_API_KEY"
python backend/analyze_server.py
```

Server berjalan di `http://127.0.0.1:8000/analyze`. Jika tidak digunakan, pencatatan makanan manual tetap berjalan normal sepenuhnya secara offline. Nilai nutrisi dari foto bersifat perkiraan dan dapat langsung disesuaikan sebelum disimpan.

## Rumus Kesehatan

1. **BMR (Mifflin-St Jeor):**
   - **Pria:** $(10 \times \text{berat}_{\text{kg}}) + (6{,}25 \times \text{tinggi}_{\text{cm}}) - (5 \times \text{usia}) + 5$
   - **Wanita:** $(10 \times \text{berat}_{\text{kg}}) + (6{,}25 \times \text{tinggi}_{\text{cm}}) - (5 \times \text{usia}) - 161$
2. **TDEE:** $\text{BMR} \times \text{Faktor Aktivitas}$ (`1,2` Sedentari · `1,375` Ringan · `1,55` Sedang · `1,725` Berat · `1,9` Sangat Berat).
3. **Target Kalori Harian:**
   - Laju aman dibatasi $\min(\text{laju}_{\text{pilihan}},\ 0{,}01 \times \text{berat}_{\text{kg}})$ dengan $\Delta E = \frac{\text{laju}_{\text{aman}} \times 7.700}{7}$.
   - **Turun:** $\max(\text{Batas Minimum},\ \text{round}(\text{TDEE} - \Delta E))$ · **Naik:** $\text{round}(\text{TDEE} + \Delta E)$ · **Jaga:** $\text{round}(\text{TDEE})$.
   - Batas minimum harian: **1.200 kkal** (wanita) dan **1.500 kkal** (pria); menolak target dengan **BMI < 18,5** pada mode turun.
4. **Target Makro Default:** Protein $1{,}6\text{ g/kg}$ ($4\text{ kkal/g}$), Lemak $25\%$ kalori target ($9\text{ kkal/g}$), Karbohidrat dari sisa kalori ($4\text{ kkal/g}$).
5. **Moving Average 7 Hari:** Rata-rata aritmetika seluruh catatan berat dalam rentang kalender $[t - 6\text{ hari},\ t]$.

## Arsitektur

Menggunakan pola **Feature-First + Repository Pattern** dengan pemisahan logika murni pada lapisan `domain`:

```text
scale-up/
├── assets/
│   ├── branding/                      # Logo kucing ScaleUp (PNG & SVG)
│   └── cats/                          # Koleksi stiker PNG kucing meme Mochi
├── backend/
│   └── analyze_server.py              # Proxy lokal opsional untuk analisis foto makanan AI
└── lib/
    ├── main.dart                      # Entry point, lokalisasi id_ID, ThemeMode & MediaQuery clamp
    ├── core/
    │   ├── constants/                 # Konstanta bisnis, spacing 8dp, & string Bahasa Indonesia
    │   ├── router/                    # GoRouter (boot putih logo kucing, onboarding, 4 tab + FAB)
    │   ├── theme/                     # Palet Clean Slate & tipografi
    │   ├── utils/                     # Formatter id_ID, konversi kg/lb, tanggal, reduce motion
    │   └── widgets/                   # AppCard, MochiCompanion, PrimaryButton, ProgressRing, dll.
    ├── data/
    │   ├── database/                  # Skema 6 tabel Drift (SQLite), indeks tanggal, & migrasi
    │   └── seed/                      # Seed 92 makanan & minuman umum Indonesia
    └── features/
        ├── onboarding/                # Domain HealthCalculator & alur onboarding 4 langkah
        ├── home/                      # Agregasi tanggal aktif, kalkulator streak & dashboard beranda
        ├── weight/                    # WeightRepository, WeightAnalytics & grafik tren
        ├── calories/                  # CaloriesRepository, analisis foto makanan & log harian
        ├── profile/                   # ProfileRepository, GoalRepository & ActiveNutritionPlan
        └── settings/                  # Pengaturan tema, satuan, notifikasi, ekspor CSV & reset data
```

## Pengembangan

```bash
# Generate ulang kode Drift & Riverpod setelah mengubah skema atau provider
dart run build_runner build --delete-conflicting-outputs

# Analisis statis kode
flutter analyze

# Jalankan seluruh unit test & widget test
flutter test
```

## Catatan Kesehatan

ScaleUp dibuat sebagai alat bantu pemantauan mandiri harian dan **bukan pengganti saran medis, diagnosis, atau konsultasi dokter maupun ahli gizi profesional**.
