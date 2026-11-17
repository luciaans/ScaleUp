import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../seed/indonesian_foods_seed.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// Database SQLite lokal utama ScaleUp berbasis Drift dengan migrasi & auto-seed.
@DriftDatabase(
  tables: [
    UserProfiles,
    Goals,
    WeightEntries,
    FoodItems,
    FoodLogs,
    Settings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            // Skema v2 memastikan indeks pencarian makanan & tanggal tujuan tersedia
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_food_items_name ON food_items (name)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_goals_start_date ON goals (start_date)',
            );
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          await ensureSeedFoods();
        },
      );

  /// Menyemai (seed) 90+ makanan Indonesia bawaan jika belum ada di database.
  Future<void> ensureSeedFoods() async {
    final countExp = foodItems.id.count();
    final query = selectOnly(foodItems)
      ..addColumns([countExp])
      ..where(foodItems.isCustom.equals(false));
    final row = await query.getSingle();
    final existingCount = row.read(countExp) ?? 0;

    if (existingCount > 0) return;

    await batch((b) {
      b.insertAll(
        foodItems,
        kIndonesianFoodsSeed
            .map(
              (item) => FoodItemsCompanion.insert(
                name: item.name,
                servingDesc: item.servingDesc,
                calories: item.calories,
                protein: item.protein,
                carbs: item.carbs,
                fat: item.fat,
                isCustom: const Value(false),
                isFavorite: const Value(false),
              ),
            )
            .toList(),
      );
    });
  }

  /// Menghapus seluruh data pengguna dan menyemai ulang daftar makanan bawaan.
  Future<void> clearAllUserData() async {
    await transaction(() async {
      await delete(foodLogs).go();
      await delete(weightEntries).go();
      await delete(goals).go();
      await delete(userProfiles).go();
      await delete(settings).go();
      await (delete(foodItems)..where((t) => t.isCustom.equals(true))).go();
      await (update(foodItems)..where((t) => t.isFavorite.equals(true)))
          .write(const FoodItemsCompanion(isFavorite: Value(false)));
    });
    await ensureSeedFoods();
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'scale_up_db',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }
}

/// Provider global database Drift yang dapat di-override pada unit/widget test.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}
