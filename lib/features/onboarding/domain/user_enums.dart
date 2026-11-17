/// Enum domain untuk profil pengguna, tingkat aktivitas, tujuan, dan kategori BMI.
enum Gender {
  male('male', 'Pria'),
  female('female', 'Wanita');

  const Gender(this.storageKey, this.label);
  final String storageKey;
  final String label;

  static Gender fromStorage(String raw) {
    return Gender.values.firstWhere(
      (e) => e.storageKey == raw,
      orElse: () => Gender.male,
    );
  }
}

enum ActivityLevel {
  sedentary(
    'sedentary',
    'Sedentari',
    1.2,
    'Banyak duduk (pekerja kantoran/belajar), olahraga sangat jarang.',
  ),
  light(
    'light',
    'Aktivitas Ringan',
    1.375,
    'Olahraga ringan atau jalan kaki aktif 1–3 hari per minggu.',
  ),
  moderate(
    'moderate',
    'Aktivitas Sedang',
    1.55,
    'Olahraga intensitas sedang 3–5 hari per minggu.',
  ),
  heavy(
    'heavy',
    'Aktivitas Berat',
    1.725,
    'Olahraga intensif atau latihan fisik 6–7 hari per minggu.',
  ),
  veryHeavy(
    'very_heavy',
    'Sangat Berat',
    1.9,
    'Pekerjaan fisik berat harian atau latihan atletik dua kali sehari.',
  );

  const ActivityLevel(
    this.storageKey,
    this.label,
    this.factor,
    this.description,
  );

  final String storageKey;
  final String label;
  final double factor;
  final String description;

  static ActivityLevel fromStorage(String raw) {
    return ActivityLevel.values.firstWhere(
      (e) => e.storageKey == raw,
      orElse: () => ActivityLevel.light,
    );
  }
}

enum GoalType {
  lose(
    'lose',
    'Turunkan Berat Badan',
    'Turun Berat',
    'Defisit kalori terukur dan bertahap demi hasil yang sehat & bertahan lama.',
  ),
  gain(
    'gain',
    'Naikkan Berat Badan',
    'Naik Berat',
    'Surplus kalori seimbang dengan asupan protein cukup untuk massa tubuh sehat.',
  ),
  maintain(
    'maintain',
    'Jaga Berat Badan',
    'Jaga Berat',
    'Pertahankan berat badan ideal dan kebiasaan makan seimbang setiap hari.',
  );

  const GoalType(
    this.storageKey,
    this.label,
    this.shortLabel,
    this.description,
  );

  final String storageKey;
  final String label;
  final String shortLabel;
  final String description;

  static GoalType fromStorage(String raw) {
    return GoalType.values.firstWhere(
      (e) => e.storageKey == raw,
      orElse: () => GoalType.maintain,
    );
  }
}

enum WeeklyRatePreset {
  slow(0.25, 'Santai', '0,25 kg/minggu • Paling ringan & mudah dijaga'),
  normal(0.50, 'Normal', '0,5 kg/minggu • Direkomendasikan untuk mayoritas'),
  fast(0.75, 'Fokus', '0,75 kg/minggu • Maksimal yang tetap aman');

  const WeeklyRatePreset(this.rateKg, this.label, this.subtitle);
  final double rateKg;
  final String label;
  final String subtitle;
}

enum BmiCategory {
  underweight('Di Bawah Rentang Ideal'),
  normal('Rentang Ideal'),
  overweight('Di Atas Rentang Ideal'),
  obese('Perlu Perhatian Kesehatan');

  const BmiCategory(this.label);
  final String label;
}
