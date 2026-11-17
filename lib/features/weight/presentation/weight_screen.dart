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

/// Layar lengkap Pencatatan Berat Harian, Grafik Tren 7 Hari, Statistik & Riwayat.
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
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: TextButton.icon(
              onPressed: () => _openWeightSheet(
                fallbackKg: planAsync.value?.currentWeightKg,
              ),
              icon: const Icon(Icons.add_rounded, size: AppSpacing.iconMd),
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
            SkeletonBox(height: 280),
            SizedBox(height: AppSpacing.md),
            SkeletonBox(height: 110),
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
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.bottomNavClearance,
            ),
            children: [
              // Ringkasan berat terkini dengan animasi count-up
              AppCard(
                onTap: () => _openWeightSheet(
                  fallbackKg: summary.currentWeightKg,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Berat Terkini',
                            style: textTheme.labelMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          AnimatedCount(
                            value: AppFormatters.kgToDisplay(
                              summary.currentWeightKg,
                              unit,
                            ),
                            formatter: (v) =>
                                '${AppFormatters.decimal1(v)} ${unit.label}',
                            style: AppTextStyles.heroNumber(
                              context,
                              fontSize: AppSpacing.heroNumberMd,
                              color: scheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.pillRadius),
                      ),
                      child: Text(
                        AppFormatters.weight(
                          summary.totalChangeKg,
                          unit: unit,
                          signed: true,
                        ),
                        style: textTheme.labelLarge?.copyWith(
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Grafik fl_chart + segmented filter + moving average 7 hari + garis target
              WeightChartCard(
                points: chartPoints,
                selectedFilter: _selectedFilter,
                onFilterChanged: (f) => setState(() => _selectedFilter = f),
                unit: unit,
                targetWeightKg: plan?.goal.targetWeight,
              ),
              const SizedBox(height: AppSpacing.md),

              // Pesan motivasi kontekstual yang suportif
              AppCard(
                backgroundColor: scheme.primaryContainer.withValues(alpha: 0.45),
                borderColor: scheme.primary.withValues(alpha: 0.3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: scheme.primary,
                      size: AppSpacing.iconMd,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            summary.motivationTitle,
                            style: textTheme.titleSmall,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            summary.motivationBody,
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Grid Statistik 2 Kolom (responsif bebas overflow)
              Text('Statistik Progres', style: textTheme.titleMedium),
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
              const SizedBox(height: AppSpacing.sm),
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
              const SizedBox(height: AppSpacing.sm),
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

              // Riwayat dengan edit & swipe-to-delete + Undo
              ...List<Widget>.generate(descEntries.length, (index) {
                final entry = descEntries[index];
                final olderEntry = index + 1 < descEntries.length
                    ? descEntries[index + 1]
                    : null;
                final deltaFromPrev = olderEntry != null
                    ? entry.weightKg - olderEntry.weightKg
                    : null;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppFormatters.relativeDate(entry.date),
                                  style: textTheme.titleSmall,
                                ),
                                if (entry.note != null &&
                                    entry.note!.isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.xxs),
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
                            Text(
                              AppFormatters.weight(
                                deltaFromPrev,
                                unit: unit,
                                signed: true,
                              ),
                              style: textTheme.labelSmall?.copyWith(
                                color: semantic.textSecondary,
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
                          const SizedBox(width: AppSpacing.xs),
                          Icon(
                            Icons.edit_outlined,
                            size: AppSpacing.iconSm,
                            color: semantic.textSecondary,
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
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: right),
        ],
      ),
    );
  }
}
