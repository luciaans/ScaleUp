import 'package:flutter_test/flutter_test.dart';
import 'package:scale_up/data/database/app_database.dart';
import 'package:scale_up/features/onboarding/domain/user_enums.dart';
import 'package:scale_up/features/weight/domain/weight_analytics.dart';

void main() {
  group('WeightAnalytics - Statistik, Filter Grafik & Motivasi', () {
    final sampleEntries = [
      WeightEntry(id: 1, date: DateTime(2026, 10, 1), weightKg: 76.0, note: null),
      WeightEntry(id: 2, date: DateTime(2026, 11, 10), weightKg: 74.0, note: null),
      WeightEntry(id: 3, date: DateTime(2026, 11, 15), weightKg: 73.2, note: null),
      WeightEntry(id: 4, date: DateTime(2026, 11, 18), weightKg: 72.8, note: 'Pagi'),
    ];

    test('memfilter titik grafik 7H, 30H, dan Semua sambil menjaga moving average',
        () {
      final points7d = WeightAnalytics.buildChartPoints(
        ascendingEntries: sampleEntries,
        filter: WeightRangeFilter.days7,
        referenceDate: DateTime(2026, 11, 18),
      );
      // 7H mencakup 12 Nov .. 18 Nov -> entri 15 Nov dan 18 Nov
      expect(points7d, hasLength(2));
      expect(points7d.first.date, DateTime(2026, 11, 15));
      // Moving average pada 15 Nov tetap menyertakan 10 Nov (dalam jendela 7 hari 9..15 Nov):
      // (74.0 + 73.2) / 2 = 73.6
      expect(points7d.first.movingAverage7dKg, closeTo(73.6, 0.01));

      final points30d = WeightAnalytics.buildChartPoints(
        ascendingEntries: sampleEntries,
        filter: WeightRangeFilter.days30,
        referenceDate: DateTime(2026, 11, 18),
      );
      expect(points30d, hasLength(3));

      final pointsAll = WeightAnalytics.buildChartPoints(
        ascendingEntries: sampleEntries,
        filter: WeightRangeFilter.all,
      );
      expect(pointsAll, hasLength(4));
    });

    test('menghitung statistik perubahan total, sisa ke target, BMI & motivasi',
        () {
      final summary = WeightAnalytics.computeSummary(
        ascendingEntries: sampleEntries,
        goalType: GoalType.lose,
        goalStartWeightKg: 76.0,
        goalTargetWeightKg: 68.0,
        heightCm: 170.0,
      );

      expect(summary.startWeightKg, 76.0);
      expect(summary.currentWeightKg, 72.8);
      expect(summary.totalChangeKg, closeTo(-3.2, 0.01));
      expect(summary.remainingToTargetKg, closeTo(4.8, 0.01));
      expect(summary.bmi, closeTo(25.19, 0.02));
      expect(summary.bmiCategory, BmiCategory.overweight);
      expect(summary.motivationTitle, contains('Positif'));
    });
  });
}
