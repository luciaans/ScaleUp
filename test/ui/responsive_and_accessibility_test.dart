import 'dart:ui' show AccessibilityFeatures;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:scale_up/core/constants/app_strings.dart';
import 'package:scale_up/data/database/app_database.dart';
import 'package:scale_up/features/calories/data/calories_repository.dart';
import 'package:scale_up/features/calories/domain/calorie_models.dart';
import 'package:scale_up/features/settings/data/settings_repository.dart';
import 'package:scale_up/main.dart';

import '../helpers/test_app_helper.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  final viewports = <({String name, Size size, double textScale, bool reduceMotion, ThemeMode theme})>[
    (
      name: 'Layar kecil 360dp + textScale 1.3x + Light Mode',
      size: const Size(360, 780),
      textScale: 1.3,
      reduceMotion: false,
      theme: ThemeMode.light,
    ),
    (
      name: 'Layar standar 411dp + Dark Mode + Reduce Motion',
      size: const Size(411, 891),
      textScale: 1.0,
      reduceMotion: true,
      theme: ThemeMode.dark,
    ),
    (
      name: 'Tablet kecil 600dp + textScale 1.15x',
      size: const Size(600, 960),
      textScale: 1.15,
      reduceMotion: false,
      theme: ThemeMode.light,
    ),
  ];

  for (final vp in viewports) {
    testWidgets('Bebas overflow di keempat tab pada ${vp.name}',
        (WidgetTester tester) async {
      tester.view.physicalSize = vp.size;
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = vp.textScale;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: vp.reduceMotion);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
      });

      final testDb = createTestDatabase();
      await seedCompletedOnboarding(testDb);
      await SettingsRepository(testDb).setThemeMode(vp.theme);

      final calRepo = CaloriesRepository(testDb);
      final sampleFood =
          await (testDb.select(testDb.foodItems)..limit(1)).getSingle();
      await calRepo.addFoodLog(
        date: DateTime.now(),
        mealType: MealType.lunch,
        foodItemId: sampleFood.id,
        quantity: 1.5,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(testDb),
          ],
          child: const ScaleUpApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Tab 1: Beranda
      expect(tester.takeException(), isNull);

      // Tab 2: Berat
      await tester.tap(find.text(AppStrings.navWeight));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Tab 3: Kalori
      await tester.tap(find.text(AppStrings.navCalories));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Tab 4: Profil & Pengaturan
      await tester.tap(find.text(AppStrings.navProfile));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await disposeWidgetTestDatabase(tester, testDb);
    });
  }
}

class FakeAccessibilityFeatures implements AccessibilityFeatures {
  const FakeAccessibilityFeatures({this.disableAnimations = false});

  @override
  final bool disableAnimations;

  @override
  bool get accessibleNavigation => false;

  @override
  bool get boldText => false;

  @override
  bool get highContrast => false;

  @override
  bool get invertColors => false;

  @override
  bool get onOffSwitchLabels => false;

  @override
  bool get reduceMotion => disableAnimations;

  @override
  bool get supportsAnnounce => true;

  @override
  bool get autoPlayAnimatedImages => !disableAnimations;

  @override
  bool get autoPlayVideos => !disableAnimations;

  @override
  bool get deterministicCursor => false;
}
