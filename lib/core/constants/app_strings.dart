/// Seluruh teks UI berbahasa Indonesia yang digunakan lintas fitur inti.
abstract final class AppStrings {
  static const String appName = 'ScaleUp';
  static const String appTagline =
      'Pantau berat badan dan kalori harian dengan mudah, terukur, dan konsisten.';

  // Navigasi utama
  static const String navHome = 'Beranda';
  static const String navWeight = 'Berat';
  static const String navCalories = 'Kalori';
  static const String navProfile = 'Profil';
  static const String quickAddTooltip = 'Catat cepat';

  // Bottom sheet Catat Cepat
  static const String quickAddTitle = 'Catat Sekarang';
  static const String quickAddSubtitle =
      'Pilih jenis catatan yang ingin kamu tambahkan hari ini';
  static const String quickAddWeightTitle = 'Catat Berat Badan';
  static const String quickAddWeightSubtitle =
      'Perbarui data berat harian dan tambahkan catatan singkat jika perlu';
  static const String quickAddFoodTitle = 'Tambah Makanan';
  static const String quickAddFoodSubtitle =
      'Catat sarapan, makan siang, makan malam, atau camilan harianmu';

  // Umum
  static const String save = 'Simpan';
  static const String cancel = 'Batal';
  static const String edit = 'Ubah';
  static const String delete = 'Hapus';
  static const String undo = 'Urungkan';
  static const String retry = 'Coba Lagi';
  static const String close = 'Tutup';
  static const String next = 'Lanjut';
  static const String back = 'Kembali';
  static const String startNow = 'Mulai Sekarang';
  static const String finishSetup = 'Selesai & Mulai Tracking';

  // Satuan
  static const String unitKg = 'kg';
  static const String unitLb = 'lb';
  static const String unitCm = 'cm';
  static const String unitKcal = 'kkal';
  static const String unitGram = 'g';

  // Tujuan
  static const String goalLose = 'Turunkan Berat Badan';
  static const String goalGain = 'Naikkan Berat Badan';
  static const String goalMaintain = 'Jaga Berat Badan';

  // Disclaimer Kesehatan
  static const String healthDisclaimerTitle = 'Informasi Penting';
  static const String healthDisclaimerBody =
      'ScaleUp adalah alat bantu pemantauan mandiri dan bukan pengganti saran medis, diagnosis, atau konsultasi dokter maupun ahli gizi profesional.';

  // Error umum
  static const String genericErrorTitle = 'Ups, Ada Kendala';
  static const String genericErrorSubtitle =
      'Data belum berhasil dimuat. Periksa koneksi dan coba beberapa saat lagi.';

  // Placeholder layar kosong
  static const String homePlaceholderTitle = 'Ringkasan Harianmu';
  static const String homePlaceholderSubtitle =
      'Pantau progres tujuan, berat badan hari ini, sisa kalori, dan streak harian di sini.';
  static const String weightPlaceholderTitle = 'Belum Ada Catatan Berat';
  static const String weightPlaceholderSubtitle =
      'Mulai catat berat badan harianmu dan lihat grafik tren 7 hari beserta progres menuju target.';
  static const String caloriesPlaceholderTitle = 'Belum Ada Catatan Makan';
  static const String caloriesPlaceholderSubtitle =
      'Tambahkan menu makan harianmu untuk memantau asupan kalori dan keseimbangan nutrisi.';
  static const String profilePlaceholderTitle = 'Profil & Pengaturan';
  static const String profilePlaceholderSubtitle =
      'Kelola data diri, target berat, tema tampilan, pengingat harian, dan ekspor data CSV.';
}
