import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils_ext.dart';
import '../../../data/database/app_database.dart';
import '../../onboarding/domain/health_calculator.dart';
import '../../settings/data/settings_repository.dart';

part 'weight_repository.g.dart';

/// Repository pencatatan berat badan harian (1 entri per hari kalender)
/// sekaligus pemicu otomatis hitung ulang baseline kalori saat berat berubah >= 2 kg.
class WeightRepository {
  const WeightRepository(this._db, this._settings);

  final AppDatabase _db;
  final SettingsRepository _settings;

  /// Mengamati seluruh catatan berat terurut dari terbaru ke terlama.
  Stream<List<WeightEntry>> watchEntriesDescending() {
    final query = _db.select(_db.weightEntries)
      ..orderBy([
        (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
      ]);
    return query.watch();
  }

  /// Mengamati seluruh catatan berat terurut kronologis (terlama ke terbaru).
  Stream<List<WeightEntry>> watchEntriesAscending() {
    final query = _db.select(_db.weightEntries)
      ..orderBy([
        (t) => OrderingTerm(expression: t.date, mode: OrderingMode.asc),
      ]);
    return query.watch();
  }

  /// Mengamati entri berat terbaru (berdasarkan tanggal paling akhir).
  Stream<WeightEntry?> watchLatestEntry() {
    final query = _db.select(_db.weightEntries)
      ..orderBy([
        (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
      ])
      ..limit(1);
    return query.watchSingleOrNull();
  }

  /// Mengambil entri berat terbaru satu kali.
  Future<WeightEntry?> getLatestEntry() async {
    final query = _db.select(_db.weightEntries)
      ..orderBy([
        (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
      ])
      ..limit(1);
    return query.getSingleOrNull();
  }

  /// Mengamati entri berat pada tanggal tertentu (mis. hari ini).
  Stream<WeightEntry?> watchEntryForDate(DateTime date) {
    final normalized = AppDateUtils.dateOnly(date);
    final query = _db.select(_db.weightEntries)
      ..where((t) => t.date.equalsValue(normalized));
    return query.watchSingleOrNull();
  }

  /// Menyimpan atau memperbarui berat pada tanggal tertentu (1 entri per hari).
  /// Mengembalikan `true` apabila perubahan berat >= 2 kg memicu penyesuaian target kalori.
  Future<bool> upsertWeight({
    required DateTime date,
    required double weightKg,
    String? note,
  }) async {
    final normalizedDate = AppDateUtils.dateOnly(date);
    final cleanedNote =
        (note != null && note.trim().isNotEmpty) ? note.trim() : null;

    await _db.into(_db.weightEntries).insert(
          WeightEntriesCompanion.insert(
            date: normalizedDate,
            weightKg: weightKg,
            note: Value(cleanedNote),
          ),
          onConflict: DoUpdate(
            (_) => WeightEntriesCompanion(
              weightKg: Value(weightKg),
              note: Value(cleanedNote),
            ),
            target: [_db.weightEntries.date],
          ),
        );

    // Evaluasi apakah entri terbaru mengubah berat >= 2 kg dari baseline kalori
    final latest = await getLatestEntry();
    if (latest != null) {
      final rawBaseline = await _settings.getValue(
        AppConstants.settingCalorieBaselineWeight,
      );
      final baselineKg =
          rawBaseline != null ? double.tryParse(rawBaseline) : null;
      if (HealthCalculator.shouldRecalculateForWeightChange(
        baselineWeightKg: baselineKg,
        currentWeightKg: latest.weightKg,
      )) {
        await _settings.setValue(
          AppConstants.settingCalorieBaselineWeight,
          latest.weightKg.toStringAsFixed(2),
        );
        return baselineKg != null;
      }
    }
    return false;
  }

  /// Menghapus catatan berat berdasarkan ID (mendukung fitur undo dengan insert kembali).
  Future<void> deleteById(int id) async {
    await (_db.delete(_db.weightEntries)..where((t) => t.id.equals(id))).go();
  }

  /// Memulihkan entri yang baru saja dihapus (Undo swipe-to-delete).
  Future<void> restoreEntry(WeightEntry entry) async {
    await upsertWeight(
      date: entry.date,
      weightKg: entry.weightKg,
      note: entry.note,
    );
  }
}

@Riverpod(keepAlive: true)
WeightRepository weightRepository(Ref ref) {
  return WeightRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(settingsRepositoryProvider),
  );
}

final weightEntriesDescProvider = StreamProvider<List<WeightEntry>>((ref) {
  return ref.watch(weightRepositoryProvider).watchEntriesDescending();
});

final weightEntriesAscProvider = StreamProvider<List<WeightEntry>>((ref) {
  return ref.watch(weightRepositoryProvider).watchEntriesAscending();
});

final latestWeightEntryProvider = StreamProvider<WeightEntry?>((ref) {
  return ref.watch(weightRepositoryProvider).watchLatestEntry();
});
