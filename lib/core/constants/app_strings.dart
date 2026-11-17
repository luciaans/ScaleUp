/// Seluruh teks UI berbahasa Indonesia yang digunakan lintas fitur inti.
abstract final class AppStrings {
  static const String appName = 'ScaleUp';
  static const String appTagline =
      'Pantau berat badan dan kalori harian dengan tenang, terukur, dan sehat.';

  // Navigasi utama
  static const String navHome = 'Beranda';
  static const String navWeight = 'Berat';
  static const String navCalories = 'Kalori';
  static const String navProfile = 'Profil';
  static const String quickAddTooltip = 'Catat cepat';

  // Bottom sheet Catat Cepat
  static const String quickAddTitle = 'Catat Cepat';
  static const String quickAddSubtitle =
      'Pilih catatan yang ingin kamu tambahkan hari ini';
  static const String quickAddWeightTitle = 'Catat Berat';
  static const String quickAddWeightSubtitle =
      'Perbarui berat badan harian beserta catatan singkat';
  static const String quickAddFoodTitle = 'Tambah Makanan';
  static const String quickAddFoodSubtitle =
      'Catat sarapan, makan siang, makan malam, atau camilan';

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
  static const String finishSetup = 'Mulai Perjalanan Sehat';

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
  static const String healthDisclaimerTitle = 'Catatan Kesehatan';
  static const String healthDisclaimerBody =
      'ScaleUp dirancang sebagai alat bantu pemantauan mandiri dan bukan pengganti saran medis, diagnosis, atau konsultasi dokter maupun ahli gizi profesional.';

  // Error umum
  static const String genericErrorTitle = 'Terjadi Kendala';
  static const String genericErrorSubtitle =
      'Maaf, data belum berhasil dimuat. Silakan coba beberapa saat lagi.';

  // Placeholder Fase 1
  static const String homePlaceholderTitle = 'Ringkasan Harianmu';
  static const String homePlaceholderSubtitle =
      'Pantau progres tujuan, berat badan hari ini, sisa kalori, dan streak harian di sini.';
  static const String weightPlaceholderTitle = 'Belum Ada Catatan Berat';
  static const String weightPlaceholderSubtitle =
      'Mulai catat berat badan harianmu untuk melihat grafik tren 7 hari dan progres menuju target.';
  static const String caloriesPlaceholderTitle = 'Belum Ada Catatan Makanan';
  static const String caloriesPlaceholderSubtitle =
      'Tambahkan menu makan harianmu untuk memantau asupan kalori dan keseimbangan nutrisi.';
  static const String profilePlaceholderTitle = 'Profil & Pengaturan';
  static const String profilePlaceholderSubtitle =
      'Kelola data diri, target berat badan, tema tampilan, pengingat harian, serta ekspor CSV.';
}
