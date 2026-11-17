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

/// Menutup [AppDatabase] dengan aman pada akhir [testWidgets].
Future<void> disposeWidgetTestDatabase(
  WidgetTester tester,
  AppDatabase db,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await db.close();
}
