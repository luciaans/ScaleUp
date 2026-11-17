import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_utils_ext.dart';
import '../../../data/database/app_database.dart';
import '../domain/streak_and_tips.dart';

/// Mengamati himpunan seluruh tanggal unik (`YYYY-MM-DD`) saat pengguna
/// mencatat berat badan ATAU makanan untuk perhitungan streak harian.
final activeLoggedDatesProvider = StreamProvider<Set<String>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final weightStream = db.select(db.weightEntries).watch();

  return weightStream.asyncExpand((weights) {
    final foodStream = db.select(db.foodLogs).watch();
    return foodStream.map((foods) {
      final keys = <String>{};
      for (final w in weights) {
        keys.add(AppDateUtils.toIsoDateKey(w.date));
      }
      for (final f in foods) {
        keys.add(AppDateUtils.toIsoDateKey(f.date));
      }
      return keys;
    });
  });
});

final streakSummaryProvider = Provider<AsyncValue<StreakSummary>>((ref) {
  final datesAsync = ref.watch(activeLoggedDatesProvider);
  return datesAsync.whenData(
    (dates) => StreakAndTips.calculateStreak(activeIsoDates: dates),
  );
});
