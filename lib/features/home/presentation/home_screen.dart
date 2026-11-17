import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils_ext.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/reduce_motion.dart';
import '../../../core/widgets/animated_count.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/date_strip_selector.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/progress_ring.dart';
import '../../../core/widgets/skeleton_box.dart';
import '../../calories/data/calories_repository.dart';
import '../../calories/presentation/widgets/food_picker_sheet.dart';
import '../../onboarding/domain/user_enums.dart';
import '../../profile/domain/active_nutrition_plan.dart';
import '../../settings/data/settings_repository.dart';
import '../../weight/data/weight_repository.dart';
import '../../weight/presentation/widgets/weight_input_sheet.dart';
import '../data/home_providers.dart';
import '../domain/streak_and_tips.dart';

/// Dashboard Beranda bergaya Bento & Bio-Tracker modern (inspirasi Nixtio UI):
/// - Header profil & badge kapsul streak
/// - Strip kalender 7 hari berbentuk pil
/// - Hero Obsidian Nutrition & Macro Bento Card dengan radial tick-gauge bercahaya
/// - Bento Grid 2 kolom (Berat Hari Ini & Skor Progres Tujuan/BMI)
/// - Kartu Wawasan Kesehatan Harian
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final ConfettiController _confettiController;
  String? _pendingMilestoneInSession;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _maybeCelebrateMilestone({
    required ActiveNutritionPlan plan,
    required StreakSummary streak,
    required int weightEntryCount,
    required Set<String> celebrated,
  }) {
    final milestone = StreakAndTips.detectUncelebratedMilestone(
      streakDays: streak.currentStreakDays,
      isGoalReached: plan.isGoalReached,
      goalType: plan.goalType,
      activeGoalId: plan.goal.id,
      totalWeightEntries: weightEntryCount,
      celebratedKeys: celebrated,
    );

    if (milestone == null || _pendingMilestoneInSession == milestone.key) {
      return;
    }

    _pendingMilestoneInSession = milestone.key;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await ref
          .read(settingsRepositoryProvider)
          .markMilestoneCelebrated(milestone.key);
      if (!mounted) return;

      if (!MotionUtils.shouldReduceMotion(context)) {
        _confettiController.play();
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(milestone.message)),
        );
    });
  }

  Widget _staggeredCard(
    BuildContext context, {
    required int index,
    required Widget child,
  }) {
    if (MotionUtils.shouldReduceMotion(context)) {
      return child;
    }
    return child
        .animate(delay: AppSpacing.staggerDelay * index)
        .fadeIn(
          duration: AppSpacing.animNormal,
          curve: Curves.easeOutCubic,
        )
        .moveY(
          begin: AppSpacing.slideOffsetPx,
          end: 0,
          duration: AppSpacing.animNormal,
          curve: Curves.easeOutCubic,
        );
  }

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(activeNutritionPlanProvider);
    final todayCaloriesAsync = ref.watch(todayCalorieSummaryProvider);
    final streakAsync = ref.watch(streakSummaryProvider);
    final loggedDates =
        ref.watch(activeLoggedDatesProvider).value ?? const <String>{};
    final entriesDescAsync = ref.watch(weightEntriesDescProvider);
    final celebrated =
        ref.watch(celebratedMilestonesProvider).value ?? const <String>{};
    final unit = ref.watch(appWeightUnitProvider).value ?? WeightUnit.kg;

    final scheme = context.colorScheme;
    final semantic = context.semanticColors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          planAsync.when(
            loading: () => CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  title: const Text(AppStrings.appName),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.bottomNavClearance,
                  ),
                  sliver: SliverList.list(
                    children: const [
                      SkeletonBox(height: 84),
                      SizedBox(height: AppSpacing.md),
                      SkeletonBox(height: 240),
                      SizedBox(height: AppSpacing.md),
                      SkeletonBox(height: 165),
                      SizedBox(height: AppSpacing.md),
                      SkeletonBox(height: 110),
                    ],
                  ),
                ),
              ],
            ),
            error: (_, _) => Center(
              child: EmptyState(
                icon: Icons.error_outline_rounded,
                title: AppStrings.genericErrorTitle,
                subtitle: AppStrings.genericErrorSubtitle,
                actionLabel: AppStrings.retry,
                onAction: () => ref.invalidate(activeNutritionPlanProvider),
              ),
            ),
            data: (plan) {
              if (plan == null) {
                return const Center(
                  child: EmptyState(
                    icon: Icons.favorite_rounded,
                    title: AppStrings.homePlaceholderTitle,
                    subtitle: AppStrings.homePlaceholderSubtitle,
                  ),
                );
              }

              final entriesDesc = entriesDescAsync.value ?? const [];
              final today = AppDateUtils.today();
              final todayWeight = entriesDesc
                  .where((e) => AppDateUtils.isSameDay(e.date, today))
                  .firstOrNull;
              final cal = todayCaloriesAsync.value;
              final streak = streakAsync.value ??
                  const StreakSummary(
                    currentStreakDays: 0,
                    loggedToday: false,
                    last7DaysLogged: [],
                  );

              _maybeCelebrateMilestone(
                plan: plan,
                streak: streak,
                weightEntryCount: entriesDesc.length,
                celebrated: celebrated,
              );

              final greeting = AppDateUtils.greetingForHour(
                DateTime.now().hour,
              );
              final tip = StreakAndTips.dailyTipForGoal(
                plan.goalType,
                date: today,
              );

              final goalAccent = switch (plan.goalType) {
                GoalType.lose => semantic.goalLose,
                GoalType.gain => semantic.goalGain,
                GoalType.maintain => semantic.goalMaintain,
              };

              final remainingKcal =
                  cal?.remainingCalories ?? plan.caloriePlan.targetCalories;
              final consumedKcal = cal?.consumedCalories ?? 0.0;
              final isOverCal = cal?.isOverTarget ?? false;

              return CustomScrollView(
                slivers: [
                  // Top Header modern ala Nixtio (Avatar + Salam + Streak Pill)
                  SliverSafeArea(
                    bottom: false,
                    sliver: SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm + 2,
                          AppSpacing.md,
                          AppSpacing.sm,
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => context.go(AppRoutes.profile),
                              child: Container(
                                width: 46,
                                height: 46,
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: scheme.primary,
                                    width: AppSpacing.borderMedium,
                                  ),
                                ),
                                child: CircleAvatar(
                                  backgroundColor: semantic.heroCardBg,
                                  child: Text(
                                    plan.profile.name.characters.first
                                        .toUpperCase(),
                                    style: textTheme.titleMedium?.copyWith(
                                      color: semantic.heroAccent,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm + 4),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    greeting,
                                    style: textTheme.labelMedium?.copyWith(
                                      color: semantic.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    plan.profile.name,
                                    style: textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm + 4,
                                  vertical: AppSpacing.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: semantic.cardSurface,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.pillRadius,
                                  ),
                                  border: Border.all(
                                    color: scheme.outlineVariant,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.local_fire_department_rounded,
                                      size: 18,
                                      color: scheme.tertiary,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        '${streak.currentStreakDays} Hari Beruntun',
                                        style: textTheme.labelMedium?.copyWith(
                                          color: scheme.onSurface,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xs,
                      AppSpacing.md,
                      AppSpacing.bottomNavClearance,
                    ),
                    sliver: SliverList.list(
                      children: [
                        // Strip Kalender 7 Hari berbentuk kapsul
                        _staggeredCard(
                          context,
                          index: 0,
                          child: DateStripSelector(
                            selectedDate: today,
                            loggedIsoDates: loggedDates,
                            onDateSelected: (d) {
                              ref
                                  .read(selectedCalorieDateProvider.notifier)
                                  .selectDate(d);
                              context.go(AppRoutes.calories);
                            },
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // 1. HERO OBSIDIAN NUTRITION & CALORIE BENTO CARD
                        _staggeredCard(
                          context,
                          index: 1,
                          child: HeroBentoCard(
                            onTap: () => context.go(AppRoutes.calories),
                            accentGlowColor: isOverCal
                                ? scheme.tertiary
                                : semantic.heroAccent,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.sm + 4,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: semantic.heroCardSurface,
                                          borderRadius: BorderRadius.circular(
                                            AppSpacing.pillRadius,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.bolt_rounded,
                                              size: 15,
                                              color: semantic.heroAccent,
                                            ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                isOverCal
                                                    ? 'Kalori Melebihi Target'
                                                    : 'Energi Harian',
                                                style: textTheme.labelSmall
                                                    ?.copyWith(
                                                      color:
                                                          semantic.heroCardFg,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Semantics(
                                      button: true,
                                      label: AppStrings.quickAddFoodTitle,
                                      child: InkWell(
                                        key: const Key(
                                          'home_quick_food_button',
                                        ),
                                        onTap: () => FoodPickerSheet.show(
                                          context,
                                          targetDate: today,
                                        ),
                                        customBorder: const CircleBorder(),
                                        child: Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: semantic.heroAccent,
                                          ),
                                          child: const Icon(
                                            Icons.add_rounded,
                                            color: AppColors.darkOnPrimary,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),

                                // Angka Kalori Besar + Radial Tick Gauge
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: AnimatedCount(
                                              value: remainingKcal
                                                  .abs()
                                                  .toDouble(),
                                              formatter: (v) =>
                                                  AppFormatters.integer(v),
                                              style: AppTextStyles.heroNumber(
                                                context,
                                                fontSize:
                                                    AppSpacing.heroNumberLg,
                                                color: semantic.heroCardFg,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            isOverCal
                                                ? 'kkal di atas target harian'
                                                : 'kkal tersisa hari ini',
                                            style:
                                                textTheme.bodySmall?.copyWith(
                                                  color: semantic.heroCardMuted,
                                                ),
                                          ),
                                          const SizedBox(height: AppSpacing.sm),
                                          Text(
                                            '${AppFormatters.integer(consumedKcal)} / ${AppFormatters.calories(plan.caloriePlan.targetCalories)}',
                                            style:
                                                textTheme.labelMedium?.copyWith(
                                                  color: semantic.heroAccent,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    ProgressRing(
                                      progress: cal?.calorieProgress ?? 0.0,
                                      size: 112,
                                      strokeWidth: 11,
                                      color: isOverCal
                                          ? scheme.tertiary
                                          : semantic.heroAccent,
                                      trackColor: semantic.heroCardSurface,
                                      semanticLabel: 'Progres kalori hari ini',
                                      center: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${((cal?.calorieProgress ?? 0.0) * 100).round()}%',
                                              style: AppTextStyles.tabularValue(
                                                context,
                                                fontSize: 19,
                                                color: semantic.heroCardFg,
                                              ),
                                            ),
                                            Text(
                                              'terisi',
                                              style: textTheme.labelSmall
                                                  ?.copyWith(
                                                    fontSize: 10,
                                                    color:
                                                        semantic.heroCardMuted,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md + 2),

                                // 3 Mini Macro Pods di dalam Hero Card
                                Row(
                                  children: [
                                    Expanded(
                                      child: _HeroMacroPod(
                                        label: 'Protein',
                                        current:
                                            cal?.consumedProteinGrams ?? 0,
                                        target: plan.caloriePlan.proteinGrams,
                                        color: semantic.proteinColor,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: _HeroMacroPod(
                                        label: 'Karbo',
                                        current: cal?.consumedCarbsGrams ?? 0,
                                        target: plan.caloriePlan.carbsGrams,
                                        color: semantic.heroAccent,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: _HeroMacroPod(
                                        label: 'Lemak',
                                        current: cal?.consumedFatGrams ?? 0,
                                        target: plan.caloriePlan.fatGrams,
                                        color: semantic.fatColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // 2. BENTO GRID 2 KOLOM: BERAT HARI INI & SKOR TUJUAN/BMI
                        _staggeredCard(
                          context,
                          index: 2,
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Bento Kiri: Berat Badan
                                Expanded(
                                  child: AppCard(
                                    onTap: () => context.go(AppRoutes.weight),
                                    padding:
                                        const EdgeInsets.all(AppSpacing.md),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 34,
                                              height: 34,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: scheme.secondary
                                                    .withValues(alpha: 0.14),
                                              ),
                                              child: Icon(
                                                Icons.monitor_weight_rounded,
                                                size: 18,
                                                color: scheme.secondary,
                                              ),
                                            ),
                                            const SizedBox(width: AppSpacing.xs),
                                            Expanded(
                                              child: Text(
                                                todayWeight != null
                                                    ? 'Berat Hari Ini'
                                                    : 'Berat Terkini',
                                                style: textTheme.labelMedium,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: AnimatedCount(
                                            value: AppFormatters.kgToDisplay(
                                              todayWeight?.weightKg ??
                                                  plan.currentWeightKg,
                                              unit,
                                            ),
                                            formatter: (v) =>
                                                '${AppFormatters.decimal1(v)} ${unit.label}',
                                            style: AppTextStyles.tabularValue(
                                              context,
                                              fontSize: 26,
                                              color: scheme.onSurface,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          todayWeight != null
                                              ? 'Tercatat hari ini'
                                              : 'Belum timbang hari ini',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: semantic.textSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const Spacer(),
                                        const SizedBox(height: AppSpacing.sm),
                                        SizedBox(
                                          width: double.infinity,
                                          child: FilledButton.tonal(
                                            key: const Key(
                                              'home_log_weight_button',
                                            ),
                                            style: FilledButton.styleFrom(
                                              backgroundColor:
                                                  scheme.secondaryContainer,
                                              foregroundColor:
                                                  scheme.onSecondaryContainer,
                                              shape: const StadiumBorder(),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: AppSpacing.sm,
                                                    vertical: AppSpacing.xs,
                                                  ),
                                            ),
                                            onPressed: () {
                                              WeightInputSheet.show(
                                                context,
                                                initialEntry: todayWeight,
                                                fallbackWeightKg:
                                                    plan.currentWeightKg,
                                              );
                                            },
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                todayWeight != null
                                                    ? AppStrings.edit
                                                    : 'Catat Berat',
                                                style: textTheme.labelLarge
                                                    ?.copyWith(
                                                      color: scheme
                                                          .onSecondaryContainer,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm + 4),

                                // Bento Kanan: Progres Tujuan & BMI Bio-Card
                                Expanded(
                                  child: AppCard(
                                    onTap: () => context.go(AppRoutes.profile),
                                    padding:
                                        const EdgeInsets.all(AppSpacing.md),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 34,
                                              height: 34,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: goalAccent.withValues(
                                                  alpha: 0.14,
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.flag_rounded,
                                                size: 18,
                                                color: goalAccent,
                                              ),
                                            ),
                                            const SizedBox(width: AppSpacing.xs),
                                            Expanded(
                                              child: Text(
                                                plan.goalType.shortLabel,
                                                style: textTheme.labelMedium,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: AppSpacing.sm),
                                        Center(
                                          child: ProgressRing(
                                            progress: plan.goalProgress,
                                            size: 76,
                                            strokeWidth: 8,
                                            showTicks: false,
                                            color: goalAccent,
                                            trackColor: goalAccent.withValues(
                                              alpha: 0.14,
                                            ),
                                            center: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                '${(plan.goalProgress * 100).round()}%',
                                                style:
                                                    AppTextStyles.tabularValue(
                                                      context,
                                                      fontSize: 16,
                                                      color: goalAccent,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          'Target ${AppFormatters.weight(plan.goal.targetWeight, unit: unit)}',
                                          style: textTheme.labelLarge,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'BMI ${AppFormatters.decimal1(plan.bmi)} • ${plan.bmiCategory.label}',
                                          style: textTheme.labelSmall?.copyWith(
                                            color: semantic.textSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // 3. KARTU WAWASAN & TIPS HARIAN (Gaya AI Longevity Insight Nixtio)
                        _staggeredCard(
                          context,
                          index: 3,
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm + 2,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: scheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(
                                          AppSpacing.pillRadius,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.auto_awesome_rounded,
                                            size: 14,
                                            color: scheme.primary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Wawasan Harian',
                                            style:
                                                textTheme.labelSmall?.copyWith(
                                                  color:
                                                      scheme.onPrimaryContainer,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        plan.goalType.label,
                                        style: textTheme.labelSmall?.copyWith(
                                          color: semantic.textSecondary,
                                        ),
                                        textAlign: TextAlign.end,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm + 2),
                                Text(
                                  tip.title,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  tip.body,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: semantic.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          // Confetti perayaan ringan (sekali per pencapaian)
          IgnorePointer(
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              emissionFrequency: 0.05,
              numberOfParticles: 16,
              gravity: 0.25,
              colors: [
                semantic.heroAccent,
                scheme.secondary,
                scheme.tertiary,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMacroPod extends StatelessWidget {
  const _HeroMacroPod({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
  });

  final String label;
  final double current;
  final int target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final textTheme = Theme.of(context).textTheme;
    final ratio = target <= 0 ? 0.0 : (current / target).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: semantic.heroCardSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd + 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(
                    color: semantic.heroCardMuted,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${current.round()}/${target}g',
              style: AppTextStyles.tabularValue(
                context,
                fontSize: 14,
                color: semantic.heroCardFg,
              ),
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 5,
              backgroundColor: semantic.heroCardBg,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
