import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils_ext.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/number_parser.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../data/database/app_database.dart';
import '../../../onboarding/domain/health_calculator.dart';
import '../../../onboarding/domain/user_enums.dart';
import '../../data/profile_repository.dart';

/// Bottom sheet untuk mengedit data profil & tingkat aktivitas kapan saja.
class EditProfileSheet extends ConsumerStatefulWidget {
  const EditProfileSheet({
    super.key,
    required this.profile,
  });

  final UserProfile profile;

  static Future<bool?> show(BuildContext context, UserProfile profile) {
    return showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => EditProfileSheet(profile: profile),
    );
  }

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _heightController;
  late Gender _gender;
  late DateTime _birthDate;
  late ActivityLevel _activityLevel;
  String? _errorText;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _heightController = TextEditingController(
      text: AppFormatters.compactDecimal(widget.profile.heightCm),
    );
    _gender = Gender.fromStorage(widget.profile.gender);
    _birthDate = widget.profile.birthDate;
    _activityLevel = ActivityLevel.fromStorage(widget.profile.activityLevel);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = AppDateUtils.today();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate.isAfter(now) ? now : _birthDate,
      firstDate: DateTime(now.year - AppConstants.maxAgeYears, 1, 1),
      lastDate: now,
      helpText: 'Pilih Tanggal Lahir',
      cancelText: AppStrings.cancel,
      confirmText: 'Pilih',
    );
    if (picked != null && mounted) {
      setState(() {
        _birthDate = AppDateUtils.dateOnly(picked);
        _errorText = HealthCalculator.validateBirthDate(_birthDate);
      });
    }
  }

  Future<void> _save() async {
    final nameErr = HealthCalculator.validateName(_nameController.text);
    if (nameErr != null) {
      setState(() => _errorText = nameErr);
      return;
    }

    final dobErr = HealthCalculator.validateBirthDate(_birthDate);
    if (dobErr != null) {
      setState(() => _errorText = dobErr);
      return;
    }

    final heightVal = NumberParser.tryParseDouble(_heightController.text);
    final heightErr = HealthCalculator.validateHeightCm(heightVal);
    if (heightErr != null) {
      setState(() => _errorText = heightErr);
      return;
    }

    setState(() {
      _errorText = null;
      _isSaving = true;
    });

    try {
      await ref.read(profileRepositoryProvider).saveProfile(
            name: _nameController.text.trim(),
            gender: _gender,
            birthDate: _birthDate,
            heightCm: heightVal!,
            activityLevel: _activityLevel,
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
    final age = AppDateUtils.calculateAgeYears(_birthDate);

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
            Text('Ubah Data Profil', style: textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Target kalori harian akan otomatis disesuaikan bila tinggi atau aktivitas berubah.',
              style: textTheme.bodySmall?.copyWith(
                color: semantic.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Text('Nama Panggilan', style: textTheme.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Text('Jenis Kelamin', style: textTheme.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: Gender.values.map((g) {
                final selected = _gender == g;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: g == Gender.male ? AppSpacing.sm : 0,
                      left: g == Gender.female ? AppSpacing.sm : 0,
                    ),
                    child: AppCard(
                      onTap: () => setState(() => _gender = g),
                      backgroundColor: selected
                          ? scheme.primaryContainer
                          : semantic.cardSurface,
                      borderColor:
                          selected ? scheme.primary : scheme.outlineVariant,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm + AppSpacing.xs,
                      ),
                      child: Center(
                        child: Text(
                          g.label,
                          style: textTheme.titleSmall?.copyWith(
                            color: selected
                                ? scheme.onPrimaryContainer
                                : scheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),

            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tanggal Lahir', style: textTheme.labelLarge),
                      const SizedBox(height: AppSpacing.xs),
                      AppCard(
                        onTap: _pickBirthDate,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${AppFormatters.mediumDate(_birthDate)} ($age th)',
                                style: textTheme.bodyMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              Icons.calendar_today_rounded,
                              size: AppSpacing.iconSm,
                              color: scheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tinggi (cm)', style: textTheme.labelLarge),
                      const SizedBox(height: AppSpacing.xs),
                      TextField(
                        controller: _heightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          suffixText: AppStrings.unitCm,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            Text('Tingkat Aktivitas', style: textTheme.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            ...ActivityLevel.values.map((level) {
              final selected = _activityLevel == level;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  onTap: () => setState(() => _activityLevel = level),
                  backgroundColor: selected
                      ? scheme.primaryContainer
                      : semantic.cardSurface,
                  borderColor:
                      selected ? scheme.primary : scheme.outlineVariant,
                  padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
                  child: Row(
                    children: [
                      Icon(
                        selected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: selected
                            ? scheme.primary
                            : semantic.textSecondary,
                        size: AppSpacing.iconMd,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(level.label, style: textTheme.titleSmall),
                            Text(
                              level.description,
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
