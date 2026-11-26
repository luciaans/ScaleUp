import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:scale_up/core/constants/app_strings.dart';
import 'package:scale_up/data/database/app_database.dart';
import 'package:scale_up/main.dart';

import '../helpers/test_app_helper.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  testWidgets(
      'Alur utama pengguna: Onboarding 4 langkah -> Beranda -> Catat Berat -> Catat Makanan',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(411, 891);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

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

    // 1. Langkah 1 Onboarding: Selamat Datang
    expect(find.text('Langkah 1 dari 4'), findsOneWidget);
    await tester.tap(find.text(AppStrings.startNow));
    await tester.pumpAndSettle();

    // 2. Langkah 2 Onboarding: Data Diri
    expect(find.text('Langkah 2 dari 4'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('onboarding_name_field')),
      'Sari',
    );
    await tester.enterText(
      find.byKey(const Key('onboarding_height_field')),
      '162',
    );
    await tester.enterText(
      find.byKey(const Key('onboarding_weight_field')),
      '64,5',
    );
    await tester.tap(find.text('Wanita'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.next));
    await tester.pumpAndSettle();

    // 3. Langkah 3 Onboarding: Tingkat Aktivitas
    expect(find.text('Langkah 3 dari 4'), findsOneWidget);
    await tester.tap(find.text('Aktivitas Sedang'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.next));
    await tester.pumpAndSettle();

    // 4. Langkah 4 Onboarding: Pilih Tujuan & Selesai
    expect(find.text('Langkah 4 dari 4'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('onboarding_target_weight_field')),
      '58',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.finishSetup));
    await tester.pumpAndSettle();

    // Verifikasi sudah masuk ke Dashboard Beranda dengan nama pengguna
    expect(find.textContaining('Sari'), findsOneWidget);

    // 5. Catat / Perbarui Berat Harian lewat tombol di Beranda
    await tester.tap(find.byKey(const Key('home_log_weight_button')));
    await tester.pumpAndSettle();

    // Tambah +0,1 kg satu kali dan isi catatan lalu simpan
    await tester.tap(find.bySemanticsLabel('Tambah 0,1 kg'));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('weight_note_field')),
      'Setelah jalan pagi',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final weightSaveFinder = find.byKey(const Key('weight_save_button'));
    await tester.ensureVisible(weightSaveFinder);
    await tester.pumpAndSettle();
    await tester.tap(weightSaveFinder);
    // Selesaikan penyimpanan async + animasi centang hingga bottom sheet tertutup
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // Pindah ke tab Berat, gulir ke Riwayat Harian, dan pastikan berat 64,6 kg & catatan tampil
    await tester.tap(find.text(AppStrings.navWeight));
    await tester.pumpAndSettle();
    expect(find.textContaining('64,6'), findsWidgets);

    await tester.drag(find.byType(ListView).first, const Offset(0, -650));
    await tester.pumpAndSettle();
    expect(find.text('Setelah jalan pagi'), findsOneWidget);

    // 6. Pindah ke tab Kalori & Catat Makanan Indonesia
    await tester.tap(find.text(AppStrings.navCalories));
    await tester.pumpAndSettle();

    final addBreakfastFinder =
        find.byKey(const Key('add_meal_breakfast_button'));
    await tester.ensureVisible(addBreakfastFinder);
    await tester.pumpAndSettle();
    await tester.tap(addBreakfastFinder);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('food_search_field')),
      'Bubur Ayam',
    );
    await tester.pumpAndSettle();

    expect(find.text('Bubur Ayam Komplit'), findsOneWidget);
    await tester.tap(find.text('Bubur Ayam Komplit'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('confirm_add_food_log_button')));
    await tester.pumpAndSettle();

    // Pastikan Bubur Ayam Komplit tercatat di daftar Sarapan pada layar Kalori
    expect(find.text('Bubur Ayam Komplit'), findsOneWidget);
    expect(find.textContaining('372'), findsWidgets);

    await disposeWidgetTestDatabase(tester, testDb);
  });
}
