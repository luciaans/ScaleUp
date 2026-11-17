import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/database/app_database.dart';

part 'settings_repository.g.dart';

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

  static ThemeMode _parseThemeMode(String? raw) {
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
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
