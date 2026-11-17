import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/skeleton_box.dart';
import '../../onboarding/domain/user_enums.dart';
import '../../settings/data/settings_repository.dart';
import '../../settings/presentation/widgets/settings_cards.dart';
import '../data/goal_repository.dart';
import '../domain/active_nutrition_plan.dart';
import 'widgets/edit_goal_sheet.dart';
import 'widgets/edit_profile_sheet.dart';

/// Layar Profil, Tujuan Aktif, Riwayat Tujuan, dan Disclaimer Kesehatan (Fase 2;
/// Pengaturan lengkap & Ekspor CSV ditambahkan pada Fase 5).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(activeNutritionPlanProvider);
    final historyAsync = ref.watch(goalHistoryProvider);
    final unit = ref.watch(appWeightUnitProvider).value ?? WeightUnit.kg;
    final textTheme = Theme.of(context).textTheme;
    final semantic = context.semanticColors;
    final scheme = context.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.navProfile),
      ),
      body: planAsync.when(
        loading: () => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.bottomNavClearance,
          ),
          children: const [
            SkeletonBox(height: 148),
            SizedBox(height: AppSpacing.md),
            SkeletonBox(height: 180),
          ],
        ),
        error: (_, _) => const Center(
          child: EmptyState(
            icon: Icons.error_outline_rounded,
            title: AppStrings.genericErrorTitle,
            subtitle: AppStrings.genericErrorSubtitle,
          ),
        ),
        data: (plan) {
          if (plan == null) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.bottomNavClearance,
              ),
              children: const [
                EmptyState(
                  icon: Icons.person_rounded,
                  title: AppStrings.profilePlaceholderTitle,
                  subtitle: AppStrings.profilePlaceholderSubtitle,
                ),
              ],
            );
          }

          final goalAccent = switch (plan.goalType) {
            GoalType.lose => semantic.goalLose,
            GoalType.gain => semantic.goalGain,
            GoalType.maintain => semantic.goalMaintain,
          };
          final goalContainer = switch (plan.goalType) {
            GoalType.lose => semantic.goalLoseContainer,
            GoalType.gain => semantic.goalGainContainer,
            GoalType.maintain => semantic.goalMaintainContainer,
          };

          final pastGoals = (historyAsync.value ?? const [])
              .where((g) => !g.isActive)
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.bottomNavClearance,
            ),
            children: [
              // Kartu Profil Diri
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: AppSpacing.lg,
                          backgroundColor: scheme.primaryContainer,
                          child: Text(
                            plan.profile.name.characters.first.toUpperCase(),
                            style: textTheme.headlineSmall?.copyWith(
                              color: scheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plan.profile.name,
                                style: textTheme.titleLarge,
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                '${plan.gender.label} • ${plan.ageYears} tahun • ${AppFormatters.compactDecimal(plan.profile.heightCm)} cm',
                                style: textTheme.bodySmall?.copyWith(
                                  color: semantic.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final updated = await EditProfileSheet.show(
                              context,
                              plan.profile,
                            );
                            if (updated == true && context.mounted) {
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Profil berhasil diperbarui.'),
                                  ),
                                );
                            }
                          },
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text(AppStrings.edit),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _MiniProfileBadge(
                          label: 'Aktivitas',
                          value: plan.activityLevel.label,
                        ),
                        _MiniProfileBadge(
                          label: 'BMR',
                          value: AppFormatters.calories(plan.caloriePlan.bmr),
                        ),
                        _MiniProfileBadge(
                          label: 'TDEE',
                          value: AppFormatters.calories(plan.caloriePlan.tdee),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Kartu Tujuan Aktif (warna aksen sesuai jenis tujuan)
              AppCard(
                backgroundColor: goalContainer.withValues(alpha: 0.55),
                borderColor: goalAccent.withValues(alpha: 0.45),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm + AppSpacing.xs,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: goalAccent.withValues(alpha: 0.16),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.pillRadius),
                          ),
                          child: Text(
                            'Tujuan Aktif',
                            style: textTheme.labelMedium?.copyWith(
                              color: goalAccent,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Mulai ${AppFormatters.mediumDate(plan.goal.startDate)}',
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
                    Text(plan.goalType.label, style: textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      plan.goalType == GoalType.maintain
                          ? 'Menjaga di sekitar ${AppFormatters.weight(plan.goal.targetWeight, unit: unit)} • Target ${AppFormatters.calories(plan.caloriePlan.targetCalories)}/hari'
                          : 'Dari ${AppFormatters.weight(plan.goal.startWeight, unit: unit)} -> Target ${AppFormatters.weight(plan.goal.targetWeight, unit: unit)}',
                      style: textTheme.bodyMedium,
                    ),
                    if (plan.goalType != GoalType.maintain) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Kecepatan ${AppFormatters.rateDecimal(plan.caloriePlan.effectiveWeeklyRateKg)} kg/minggu • Target ${AppFormatters.calories(plan.caloriePlan.targetCalories)}/hari',
                        style: textTheme.bodySmall?.copyWith(
                          color: semantic.textSecondary,
                        ),
                      ),
                      if (plan.caloriePlan.estimatedTargetDate != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Estimasi tercapai: ${AppFormatters.mediumDate(plan.caloriePlan.estimatedTargetDate!)}',
                          style: textTheme.labelLarge?.copyWith(
                            color: goalAccent,
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: AppSpacing.md),
                    PrimaryButton(
                      label: 'Ubah Tujuan',
                      isOutlined: true,
                      backgroundColor: goalAccent,
                      foregroundColor: goalAccent,
                      icon: Icons.flag_outlined,
                      onPressed: () async {
                        final changed = await EditGoalSheet.show(
                          context,
                          activePlan: plan,
                          unit: unit,
                        );
                        if (changed == true && context.mounted) {
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Tujuan baru diaktifkan. Target kalori telah disesuaikan.',
                                ),
                              ),
                            );
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
              const SettingsCards(),

              if (pastGoals.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('Riwayat Tujuan Sebelumnya', style: textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                ...pastGoals.take(5).map((oldGoal) {
                  final oldType = GoalType.fromStorage(oldGoal.type);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Icon(
                            Icons.history_rounded,
                            color: semantic.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  oldType.label,
                                  style: textTheme.titleSmall,
                                ),
                                Text(
                                  'Mulai ${AppFormatters.mediumDate(oldGoal.startDate)} • Target ${AppFormatters.weight(oldGoal.targetWeight, unit: unit)}',
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
                  );
                }),
              ],

              const SizedBox(height: AppSpacing.lg),
              AppCard(
                backgroundColor: semantic.surfaceMuted,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.health_and_safety_outlined,
                      color: scheme.secondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.healthDisclaimerTitle,
                            style: textTheme.titleSmall,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            AppStrings.healthDisclaimerBody,
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
            ],
          );
        },
      ),
    );
  }
}

class _MiniProfileBadge extends StatelessWidget {
  const _MiniProfileBadge({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final semantic = context.semanticColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(color: semantic.textSecondary),
        ),
        Text(value, style: textTheme.labelLarge),
      ],
    );
  }
}
