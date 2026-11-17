import 'package:flutter_test/flutter_test.dart';
import 'package:scale_up/data/database/app_database.dart';
import 'package:scale_up/features/calories/domain/calorie_models.dart';
import 'package:scale_up/features/home/domain/streak_and_tips.dart';
import 'package:scale_up/features/onboarding/domain/user_enums.dart';
import 'package:scale_up/features/settings/data/csv_export_service.dart';

void main() {
  group('StreakAndTips & CsvExportService (Fase 5)', () {
    test('menghitung streak berurutan dengan akurat saat hari ini tercatat maupun belum',
        () {
      final refToday = DateTime(2026, 11, 18);
      final datesLogged = <String>{
        '2026-11-15',
        '2026-11-16',
        '2026-11-17',
      };

      // Hari ini belum dicatat tapi kemarin tercatat -> streak 3 hari tetap terjaga
      final beforeTodayLog = StreakAndTips.calculateStreak(
        activeIsoDates: datesLogged,
        referenceToday: refToday,
      );
      expect(beforeTodayLog.currentStreakDays, 3);
      expect(beforeTodayLog.loggedToday, isFalse);

      // Setelah hari ini dicatat -> streak bertambah menjadi 4 hari
      final afterTodayLog = StreakAndTips.calculateStreak(
        activeIsoDates: {...datesLogged, '2026-11-18'},
        referenceToday: refToday,
      );
      expect(afterTodayLog.currentStreakDays, 4);
      expect(afterTodayLog.loggedToday, isTrue);
    });

    test('mendeteksi milestone perayaan hanya sekali per pencapaian', () {
      final firstCheck = StreakAndTips.detectUncelebratedMilestone(
        streakDays: 7,
        isGoalReached: false,
        goalType: GoalType.lose,
        activeGoalId: 1,
        totalWeightEntries: 7,
        celebratedKeys: const {},
      );
      expect(firstCheck?.key, 'streak_7');

      final secondCheck = StreakAndTips.detectUncelebratedMilestone(
        streakDays: 8,
        isGoalReached: false,
        goalType: GoalType.lose,
        activeGoalId: 1,
        totalWeightEntries: 8,
        celebratedKeys: const {'streak_7'},
      );
      expect(secondCheck, isNull);
    });

    test('membangun string CSV berisi header, riwayat berat, dan log makanan', () {
      final csvText = CsvExportService.buildCsvContent(
        weights: [
          WeightEntry(
            id: 1,
            date: DateTime(2026, 11, 18),
            weightKg: 68.4,
            note: 'Pagi',
          ),
        ],
        foodLogs: [
          FoodLogWithItem(
            log: FoodLog(
              id: 1,
              date: DateTime(2026, 11, 18),
              mealType: 'breakfast',
              foodItemId: 10,
              quantity: 1.0,
            ),
            item: const FoodItem(
              id: 10,
              name: 'Nasi Uduk',
              servingDesc: '1 porsi',
              calories: 260,
              protein: 4.5,
              carbs: 41.0,
              fat: 8.5,
              isCustom: false,
              isFavorite: false,
            ),
          ),
        ],
      );

      expect(csvText, contains('Kategori'));
      expect(csvText, contains('Berat Badan'));
      expect(csvText, contains('68.4'));
      expect(csvText, contains('Nasi Uduk'));
      expect(csvText, contains('Sarapan'));
    });
  });
}
