import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
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

/// Layar Profil, Identitas Metabolik, Tujuan & Pengaturan bergaya Bento (Nixtio).
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
            SkeletonBox(height: 170),
            SizedBox(height: AppSpacing.md),
            SkeletonBox(height: 185),
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

          final pastGoals = (historyAsync.value ?? const [])
              .where((g) => !g.isActive)
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.bottomNavClearance,
            ),
            children: [
              // HERO OBSIDIAN IDENTITY & METABOLIC CARD
              HeroBentoCard(
                accentGlowColor: semantic.heroAccent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: scheme.primaryContainer,
                            border: Border.all(
                              color: scheme.onSurface,
                              width: AppSpacing.borderMedium,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            plan.profile.name.characters.first.toUpperCase(),
                            style: textTheme.headlineSmall?.copyWith(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w800,
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
                                style: textTheme.titleLarge?.copyWith(
                                  color: semantic.heroCardFg,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${plan.gender.label} • ${plan.ageYears} th • ${AppFormatters.compactDecimal(plan.profile.heightCm)} cm',
                                style: textTheme.bodySmall?.copyWith(
                                  color: semantic.heroCardMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            backgroundColor: semantic.heroCardSurface,
                            foregroundColor: semantic.heroCardFg,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm + 4,
                              vertical: AppSpacing.xs,
                            ),
                          ),
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
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text(AppStrings.edit),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md + 2),
                    Row(
                      children: [
                        Expanded(
                          child: _DarkProfilePod(
                            label: 'Aktivitas',
                            value: plan.activityLevel.label,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _DarkProfilePod(
                            label: 'BMR',
                            value: AppFormatters.calories(plan.caloriePlan.bmr),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _DarkProfilePod(
                            label: 'TDEE',
                            value:
                                AppFormatters.calories(plan.caloriePlan.tdee),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Kartu Tujuan Aktif Bento
              AppCard(
                borderColor: goalAccent.withValues(alpha: 0.35),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm + 4,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: goalAccent.withValues(alpha: 0.14),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.pillRadius),
                          ),
                          child: Text(
                            'Tujuan Aktif',
                            style: textTheme.labelMedium?.copyWith(
                              color: goalAccent,
                              fontWeight: FontWeight.w700,
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
                    const SizedBox(height: AppSpacing.sm + 4),
                    Text(
                      plan.goalType.label,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      plan.goalType == GoalType.maintain
                          ? 'Menjaga di sekitar ${AppFormatters.weight(plan.goal.targetWeight, unit: unit)} • ${AppFormatters.calories(plan.caloriePlan.targetCalories)}/hari'
                          : '${AppFormatters.weight(plan.goal.startWeight, unit: unit)} menuju ${AppFormatters.weight(plan.goal.targetWeight, unit: unit)}',
                      style: textTheme.bodyMedium,
                    ),
                    if (plan.goalType != GoalType.maintain) ...[
                      const SizedBox(height: AppSpacing.xxs),
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

class _DarkProfilePod extends StatelessWidget {
  const _DarkProfilePod({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: semantic.heroCardSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: semantic.heroCardMuted,
              fontSize: 10.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyles.tabularValue(
                context,
                fontSize: 13.5,
                color: semantic.heroCardFg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
