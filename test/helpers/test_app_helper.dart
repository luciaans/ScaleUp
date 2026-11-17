import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:scale_up/core/constants/app_constants.dart';
import 'package:scale_up/data/database/app_database.dart';

/// Menyiapkan konfigurasi test global (locale Indonesia & matikan HTTP GoogleFonts).
Future<void> initTestEnvironment() async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  GoogleFonts.config.allowRuntimeFetching = false;
  await initializeDateFormatting(AppConstants.localeId);
}

/// Membuat instance [AppDatabase] in-memory terisolasi (closeStreamsSynchronously aktif untuk FakeAsync).
AppDatabase createTestDatabase() {
  return AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
}

/// Menyemai profil contoh + tujuan aktif + tanda onboarding selesai untuk test layar utama.
Future<void> seedCompletedOnboarding(AppDatabase db) async {
  await db.into(db.userProfiles).insert(
        UserProfilesCompanion.insert(
          name: 'Andi',
          gender: 'male',
          birthDate: DateTime(1996, 4, 12),
          heightCm: 172,
          activityLevel: 'moderate',
        ),
      );
  await db.into(db.goals).insert(
        GoalsCompanion.insert(
          type: 'lose',
          startWeight: 74.0,
          targetWeight: 68.0,
          weeklyRate: 0.5,
          startDate: DateTime(2026, 11, 1),
          isActive: const Value(true),
        ),
      );
  await db.into(db.weightEntries).insert(
        WeightEntriesCompanion.insert(
          date: DateTime(2026, 11, 1),
          weightKg: 74.0,
        ),
      );
  await db.into(db.settings).insertOnConflictUpdate(
        SettingsCompanion.insert(
          key: AppConstants.settingOnboardingComplete,
          value: 'true',
        ),
      );
  await db.into(db.settings).insertOnConflictUpdate(
        SettingsCompanion.insert(
          key: AppConstants.settingCalorieBaselineWeight,
          value: '74.00',
        ),
      );
}

/// Menutup [AppDatabase] dengan aman pada akhir [testWidgets].
Future<void> disposeWidgetTestDatabase(
  WidgetTester tester,
  AppDatabase db,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await db.close();
}
