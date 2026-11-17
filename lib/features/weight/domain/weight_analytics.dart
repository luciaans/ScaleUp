import '../../../core/utils/date_utils_ext.dart';
import '../../../data/database/app_database.dart';
import '../../onboarding/domain/health_calculator.dart';
import '../../onboarding/domain/user_enums.dart';

/// Filter rentang waktu untuk grafik berat badan.
enum WeightRangeFilter {
  days7('7H', 7),
  days30('30H', 30),
  days90('90H', 90),
  all('Semua', null);

  const WeightRangeFilter(this.label, this.days);
  final String label;
  final int? days;
}

/// Titik data grafik berat harian beserta nilai tren moving average 7 hari.
class WeightChartPoint {
  const WeightChartPoint({
    required this.date,
    required this.weightKg,
    required this.movingAverage7dKg,
  });

  final DateTime date;
  final double weightKg;
  final double movingAverage7dKg;
}

/// Ringkasan statistik progres berat badan & pesan motivasi kontekstual.
class WeightStatisticsSummary {
  const WeightStatisticsSummary({
    required this.startWeightKg,
    required this.currentWeightKg,
    required this.targetWeightKg,
    required this.totalChangeKg,
    required this.weeklyChangeRateKg,
    required this.remainingToTargetKg,
    required this.bmi,
    required this.bmiCategory,
    required this.motivationTitle,
    required this.motivationBody,
  });

  final double startWeightKg;
  final double currentWeightKg;
  final double targetWeightKg;
  final double totalChangeKg;
  final double weeklyChangeRateKg;
  final double remainingToTargetKg;
  final double bmi;
  final BmiCategory bmiCategory;
  final String motivationTitle;
  final String motivationBody;
}

/// Fungsi murni analitik berat badan, pemfilteran grafik, dan generator motivasi suportif.
abstract final class WeightAnalytics {
  /// Menyusun titik grafik lengkap dengan moving average 7 hari yang dihitung
  /// dari seluruh riwayat kronologis sebelum dipotong berdasarkan [filter].
  static List<WeightChartPoint> buildChartPoints({
    required List<WeightEntry> ascendingEntries,
    required WeightRangeFilter filter,
    DateTime? referenceDate,
  }) {
    if (ascendingEntries.isEmpty) return const [];

    final rawPairs = ascendingEntries
        .map((e) => (date: AppDateUtils.dateOnly(e.date), weightKg: e.weightKg))
        .toList();

    final movingAverages = HealthCalculator.calculateMovingAverage(
      rawPairs,
      windowDays: 7,
    );

    final allPoints = List<WeightChartPoint>.generate(
      ascendingEntries.length,
      (i) => WeightChartPoint(
        date: rawPairs[i].date,
        weightKg: rawPairs[i].weightKg,
        movingAverage7dKg: movingAverages[i].averageKg,
      ),
    );

    if (filter.days == null) {
      return allPoints;
    }

    final anchor = AppDateUtils.dateOnly(
      referenceDate ?? allPoints.last.date,
    );
    final cutoff = DateTime(
      anchor.year,
      anchor.month,
      anchor.day - (filter.days! - 1),
    );

    return allPoints
        .where((point) => !point.date.isBefore(cutoff))
        .toList();
  }

  /// Menghitung seluruh statistik berat badan & pesan motivasi kontekstual.
  static WeightStatisticsSummary computeSummary({
    required List<WeightEntry> ascendingEntries,
    required GoalType goalType,
    required double? goalStartWeightKg,
    required double? goalTargetWeightKg,
    required double heightCm,
  }) {
    final fallbackWeight = goalStartWeightKg ?? 65.0;
    final startWeight = goalStartWeightKg ??
        (ascendingEntries.isNotEmpty
            ? ascendingEntries.first.weightKg
            : fallbackWeight);
    final currentWeight = ascendingEntries.isNotEmpty
        ? ascendingEntries.last.weightKg
        : startWeight;
    final targetWeight = goalTargetWeightKg ?? startWeight;

    final totalChange = currentWeight - startWeight;

    double weeklyChange = 0.0;
    if (ascendingEntries.length >= 2) {
      final firstEntry = ascendingEntries.first;
      final lastEntry = ascendingEntries.last;
      final spanDays = AppDateUtils.dateOnly(lastEntry.date)
          .difference(AppDateUtils.dateOnly(firstEntry.date))
          .inDays;
      final effectiveWeeks = spanDays < 7 ? 1.0 : spanDays / 7.0;
      weeklyChange =
          (lastEntry.weightKg - firstEntry.weightKg) / effectiveWeeks;
    }

    double remaining = 0.0;
    if (goalType == GoalType.lose) {
      remaining =
          currentWeight > targetWeight ? currentWeight - targetWeight : 0.0;
    } else if (goalType == GoalType.gain) {
      remaining =
          currentWeight < targetWeight ? targetWeight - currentWeight : 0.0;
    } else {
      remaining = (currentWeight - targetWeight).abs();
    }

    final bmi = HealthCalculator.calculateBmi(
      weightKg: currentWeight,
      heightCm: heightCm,
    );
    final bmiCat = HealthCalculator.classifyBmi(bmi);

    final motivation = buildMotivationalMessage(
      goalType: goalType,
      totalChangeKg: totalChange,
      remainingToTargetKg: remaining,
      entryCount: ascendingEntries.length,
    );

    return WeightStatisticsSummary(
      startWeightKg: startWeight,
      currentWeightKg: currentWeight,
      targetWeightKg: targetWeight,
      totalChangeKg: totalChange,
      weeklyChangeRateKg: weeklyChange,
      remainingToTargetKg: remaining,
      bmi: bmi,
      bmiCategory: bmiCat,
      motivationTitle: motivation.title,
      motivationBody: motivation.body,
    );
  }

  /// Menghasilkan pesan motivasi kontekstual yang hangat, positif, dan bebas penghakiman.
  static ({String title, String body}) buildMotivationalMessage({
    required GoalType goalType,
    required double totalChangeKg,
    required double remainingToTargetKg,
    required int entryCount,
  }) {
    if (entryCount <= 1) {
      return (
        title: 'Langkah Awal yang Hebat!',
        body:
            'Mencatat berat secara rutin membantumu mengenali pola alami tubuh dengan tenang.',
      );
    }

    if (goalType != GoalType.maintain && remainingToTargetKg <= 0.05) {
      return (
        title: 'Target Tercapai!',
        body:
            'Selamat! Konsistensi harianmu membuahkan hasil sehat. Mari jaga kebiasaan baik ini.',
      );
    }

    switch (goalType) {
      case GoalType.lose:
        if (totalChangeKg <= -0.2) {
          return (
            title: 'Arah Progresmu Positif',
            body:
                'Perubahan bertahap adalah cara paling sehat agar hasilnya bertahan jangka panjang.',
          );
        }
        return (
          title: 'Tetap Tenang & Konsisten',
          body:
              'Fluktuasi harian karena cairan tubuh atau waktu makan sangatlah wajar. Fokus pada tren 7 harimu!',
        );
      case GoalType.gain:
        if (totalChangeKg >= 0.2) {
          return (
            title: 'Progres Bertumbuh Baik',
            body:
                'Asupan bernutrisi dan pola makan teraturmu mulai mendukung kenaikan yang sehat.',
          );
        }
        return (
          title: 'Nikmati Prosesnya Bertahap',
          body:
              'Menaikkan berat badan sehat memang butuh kesabaran. Tambahkan camilan bergizi sedikit demi sedikit.',
        );
      case GoalType.maintain:
        if (remainingToTargetKg <= 1.5) {
          return (
            title: 'Keseimbangan Terjaga Baik',
            body:
                'Berat badanmu berada nyaman di sekitar rentang target. Teruskan ritme sehatmu!',
          );
        }
        return (
          title: 'Kembali ke Ritme Nyaman',
          body:
              'Sedikit pergeseran berat itu wajar. Sesuaikan porsi harian secara perlahan tanpa terburu-buru.',
        );
    }
  }
}
