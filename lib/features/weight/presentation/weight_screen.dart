import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/animated_count.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_box.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../../data/database/app_database.dart';
import '../../onboarding/domain/user_enums.dart';
import '../../profile/domain/active_nutrition_plan.dart';
import '../../settings/data/settings_repository.dart';
import '../data/weight_repository.dart';
import '../domain/weight_analytics.dart';
import 'widgets/weight_chart_card.dart';
import 'widgets/weight_input_sheet.dart';

/// Layar Berat & Biometrik bergaya Health Tracking App UI (Nixtio):
/// - Hero Obsidian Biometric Card + Visual BMI Spectrum Range Bar
/// - Grafik fl_chart kurva halus + tren 7 hari + segmented pill switcher
/// - Bento Grid Statistik 2x3 & Riwayat Harian swipe-to-delete
class WeightScreen extends ConsumerStatefulWidget {
  const WeightScreen({super.key});

  @override
  ConsumerState<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends ConsumerState<WeightScreen> {
  WeightRangeFilter _selectedFilter = WeightRangeFilter.days30;

  Future<void> _openWeightSheet({
    WeightEntry? entry,
    double? fallbackKg,
  }) async {
    final recalculated = await WeightInputSheet.show(
      context,
      initialEntry: entry,
      fallbackWeightKg: fallbackKg,
    );
    if (recalculated == true && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Berat tersimpan! Target kalori harian disesuaikan dengan progres barumu.',
            ),
          ),
        );
    }
  }

  Future<void> _deleteWithUndo(WeightEntry entry, WeightUnit unit) async {
    await ref.read(weightRepositoryProvider).deleteById(entry.id);
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Catatan ${AppFormatters.weight(entry.weightKg, unit: unit)} dihapus',
        ),
        action: SnackBarAction(
          label: AppStrings.undo,
          onPressed: () {
            ref.read(weightRepositoryProvider).restoreEntry(entry);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entriesAscAsync = ref.watch(weightEntriesAscProvider);
    final entriesDescAsync = ref.watch(weightEntriesDescProvider);
    final planAsync = ref.watch(activeNutritionPlanProvider);
    final unit = ref.watch(appWeightUnitProvider).value ?? WeightUnit.kg;

    final textTheme = Theme.of(context).textTheme;
    final semantic = context.semanticColors;
    final scheme = context.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.navWeight),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                backgroundColor: semantic.heroCardBg,
                foregroundColor: semantic.heroAccent,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
              ),
              onPressed: () => _openWeightSheet(
                fallbackKg: planAsync.value?.currentWeightKg,
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Catat'),
            ),
          ),
        ],
      ),
      body: entriesAscAsync.when(
        loading: () => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.bottomNavClearance,
          ),
          children: const [
            SkeletonBox(height: 180),
            SizedBox(height: AppSpacing.md),
            SkeletonBox(height: 280),
            SizedBox(height: AppSpacing.md),
            SkeletonBox(height: 110),
          ],
        ),
        error: (_, _) => Center(
          child: EmptyState(
            icon: Icons.error_outline_rounded,
            title: AppStrings.genericErrorTitle,
            subtitle: AppStrings.genericErrorSubtitle,
            actionLabel: AppStrings.retry,
            onAction: () => ref.invalidate(weightEntriesAscProvider),
          ),
        ),
        data: (ascEntries) {
          final descEntries = entriesDescAsync.value ?? const [];
          final plan = planAsync.value;

          if (ascEntries.isEmpty) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.bottomNavClearance,
              ),
              children: [
                EmptyState(
                  icon: Icons.monitor_weight_rounded,
                  accentColor: scheme.secondary,
                  title: AppStrings.weightPlaceholderTitle,
                  subtitle: AppStrings.weightPlaceholderSubtitle,
                  actionLabel: AppStrings.quickAddWeightTitle,
                  onAction: () => _openWeightSheet(
                    fallbackKg: plan?.currentWeightKg,
                  ),
                ),
              ],
            );
          }

          final summary = WeightAnalytics.computeSummary(
            ascendingEntries: ascEntries,
            goalType: plan?.goalType ?? GoalType.maintain,
            goalStartWeightKg: plan?.goal.startWeight,
            goalTargetWeightKg: plan?.goal.targetWeight,
            heightCm: plan?.profile.heightCm ?? 168.0,
          );

          final chartPoints = WeightAnalytics.buildChartPoints(
            ascendingEntries: ascEntries,
            filter: _selectedFilter,
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.bottomNavClearance,
            ),
            children: [
              // HERO OBSIDIAN WEIGHT & BIOMARKER SPECTRUM CARD
              HeroBentoCard(
                accentGlowColor: scheme.secondary,
                onTap: () => _openWeightSheet(
                  fallbackKg: summary.currentWeightKg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Berat Terkini',
                            style: textTheme.labelMedium?.copyWith(
                              color: semantic.heroCardMuted,
                            ),
                          ),
                        ),
                        Container(
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
                          child: Text(
                            AppFormatters.weight(
                              summary.totalChangeKg,
                              unit: unit,
                              signed: true,
                            ),
                            style: textTheme.labelMedium?.copyWith(
                              color: semantic.heroAccent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: AnimatedCount(
                        value: AppFormatters.kgToDisplay(
                          summary.currentWeightKg,
                          unit,
                        ),
                        formatter: (v) =>
                            '${AppFormatters.decimal1(v)} ${unit.label}',
                        style: AppTextStyles.heroNumber(
                          context,
                          fontSize: AppSpacing.heroNumberLg,
                          color: semantic.heroCardFg,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Biomarker BMI Range Bar (Gaya Health Tracking App Nixtio)
                    _BmiSpectrumBar(
                      bmi: summary.bmi,
                      categoryLabel: summary.bmiCategory.label,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Grafik fl_chart + segmented pill filter + tren 7 hari
              WeightChartCard(
                points: chartPoints,
                selectedFilter: _selectedFilter,
                onFilterChanged: (f) => setState(() => _selectedFilter = f),
                unit: unit,
                targetWeightKg: plan?.goal.targetWeight,
              ),
              const SizedBox(height: AppSpacing.md),

              // Pesan motivasi kontekstual bergaya Insight Card
              AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.primaryContainer,
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: scheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm + 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            summary.motivationTitle,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            summary.motivationBody,
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
              const SizedBox(height: AppSpacing.lg),

              // Bento Grid Statistik 2 Kolom
              Text('Metrik Progres', style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              _TwoColumnStatsRow(
                left: StatTile(
                  label: 'Berat Awal',
                  value: AppFormatters.weight(
                    summary.startWeightKg,
                    unit: unit,
                  ),
                  icon: Icons.flag_outlined,
                  accentColor: scheme.primary,
                ),
                right: StatTile(
                  label: 'Berat Sekarang',
                  value: AppFormatters.weight(
                    summary.currentWeightKg,
                    unit: unit,
                  ),
                  icon: Icons.monitor_weight_outlined,
                  accentColor: scheme.secondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              _TwoColumnStatsRow(
                left: StatTile(
                  label: 'Perubahan Total',
                  value: AppFormatters.weight(
                    summary.totalChangeKg,
                    unit: unit,
                    signed: true,
                  ),
                  icon: Icons.swap_vert_rounded,
                  accentColor: scheme.secondary,
                ),
                right: StatTile(
                  label: 'Rata-rata / Minggu',
                  value:
                      '${AppFormatters.weight(summary.weeklyChangeRateKg, unit: unit, signed: true)}/mg',
                  icon: Icons.timeline_rounded,
                  accentColor: scheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              _TwoColumnStatsRow(
                left: StatTile(
                  label: 'Sisa ke Target',
                  value: AppFormatters.weight(
                    summary.remainingToTargetKg,
                    unit: unit,
                  ),
                  subtitle:
                      'Target ${AppFormatters.weight(summary.targetWeightKg, unit: unit)}',
                  icon: Icons.track_changes_rounded,
                  accentColor: scheme.tertiary,
                ),
                right: StatTile(
                  label: 'Indeks Massa Tubuh',
                  value: 'BMI ${AppFormatters.decimal1(summary.bmi)}',
                  subtitle: summary.bmiCategory.label,
                  icon: Icons.favorite_border_rounded,
                  accentColor: scheme.primary,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Riwayat Harian',
                      style: textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      'Geser kiri untuk hapus',
                      style: textTheme.bodySmall?.copyWith(
                        color: semantic.textSecondary,
                      ),
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Riwayat Harian bergaya kapsul modern
              ...List<Widget>.generate(descEntries.length, (index) {
                final entry = descEntries[index];
                final olderEntry = index + 1 < descEntries.length
                    ? descEntries[index + 1]
                    : null;
                final deltaFromPrev = olderEntry != null
                    ? entry.weightKg - olderEntry.weightKg
                    : null;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
                  child: Dismissible(
                    key: ValueKey<int>(entry.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.errorContainer,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.cardRadius),
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: scheme.error,
                      ),
                    ),
                    onDismissed: (_) => _deleteWithUndo(entry, unit),
                    child: AppCard(
                      onTap: () => _openWeightSheet(entry: entry),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: scheme.secondary.withValues(alpha: 0.12),
                            ),
                            child: Icon(
                              Icons.calendar_today_rounded,
                              size: 17,
                              color: scheme.secondary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm + 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppFormatters.relativeDate(entry.date),
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (entry.note != null &&
                                    entry.note!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    entry.note!,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: semantic.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (deltaFromPrev != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: semantic.surfaceMuted,
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.pillRadius,
                                ),
                              ),
                              child: Text(
                                AppFormatters.weight(
                                  deltaFromPrev,
                                  unit: unit,
                                  signed: true,
                                ),
                                style: textTheme.labelSmall?.copyWith(
                                  color: semantic.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          Text(
                            AppFormatters.weight(entry.weightKg, unit: unit),
                            style: AppTextStyles.tabularValue(
                              context,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _BmiSpectrumBar extends StatelessWidget {
  const _BmiSpectrumBar({
    required this.bmi,
    required this.categoryLabel,
  });

  final double bmi;
  final String categoryLabel;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final scheme = context.colorScheme;
    final textTheme = Theme.of(context).textTheme;
    // Petakan BMI 15..35 ke posisi 0.0..1.0
    final pos = ((bmi - 15.0) / 20.0).clamp(0.04, 0.96);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 4),
      decoration: BoxDecoration(
        color: semantic.heroCardSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd + 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'BMI ${AppFormatters.decimal1(bmi)}',
                style: textTheme.labelMedium?.copyWith(
                  color: semantic.heroCardFg,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  categoryLabel,
                  style: textTheme.labelSmall?.copyWith(
                    color: semantic.heroAccent,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final markerLeft = (constraints.maxWidth - 12) * pos;
              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                    child: SizedBox(
                      height: 6,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 18,
                            child: ColoredBox(color: scheme.secondary),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            flex: 32,
                            child: ColoredBox(color: semantic.heroAccent),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            flex: 25,
                            child: ColoredBox(color: scheme.tertiary),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            flex: 25,
                            child: ColoredBox(color: scheme.error),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: markerLeft,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: semantic.heroCardFg,
                        border: Border.all(
                          color: semantic.heroCardBg,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TwoColumnStatsRow extends StatelessWidget {
  const _TwoColumnStatsRow({
    required this.left,
    required this.right,
  });

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(child: right),
        ],
      ),
    );
  }
}
