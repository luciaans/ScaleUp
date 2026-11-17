/// Utilitas tanggal kalender lokal yang aman terhadap perubahan jam/zona waktu.
abstract final class AppDateUtils {
  /// Menormalisasi [date] ke awal hari lokal (00:00:00).
  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Hari ini (00:00:00).
  static DateTime today() => dateOnly(DateTime.now());

  /// Kemarin (00:00:00).
  static DateTime yesterday([DateTime? reference]) {
    final base = dateOnly(reference ?? DateTime.now());
    return DateTime(base.year, base.month, base.day - 1);
  }

  /// Mengubah tanggal ke kunci string kalender `YYYY-MM-DD`.
  static String toIsoDateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Mengurai kunci string `YYYY-MM-DD` menjadi [DateTime] lokal (00:00:00).
  static DateTime fromIsoDateKey(String key) {
    final parts = key.split('-');
    if (parts.length == 3) {
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y != null && m != null && d != null) {
        return DateTime(y, m, d);
      }
    }
    final parsed = DateTime.parse(key);
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  /// Mengecek apakah dua [DateTime] berada pada hari kalender yang sama.
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Menghitung usia penuh (tahun) berdasarkan [birthDate] terhadap [reference].
  static int calculateAgeYears(DateTime birthDate, {DateTime? reference}) {
    final now = dateOnly(reference ?? DateTime.now());
    final dob = dateOnly(birthDate);
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  /// Salam Bahasa Indonesia berdasarkan jam lokal.
  static String greetingForHour(int hour) {
    if (hour >= 4 && hour < 11) return 'Selamat Pagi';
    if (hour >= 11 && hour < 15) return 'Selamat Siang';
    if (hour >= 15 && hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }
}
