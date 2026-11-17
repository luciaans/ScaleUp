import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils_ext.dart';
import '../../../data/database/app_database.dart';
import '../../onboarding/domain/user_enums.dart';
import '../../settings/data/settings_repository.dart';
import '../../weight/data/weight_repository.dart';

part 'profile_repository.g.dart';

/// Repository profil pengguna (nama, jenis kelamin, tanggal lahir, tinggi, tingkat aktivitas).
class ProfileRepository {
  const ProfileRepository(this._db, this._settings, this._weightRepo);

  final AppDatabase _db;
  final SettingsRepository _settings;
  final WeightRepository _weightRepo;

  Stream<UserProfile?> watchProfile() {
    final query = _db.select(_db.userProfiles)..limit(1);
    return query.watchSingleOrNull();
  }

  Future<UserProfile?> getProfile() async {
    final query = _db.select(_db.userProfiles)..limit(1);
    return query.getSingleOrNull();
  }

  /// Menyimpan atau memperbarui profil pengguna.
  /// Otomatis menyinkronkan baseline berat kalori agar target kalori dihitung ulang
  /// saat tingkat aktivitas atau tinggi badan diganti.
  Future<void> saveProfile({
    required String name,
    required Gender gender,
    required DateTime birthDate,
    required double heightCm,
    required ActivityLevel activityLevel,
  }) async {
    final existing = await getProfile();
    final normalizedDob = AppDateUtils.dateOnly(birthDate);
    final trimmedName = name.trim();

    if (existing == null) {
      await _db.into(_db.userProfiles).insert(
            UserProfilesCompanion.insert(
              name: trimmedName,
              gender: gender.storageKey,
              birthDate: normalizedDob,
              heightCm: heightCm,
              activityLevel: activityLevel.storageKey,
            ),
          );
    } else {
      await (_db.update(_db.userProfiles)
            ..where((t) => t.id.equals(existing.id)))
          .write(
        UserProfilesCompanion(
          name: Value(trimmedName),
          gender: Value(gender.storageKey),
          birthDate: Value(normalizedDob),
          heightCm: Value(heightCm),
          activityLevel: Value(activityLevel.storageKey),
        ),
      );
    }

    // Sinkronkan baseline berat ke berat terkini ketika profil/aktivitas diperbarui
    final latestWeight = await _weightRepo.getLatestEntry();
    if (latestWeight != null) {
      await _settings.setValue(
        AppConstants.settingCalorieBaselineWeight,
        latestWeight.weightKg.toStringAsFixed(2),
      );
    }
  }
}

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) {
  return ProfileRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(settingsRepositoryProvider),
    ref.watch(weightRepositoryProvider),
  );
}

final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  return ref.watch(profileRepositoryProvider).watchProfile();
});
