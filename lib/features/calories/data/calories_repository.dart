import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/date_utils_ext.dart';
import '../../../data/database/app_database.dart';
import '../../profile/domain/active_nutrition_plan.dart';
import '../domain/calorie_models.dart';

part 'calories_repository.g.dart';

/// Repository pencatatan makanan, pencarian makanan, favorit, makanan custom,
/// riwayat 7 hari, dan salin dari kemarin.
class CaloriesRepository {
  const CaloriesRepository(this._db);

  final AppDatabase _db;

  /// Mengamati semua item makanan diurutkan berdasarkan nama.
  Stream<List<FoodItem>> watchAllFoods() {
    final query = _db.select(_db.foodItems)
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.watch();
  }

  /// Mengamati daftar makanan yang terakhir kali dicatat oleh pengguna.
  Stream<List<FoodItem>> watchRecentFoods({int limit = 15}) {
    final joined = _db.select(_db.foodLogs).join([
      innerJoin(
        _db.foodItems,
        _db.foodItems.id.equalsExp(_db.foodLogs.foodItemId),
      ),
    ])
      ..orderBy([OrderingTerm.desc(_db.foodLogs.id)])
      ..limit(60);

    return joined.watch().map((rows) {
      final seenIds = <int>{};
      final items = <FoodItem>[];
      for (final row in rows) {
        final item = row.readTable(_db.foodItems);
        if (seenIds.add(item.id)) {
          items.add(item);
          if (items.length >= limit) break;
        }
      }
      return items;
    });
  }

  /// Mengamati seluruh log makanan beserta item-nya pada tanggal kalender tertentu.
  Stream<List<FoodLogWithItem>> watchLogsForDate(DateTime date) {
    final targetDate = AppDateUtils.dateOnly(date);
    final joined = _db.select(_db.foodLogs).join([
      innerJoin(
        _db.foodItems,
        _db.foodItems.id.equalsExp(_db.foodLogs.foodItemId),
      ),
    ])
      ..where(_db.foodLogs.date.equalsValue(targetDate))
      ..orderBy([OrderingTerm.asc(_db.foodLogs.id)]);

    return joined.watch().map(
          (rows) => rows
              .map(
                (r) => FoodLogWithItem(
                  log: r.readTable(_db.foodLogs),
                  item: r.readTable(_db.foodItems),
                ),
              )
              .toList(),
        );
  }

  /// Mengamati seri kalori harian selama 7 hari terakhir hingga [endDate].
  Stream<List<DailyCaloriePoint>> watch7DayCalories(DateTime endDate) {
    final end = AppDateUtils.dateOnly(endDate);
    final start = DateTime(end.year, end.month, end.day - 6);
    final startKey = AppDateUtils.toIsoDateKey(start);
    final endKey = AppDateUtils.toIsoDateKey(end);

    final joined = _db.select(_db.foodLogs).join([
      innerJoin(
        _db.foodItems,
        _db.foodItems.id.equalsExp(_db.foodLogs.foodItemId),
      ),
    ])
      ..where(
        _db.foodLogs.date.isBiggerOrEqualValue(startKey) &
            _db.foodLogs.date.isSmallerOrEqualValue(endKey),
      );

    return joined.watch().map((rows) {
      final entries = rows
          .map(
            (r) => FoodLogWithItem(
              log: r.readTable(_db.foodLogs),
              item: r.readTable(_db.foodItems),
            ),
          )
          .toList();
      return CalorieAnalytics.build7DaySeries(
        endDate: end,
        logsInWindow: entries,
      );
    });
  }

  /// Mengubah status favorit pada sebuah [FoodItem].
  Future<void> toggleFavorite(int foodItemId, bool isFavorite) async {
    await (_db.update(_db.foodItems)..where((t) => t.id.equals(foodItemId)))
        .write(FoodItemsCompanion(isFavorite: Value(isFavorite)));
  }

  /// Menambahkan makanan custom buatan pengguna dan mengembalikan ID baris barunya.
  Future<int> addCustomFood({
    required String name,
    required String servingDesc,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
  }) {
    return _db.into(_db.foodItems).insert(
          FoodItemsCompanion.insert(
            name: name.trim(),
            servingDesc: servingDesc.trim(),
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            isCustom: const Value(true),
            isFavorite: const Value(false),
          ),
        );
  }

  /// Mencatat porsi makanan pada tanggal & waktu makan tertentu.
  Future<int> addFoodLog({
    required DateTime date,
    required MealType mealType,
    required int foodItemId,
    required double quantity,
  }) {
    return _db.into(_db.foodLogs).insert(
          FoodLogsCompanion.insert(
            date: AppDateUtils.dateOnly(date),
            mealType: mealType.storageKey,
            foodItemId: foodItemId,
            quantity: Value(quantity),
          ),
        );
  }

  /// Memperbarui jumlah porsi pada catatan log yang sudah ada.
  Future<void> updateLogQuantity({
    required int logId,
    required double quantity,
  }) async {
    if (quantity <= 0) {
      await deleteFoodLog(logId);
      return;
    }
    await (_db.update(_db.foodLogs)..where((t) => t.id.equals(logId)))
        .write(FoodLogsCompanion(quantity: Value(quantity)));
  }

  /// Menghapus satu item log makanan.
  Future<void> deleteFoodLog(int logId) async {
    await (_db.delete(_db.foodLogs)..where((t) => t.id.equals(logId))).go();
  }

  /// Memulihkan item log yang baru saja dihapus (Undo).
  Future<void> restoreFoodLog(FoodLog deleted) async {
    await _db.into(_db.foodLogs).insert(
          FoodLogsCompanion.insert(
            date: deleted.date,
            mealType: deleted.mealType,
            foodItemId: deleted.foodItemId,
            quantity: Value(deleted.quantity),
          ),
        );
  }

  /// Menyalin seluruh makanan dari kemarin (`targetDate - 1 hari`) ke `targetDate`.
  /// Mengembalikan jumlah item yang berhasil disalin.
  Future<int> copyFromYesterday(DateTime targetDate) async {
    final destDate = AppDateUtils.dateOnly(targetDate);
    final prevDate = AppDateUtils.yesterday(destDate);

    final yesterdayLogs = await (_db.select(_db.foodLogs)
          ..where((t) => t.date.equalsValue(prevDate))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();

    if (yesterdayLogs.isEmpty) return 0;

    await _db.batch((b) {
      b.insertAll(
        _db.foodLogs,
        yesterdayLogs
            .map(
              (log) => FoodLogsCompanion.insert(
                date: destDate,
                mealType: log.mealType,
                foodItemId: log.foodItemId,
                quantity: Value(log.quantity),
              ),
            )
            .toList(),
      );
    });

    return yesterdayLogs.length;
  }
}

@Riverpod(keepAlive: true)
CaloriesRepository caloriesRepository(Ref ref) {
  return CaloriesRepository(ref.watch(appDatabaseProvider));
}

/// State tanggal aktif pada layar Kalori (default: hari ini).
@riverpod
class SelectedCalorieDate extends _$SelectedCalorieDate {
  @override
  DateTime build() => AppDateUtils.today();

  void selectDate(DateTime date) {
    final today = AppDateUtils.today();
    final normalized = AppDateUtils.dateOnly(date);
    state = normalized.isAfter(today) ? today : normalized;
  }

  void shiftDays(int delta) {
    selectDate(DateTime(state.year, state.month, state.day + delta));
  }
}

final allFoodItemsProvider = StreamProvider<List<FoodItem>>((ref) {
  return ref.watch(caloriesRepositoryProvider).watchAllFoods();
});

final recentFoodItemsProvider = StreamProvider<List<FoodItem>>((ref) {
  return ref.watch(caloriesRepositoryProvider).watchRecentFoods();
});

final selectedDateFoodLogsProvider =
    StreamProvider<List<FoodLogWithItem>>((ref) {
  final date = ref.watch(selectedCalorieDateProvider);
  return ref.watch(caloriesRepositoryProvider).watchLogsForDate(date);
});

final todayFoodLogsProvider = StreamProvider<List<FoodLogWithItem>>((ref) {
  return ref
      .watch(caloriesRepositoryProvider)
      .watchLogsForDate(AppDateUtils.today());
});

final weeklyCalorieSeriesProvider =
    StreamProvider<List<DailyCaloriePoint>>((ref) {
  final date = ref.watch(selectedCalorieDateProvider);
  return ref.watch(caloriesRepositoryProvider).watch7DayCalories(date);
});

@riverpod
AsyncValue<DailyCalorieSummary> selectedDailyCalorieSummary(Ref ref) {
  final date = ref.watch(selectedCalorieDateProvider);
  final logsAsync = ref.watch(selectedDateFoodLogsProvider);
  final planAsync = ref.watch(activeNutritionPlanProvider);

  if (logsAsync.isLoading || planAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (logsAsync.hasError) {
    return AsyncValue.error(logsAsync.error!, logsAsync.stackTrace!);
  }

  final plan = planAsync.value?.caloriePlan;
  return AsyncValue.data(
    CalorieAnalytics.computeDailySummary(
      date: date,
      logs: logsAsync.value ?? const [],
      targetCalories: plan?.targetCalories ?? 2000,
      targetProteinGrams: plan?.proteinGrams ?? 100,
      targetCarbsGrams: plan?.carbsGrams ?? 250,
      targetFatGrams: plan?.fatGrams ?? 55,
    ),
  );
}

@riverpod
AsyncValue<DailyCalorieSummary> todayCalorieSummary(Ref ref) {
  final today = AppDateUtils.today();
  final logsAsync = ref.watch(todayFoodLogsProvider);
  final planAsync = ref.watch(activeNutritionPlanProvider);

  if (logsAsync.isLoading || planAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (logsAsync.hasError) {
    return AsyncValue.error(logsAsync.error!, logsAsync.stackTrace!);
  }

  final plan = planAsync.value?.caloriePlan;
  return AsyncValue.data(
    CalorieAnalytics.computeDailySummary(
      date: today,
      logs: logsAsync.value ?? const [],
      targetCalories: plan?.targetCalories ?? 2000,
      targetProteinGrams: plan?.proteinGrams ?? 100,
      targetCarbsGrams: plan?.carbsGrams ?? 250,
      targetFatGrams: plan?.fatGrams ?? 55,
    ),
  );
}
