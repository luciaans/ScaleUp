import '../../../core/utils/date_utils_ext.dart';
import '../../../data/database/app_database.dart';

/// Kategori waktu makan harian.
enum MealType {
  breakfast('breakfast', 'Sarapan'),
  lunch('lunch', 'Makan Siang'),
  dinner('dinner', 'Makan Malam'),
  snack('snack', 'Camilan');

  const MealType(this.storageKey, this.label);
  final String storageKey;
  final String label;

  static MealType fromStorage(String raw) {
    return MealType.values.firstWhere(
      (e) => e.storageKey == raw,
      orElse: () => MealType.snack,
    );
  }

  /// Menentukan waktu makan default yang paling relevan berdasarkan jam lokal.
  static MealType suggestedForHour(int hour) {
    if (hour >= 5 && hour < 11) return MealType.breakfast;
    if (hour >= 11 && hour < 16) return MealType.lunch;
    if (hour >= 16 && hour < 21) return MealType.dinner;
    return MealType.snack;
  }
}

/// Gabungan catatan log makanan beserta detail item makanannya.
class FoodLogWithItem {
  const FoodLogWithItem({
    required this.log,
    required this.item,
  });

  final FoodLog log;
  final FoodItem item;

  double get totalCalories => item.calories * log.quantity;
  double get totalProtein => item.protein * log.quantity;
  double get totalCarbs => item.carbs * log.quantity;
  double get totalFat => item.fat * log.quantity;
}

/// Titik kalori harian untuk grafik riwayat 7 hari.
class DailyCaloriePoint {
  const DailyCaloriePoint({
    required this.date,
    required this.totalCalories,
  });

  final DateTime date;
  final double totalCalories;
}

/// Ringkasan asupan kalori & makro satu hari penuh.
class DailyCalorieSummary {
  const DailyCalorieSummary({
    required this.date,
    required this.targetCalories,
    required this.targetProteinGrams,
    required this.targetCarbsGrams,
    required this.targetFatGrams,
    required this.consumedCalories,
    required this.consumedProteinGrams,
    required this.consumedCarbsGrams,
    required this.consumedFatGrams,
    required this.byMeal,
  });

  final DateTime date;
  final int targetCalories;
  final int targetProteinGrams;
  final int targetCarbsGrams;
  final int targetFatGrams;

  final double consumedCalories;
  final double consumedProteinGrams;
  final double consumedCarbsGrams;
  final double consumedFatGrams;
  final Map<MealType, List<FoodLogWithItem>> byMeal;

  int get remainingCalories => targetCalories - consumedCalories.round();
  bool get isOverTarget => remainingCalories < 0;

  double get calorieProgress => targetCalories <= 0
      ? 0.0
      : (consumedCalories / targetCalories).clamp(0.0, 1.0);

  double mealCalories(MealType type) {
    final list = byMeal[type] ?? const [];
    return list.fold(0.0, (sum, entry) => sum + entry.totalCalories);
  }
}

/// Fungsi murni analitik kalori & makro harian.
abstract final class CalorieAnalytics {
  static DailyCalorieSummary computeDailySummary({
    required DateTime date,
    required List<FoodLogWithItem> logs,
    required int targetCalories,
    required int targetProteinGrams,
    required int targetCarbsGrams,
    required int targetFatGrams,
  }) {
    final grouped = <MealType, List<FoodLogWithItem>>{
      for (final meal in MealType.values) meal: <FoodLogWithItem>[],
    };

    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;

    for (final entry in logs) {
      final meal = MealType.fromStorage(entry.log.mealType);
      grouped[meal]!.add(entry);
      calories += entry.totalCalories;
      protein += entry.totalProtein;
      carbs += entry.totalCarbs;
      fat += entry.totalFat;
    }

    return DailyCalorieSummary(
      date: AppDateUtils.dateOnly(date),
      targetCalories: targetCalories,
      targetProteinGrams: targetProteinGrams,
      targetCarbsGrams: targetCarbsGrams,
      targetFatGrams: targetFatGrams,
      consumedCalories: calories,
      consumedProteinGrams: protein,
      consumedCarbsGrams: carbs,
      consumedFatGrams: fat,
      byMeal: grouped,
    );
  }

  /// Menyusun tepat 7 titik hari berurutan yang berakhir pada [endDate].
  static List<DailyCaloriePoint> build7DaySeries({
    required DateTime endDate,
    required List<FoodLogWithItem> logsInWindow,
  }) {
    final normalizedEnd = AppDateUtils.dateOnly(endDate);
    final totalsByKey = <String, double>{};

    for (final entry in logsInWindow) {
      final key = AppDateUtils.toIsoDateKey(entry.log.date);
      totalsByKey[key] = (totalsByKey[key] ?? 0.0) + entry.totalCalories;
    }

    return List<DailyCaloriePoint>.generate(7, (index) {
      final dayOffset = 6 - index;
      final date = DateTime(
        normalizedEnd.year,
        normalizedEnd.month,
        normalizedEnd.day - dayOffset,
      );
      final key = AppDateUtils.toIsoDateKey(date);
      return DailyCaloriePoint(
        date: date,
        totalCalories: totalsByKey[key] ?? 0.0,
      );
    });
  }
}
