import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils_ext.dart';
import '../../../data/database/app_database.dart';
import '../../onboarding/domain/user_enums.dart';
import '../../settings/data/settings_repository.dart';

part 'goal_repository.g.dart';

/// Repository tujuan berat badan.
/// Menyimpan riwayat seluruh tujuan lama (`isActive = false`) dan memastikan hanya satu tujuan aktif.
class GoalRepository {
  const GoalRepository(this._db, this._settings);

  final AppDatabase _db;
  final SettingsRepository _settings;

  /// Mengamati satu tujuan yang sedang aktif.
  Stream<Goal?> watchActiveGoal() {
    final query = _db.select(_db.goals)
      ..where((t) => t.isActive.equals(true))
      ..orderBy([(t) => OrderingTerm.desc(t.id)])
      ..limit(1);
    return query.watchSingleOrNull();
  }

  Future<Goal?> getActiveGoal() async {
    final query = _db.select(_db.goals)
      ..where((t) => t.isActive.equals(true))
      ..orderBy([(t) => OrderingTerm.desc(t.id)])
      ..limit(1);
    return query.getSingleOrNull();
  }

  /// Mengamati seluruh riwayat tujuan (termasuk yang sudah diganti).
  Stream<List<Goal>> watchGoalHistory() {
    final query = _db.select(_db.goals)
      ..orderBy([(t) => OrderingTerm.desc(t.id)]);
    return query.watch();
  }

  /// Mengaktifkan tujuan baru dan menonaktifkan tujuan sebelumnya tanpa menghapus riwayat.
  Future<void> setNewGoal({
    required GoalType type,
    required double startWeight,
    required double targetWeight,
    required double weeklyRate,
    DateTime? startDate,
  }) async {
    final effectiveTarget =
        type == GoalType.maintain ? startWeight : targetWeight;
    final effectiveRate = type == GoalType.maintain ? 0.0 : weeklyRate;
    final effectiveDate = AppDateUtils.dateOnly(startDate ?? DateTime.now());

    await _db.transaction(() async {
      await (_db.update(_db.goals)..where((t) => t.isActive.equals(true)))
          .write(const GoalsCompanion(isActive: Value(false)));

      await _db.into(_db.goals).insert(
            GoalsCompanion.insert(
              type: type.storageKey,
              startWeight: startWeight,
              targetWeight: effectiveTarget,
              weeklyRate: effectiveRate,
              startDate: effectiveDate,
              isActive: const Value(true),
            ),
          );
    });

    // Hitung ulang baseline kalori setiap kali tujuan diganti
    await _settings.setValue(
      AppConstants.settingCalorieBaselineWeight,
      startWeight.toStringAsFixed(2),
    );
  }
}

@Riverpod(keepAlive: true)
GoalRepository goalRepository(Ref ref) {
  return GoalRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(settingsRepositoryProvider),
  );
}

final activeGoalProvider = StreamProvider<Goal?>((ref) {
  return ref.watch(goalRepositoryProvider).watchActiveGoal();
});

final goalHistoryProvider = StreamProvider<List<Goal>>((ref) {
  return ref.watch(goalRepositoryProvider).watchGoalHistory();
});
