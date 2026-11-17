import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/date_utils_ext.dart';
import '../../../data/database/app_database.dart';
import '../../calories/domain/calorie_models.dart';

part 'csv_export_service.g.dart';

/// Layanan ekspor riwayat berat & log makanan ke format CSV standar (mendukung Mobile & Web).
class CsvExportService {
  const CsvExportService(this._db);

  final AppDatabase _db;

  /// Membangun string CSV murni dari daftar catatan berat dan log makanan.
  static String buildCsvContent({
    required List<WeightEntry> weights,
    required List<FoodLogWithItem> foodLogs,
  }) {
    final rows = <List<Object?>>[
      <Object?>[
        'Kategori',
        'Tanggal',
        'Waktu Makan / Jenis',
        'Item / Catatan',
        'Porsi',
        'Berat (kg)',
        'Kalori (kkal)',
        'Protein (g)',
        'Karbohidrat (g)',
        'Lemak (g)',
      ],
    ];

    for (final w in weights) {
      rows.add(<Object?>[
        'Berat Badan',
        AppDateUtils.toIsoDateKey(w.date),
        '-',
        w.note ?? '',
        '-',
        w.weightKg.toStringAsFixed(1),
        '-',
        '-',
        '-',
        '-',
      ]);
    }

    for (final entry in foodLogs) {
      final mealLabel = MealType.fromStorage(entry.log.mealType).label;
      rows.add(<Object?>[
        'Makanan',
        AppDateUtils.toIsoDateKey(entry.log.date),
        mealLabel,
        '${entry.item.name} (${entry.item.servingDesc})',
        entry.log.quantity.toStringAsFixed(2),
        '-',
        entry.totalCalories.toStringAsFixed(0),
        entry.totalProtein.toStringAsFixed(1),
        entry.totalCarbs.toStringAsFixed(1),
        entry.totalFat.toStringAsFixed(1),
      ]);
    }

    return csv.encode(rows);
  }

  /// Mengumpulkan seluruh data dari SQLite dan membagikan / mengunduh file CSV.
  Future<void> exportAndShareCsv() async {
    final weights = await (_db.select(_db.weightEntries)
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();

    final joinedLogs = await (_db.select(_db.foodLogs).join([
          innerJoin(
            _db.foodItems,
            _db.foodItems.id.equalsExp(_db.foodLogs.foodItemId),
          ),
        ])
          ..orderBy([OrderingTerm.desc(_db.foodLogs.date)]))
        .get();

    final foodLogs = joinedLogs
        .map(
          (r) => FoodLogWithItem(
            log: r.readTable(_db.foodLogs),
            item: r.readTable(_db.foodItems),
          ),
        )
        .toList();

    final csvString = buildCsvContent(
      weights: weights,
      foodLogs: foodLogs,
    );

    final dateStamp =
        AppDateUtils.toIsoDateKey(AppDateUtils.today()).replaceAll('-', '');
    final fileName = 'scaleup_data_$dateStamp.csv';
    final csvBytes = Uint8List.fromList(utf8.encode(csvString));

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            csvBytes,
            mimeType: 'text/csv',
            name: fileName,
          ),
        ],
        fileNameOverrides: [fileName],
        subject: 'Ekspor Data ScaleUp ($dateStamp)',
        text: 'Berikut data pencatatan berat badan dan kalori harian dari ScaleUp.',
      ),
    );
  }
}

@Riverpod(keepAlive: true)
CsvExportService csvExportService(Ref ref) {
  return CsvExportService(ref.watch(appDatabaseProvider));
}
