import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:scale_up/core/constants/app_strings.dart';
import 'package:scale_up/data/database/app_database.dart';
import 'package:scale_up/main.dart';

import 'helpers/test_app_helper.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  testWidgets('Pengguna baru diarahkan otomatis ke layar Onboarding langkah 1',
      (WidgetTester tester) async {
    final testDb = createTestDatabase();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(testDb),
        ],
        child: const ScaleUpApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Langkah 1 dari 4'), findsOneWidget);
    expect(find.text(AppStrings.healthDisclaimerTitle), findsOneWidget);

    await disposeWidgetTestDatabase(tester, testDb);
  });

  testWidgets(
      'Shell navigasi menampilkan 4 tab, Profil aktif, dan FAB Catat Cepat',
      (WidgetTester tester) async {
    final testDb = createTestDatabase();
    await seedCompletedOnboarding(testDb);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(testDb),
        ],
        child: const ScaleUpApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text(AppStrings.navProfile), findsOneWidget);

    // Pindah ke tab Profil untuk memastikan kartu profil & tujuan tampil
    await tester.tap(find.text(AppStrings.navProfile));
    await tester.pumpAndSettle();
    expect(find.text('Andi'), findsOneWidget);
    expect(find.text('Tujuan Aktif'), findsOneWidget);

    // Tekan FAB Catat Cepat untuk membuka bottom sheet
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.quickAddTitle), findsOneWidget);

    Navigator.of(tester.element(find.text(AppStrings.quickAddTitle))).pop();
    await tester.pumpAndSettle();

    await disposeWidgetTestDatabase(tester, testDb);
  });
}
