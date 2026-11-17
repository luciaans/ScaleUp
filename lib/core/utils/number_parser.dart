/// Parser angka desimal yang mendukung pemisah koma Indonesia (`68,5`) maupun titik (`68.5`).
abstract final class NumberParser {
  static double? tryParseDouble(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.trim().replaceAll(' ', '').replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }
}
