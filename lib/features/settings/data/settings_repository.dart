import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/database/app_database.dart';

part 'settings_repository.g.dart';

/// Konfigurasi pengingat harian (timbang berat & catat makanan).
class ReminderPreferences {
  const ReminderPreferences({
    required this.weightEnabled,
    required this.weightTime,
    required this.mealEnabled,
    required this.mealTime,
  });

  final bool weightEnabled;
  final TimeOfDay weightTime;
  final bool mealEnabled;
  final TimeOfDay mealTime;

  static String formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static TimeOfDay parseTime(String? raw, TimeOfDay fallback) {
    if (raw == null) return fallback;
    final parts = raw.split(':');
    if (parts.length != 2) return fallback;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return fallback;
    }
    return TimeOfDay(hour: h, minute: m);
  }
}

/// Repository penyimpanan pasangan key-value preferensi aplikasi di tabel Settings.
class SettingsRepository {
  const SettingsRepository(this._db);

  final AppDatabase _db;

  Future<String?> getValue(String key) async {
    final query = _db.select(_db.settings)..where((t) => t.key.equals(key));
    final row = await query.getSingleOrNull();
    return row?.value;
  }

  Stream<String?> watchValue(String key) {
    final query = _db.select(_db.settings)..where((t) => t.key.equals(key));
    return query.watchSingleOrNull().map((row) => row?.value);
  }

  Future<void> setValue(String key, String value) async {
    await _db.into(_db.settings).insertOnConflictUpdate(
          SettingsCompanion.insert(key: key, value: value),
        );
  }

  Future<bool> isOnboardingComplete() async {
    final raw = await getValue(AppConstants.settingOnboardingComplete);
    return raw == 'true';
  }

  Stream<bool> watchOnboardingComplete() {
    return watchValue(AppConstants.settingOnboardingComplete)
        .map((v) => v == 'true');
  }

  Future<void> setOnboardingComplete(bool completed) async {
    await setValue(
      AppConstants.settingOnboardingComplete,
      completed ? 'true' : 'false',
    );
  }

  Stream<ThemeMode> watchThemeMode() {
    return watchValue(AppConstants.settingThemeMode).map(_parseThemeMode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await setValue(AppConstants.settingThemeMode, mode.name);
  }

  Stream<WeightUnit> watchWeightUnit() {
    return watchValue(AppConstants.settingWeightUnit)
        .map(WeightUnit.fromStorage);
  }

  Future<void> setWeightUnit(WeightUnit unit) async {
    await setValue(AppConstants.settingWeightUnit, unit.storageKey);
  }

  Stream<ReminderPreferences> watchReminders() {
    return _db.select(_db.settings).watch().map((rows) {
      final map = {for (final r in rows) r.key: r.value};
      return ReminderPreferences(
        weightEnabled:
            map[AppConstants.settingWeightReminderEnabled] == 'true',
        weightTime: ReminderPreferences.parseTime(
          map[AppConstants.settingWeightReminderTime],
          const TimeOfDay(hour: 7, minute: 0),
        ),
        mealEnabled: map[AppConstants.settingMealReminderEnabled] == 'true',
        mealTime: ReminderPreferences.parseTime(
          map[AppConstants.settingMealReminderTime],
          const TimeOfDay(hour: 12, minute: 30),
        ),
      );
    });
  }

  Future<void> setWeightReminder({
    required bool enabled,
    required TimeOfDay time,
  }) async {
    await setValue(
      AppConstants.settingWeightReminderEnabled,
      enabled ? 'true' : 'false',
    );
    await setValue(
      AppConstants.settingWeightReminderTime,
      ReminderPreferences.formatTime(time),
    );
  }

  Future<void> setMealReminder({
    required bool enabled,
    required TimeOfDay time,
  }) async {
    await setValue(
      AppConstants.settingMealReminderEnabled,
      enabled ? 'true' : 'false',
    );
    await setValue(
      AppConstants.settingMealReminderTime,
      ReminderPreferences.formatTime(time),
    );
  }

  Stream<Set<String>> watchCelebratedMilestones() {
    return watchValue(AppConstants.settingCelebratedMilestones).map((raw) {
      if (raw == null || raw.trim().isEmpty) return <String>{};
      return raw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet();
    });
  }

  Future<void> markMilestoneCelebrated(String key) async {
    final currentRaw =
        await getValue(AppConstants.settingCelebratedMilestones) ?? '';
    final set = currentRaw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
      ..add(key);
    await setValue(AppConstants.settingCelebratedMilestones, set.join(','));
  }

  static ThemeMode _parseThemeMode(String? raw) {
    return switch (raw) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
  }
}

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) {
  return SettingsRepository(ref.watch(appDatabaseProvider));
}

@riverpod
Stream<ThemeMode> appThemeMode(Ref ref) {
  return ref.watch(settingsRepositoryProvider).watchThemeMode();
}

@riverpod
Stream<WeightUnit> appWeightUnit(Ref ref) {
  return ref.watch(settingsRepositoryProvider).watchWeightUnit();
}

@riverpod
Stream<bool> onboardingCompleted(Ref ref) {
  return ref.watch(settingsRepositoryProvider).watchOnboardingComplete();
}

@riverpod
Stream<ReminderPreferences> reminderPreferences(Ref ref) {
  return ref.watch(settingsRepositoryProvider).watchReminders();
}

@riverpod
Stream<Set<String>> celebratedMilestones(Ref ref) {
  return ref.watch(settingsRepositoryProvider).watchCelebratedMilestones();
}
