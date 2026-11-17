import 'package:flutter_test/flutter_test.dart';
import 'package:scale_up/data/database/app_database.dart';
import 'package:scale_up/features/calories/data/calories_repository.dart';
import 'package:scale_up/features/calories/domain/calorie_models.dart';

import '../helpers/test_app_helper.dart';

void main() {
  late AppDatabase db;
  late CaloriesRepository repo;

  setUpAll(() async {
    await initTestEnvironment();
  });

  setUp(() {
    db = createTestDatabase();
    repo = CaloriesRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('CaloriesRepository & CalorieAnalytics (Fase 4)', () {
    test('mencatat makanan per waktu makan, custom food, favorit & hitung ringkasan',
        () async {
      final customId = await repo.addCustomFood(
        name: 'Smoothie Mangga Oat',
        servingDesc: '1 gelas',
        calories: 250,
        protein: 10,
        carbs: 40,
        fat: 5,
      );

      await repo.toggleFavorite(customId, true);
      final today = DateTime(2026, 11, 18);

      await repo.addFoodLog(
        date: today,
        mealType: MealType.breakfast,
        foodItemId: customId,
        quantity: 1.5,
      );

      final logs = await repo.watchLogsForDate(today).first;
      expect(logs, hasLength(1));
      expect(logs.single.item.isFavorite, isTrue);

      final summary = CalorieAnalytics.computeDailySummary(
        date: today,
        logs: logs,
        targetCalories: 2000,
        targetProteinGrams: 110,
        targetCarbsGrams: 250,
        targetFatGrams: 55,
      );

      expect(summary.consumedCalories, closeTo(375.0, 0.01));
      expect(summary.remainingCalories, 1625);
      expect(summary.consumedProteinGrams, closeTo(15.0, 0.01));
      expect(summary.byMeal[MealType.breakfast], hasLength(1));
    });

    test('copyFromYesterday menyalin seluruh menu kemarin ke hari ini dengan satu tap',
        () async {
      final foods = await repo.watchAllFoods().first;
      final nasiPutih = foods.firstWhere((f) => f.name == 'Nasi Putih');
      final ayamBakar = foods.firstWhere((f) => f.name == 'Ayam Bakar Kecap');

      final yesterday = DateTime(2026, 11, 17);
      final today = DateTime(2026, 11, 18);

      await repo.addFoodLog(
        date: yesterday,
        mealType: MealType.lunch,
        foodItemId: nasiPutih.id,
        quantity: 1.0,
      );
      await repo.addFoodLog(
        date: yesterday,
        mealType: MealType.lunch,
        foodItemId: ayamBakar.id,
        quantity: 1.0,
      );

      final copiedCount = await repo.copyFromYesterday(today);
      expect(copiedCount, 2);

      final todayLogs = await repo.watchLogsForDate(today).first;
      expect(todayLogs, hasLength(2));
      expect(
        todayLogs.fold<double>(0, (sum, e) => sum + e.totalCalories),
        closeTo(nasiPutih.calories + ayamBakar.calories, 0.01),
      );
    });
  });
}
