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
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/primary_button.dart';
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

/// Dashboard utama (Beranda):
/// CustomScrollView + SliverAppBar yang mengecil saat di-scroll,
/// kartu staggered fade + slide up 20px, dan perayaan confetti ringan sekali per pencapaian.
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
                      SkeletonBox(height: 150),
                      SizedBox(height: AppSpacing.md),
                      SkeletonBox(height: 130),
                      SizedBox(height: AppSpacing.md),
                      SkeletonBox(height: 145),
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
                return Center(
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
              final calorieSummary = todayCaloriesAsync.value;
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
              final goalBg = switch (plan.goalType) {
                GoalType.lose => semantic.goalLoseContainer,
                GoalType.gain => semantic.goalGainContainer,
                GoalType.maintain => semantic.goalMaintainContainer,
              };

              return CustomScrollView(
                slivers: [
                  // SliverAppBar mengecil saat di-scroll
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 112,
                    backgroundColor: semantic.background,
                    flexibleSpace: FlexibleSpaceBar(
                      titlePadding: const EdgeInsetsDirectional.only(
                        start: AppSpacing.md,
                        end: AppSpacing.md,
                        bottom: AppSpacing.sm + AppSpacing.xs,
                      ),
                      title: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$greeting, ${plan.profile.name}!',
                            style: textTheme.titleLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            AppFormatters.fullDate(today),
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

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xs,
                      AppSpacing.md,
                      AppSpacing.bottomNavClearance,
                    ),
                    sliver: SliverList.list(
                      children: [
                        // 1. Kartu Tujuan dengan Progres Melingkar (%)
                        _staggeredCard(
                          context,
                          index: 0,
                          child: AppCard(
                            onTap: () => context.go(AppRoutes.profile),
                            backgroundColor: goalBg.withValues(alpha: 0.55),
                            borderColor: goalAccent.withValues(alpha: 0.4),
                            child: Row(
                              children: [
                                ProgressRing(
                                  progress: plan.goalProgress,
                                  size: 92,
                                  strokeWidth: AppSpacing.ringStrokeMd,
                                  color: goalAccent,
                                  trackColor:
                                      goalAccent.withValues(alpha: 0.16),
                                  semanticLabel:
                                      'Progres tujuan ${(plan.goalProgress * 100).round()} persen',
                                  center: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '${(plan.goalProgress * 100).round()}%',
                                      style: AppTextStyles.tabularValue(
                                        context,
                                        fontSize: 20,
                                        color: goalAccent,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        plan.goalType.label,
                                        style: textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        plan.goalType == GoalType.maintain
                                            ? 'Target stabil di ${AppFormatters.weight(plan.goal.targetWeight, unit: unit)}'
                                            : '${AppFormatters.weight(plan.currentWeightKg, unit: unit)} menuju ${AppFormatters.weight(plan.goal.targetWeight, unit: unit)}',
                                        style: textTheme.bodyMedium,
                                      ),
                                      if (plan.goalType != GoalType.maintain &&
                                          plan.caloriePlan
                                                  .estimatedTargetDate !=
                                              null) ...[
                                        const SizedBox(height: AppSpacing.xxs),
                                        Text(
                                          plan.isGoalReached
                                              ? 'Target sudah tercapai!'
                                              : 'Estimasi: ${AppFormatters.mediumDate(plan.caloriePlan.estimatedTargetDate!)}',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: semantic.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // 2. Kartu Berat Hari Ini + Tombol Catat
                        _staggeredCard(
                          context,
                          index: 1,
                          child: AppCard(
                            onTap: () => context.go(AppRoutes.weight),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.monitor_weight_rounded,
                                            size: AppSpacing.iconSm,
                                            color: scheme.secondary,
                                          ),
                                          const SizedBox(width: AppSpacing.xs),
                                          Flexible(
                                            child: Text(
                                              todayWeight != null
                                                  ? 'Berat Hari Ini'
                                                  : 'Belum Catat Berat Hari Ini',
                                              style: textTheme.labelMedium,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      if (todayWeight != null)
                                        AnimatedCount(
                                          value: AppFormatters.kgToDisplay(
                                            todayWeight.weightKg,
                                            unit,
                                          ),
                                          formatter: (v) =>
                                              '${AppFormatters.decimal1(v)} ${unit.label}',
                                          style: AppTextStyles.heroNumber(
                                            context,
                                            fontSize: AppSpacing.heroNumberMd,
                                            color: scheme.secondary,
                                          ),
                                        )
                                      else
                                        Text(
                                          'Terakhir: ${AppFormatters.weight(plan.currentWeightKg, unit: unit)}',
                                          style: textTheme.titleMedium,
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                PrimaryButton(
                                  key: const Key('home_log_weight_button'),
                                  label: todayWeight != null
                                      ? AppStrings.edit
                                      : 'Catat Berat',
                                  isFullWidth: false,
                                  backgroundColor: scheme.secondary,
                                  foregroundColor: scheme.onSecondary,
                                  onPressed: () {
                                    WeightInputSheet.show(
                                      context,
                                      initialEntry: todayWeight,
                                      fallbackWeightKg: plan.currentWeightKg,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // 3. Kartu Sisa Kalori Hari Ini (Ring)
                        _staggeredCard(
                          context,
                          index: 2,
                          child: AppCard(
                            onTap: () => context.go(AppRoutes.calories),
                            child: Row(
                              children: [
                                ProgressRing(
                                  progress:
                                      calorieSummary?.calorieProgress ?? 0.0,
                                  size: 84,
                                  strokeWidth: AppSpacing.ringStrokeMd,
                                  color: (calorieSummary?.isOverTarget ?? false)
                                      ? scheme.tertiary
                                      : scheme.primary,
                                  semanticLabel: 'Progres kalori hari ini',
                                  center: Icon(
                                    Icons.restaurant_rounded,
                                    color:
                                        (calorieSummary?.isOverTarget ?? false)
                                            ? scheme.tertiary
                                            : scheme.primary,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (calorieSummary?.isOverTarget ?? false)
                                            ? 'Kalori Melebihi Target'
                                            : 'Sisa Kalori Hari Ini',
                                        style: textTheme.labelMedium,
                                      ),
                                      const SizedBox(height: AppSpacing.xxs),
                                      AnimatedCount(
                                        value: (calorieSummary
                                                    ?.remainingCalories ??
                                                plan.caloriePlan.targetCalories)
                                            .abs()
                                            .toDouble(),
                                        formatter: (v) =>
                                            AppFormatters.calories(v),
                                        style: AppTextStyles.tabularValue(
                                          context,
                                          fontSize: 26,
                                          color: scheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xxs),
                                      Text(
                                        'Terpakai ${AppFormatters.integer(calorieSummary?.consumedCalories ?? 0)} dari ${AppFormatters.calories(plan.caloriePlan.targetCalories)}',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: semantic.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton.filledTonal(
                                  key: const Key('home_quick_food_button'),
                                  tooltip: AppStrings.quickAddFoodTitle,
                                  onPressed: () => FoodPickerSheet.show(
                                    context,
                                    targetDate: today,
                                  ),
                                  icon: const Icon(Icons.add_rounded),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // 4. Kartu Streak Pencatatan
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
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: scheme.tertiaryContainer,
                                        borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusMd,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.local_fire_department_rounded,
                                        color: scheme.tertiary,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${streak.currentStreakDays} Hari Beruntun',
                                            style: textTheme.titleMedium,
                                          ),
                                          Text(
                                            streak.loggedToday
                                                ? 'Kamu sudah mencatat progres hari ini!'
                                                : 'Catat berat atau makanan hari ini untuk menjaga streak.',
                                            style:
                                                textTheme.bodySmall?.copyWith(
                                                  color: semantic.textSecondary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (streak.last7DaysLogged.isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.md),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: streak.last7DaysLogged.map((d) {
                                      return Column(
                                        children: [
                                          Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: d.isLogged
                                                  ? scheme.tertiary
                                                  : semantic.surfaceMuted,
                                            ),
                                            child: Icon(
                                              d.isLogged
                                                  ? Icons.check_rounded
                                                  : Icons.remove_rounded,
                                              size: 16,
                                              color: d.isLogged
                                                  ? scheme.onTertiary
                                                  : semantic.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(
                                            height: AppSpacing.xxs,
                                          ),
                                          Text(
                                            AppFormatters.shortChartDate(
                                              d.date,
                                            ),
                                            style: textTheme.labelSmall,
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // 5. Kartu Tips Harian Kontekstual
                        _staggeredCard(
                          context,
                          index: 4,
                          child: AppCard(
                            backgroundColor: semantic.surfaceMuted,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.tips_and_updates_outlined,
                                  color: scheme.primary,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tips Hari Ini • ${tip.title}',
                                        style: textTheme.titleSmall,
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        tip.body,
                                        style: textTheme.bodySmall?.copyWith(
                                          color: semantic.textSecondary,
                                        ),
                                      ),
                                    ],
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
                scheme.primary,
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
