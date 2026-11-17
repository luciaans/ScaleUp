/// Konstanta aturan bisnis, batas validasi kesehatan, dan kunci penyimpanan.
abstract final class AppConstants {
  static const String appName = 'ScaleUp';
  static const String localeId = 'id_ID';

  // Batas validasi profil & kesehatan
  static const double minHeightCm = 100.0;
  static const double maxHeightCm = 250.0;
  static const double minWeightKg = 25.0;
  static const double maxWeightKg = 300.0;
  static const int minAgeYears = 18;
  static const int maxAgeYears = 120;

  // Aturan kesehatan wajib
  static const int minCaloriesFemale = 1200;
  static const int minCaloriesMale = 1500;
  static const double minHealthyBmiForLoss = 18.5;
  static const double maxWeeklyChangePercent = 0.01; // Maks 1% berat badan/minggu
  static const double autoRecalcWeightDeltaKg = 2.0; // Hitung ulang saat berubah >= 2 kg

  // Konstanta energi & nutrisi
  static const double kcalPerKgBodyWeight = 7700.0;
  static const double kcalPerGramProtein = 4.0;
  static const double kcalPerGramCarbs = 4.0;
  static const double kcalPerGramFat = 9.0;
  static const double defaultProteinPerKg = 1.6;
  static const double defaultFatCalorieRatio = 0.25;

  // Kecepatan perubahan mingguan preset (kg/minggu)
  static const double rateSlow = 0.25;
  static const double rateNormal = 0.50;
  static const double rateFast = 0.75;
  static const double weightStepKg = 0.1;

  // Konversi satuan
  static const double kgToLbFactor = 2.2046226218;

  // Kunci tabel Settings
  static const String settingOnboardingComplete = 'onboarding_complete';
  static const String settingThemeMode = 'theme_mode'; // system | light | dark
  static const String settingWeightUnit = 'weight_unit'; // kg | lb
  static const String settingWeightReminderEnabled = 'weight_reminder_enabled';
  static const String settingWeightReminderTime = 'weight_reminder_time'; // HH:mm
  static const String settingMealReminderEnabled = 'meal_reminder_enabled';
  static const String settingMealReminderTime = 'meal_reminder_time'; // HH:mm
  static const String settingCelebratedMilestones = 'celebrated_milestones';
  static const String settingCalorieBaselineWeight = 'calorie_baseline_weight';

  // Default pengingat
  static const String defaultWeightReminderTime = '07:00';
  static const String defaultMealReminderTime = '12:30';

  // ID Notifikasi
  static const int notificationIdWeight = 1001;
  static const int notificationIdMeal = 1002;
}
