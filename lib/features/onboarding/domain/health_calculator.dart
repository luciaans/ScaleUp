import 'dart:math' as math;

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils_ext.dart';
import '../../../core/utils/formatters.dart';
import 'user_enums.dart';

/// Hasil perhitungan target kalori & makro harian beserta catatan aturan kesehatan.
class CalorieCalculationResult {
  const CalorieCalculationResult({
    required this.bmr,
    required this.tdee,
    required this.targetCalories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.requestedWeeklyRateKg,
    required this.effectiveWeeklyRateKg,
    required this.wasClampedToMinCalories,
    required this.wasClampedByOnePercentRule,
    this.estimatedTargetDate,
  });

  final double bmr;
  final double tdee;
  final int targetCalories;
  final int proteinGrams;
  final int carbsGrams;
  final int fatGrams;
  final double requestedWeeklyRateKg;
  final double effectiveWeeklyRateKg;
  final bool wasClampedToMinCalories;
  final bool wasClampedByOnePercentRule;
  final DateTime? estimatedTargetDate;
}

/// Hasil validasi input tujuan beserta pesan ramah Bahasa Indonesia.
class GoalValidationResult {
  const GoalValidationResult._({
    required this.isValid,
    this.errorMessage,
    this.warningMessage,
  });

  const GoalValidationResult.valid({String? warningMessage})
      : this._(isValid: true, warningMessage: warningMessage);

  const GoalValidationResult.invalid(String message)
      : this._(isValid: false, errorMessage: message);

  final bool isValid;
  final String? errorMessage;
  final String? warningMessage;
}

/// Kumpulan fungsi murni (pure functions) untuk seluruh perhitungan kesehatan ScaleUp.
abstract final class HealthCalculator {
  /// Rumus Mifflin-St Jeor:
  /// - Pria: `10*kg + 6,25*cm - 5*usia + 5`
  /// - Wanita: `10*kg + 6,25*cm - 5*usia - 161`
  static double calculateBmr({
    required Gender gender,
    required double weightKg,
    required double heightCm,
    required int ageYears,
  }) {
    final base = (10.0 * weightKg) + (6.25 * heightCm) - (5.0 * ageYears);
    return gender == Gender.male ? base + 5.0 : base - 161.0;
  }

  /// TDEE = BMR x faktor aktivitas (1,2 / 1,375 / 1,55 / 1,725 / 1,9).
  static double calculateTdee({
    required double bmr,
    required ActivityLevel activityLevel,
  }) {
    return bmr * activityLevel.factor;
  }

  /// Menghitung Indeks Massa Tubuh (BMI = kg / m^2).
  static double calculateBmi({
    required double weightKg,
    required double heightCm,
  }) {
    if (heightCm <= 0) return 0;
    final heightM = heightCm / 100.0;
    return weightKg / (heightM * heightM);
  }

  /// Berat badan minimum (kg) untuk mencapai BMI 18,5 pada tinggi tertentu.
  static double minHealthyWeightForHeight(double heightCm) {
    final heightM = heightCm / 100.0;
    final raw = AppConstants.minHealthyBmiForLoss * heightM * heightM;
    // Bulatkan ke atas 0,1 kg terdekat agar BMI tidak di bawah 18,5
    return (raw * 10.0).ceil() / 10.0;
  }

  /// Kategori BMI suportif tanpa menghakimi.
  static BmiCategory classifyBmi(double bmi) {
    if (bmi < 18.5) return BmiCategory.underweight;
    if (bmi < 25.0) return BmiCategory.normal;
    if (bmi < 30.0) return BmiCategory.overweight;
    return BmiCategory.obese;
  }

  /// Batas aman kecepatan perubahan berat mingguan: maksimal 1% berat badan/minggu.
  static double maxSafeWeeklyRateKg(double currentWeightKg) {
    if (currentWeightKg <= 0) return 0;
    return currentWeightKg * AppConstants.maxWeeklyChangePercent;
  }

  /// Batas kalori minimum wajib berdasarkan jenis kelamin:
  /// 1200 kkal (wanita) / 1500 kkal (pria).
  static int minAllowedCalories(Gender gender) {
    return gender == Gender.female
        ? AppConstants.minCaloriesFemale
        : AppConstants.minCaloriesMale;
  }

  /// Menghitung target makro default:
  /// - Protein: 1,6 g/kg berat badan (4 kkal/g)
  /// - Lemak: 25% dari target kalori (9 kkal/g)
  /// - Karbohidrat: sisa kalori (4 kkal/g)
  static ({int proteinGrams, int carbsGrams, int fatGrams}) calculateMacros({
    required int targetCalories,
    required double weightKg,
  }) {
    final proteinGrams = (weightKg * AppConstants.defaultProteinPerKg).round();
    final proteinKcal = proteinGrams * AppConstants.kcalPerGramProtein;

    final fatKcal = targetCalories * AppConstants.defaultFatCalorieRatio;
    final fatGrams = (fatKcal / AppConstants.kcalPerGramFat).round();
    final actualFatKcal = fatGrams * AppConstants.kcalPerGramFat;

    final remainingKcal = math.max(
      0.0,
      targetCalories - proteinKcal - actualFatKcal,
    );
    final carbsGrams = (remainingKcal / AppConstants.kcalPerGramCarbs).round();

    return (
      proteinGrams: proteinGrams,
      carbsGrams: carbsGrams,
      fatGrams: fatGrams,
    );
  }

  /// Menghitung estimasi tanggal target tercapai.
  static DateTime? estimateTargetDate({
    required GoalType goalType,
    required double currentWeightKg,
    required double targetWeightKg,
    required double effectiveWeeklyRateKg,
    DateTime? startDate,
  }) {
    final baseDate = AppDateUtils.dateOnly(startDate ?? DateTime.now());

    if (goalType == GoalType.maintain) {
      return baseDate;
    }

    if (goalType == GoalType.lose && currentWeightKg <= targetWeightKg) {
      return baseDate;
    }
    if (goalType == GoalType.gain && currentWeightKg >= targetWeightKg) {
      return baseDate;
    }

    if (effectiveWeeklyRateKg <= 0) {
      return null;
    }

    final diffKg = (currentWeightKg - targetWeightKg).abs();
    final daysNeeded = (diffKg / effectiveWeeklyRateKg * 7.0).ceil();
    return DateTime(baseDate.year, baseDate.month, baseDate.day + daysNeeded);
  }

  /// Menghitung rencana nutrisi lengkap dengan penegakan seluruh aturan kesehatan.
  static CalorieCalculationResult calculateCompletePlan({
    required Gender gender,
    required double weightKg,
    required double heightCm,
    required int ageYears,
    required ActivityLevel activityLevel,
    required GoalType goalType,
    required double targetWeightKg,
    required double requestedWeeklyRateKg,
    DateTime? referenceDate,
  }) {
    final bmr = calculateBmr(
      gender: gender,
      weightKg: weightKg,
      heightCm: heightCm,
      ageYears: ageYears,
    );
    final tdee = calculateTdee(bmr: bmr, activityLevel: activityLevel);

    final maxOnePercentRate = maxSafeWeeklyRateKg(weightKg);
    double safeRate = goalType == GoalType.maintain
        ? 0.0
        : math.max(0.0, requestedWeeklyRateKg);
    bool clampedByOnePercent = false;

    if (goalType != GoalType.maintain && safeRate > maxOnePercentRate + 1e-6) {
      safeRate = maxOnePercentRate;
      clampedByOnePercent = true;
    }

    final dailyDelta = (safeRate * AppConstants.kcalPerKgBodyWeight) / 7.0;
    double rawTarget = switch (goalType) {
      GoalType.lose => tdee - dailyDelta,
      GoalType.gain => tdee + dailyDelta,
      GoalType.maintain => tdee,
    };

    final minCalories = minAllowedCalories(gender);
    bool clampedToMinCalories = false;
    if (rawTarget.round() < minCalories) {
      rawTarget = minCalories.toDouble();
      clampedToMinCalories = true;
    }

    final targetCalories = rawTarget.round();

    // Hitung kecepatan efektif nyata apabila defisit dibatasi batas kalori minimum
    double effectiveRate = safeRate;
    if (goalType == GoalType.lose && clampedToMinCalories) {
      final actualDeficit = math.max(0.0, tdee - targetCalories);
      effectiveRate = (actualDeficit * 7.0) / AppConstants.kcalPerKgBodyWeight;
    }

    final macros = calculateMacros(
      targetCalories: targetCalories,
      weightKg: weightKg,
    );

    final estimatedDate = estimateTargetDate(
      goalType: goalType,
      currentWeightKg: weightKg,
      targetWeightKg:
          goalType == GoalType.maintain ? weightKg : targetWeightKg,
      effectiveWeeklyRateKg: effectiveRate,
      startDate: referenceDate,
    );

    return CalorieCalculationResult(
      bmr: bmr,
      tdee: tdee,
      targetCalories: targetCalories,
      proteinGrams: macros.proteinGrams,
      carbsGrams: macros.carbsGrams,
      fatGrams: macros.fatGrams,
      requestedWeeklyRateKg:
          goalType == GoalType.maintain ? 0.0 : requestedWeeklyRateKg,
      effectiveWeeklyRateKg: effectiveRate,
      wasClampedToMinCalories: clampedToMinCalories,
      wasClampedByOnePercentRule: clampedByOnePercent,
      estimatedTargetDate: estimatedDate,
    );
  }

  /// Validasi data profil (nama, tanggal lahir >= 18 tahun & tidak di masa depan, tinggi, berat).
  static String? validateName(String? raw) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) return 'Masukkan nama panggilanmu terlebih dahulu.';
    if (trimmed.length > 60) return 'Nama maksimal 60 karakter.';
    return null;
  }

  static String? validateBirthDate(DateTime? birthDate, {DateTime? now}) {
    if (birthDate == null) return 'Pilih tanggal lahirmu terlebih dahulu.';
    final today = AppDateUtils.dateOnly(now ?? DateTime.now());
    final dob = AppDateUtils.dateOnly(birthDate);

    if (dob.isAfter(today)) {
      return 'Tanggal lahir tidak boleh berada di masa depan.';
    }

    final age = AppDateUtils.calculateAgeYears(dob, reference: today);
    if (age < AppConstants.minAgeYears) {
      return 'Maaf, ScaleUp ditujukan bagi pengguna berusia 18 tahun ke atas karena masa pertumbuhan remaja memerlukan pendampingan dokter atau ahli gizi.';
    }
    if (age > AppConstants.maxAgeYears) {
      return 'Periksa kembali tahun kelahiran yang dimasukkan.';
    }
    return null;
  }

  static String? validateHeightCm(double? heightCm) {
    if (heightCm == null || heightCm.isNaN) {
      return 'Masukkan tinggi badan dalam cm.';
    }
    if (heightCm < AppConstants.minHeightCm ||
        heightCm > AppConstants.maxHeightCm) {
      return 'Tinggi badan harus di antara 100 hingga 250 cm.';
    }
    return null;
  }

  static String? validateWeightKg(double? weightKg) {
    if (weightKg == null || weightKg.isNaN) {
      return 'Masukkan berat badan yang valid.';
    }
    if (weightKg < AppConstants.minWeightKg ||
        weightKg > AppConstants.maxWeightKg) {
      return 'Berat badan harus di antara 25 hingga 300 kg.';
    }
    return null;
  }

  /// Validasi pilihan tujuan beserta aturan kesehatan BMI >= 18,5 dan batas kecepatan 1%.
  static GoalValidationResult validateGoal({
    required GoalType goalType,
    required double currentWeightKg,
    required double targetWeightKg,
    required double heightCm,
    required double weeklyRateKg,
  }) {
    if (goalType == GoalType.maintain) {
      return const GoalValidationResult.valid();
    }

    final weightErr = validateWeightKg(targetWeightKg);
    if (weightErr != null) {
      return GoalValidationResult.invalid(weightErr);
    }

    if (goalType == GoalType.lose) {
      if (targetWeightKg >= currentWeightKg) {
        return const GoalValidationResult.invalid(
          'Untuk tujuan menurunkan berat badan, berat target perlu lebih rendah dari berat saat ini.',
        );
      }

      final targetBmi = calculateBmi(
        weightKg: targetWeightKg,
        heightCm: heightCm,
      );
      if (targetBmi < AppConstants.minHealthyBmiForLoss) {
        final minSafeKg = minHealthyWeightForHeight(heightCm);
        return GoalValidationResult.invalid(
          'Berat target membuat BMI di bawah 18,5. Demi kesehatanmu, pilih berat target minimal ${AppFormatters.decimal1(minSafeKg)} kg.',
        );
      }
    } else if (goalType == GoalType.gain) {
      if (targetWeightKg <= currentWeightKg) {
        return const GoalValidationResult.invalid(
          'Untuk tujuan menaikkan berat badan, berat target perlu lebih tinggi dari berat saat ini.',
        );
      }
    }

    if (weeklyRateKg <= 0) {
      return const GoalValidationResult.invalid(
        'Pilih kecepatan perubahan mingguan yang valid.',
      );
    }

    final maxRate = maxSafeWeeklyRateKg(currentWeightKg);
    if (weeklyRateKg > maxRate + 1e-6) {
      return GoalValidationResult.valid(
        warningMessage:
            'Kecepatan otomatis disesuaikan ke ${AppFormatters.rateDecimal(maxRate)} kg/minggu (maksimal 1% berat badan per minggu) agar tetap aman bagi tubuhmu.',
      );
    }

    return const GoalValidationResult.valid();
  }

  /// Mengecek apakah target kalori perlu dihitung ulang akibat perubahan berat >= 2 kg.
  static bool shouldRecalculateForWeightChange({
    required double? baselineWeightKg,
    required double currentWeightKg,
  }) {
    if (baselineWeightKg == null) return true;
    return (currentWeightKg - baselineWeightKg).abs() >=
        AppConstants.autoRecalcWeightDeltaKg;
  }

  /// Menghitung moving average `windowDays` hari kalender untuk meredam fluktuasi harian.
  /// Mengasumsikan [sortedEntries] terurut menaik berdasarkan tanggal.
  static List<({DateTime date, double averageKg})> calculateMovingAverage(
    List<({DateTime date, double weightKg})> sortedEntries, {
    int windowDays = 7,
  }) {
    if (sortedEntries.isEmpty) return const [];

    final result = <({DateTime date, double averageKg})>[];
    for (int i = 0; i < sortedEntries.length; i++) {
      final currentDate = AppDateUtils.dateOnly(sortedEntries[i].date);
      final windowStart = DateTime(
        currentDate.year,
        currentDate.month,
        currentDate.day - (windowDays - 1),
      );

      double sum = 0;
      int count = 0;
      for (int j = i; j >= 0; j--) {
        final candidateDate = AppDateUtils.dateOnly(sortedEntries[j].date);
        if (candidateDate.isBefore(windowStart)) break;
        sum += sortedEntries[j].weightKg;
        count++;
      }

      result.add((
        date: currentDate,
        averageKg: count > 0 ? sum / count : sortedEntries[i].weightKg,
      ));
    }

    return result;
  }
}
