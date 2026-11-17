import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:scale_up/data/database/app_database.dart';
import 'package:scale_up/data/seed/indonesian_foods_seed.dart';

import '../helpers/test_app_helper.dart';

void main() {
  late AppDatabase db;

  setUpAll(() async {
    await initTestEnvironment();
  });

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  group('AppDatabase Fase 1 (Skema, Seed Makanan Indonesia & Constraint)', () {
    test('otomatis menyemai minimal 80 makanan Indonesia saat pertama dibuka',
        () async {
      final foods = await db.select(db.foodItems).get();

      expect(foods.length, greaterThanOrEqualTo(80));
      expect(foods.length, equals(kIndonesianFoodsSeed.length));
      expect(foods.every((f) => !f.isCustom), isTrue);

      final names = foods.map((f) => f.name.toLowerCase()).toList();
      expect(names.any((n) => n.contains('nasi putih')), isTrue);
      expect(names.any((n) => n.contains('nasi goreng')), isTrue);
      expect(names.any((n) => n.contains('bubur ayam')), isTrue);
      expect(names.any((n) => n.contains('tempe goreng')), isTrue);
      expect(names.any((n) => n.contains('tahu')), isTrue);
      expect(names.any((n) => n.contains('ayam goreng')), isTrue);
      expect(names.any((n) => n.contains('telur')), isTrue);
      expect(names.any((n) => n.contains('rendang')), isTrue);
      expect(names.any((n) => n.contains('gado-gado')), isTrue);
      expect(names.any((n) => n.contains('pecel')), isTrue);
      expect(names.any((n) => n.contains('teh manis')), isTrue);
    });

    test('menegakkan constraint UNIQUE per hari kalender pada WeightEntries',
        () async {
      final morning = DateTime(2026, 11, 18, 7, 15);
      final night = DateTime(2026, 11, 18, 21, 45);

      await db.into(db.weightEntries).insert(
            WeightEntriesCompanion.insert(
              date: morning,
              weightKg: 70.4,
              note: const Value('Pagi hari'),
            ),
          );

      // Insert langsung di tanggal kalender yang sama harus ditolak oleh UNIQUE
      expect(
        () => db.into(db.weightEntries).insert(
              WeightEntriesCompanion.insert(
                date: night,
                weightKg: 70.1,
              ),
            ),
        throwsA(isA<Exception>()),
      );

      // Upsert berdasarkan tanggal kalender memperbarui baris yang ada
      await db.into(db.weightEntries).insert(
            WeightEntriesCompanion.insert(
              date: night,
              weightKg: 70.1,
              note: const Value('Diperbarui malam'),
            ),
            onConflict: DoUpdate(
              (_) => const WeightEntriesCompanion(
                weightKg: Value(70.1),
                note: Value('Diperbarui malam'),
              ),
              target: [db.weightEntries.date],
            ),
          );

      final all = await db.select(db.weightEntries).get();
      expect(all, hasLength(1));
      expect(all.single.weightKg, 70.1);
      expect(all.single.note, 'Diperbarui malam');
    });

    test('clearAllUserData menghapus data pengguna dan mempertahankan seed bawaan',
        () async {
      await db.into(db.settings).insert(
            SettingsCompanion.insert(key: 'theme_mode', value: 'dark'),
          );
      await db.into(db.foodItems).insert(
            FoodItemsCompanion.insert(
              name: 'Smoothie Pisang Buatan Sendiri',
              servingDesc: '1 gelas',
              calories: 210,
              protein: 8,
              carbs: 34,
              fat: 4,
              isCustom: const Value(true),
            ),
          );

      await db.clearAllUserData();

      final settingsAfter = await db.select(db.settings).get();
      final customFoodsAfter = await (db.select(db.foodItems)
            ..where((t) => t.isCustom.equals(true)))
          .get();
      final seedFoodsAfter = await (db.select(db.foodItems)
            ..where((t) => t.isCustom.equals(false)))
          .get();

      expect(settingsAfter, isEmpty);
      expect(customFoodsAfter, isEmpty);
      expect(seedFoodsAfter.length, equals(kIndonesianFoodsSeed.length));
    });
  });
}
