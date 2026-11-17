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

  testWidgets(
      'Shell navigasi menampilkan 4 tab dan FAB Catat Cepat membuka bottom sheet',
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

    // Pastikan NavigationBar dengan 4 tab utama tampil
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text(AppStrings.navHome), findsWidgets);
    expect(find.text(AppStrings.navWeight), findsOneWidget);
    expect(find.text(AppStrings.navCalories), findsOneWidget);
    expect(find.text(AppStrings.navProfile), findsOneWidget);

    // Pindah antar tab
    await tester.tap(find.text(AppStrings.navWeight));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.weightPlaceholderTitle), findsOneWidget);

    await tester.tap(find.text(AppStrings.navCalories));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.caloriesPlaceholderTitle), findsOneWidget);

    await tester.tap(find.text(AppStrings.navProfile));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.profilePlaceholderTitle), findsOneWidget);

    // Tekan FAB Catat Cepat untuk membuka bottom sheet
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.quickAddTitle), findsOneWidget);
    expect(find.text(AppStrings.quickAddWeightTitle), findsOneWidget);
    expect(find.text(AppStrings.quickAddFoodTitle), findsOneWidget);

    // Tutup bottom sheet sebelum teardown
    Navigator.of(tester.element(find.text(AppStrings.quickAddTitle))).pop();
    await tester.pumpAndSettle();

    await disposeWidgetTestDatabase(tester, testDb);
  });
}
