import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils_ext.dart';
import '../../../data/database/app_database.dart';
import '../../onboarding/domain/health_calculator.dart';
import '../../onboarding/domain/user_enums.dart';
import '../../settings/data/settings_repository.dart';
import '../../weight/data/weight_repository.dart';
import '../data/goal_repository.dart';
import '../data/profile_repository.dart';

part 'active_nutrition_plan.g.dart';

/// Ringkasan terpadu profil, tujuan aktif, berat terkini, dan rencana nutrisi harian.
class ActiveNutritionPlan {
  const ActiveNutritionPlan({
    required this.profile,
    required this.goal,
    required this.currentWeightKg,
    required this.calculationWeightKg,
    required this.ageYears,
    required this.bmi,
    required this.bmiCategory,
    required this.caloriePlan,
  });

  final UserProfile profile;
  final Goal goal;
  final double currentWeightKg;
  final double calculationWeightKg;
  final int ageYears;
  final double bmi;
  final BmiCategory bmiCategory;
  final CalorieCalculationResult caloriePlan;

  Gender get gender => Gender.fromStorage(profile.gender);
  ActivityLevel get activityLevel =>
      ActivityLevel.fromStorage(profile.activityLevel);
  GoalType get goalType => GoalType.fromStorage(goal.type);

  /// Persentase progres menuju berat target (0.0 .. 1.0).
  double get goalProgress {
    if (goalType == GoalType.maintain) {
      final diff = (currentWeightKg - goal.targetWeight).abs();
      return diff <= 2.0 ? 1.0 : (1.0 - ((diff - 2.0) / 10.0)).clamp(0.0, 1.0);
    }
    final totalDelta = (goal.targetWeight - goal.startWeight).abs();
    if (totalDelta < 0.05) return 1.0;

    if (goalType == GoalType.lose) {
      final achieved = goal.startWeight - currentWeightKg;
      return (achieved / totalDelta).clamp(0.0, 1.0);
    } else {
      final achieved = currentWeightKg - goal.startWeight;
      return (achieved / totalDelta).clamp(0.0, 1.0);
    }
  }

  /// Apakah target berat badan sudah tercapai.
  bool get isGoalReached {
    if (goalType == GoalType.lose) {
      return currentWeightKg <= goal.targetWeight + 0.05;
    }
    if (goalType == GoalType.gain) {
      return currentWeightKg >= goal.targetWeight - 0.05;
    }
    return (currentWeightKg - goal.targetWeight).abs() <= 1.0;
  }
}

@riverpod
Stream<String?> calorieBaselineRaw(Ref ref) {
  return ref
      .watch(settingsRepositoryProvider)
      .watchValue(AppConstants.settingCalorieBaselineWeight);
}

@riverpod
AsyncValue<ActiveNutritionPlan?> activeNutritionPlan(Ref ref) {
  final profileAsync = ref.watch(userProfileProvider);
  final goalAsync = ref.watch(activeGoalProvider);
  final latestWeightAsync = ref.watch(latestWeightEntryProvider);
  final baselineAsync = ref.watch(calorieBaselineRawProvider);

  if (profileAsync.isLoading ||
      goalAsync.isLoading ||
      latestWeightAsync.isLoading ||
      baselineAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (profileAsync.hasError) {
    return AsyncValue.error(profileAsync.error!, profileAsync.stackTrace!);
  }
  if (goalAsync.hasError) {
    return AsyncValue.error(goalAsync.error!, goalAsync.stackTrace!);
  }

  final profile = profileAsync.value;
  final goal = goalAsync.value;
  if (profile == null || goal == null) {
    return const AsyncValue.data(null);
  }

  final currentWeightKg = latestWeightAsync.value?.weightKg ?? goal.startWeight;
  final parsedBaseline = baselineAsync.value != null
      ? double.tryParse(baselineAsync.value!)
      : null;
  final calculationWeightKg = parsedBaseline ?? currentWeightKg;

  final ageYears = AppDateUtils.calculateAgeYears(profile.birthDate);
  final gender = Gender.fromStorage(profile.gender);
  final activity = ActivityLevel.fromStorage(profile.activityLevel);
  final goalType = GoalType.fromStorage(goal.type);

  final bmi = HealthCalculator.calculateBmi(
    weightKg: currentWeightKg,
    heightCm: profile.heightCm,
  );

  final plan = HealthCalculator.calculateCompletePlan(
    gender: gender,
    weightKg: calculationWeightKg,
    heightCm: profile.heightCm,
    ageYears: ageYears,
    activityLevel: activity,
    goalType: goalType,
    targetWeightKg: goal.targetWeight,
    requestedWeeklyRateKg: goal.weeklyRate,
  );

  // Gunakan berat aktual saat ini untuk estimasi tanggal tercapai agar selalu mutakhir
  final liveEstimatedDate = HealthCalculator.estimateTargetDate(
    goalType: goalType,
    currentWeightKg: currentWeightKg,
    targetWeightKg: goal.targetWeight,
    effectiveWeeklyRateKg: plan.effectiveWeeklyRateKg,
  );

  final updatedPlan = CalorieCalculationResult(
    bmr: plan.bmr,
    tdee: plan.tdee,
    targetCalories: plan.targetCalories,
    proteinGrams: plan.proteinGrams,
    carbsGrams: plan.carbsGrams,
    fatGrams: plan.fatGrams,
    requestedWeeklyRateKg: plan.requestedWeeklyRateKg,
    effectiveWeeklyRateKg: plan.effectiveWeeklyRateKg,
    wasClampedToMinCalories: plan.wasClampedToMinCalories,
    wasClampedByOnePercentRule: plan.wasClampedByOnePercentRule,
    estimatedTargetDate: liveEstimatedDate,
  );

  return AsyncValue.data(
    ActiveNutritionPlan(
      profile: profile,
      goal: goal,
      currentWeightKg: currentWeightKg,
      calculationWeightKg: calculationWeightKg,
      ageYears: ageYears,
      bmi: bmi,
      bmiCategory: HealthCalculator.classifyBmi(bmi),
      caloriePlan: updatedPlan,
    ),
  );
}
