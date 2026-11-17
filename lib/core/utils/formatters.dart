import 'package:intl/intl.dart';

import '../constants/app_constants.dart';
import '../constants/app_strings.dart';
import 'date_utils_ext.dart';

/// Pilihan satuan berat badan aplikasi.
enum WeightUnit {
  kg,
  lb;

  String get label => this == WeightUnit.kg ? AppStrings.unitKg : AppStrings.unitLb;

  static WeightUnit fromStorage(String? raw) =>
      raw == 'lb' ? WeightUnit.lb : WeightUnit.kg;

  String get storageKey => name;
}

/// Formatter angka, berat, kalori, dan tanggal dalam locale `id_ID`.
abstract final class AppFormatters {
  static double kgToDisplay(double weightKg, WeightUnit unit) {
    if (unit == WeightUnit.lb) {
      return weightKg * AppConstants.kgToLbFactor;
    }
    return weightKg;
  }

  static double displayToKg(double displayValue, WeightUnit unit) {
    if (unit == WeightUnit.lb) {
      return displayValue / AppConstants.kgToLbFactor;
    }
    return displayValue;
  }

  /// Format angka 1 desimal gaya Indonesia (contoh: `68,4`).
  static String decimal1(num value) =>
      NumberFormat('0.0', AppConstants.localeId).format(value);

  /// Format angka hingga 1 desimal opsional (contoh: `1` atau `1,5`).
  static String compactDecimal(num value) =>
      NumberFormat('#,##0.#', AppConstants.localeId).format(value);

  /// Format angka hingga 2 desimal opsional (contoh: `0,25` atau `0,5`).
  static String rateDecimal(num value) =>
      NumberFormat('0.##', AppConstants.localeId).format(value);

  /// Format bilangan bulat dengan pemisah ribuan Indonesia (contoh: `1.850`).
  static String integer(num value) =>
      NumberFormat('#,##0', AppConstants.localeId).format(value.round());

  /// Format berat beserta satuan aktif (contoh: `68,4 kg` atau `150,8 lb`).
  static String weight(
    double weightKg, {
    WeightUnit unit = WeightUnit.kg,
    bool includeUnit = true,
    bool signed = false,
  }) {
    final converted = kgToDisplay(weightKg, unit);
    final absFormatted = decimal1(converted.abs());
    final prefix = signed
        ? (converted > 0.04
            ? '+'
            : (converted < -0.04 ? '-' : ''))
        : (converted < -0.04 ? '-' : '');
    final base = '$prefix$absFormatted';
    return includeUnit ? '$base ${unit.label}' : base;
  }

  /// Format kalori (contoh: `1.850 kkal`).
  static String calories(num kcal, {bool includeUnit = true}) {
    final base = integer(kcal);
    return includeUnit ? '$base ${AppStrings.unitKcal}' : base;
  }

  /// Format tanggal lengkap Indonesia (contoh: `Rabu, 18 Nov 2026`).
  static String fullDate(DateTime date) =>
      DateFormat('EEEE, d MMM yyyy', AppConstants.localeId).format(date);

  /// Format tanggal sedang Indonesia (contoh: `18 Nov 2026`).
  static String mediumDate(DateTime date) =>
      DateFormat('d MMM yyyy', AppConstants.localeId).format(date);

  /// Format tanggal singkat untuk sumbu grafik (contoh: `18 Nov` atau `18/11`).
  static String shortChartDate(DateTime date) =>
      DateFormat('d/M', AppConstants.localeId).format(date);

  /// Format tanggal kontekstual ("Hari ini", "Kemarin", atau `18 Nov 2026`).
  static String relativeDate(DateTime date, {DateTime? now}) {
    final ref = AppDateUtils.dateOnly(now ?? DateTime.now());
    final target = AppDateUtils.dateOnly(date);
    if (AppDateUtils.isSameDay(target, ref)) {
      return 'Hari ini, ${DateFormat('d MMM', AppConstants.localeId).format(target)}';
    }
    if (AppDateUtils.isSameDay(target, AppDateUtils.yesterday(ref))) {
      return 'Kemarin, ${DateFormat('d MMM', AppConstants.localeId).format(target)}';
    }
    return mediumDate(target);
  }
}
