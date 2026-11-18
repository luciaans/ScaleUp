# Analisis foto makanan

Fitur foto memakai Firebase AI Logic dan Gemini Flash. Tidak perlu menaruh API
key Gemini di source code. Buat project di Firebase, aktifkan Firebase AI Logic
dengan Gemini Developer API, lalu daftarkan aplikasi Android dan/atau Web di
project tersebut.

Jalankan aplikasi dengan Firebase app identifiers dari Firebase Console:

```powershell
flutter run `
  --dart-define=FIREBASE_API_KEY=... `
  --dart-define=FIREBASE_APP_ID=... `
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... `
  --dart-define=FIREBASE_PROJECT_ID=...
```

Identifier ini adalah konfigurasi aplikasi Firebase, bukan API key untuk
memanggil Gemini secara langsung. Untuk rilis, gunakan Firebase App Check dan
atur batas penggunaan/anggaran di Firebase/Google Cloud. Tanpa konfigurasi ini,
aplikasi tetap berjalan untuk pencatatan manual dan menampilkan pesan setup
saat tombol foto dipakai.

Nilai nutrisi dari foto adalah perkiraan berdasarkan makanan dan porsi yang
tampak. Foto tidak bisa memastikan berat bahan, minyak, saus, atau resep dengan
akurasi timbangan; pengguna tetap bisa mengoreksi hasil di daftar makanan.
