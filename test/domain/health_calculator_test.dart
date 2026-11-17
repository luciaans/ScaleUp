import 'package:flutter_test/flutter_test.dart';
import 'package:scale_up/features/onboarding/domain/health_calculator.dart';
import 'package:scale_up/features/onboarding/domain/user_enums.dart';

void main() {
  group('HealthCalculator - BMR, TDEE & BMI', () {
    test('menghitung BMR Mifflin-St Jeor akurat untuk pria dan wanita', () {
      // Pria: 10*70 + 6.25*175 - 5*28 + 5 = 700 + 1093.75 - 140 + 5 = 1658.75
      final maleBmr = HealthCalculator.calculateBmr(
        gender: Gender.male,
        weightKg: 70,
        heightCm: 175,
        ageYears: 28,
      );
      expect(maleBmr, closeTo(1658.75, 0.01));

      // Wanita: 10*60 + 6.25*160 - 5*25 - 161 = 600 + 1000 - 125 - 161 = 1314.0
      final femaleBmr = HealthCalculator.calculateBmr(
        gender: Gender.female,
        weightKg: 60,
        heightCm: 160,
        ageYears: 25,
      );
      expect(femaleBmr, closeTo(1314.0, 0.01));
    });

    test('menghitung TDEE sesuai kelima faktor tingkat aktivitas', () {
      const bmr = 1500.0;
      expect(
        HealthCalculator.calculateTdee(
          bmr: bmr,
          activityLevel: ActivityLevel.sedentary,
        ),
        closeTo(1800.0, 0.01),
      );
      expect(
        HealthCalculator.calculateTdee(
          bmr: bmr,
          activityLevel: ActivityLevel.light,
        ),
        closeTo(2062.5, 0.01),
      );
      expect(
        HealthCalculator.calculateTdee(
          bmr: bmr,
          activityLevel: ActivityLevel.moderate,
        ),
        closeTo(2325.0, 0.01),
      );
      expect(
        HealthCalculator.calculateTdee(
          bmr: bmr,
          activityLevel: ActivityLevel.heavy,
        ),
        closeTo(2587.5, 0.01),
      );
      expect(
        HealthCalculator.calculateTdee(
          bmr: bmr,
          activityLevel: ActivityLevel.veryHeavy,
        ),
        closeTo(2850.0, 0.01),
      );
    });

    test('menghitung BMI dan klasifikasi kategori secara akurat', () {
      final bmiNormal = HealthCalculator.calculateBmi(
        weightKg: 65,
        heightCm: 170,
      );
      expect(bmiNormal, closeTo(22.49, 0.02));
      expect(HealthCalculator.classifyBmi(bmiNormal), BmiCategory.normal);
      expect(HealthCalculator.classifyBmi(18.0), BmiCategory.underweight);
      expect(HealthCalculator.classifyBmi(27.2), BmiCategory.overweight);
      expect(HealthCalculator.classifyBmi(31.5), BmiCategory.obese);
    });
  });

  group('HealthCalculator - Target Kalori, Makro & Aturan Kesehatan', () {
    test('menghitung defisit & surplus kalori normal (1 kg = 7700 kkal)', () {
      // Pria 80 kg, 175 cm, 30 th, Moderate (1.55)
      // BMR = 800 + 1093.75 - 150 + 5 = 1748.75 -> TDEE = 2710.56
      // Kecepatan turun 0.5 kg/mg -> defisit 550 kkal/hari -> target ~2161 kkal
      final losePlan = HealthCalculator.calculateCompletePlan(
        gender: Gender.male,
        weightKg: 80,
        heightCm: 175,
        ageYears: 30,
        activityLevel: ActivityLevel.moderate,
        goalType: GoalType.lose,
        targetWeightKg: 72,
        requestedWeeklyRateKg: 0.5,
        referenceDate: DateTime(2026, 11, 18),
      );

      expect(losePlan.wasClampedByOnePercentRule, isFalse);
      expect(losePlan.wasClampedToMinCalories, isFalse);
      expect(losePlan.targetCalories, 2161);
      // 8 kg pada laju 0.5 kg/mg = 16 minggu = 112 hari
      expect(
        losePlan.estimatedTargetDate,
        DateTime(2026, 11, 18 + 112),
      );
    });

    test('menegakkan batas kalori minimum 1200 kkal (wanita) dan 1500 kkal (pria)',
        () {
      // Wanita kecil sedentari dengan defisit agresif harus di-clamp ke 1200 kkal
      final femaleClamped = HealthCalculator.calculateCompletePlan(
        gender: Gender.female,
        weightKg: 52,
        heightCm: 155,
        ageYears: 32,
        activityLevel: ActivityLevel.sedentary,
        goalType: GoalType.lose,
        targetWeightKg: 47,
        requestedWeeklyRateKg: 0.5,
      );
      expect(femaleClamped.targetCalories, 1200);
      expect(femaleClamped.wasClampedToMinCalories, isTrue);

      // Pria sedentari dengan defisit besar harus di-clamp minimal 1500 kkal
      final maleClamped = HealthCalculator.calculateCompletePlan(
        gender: Gender.male,
        weightKg: 60,
        heightCm: 165,
        ageYears: 40,
        activityLevel: ActivityLevel.sedentary,
        goalType: GoalType.lose,
        targetWeightKg: 56,
        requestedWeeklyRateKg: 0.6,
      );
      expect(maleClamped.targetCalories, 1500);
      expect(maleClamped.wasClampedToMinCalories, isTrue);
    });

    test('membatasi kecepatan maksimal 1% berat badan per minggu', () {
      // Berat 50 kg -> maks aman 0.50 kg/minggu; minta 0.75 kg/minggu
      final clampedRatePlan = HealthCalculator.calculateCompletePlan(
        gender: Gender.male,
        weightKg: 50,
        heightCm: 165,
        ageYears: 22,
        activityLevel: ActivityLevel.heavy,
        goalType: GoalType.gain,
        targetWeightKg: 58,
        requestedWeeklyRateKg: 0.75,
      );

      expect(clampedRatePlan.wasClampedByOnePercentRule, isTrue);
      expect(clampedRatePlan.effectiveWeeklyRateKg, closeTo(0.50, 0.001));
    });

    test('menghitung makro default (protein 1.6g/kg, lemak 25% kalori, sisa karbo)',
        () {
      final macros = HealthCalculator.calculateMacros(
        targetCalories: 2000,
        weightKg: 70,
      );
      // Protein = 70 * 1.6 = 112g (448 kkal)
      // Lemak = 2000 * 0.25 / 9 = 55.55 -> 56g (504 kkal)
      // Sisa karbo = (2000 - 448 - 504) / 4 = 1048 / 4 = 262g
      expect(macros.proteinGrams, 112);
      expect(macros.fatGrams, 56);
      expect(macros.carbsGrams, 262);
    });
  });

  group('HealthCalculator - Validasi Profil, Tujuan & Moving Average', () {
    test('menolak pengguna berusia di bawah 18 tahun dan tanggal lahir masa depan',
        () {
      final refDate = DateTime(2026, 11, 18);
      final under18 = DateTime(2010, 5, 10);
      final futureDate = DateTime(2027, 1, 1);
      final adult18 = DateTime(2008, 11, 18);

      expect(
        HealthCalculator.validateBirthDate(under18, now: refDate),
        contains('18 tahun'),
      );
      expect(
        HealthCalculator.validateBirthDate(futureDate, now: refDate),
        contains('masa depan'),
      );
      expect(
        HealthCalculator.validateBirthDate(adult18, now: refDate),
        isNull,
      );
    });

    test('menolak berat target yang menyebabkan BMI < 18,5 untuk tujuan turun',
        () {
      // Tinggi 170 cm -> BMI 18,5 setara ~53,5 kg; target 50 kg harus ditolak
      final invalidGoal = HealthCalculator.validateGoal(
        goalType: GoalType.lose,
        currentWeightKg: 62,
        targetWeightKg: 50,
        heightCm: 170,
        weeklyRateKg: 0.5,
      );
      expect(invalidGoal.isValid, isFalse);
      expect(invalidGoal.errorMessage, contains('18,5'));

      final validGoal = HealthCalculator.validateGoal(
        goalType: GoalType.lose,
        currentWeightKg: 62,
        targetWeightKg: 56,
        heightCm: 170,
        weeklyRateKg: 0.5,
      );
      expect(validGoal.isValid, isTrue);
    });

    test('mendeteksi pemicu hitung ulang kalori saat berat berubah >= 2 kg', () {
      expect(
        HealthCalculator.shouldRecalculateForWeightChange(
          baselineWeightKg: 70.0,
          currentWeightKg: 68.5,
        ),
        isFalse,
      );
      expect(
        HealthCalculator.shouldRecalculateForWeightChange(
          baselineWeightKg: 70.0,
          currentWeightKg: 68.0,
        ),
        isTrue,
      );
    });

    test('menghitung moving average 7 hari kalender dengan benar', () {
      final entries = [
        (date: DateTime(2026, 11, 1), weightKg: 70.0),
        (date: DateTime(2026, 11, 2), weightKg: 71.0),
        (date: DateTime(2026, 11, 8), weightKg: 68.0),
      ];
      final ma = HealthCalculator.calculateMovingAverage(entries, windowDays: 7);

      expect(ma, hasLength(3));
      expect(ma[0].averageKg, closeTo(70.0, 0.001));
      expect(ma[1].averageKg, closeTo(70.5, 0.001));
      // Pada 8 Nov, jendela 7 hari adalah 2 Nov..8 Nov (71.0 dan 68.0 -> rata-rata 69.5)
      expect(ma[2].averageKg, closeTo(69.5, 0.001));
    });
  });
}
