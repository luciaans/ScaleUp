import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
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
import '../../home/data/home_providers.dart';
import '../data/calories_repository.dart';
import '../domain/calorie_models.dart';
import 'widgets/food_picker_sheet.dart';
import 'widgets/weekly_calorie_chart_card.dart';

/// Layar Nutrisi & Kalori bergaya AI Nutrition Tracker (Nixtio):
/// - Strip kalender kapsul 7 hari + pemilih kalender penuh
/// - Hero Obsidian Nutrition Dial & Macro Percentage Breakdown
/// - Bento Meal Slots (Sarapan, Makan Siang, Makan Malam, Camilan)
/// - Grafik Riwayat Kalori 7 Hari
class CaloriesScreen extends ConsumerStatefulWidget {
  const CaloriesScreen({super.key});

  @override
  ConsumerState<CaloriesScreen> createState() => _CaloriesScreenState();
}

class _CaloriesScreenState extends ConsumerState<CaloriesScreen> {
  final Set<MealType> _collapsedMeals = <MealType>{};
  bool _isCopyingYesterday = false;

  Future<void> _openFoodPicker(DateTime date, MealType mealType) async {
    await FoodPickerSheet.show(
      context,
      targetDate: date,
      initialMealType: mealType,
    );
  }

  Future<void> _handleCopyYesterday(DateTime targetDate) async {
    if (_isCopyingYesterday) return;
    setState(() => _isCopyingYesterday = true);

    try {
      final copied = await ref
          .read(caloriesRepositoryProvider)
          .copyFromYesterday(targetDate);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              copied > 0
                  ? '$copied menu dari kemarin berhasil disalin!'
                  : 'Belum ada catatan makanan pada hari kemarin untuk disalin.',
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isCopyingYesterday = false);
      }
    }
  }

  Future<void> _editQuantitySheet(FoodLogWithItem entry) async {
    double tempQty = entry.log.quantity;
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final textTheme = Theme.of(ctx).textTheme;
            final scheme = ctx.colorScheme;
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(entry.item.name, style: textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(entry.item.servingDesc, style: textTheme.bodySmall),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        onPressed: tempQty > 0.25
                            ? () => setSheetState(
                                  () => tempQty =
                                      (tempQty - 0.25).clamp(0.25, 20.0),
                                )
                            : null,
                        icon: const Icon(Icons.remove_rounded),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Text(
                        '${AppFormatters.rateDecimal(tempQty)} porsi',
                        style: AppTextStyles.tabularValue(ctx, fontSize: 26),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      IconButton.filledTonal(
                        onPressed: () => setSheetState(
                          () => tempQty = (tempQty + 0.25).clamp(0.25, 20.0),
                        ),
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            Navigator.of(sheetCtx).pop();
                            await _deleteLogWithUndo(entry);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: scheme.error,
                            side: BorderSide(color: scheme.error),
                          ),
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text(AppStrings.delete),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await ref
                                .read(caloriesRepositoryProvider)
                                .updateLogQuantity(
                                  logId: entry.log.id,
                                  quantity: tempQty,
                                );
                            if (sheetCtx.mounted) {
                              Navigator.of(sheetCtx).pop();
                            }
                          },
                          child: const Text(AppStrings.save),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteLogWithUndo(FoodLogWithItem entry) async {
    await ref.read(caloriesRepositoryProvider).deleteFoodLog(entry.log.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${entry.item.name} dihapus dari log'),
          action: SnackBarAction(
            label: AppStrings.undo,
            onPressed: () {
              ref.read(caloriesRepositoryProvider).restoreFoodLog(entry.log);
            },
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedCalorieDateProvider);
    final summaryAsync = ref.watch(selectedDailyCalorieSummaryProvider);
    final weeklySeries =
        ref.watch(weeklyCalorieSeriesProvider).value ?? const [];
    final loggedDates =
        ref.watch(activeLoggedDatesProvider).value ?? const <String>{};

    final textTheme = Theme.of(context).textTheme;
    final semantic = context.semanticColors;
    final scheme = context.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.navCalories),
        actions: [
          IconButton(
            tooltip: 'Pilih tanggal di kalender',
            onPressed: () async {
              final today = AppDateUtils.today();
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(today.year - 3, 1, 1),
                lastDate: today,
              );
              if (picked != null) {
                ref
                    .read(selectedCalorieDateProvider.notifier)
                    .selectDate(picked);
              }
            },
            icon: const Icon(Icons.calendar_month_rounded),
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: TextButton.icon(
              onPressed: _isCopyingYesterday
                  ? null
                  : () => _handleCopyYesterday(selectedDate),
              icon: const Icon(Icons.copy_all_rounded, size: AppSpacing.iconSm),
              label: const Text('Salin Kemarin'),
            ),
          ),
        ],
      ),
      body: summaryAsync.when(
        loading: () => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.bottomNavClearance,
          ),
          children: const [
            SkeletonBox(height: 82),
            SizedBox(height: AppSpacing.md),
            SkeletonBox(height: 260),
            SizedBox(height: AppSpacing.md),
            SkeletonBox(height: 92),
          ],
        ),
        error: (_, _) => Center(
          child: EmptyState(
            icon: Icons.error_outline_rounded,
            title: AppStrings.genericErrorTitle,
            subtitle: AppStrings.genericErrorSubtitle,
            actionLabel: AppStrings.retry,
            onAction: () => ref.invalidate(selectedDateFoodLogsProvider),
          ),
        ),
        data: (summary) {
          final ringColor = summary.isOverTarget
              ? scheme.tertiary
              : semantic.heroAccent;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.bottomNavClearance,
            ),
            children: [
              // Strip kalender 7 hari kapsul
              DateStripSelector(
                selectedDate: selectedDate,
                loggedIsoDates: loggedDates,
                onDateSelected: (d) => ref
                    .read(selectedCalorieDateProvider.notifier)
                    .selectDate(d),
              ),
              const SizedBox(height: AppSpacing.md),

              // HERO OBSIDIAN NUTRITION DIAL & MACRO BREAKDOWN
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 350;
                  final ringSize = isCompact ? 124.0 : 146.0;
                  final cardPad = isCompact ? AppSpacing.md : AppSpacing.lg - 4;

                  return HeroBentoCard(
                    padding: EdgeInsets.all(cardPad),
                    accentGlowColor: ringColor,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: _DarkCalorieSideStat(
                                label: 'Terpakai',
                                kcal: summary.consumedCalories.round(),
                                alignEnd: false,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            ProgressRing(
                              progress: summary.calorieProgress,
                              size: ringSize,
                              strokeWidth: AppSpacing.ringStrokeLg,
                              color: ringColor,
                              trackColor: semantic.heroCardSurface,
                              semanticLabel:
                                  'Kalori terpakai ${summary.consumedCalories.round()} dari target ${summary.targetCalories} kilokalori',
                              center: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedCount(
                                      value: summary.remainingCalories
                                          .abs()
                                          .toDouble(),
                                      formatter: (v) =>
                                          AppFormatters.integer(v),
                                      style: AppTextStyles.heroNumber(
                                        context,
                                        fontSize: AppSpacing.heroNumberMd,
                                        color: semantic.heroCardFg,
                                      ),
                                    ),
                                    Text(
                                      summary.isOverTarget
                                          ? 'kkal lebih'
                                          : 'kkal tersisa',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: semantic.heroCardMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: _DarkCalorieSideStat(
                                label: 'Target',
                                kcal: summary.targetCalories,
                                alignEnd: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg - 4),

                        // 3 Macro Breakdown Pods dengan persentase & mini progress bar
                        Row(
                          children: [
                            Expanded(
                              child: _MacroBreakdownTile(
                                label: 'Protein',
                                consumedGrams: summary.consumedProteinGrams,
                                targetGrams: summary.targetProteinGrams,
                                color: semantic.proteinColor,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _MacroBreakdownTile(
                                label: 'Karbo',
                                consumedGrams: summary.consumedCarbsGrams,
                                targetGrams: summary.targetCarbsGrams,
                                color: semantic.heroAccent,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _MacroBreakdownTile(
                                label: 'Lemak',
                                consumedGrams: summary.consumedFatGrams,
                                targetGrams: summary.targetFatGrams,
                                color: semantic.fatColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // 4 Kartu Bento Waktu Makan
              ...MealType.values.map((meal) {
                final items = summary.byMeal[meal] ?? const [];
                final mealKcal = summary.mealCalories(meal);
                final isCollapsed = _collapsedMeals.contains(meal);
                final (mealIcon, mealAccent) = switch (meal) {
                  MealType.breakfast => (
                    Icons.wb_twilight_rounded,
                    scheme.tertiary,
                  ),
                  MealType.lunch => (Icons.wb_sunny_rounded, scheme.primary),
                  MealType.dinner => (
                    Icons.nights_stay_rounded,
                    scheme.secondary,
                  ),
                  MealType.snack => (
                    Icons.cookie_outlined,
                    AppColors.softViolet,
                  ),
                };

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
                  child: AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusMd),
                                onTap: () {
                                  MotionUtils.selectionClick();
                                  setState(() {
                                    if (isCollapsed) {
                                      _collapsedMeals.remove(meal);
                                    } else {
                                      _collapsedMeals.add(meal);
                                    }
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.xxs,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: mealAccent.withValues(
                                            alpha: 0.14,
                                          ),
                                        ),
                                        child: Icon(
                                          mealIcon,
                                          color: mealAccent,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm + 4),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              meal.label,
                                              style: textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              '${items.length} menu • ${AppFormatters.calories(mealKcal)}',
                                              style: textTheme.bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        semantic.textSecondary,
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      AnimatedRotation(
                                        turns: isCollapsed ? -0.25 : 0.0,
                                        duration: MotionUtils.duration(
                                          context,
                                          AppSpacing.animFast,
                                        ),
                                        child: Icon(
                                          Icons.expand_more_rounded,
                                          color: semantic.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            FilledButton.tonalIcon(
                              key: Key('add_meal_${meal.storageKey}_button'),
                              style: FilledButton.styleFrom(
                                backgroundColor: semantic.surfaceMuted,
                                foregroundColor: scheme.onSurface,
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm + 4,
                                  vertical: AppSpacing.xs,
                                ),
                              ),
                              onPressed: () =>
                                  _openFoodPicker(selectedDate, meal),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Tambah'),
                            ),
                          ],
                        ),
                        if (!isCollapsed && items.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm + 2),
                          const Divider(),
                          ...items.map((entry) {
                            return Dismissible(
                              key: ValueKey<int>(entry.log.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(
                                  right: AppSpacing.md,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.errorContainer,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd,
                                  ),
                                ),
                                child: Icon(
                                  Icons.delete_outline_rounded,
                                  color: scheme.error,
                                ),
                              ),
                              onDismissed: (_) => _deleteLogWithUndo(entry),
                              child: InkWell(
                                onTap: () => _editQuantitySheet(entry),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.sm + 2,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              entry.item.name,
                                              style: textTheme.bodyMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            Text(
                                              '${AppFormatters.rateDecimal(entry.log.quantity)} x ${entry.item.servingDesc} • P ${AppFormatters.compactDecimal(entry.totalProtein)}g',
                                              style: textTheme.bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        semantic.textSecondary,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.sm + 2,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: semantic.surfaceMuted,
                                          borderRadius: BorderRadius.circular(
                                            AppSpacing.pillRadius,
                                          ),
                                        ),
                                        child: Text(
                                          AppFormatters.calories(
                                            entry.totalCalories,
                                          ),
                                          style: textTheme.labelMedium
                                              ?.copyWith(
                                                color: scheme.onSurface,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                );
              }),

              if (weeklySeries.isNotEmpty)
                WeeklyCalorieChartCard(
                  series: weeklySeries,
                  targetCalories: summary.targetCalories,
                  selectedDate: selectedDate,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DarkCalorieSideStat extends StatelessWidget {
  const _DarkCalorieSideStat({
    required this.label,
    required this.kcal,
    required this.alignEnd,
  });

  final String label;
  final int kcal;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final semantic = context.semanticColors;

    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(color: semantic.heroCardMuted),
        ),
        const SizedBox(height: AppSpacing.xxs),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            AppFormatters.integer(kcal),
            style: AppTextStyles.tabularValue(
              context,
              fontSize: 19,
              color: semantic.heroCardFg,
            ),
          ),
        ),
        Text(
          AppStrings.unitKcal,
          style: textTheme.labelSmall?.copyWith(
            color: semantic.heroCardMuted,
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }
}

class _MacroBreakdownTile extends StatelessWidget {
  const _MacroBreakdownTile({
    required this.label,
    required this.consumedGrams,
    required this.targetGrams,
    required this.color,
  });

  final String label;
  final double consumedGrams;
  final int targetGrams;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final semantic = context.semanticColors;
    final ratio = targetGrams <= 0
        ? 0.0
        : (consumedGrams / targetGrams).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 3),
      decoration: BoxDecoration(
        color: semantic.heroCardSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd + 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(
                    color: semantic.heroCardMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${(ratio * 100).round()}%',
                style: textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: ratio),
              duration: MotionUtils.duration(context, AppSpacing.animNormal),
              curve: Curves.easeOutCubic,
              builder: (context, val, _) {
                return LinearProgressIndicator(
                  value: val,
                  minHeight: 6,
                  backgroundColor: semantic.heroCardBg,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${consumedGrams.round()} / ${targetGrams}g',
              style: AppTextStyles.tabularValue(
                context,
                fontSize: 13,
                color: semantic.heroCardFg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
