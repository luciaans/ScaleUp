import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/number_parser.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../onboarding/domain/health_calculator.dart';
import '../../../onboarding/domain/user_enums.dart';
import '../../data/goal_repository.dart';
import '../../domain/active_nutrition_plan.dart';

/// Bottom sheet untuk mengganti tujuan berat badan kapan saja.
/// Tujuan lama tetap tersimpan di riwayat, hanya satu tujuan baru yang aktif.
class EditGoalSheet extends ConsumerStatefulWidget {
  const EditGoalSheet({
    super.key,
    required this.activePlan,
    required this.unit,
  });

  final ActiveNutritionPlan activePlan;
  final WeightUnit unit;

  static Future<bool?> show(
    BuildContext context, {
    required ActiveNutritionPlan activePlan,
    required WeightUnit unit,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => EditGoalSheet(activePlan: activePlan, unit: unit),
    );
  }

  @override
  ConsumerState<EditGoalSheet> createState() => _EditGoalSheetState();
}

class _EditGoalSheetState extends ConsumerState<EditGoalSheet> {
  late GoalType _goalType;
  late double _weeklyRate;
  late final TextEditingController _targetController;
  String? _errorText;
  bool _isSaving = false;

  double get _currentWeightKg => widget.activePlan.currentWeightKg;

  @override
  void initState() {
    super.initState();
    _goalType = widget.activePlan.goalType;
    _weeklyRate = widget.activePlan.goal.weeklyRate > 0
        ? widget.activePlan.goal.weeklyRate
        : WeeklyRatePreset.normal.rateKg;
    final initialTargetDisplay = AppFormatters.kgToDisplay(
      widget.activePlan.goal.targetWeight,
      widget.unit,
    );
    _targetController = TextEditingController(
      text: AppFormatters.decimal1(initialTargetDisplay),
    );
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  double? get _parsedTargetKg {
    if (_goalType == GoalType.maintain) return _currentWeightKg;
    final parsedDisplay = NumberParser.tryParseDouble(_targetController.text);
    if (parsedDisplay == null) return null;
    return AppFormatters.displayToKg(parsedDisplay, widget.unit);
  }

  Future<void> _save() async {
    final targetKg = _parsedTargetKg;
    if (targetKg == null) {
      setState(() => _errorText = 'Masukkan angka berat target yang valid.');
      return;
    }

    final validation = HealthCalculator.validateGoal(
      goalType: _goalType,
      currentWeightKg: _currentWeightKg,
      targetWeightKg: targetKg,
      heightCm: widget.activePlan.profile.heightCm,
      weeklyRateKg: _weeklyRate,
    );

    if (!validation.isValid) {
      setState(() => _errorText = validation.errorMessage);
      return;
    }

    final maxRate = HealthCalculator.maxSafeWeeklyRateKg(_currentWeightKg);
    final safeRate = _goalType == GoalType.maintain
        ? 0.0
        : (_weeklyRate > maxRate ? maxRate : _weeklyRate);

    setState(() {
      _errorText = null;
      _isSaving = true;
    });

    try {
      await ref.read(goalRepositoryProvider).setNewGoal(
            type: _goalType,
            startWeight: _currentWeightKg,
            targetWeight: targetKg,
            weeklyRate: safeRate,
          );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final semantic = context.semanticColors;
    final scheme = context.colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    final targetKg = _parsedTargetKg ?? _currentWeightKg;
    final preview = HealthCalculator.calculateCompletePlan(
      gender: widget.activePlan.gender,
      weightKg: _currentWeightKg,
      heightCm: widget.activePlan.profile.heightCm,
      ageYears: widget.activePlan.ageYears,
      activityLevel: widget.activePlan.activityLevel,
      goalType: _goalType,
      targetWeightKg: targetKg,
      requestedWeeklyRateKg: _weeklyRate,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ubah Tujuan Berat Badan', style: textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Riwayat tujuan sebelumnya tetap tersimpan secara aman.',
              style: textTheme.bodySmall?.copyWith(
                color: semantic.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            ...GoalType.values.map((type) {
              final selected = _goalType == type;
              final accent = switch (type) {
                GoalType.lose => semantic.goalLose,
                GoalType.gain => semantic.goalGain,
                GoalType.maintain => semantic.goalMaintain,
              };
              final bg = switch (type) {
                GoalType.lose => semantic.goalLoseContainer,
                GoalType.gain => semantic.goalGainContainer,
                GoalType.maintain => semantic.goalMaintainContainer,
              };

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  onTap: () => setState(() {
                    _goalType = type;
                    _errorText = null;
                  }),
                  backgroundColor: selected ? bg : semantic.cardSurface,
                  borderColor: selected ? accent : scheme.outlineVariant,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Icon(
                        selected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: selected ? accent : semantic.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(type.label, style: textTheme.titleSmall),
                      ),
                    ],
                  ),
                ),
              );
            }),

            if (_goalType != GoalType.maintain) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Berat Target (${widget.unit.label})',
                style: textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: _targetController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  suffixText: widget.unit.label,
                  helperText:
                      'Berat saat ini: ${AppFormatters.weight(_currentWeightKg, unit: widget.unit)}',
                ),
                onChanged: (_) => setState(() => _errorText = null),
              ),
              const SizedBox(height: AppSpacing.md),

              Text('Kecepatan Mingguan', style: textTheme.labelLarge),
              const SizedBox(height: AppSpacing.xs),
              ...WeeklyRatePreset.values.map((preset) {
                final selected = (_weeklyRate - preset.rateKg).abs() < 0.01;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    onTap: () => setState(() {
                      _weeklyRate = preset.rateKg;
                      _errorText = null;
                    }),
                    backgroundColor: selected
                        ? scheme.primaryContainer
                        : semantic.cardSurface,
                    borderColor:
                        selected ? scheme.primary : scheme.outlineVariant,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm + AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selected
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: selected
                              ? scheme.primary
                              : semantic.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(preset.label, style: textTheme.titleSmall),
                              Text(
                                preset.subtitle,
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

            const SizedBox(height: AppSpacing.sm),
            AppCard(
              backgroundColor: semantic.surfaceMuted,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Target Baru: ${AppFormatters.calories(preview.targetCalories)} / hari',
                    style: textTheme.titleSmall?.copyWith(
                      color: scheme.primary,
                    ),
                  ),
                  if (_goalType != GoalType.maintain &&
                      preview.estimatedTargetDate != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Estimasi tercapai: ${AppFormatters.mediumDate(preview.estimatedTargetDate!)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: semantic.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            if (_errorText != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Text(
                  _errorText!,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onErrorContainer,
                  ),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: AppStrings.save,
              isLoading: _isSaving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
