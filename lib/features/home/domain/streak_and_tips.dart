import '../../../core/utils/date_utils_ext.dart';
import '../../onboarding/domain/user_enums.dart';

/// Hasil perhitungan streak pencatatan harian pengguna.
class StreakSummary {
  const StreakSummary({
    required this.currentStreakDays,
    required this.loggedToday,
    required this.last7DaysLogged,
  });

  final int currentStreakDays;
  final bool loggedToday;

  /// Status pencatatan 7 hari terakhir berurutan dari 6 hari lalu hingga hari ini.
  final List<({DateTime date, bool isLogged})> last7DaysLogged;
}

/// Fungsi murni untuk menghitung streak pencatatan, deteksi milestone perayaan,
/// serta kurasi tips harian sesuai tujuan.
abstract final class StreakAndTips {
  /// Menghitung streak hari berturut-turut berdasarkan himpunan kunci tanggal `YYYY-MM-DD`.
  static StreakSummary calculateStreak({
    required Set<String> activeIsoDates,
    DateTime? referenceToday,
  }) {
    final today = AppDateUtils.dateOnly(referenceToday ?? DateTime.now());
    final todayKey = AppDateUtils.toIsoDateKey(today);
    final loggedToday = activeIsoDates.contains(todayKey);

    int streak = 0;
    DateTime cursor = loggedToday ? today : AppDateUtils.yesterday(today);

    while (activeIsoDates.contains(AppDateUtils.toIsoDateKey(cursor))) {
      streak++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }

    final last7 = List<({DateTime date, bool isLogged})>.generate(7, (idx) {
      final offset = 6 - idx;
      final d = DateTime(today.year, today.month, today.day - offset);
      return (
        date: d,
        isLogged: activeIsoDates.contains(AppDateUtils.toIsoDateKey(d)),
      );
    });

    return StreakSummary(
      currentStreakDays: streak,
      loggedToday: loggedToday,
      last7DaysLogged: last7,
    );
  }

  /// Mendeteksi apakah ada milestone baru (streak 7, streak 30, atau target tercapai)
  /// yang belum pernah dirayakan sebelumnya.
  static ({String key, String message})? detectUncelebratedMilestone({
    required int streakDays,
    required bool isGoalReached,
    required GoalType goalType,
    required int activeGoalId,
    required int totalWeightEntries,
    required Set<String> celebratedKeys,
  }) {
    if (goalType != GoalType.maintain &&
        isGoalReached &&
        totalWeightEntries >= 2) {
      final goalKey = 'goal_$activeGoalId';
      if (!celebratedKeys.contains(goalKey)) {
        return (
          key: goalKey,
          message:
              'Selamat! Kamu berhasil mencapai berat targetmu dengan konsisten!',
        );
      }
    }

    if (streakDays >= 30 && !celebratedKeys.contains('streak_30')) {
      return (
        key: 'streak_30',
        message: 'Luar biasa! 30 hari berturut-turut mencatat kebiasaan sehat!',
      );
    }

    if (streakDays >= 7 && !celebratedKeys.contains('streak_7')) {
      return (
        key: 'streak_7',
        message: 'Hebat! Kamu sudah konsisten mencatat selama 7 hari beruntun!',
      );
    }

    return null;
  }

  /// Memilih tips harian positif yang sesuai dengan tujuan aktif.
  static ({String title, String body}) dailyTipForGoal(
    GoalType goalType, {
    DateTime? date,
  }) {
    final targetDate = AppDateUtils.dateOnly(date ?? DateTime.now());
    final daySeed =
        targetDate.difference(DateTime(targetDate.year, 1, 1)).inDays;

    final tips = switch (goalType) {
      GoalType.lose => _loseTips,
      GoalType.gain => _gainTips,
      GoalType.maintain => _maintainTips,
    };

    return tips[daySeed.abs() % tips.length];
  }

  static const List<({String title, String body})> _loseTips = [
    (
      title: 'Utamakan Protein di Tiap Waktu Makan',
      body:
          'Lauk seperti telur rebus, tempe kukus, tahu, ikan bakar, atau dada ayam membantu kenyang lebih lama.',
    ),
    (
      title: 'Minum Air Putih Sebelum Makan',
      body:
          'Segelas air putih 15 menit sebelum makan membantu tubuh mengenali rasa kenyang dengan lebih tenang.',
    ),
    (
      title: 'Bijak Memilih Kuah & Minuman Manis',
      body:
          'Mengganti es teh manis dengan teh tawar atau air mineral bisa menghemat sekitar 90–150 kkal tanpa mengurangi porsi makan.',
    ),
    (
      title: 'Tidur Cukup Bantu Jaga Nafsu Makan',
      body:
          'Istirahat 7–8 jam per malam menjaga hormon lapar tetap seimbang sepanjang hari berikutnya.',
    ),
  ];

  static const List<({String title, String body})> _gainTips = [
    (
      title: 'Tambah Camilan Padat Nutrisi',
      body:
          'Selipkan alpukat, kacang sangrai, pisang, susu, atau telur rebus di sela waktu makan utama tanpa membuat begah.',
    ),
    (
      title: 'Makan Lebih Sering dengan Porsi Nyaman',
      body:
          'Membagi asupan menjadi 3 makan utama dan 2 camilan bergizi lebih nyaman bagi pencernaan daripada makan sekaligus besar.',
    ),
    (
      title: 'Padukan dengan Latihan Kekuatan Ringan',
      body:
          'Olahraga beban ringan dan asupan protein cukup membantu kenaikan berat badan lebih berkualitas.',
    ),
    (
      title: 'Minum Setelah Makan Utama',
      body:
          'Minum cairan berkalori seperti susu atau jus buah setelah makan agar perut tidak cepat penuh sebelum lauk habis.',
    ),
  ];

  static const List<({String title, String body})> _maintainTips = [
    (
      title: 'Isi Setengah Piring dengan Sayur & Buah',
      body:
          'Kombinasi sayur bening, lalapan, atau buah potong menjaga serat dan vitamin harian tetap tercukupi.',
    ),
    (
      title: 'Timbang di Waktu yang Konsisten',
      body:
          'Menimbang berat di pagi hari setelah ke kamar mandi memberikan gambaran tren mingguan yang paling stabil.',
    ),
    (
      title: 'Aktif Bergerak Ringan Setiap Hari',
      body:
          'Jalan kaki santai 20–30 menit setelah bekerja membantu menjaga kebugaran dan suasana hati.',
    ),
    (
      title: 'Nikmati Makanan Favorit Secara Sadar',
      body:
          'Menjaga berat badan bukan berarti pantang total—nikmati makanan favoritmu dalam porsi yang seimbang.',
    ),
  ];
}
