import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils_ext.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/number_parser.dart';
import '../../../core/utils/reduce_motion.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../profile/data/goal_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../../settings/data/settings_repository.dart';
import '../../weight/data/weight_repository.dart';
import '../domain/health_calculator.dart';
import '../domain/user_enums.dart';

/// Alur Onboarding 4 langkah dengan progress indicator:
/// (1) Selamat datang + disclaimer kesehatan
/// (2) Data diri + validasi usia >= 18 thn, tinggi 100-250 cm, berat 25-300 kg
/// (3) Tingkat aktivitas dengan penjelasan tiap pilihan
/// (4) Pilih tujuan + pratinjau target kalori & estimasi tanggal tercapai
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const int _totalSteps = 4;
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Step 2: Data diri
  final _nameController = TextEditingController();
  final _heightController = TextEditingController(text: '165');
  final _weightController = TextEditingController(text: '68');
  Gender _gender = Gender.male;
  DateTime? _birthDate = DateTime(1998, 6, 15);
  String? _step2Error;

  // Step 3: Tingkat aktivitas
  ActivityLevel _activityLevel = ActivityLevel.light;

  // Step 4: Pilihan tujuan
  GoalType _goalType = GoalType.lose;
  final _targetWeightController = TextEditingController(text: '62');
  double _weeklyRate = AppConstants.rateNormal;
  String? _step4Error;

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  double get _parsedHeight =>
      NumberParser.tryParseDouble(_heightController.text) ?? 165.0;
  double get _parsedWeight =>
      NumberParser.tryParseDouble(_weightController.text) ?? 68.0;
  double get _parsedTargetWeight =>
      NumberParser.tryParseDouble(_targetWeightController.text) ?? _parsedWeight;

  Future<void> _pickBirthDate() async {
    final now = AppDateUtils.today();
    final initial = _birthDate ?? DateTime(now.year - 25, 6, 15);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(now.year - AppConstants.maxAgeYears, 1, 1),
      lastDate: now,
      helpText: 'Pilih Tanggal Lahir',
      cancelText: AppStrings.cancel,
      confirmText: 'Pilih',
    );
    if (picked != null && mounted) {
      setState(() {
        _birthDate = AppDateUtils.dateOnly(picked);
        _step2Error = HealthCalculator.validateBirthDate(_birthDate);
      });
    }
  }

  bool _validateStep2() {
    final nameErr = HealthCalculator.validateName(_nameController.text);
    if (nameErr != null) {
      setState(() => _step2Error = nameErr);
      return false;
    }

    final dobErr = HealthCalculator.validateBirthDate(_birthDate);
    if (dobErr != null) {
      setState(() => _step2Error = dobErr);
      return false;
    }

    final heightVal = NumberParser.tryParseDouble(_heightController.text);
    final heightErr = HealthCalculator.validateHeightCm(heightVal);
    if (heightErr != null) {
      setState(() => _step2Error = heightErr);
      return false;
    }

    final weightVal = NumberParser.tryParseDouble(_weightController.text);
    final weightErr = HealthCalculator.validateWeightKg(weightVal);
    if (weightErr != null) {
      setState(() => _step2Error = weightErr);
      return false;
    }

    setState(() => _step2Error = null);

    // Sesuaikan saran berat target awal jika pengguna belum mengubahnya secara kompatibel
    if (_goalType == GoalType.lose && _parsedTargetWeight >= weightVal!) {
      final minSafe = HealthCalculator.minHealthyWeightForHeight(heightVal!);
      final suggested = (weightVal - 4.0).clamp(minSafe, weightVal - 0.5);
      _targetWeightController.text = AppFormatters.decimal1(suggested);
    } else if (_goalType == GoalType.gain &&
        _parsedTargetWeight <= weightVal!) {
      _targetWeightController.text = AppFormatters.decimal1(weightVal + 4.0);
    }
    return true;
  }

  bool _validateStep4() {
    final targetVal = _goalType == GoalType.maintain
        ? _parsedWeight
        : NumberParser.tryParseDouble(_targetWeightController.text);
    if (targetVal == null) {
      setState(() => _step4Error = 'Masukkan berat target yang valid.');
      return false;
    }

    final validation = HealthCalculator.validateGoal(
      goalType: _goalType,
      currentWeightKg: _parsedWeight,
      targetWeightKg: targetVal,
      heightCm: _parsedHeight,
      weeklyRateKg: _weeklyRate,
    );

    if (!validation.isValid) {
      setState(() => _step4Error = validation.errorMessage);
      return false;
    }

    setState(() => _step4Error = null);
    return true;
  }

  Future<void> _handleNext() async {
    FocusScope.of(context).unfocus();
    if (_currentStep == 0) {
      setState(() => _currentStep = 1);
      return;
    }
    if (_currentStep == 1) {
      if (_validateStep2()) {
        setState(() => _currentStep = 2);
      }
      return;
    }
    if (_currentStep == 2) {
      setState(() => _currentStep = 3);
      return;
    }
    if (_currentStep == 3) {
      if (!_validateStep4()) return;
      await _finishOnboarding();
    }
  }

  void _handleBack() {
    FocusScope.of(context).unfocus();
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  Future<void> _finishOnboarding() async {
    setState(() => _isSubmitting = true);
    try {
      final heightCm = _parsedHeight;
      final weightKg = _parsedWeight;
      final targetKg =
          _goalType == GoalType.maintain ? weightKg : _parsedTargetWeight;
      final maxRate = HealthCalculator.maxSafeWeeklyRateKg(weightKg);
      final savedRate = _goalType == GoalType.maintain
          ? 0.0
          : (_weeklyRate > maxRate ? maxRate : _weeklyRate);

      await ref.read(weightRepositoryProvider).upsertWeight(
            date: AppDateUtils.today(),
            weightKg: weightKg,
            note: 'Berat awal',
          );
      await ref.read(profileRepositoryProvider).saveProfile(
            name: _nameController.text.trim(),
            gender: _gender,
            birthDate: _birthDate!,
            heightCm: heightCm,
            activityLevel: _activityLevel,
          );
      await ref.read(goalRepositoryProvider).setNewGoal(
            type: _goalType,
            startWeight: weightKg,
            targetWeight: targetKg,
            weeklyRate: savedRate,
          );
      await ref.read(settingsRepositoryProvider).setOnboardingComplete(true);

      if (mounted) {
        context.go(AppRoutes.home);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final semantic = context.semanticColors;
    final scheme = context.colorScheme;
    final progress = (_currentStep + 1) / _totalSteps;
    final animDuration = MotionUtils.duration(context, AppSpacing.animNormal);

    final buttonLabel = switch (_currentStep) {
      0 => AppStrings.startNow,
      3 => AppStrings.finishSetup,
      _ => AppStrings.next,
    };

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header progress indicator 4 langkah
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (_currentStep > 0)
                        IconButton(
                          onPressed: _isSubmitting ? null : _handleBack,
                          tooltip: AppStrings.back,
                          icon: const Icon(Icons.arrow_back_rounded),
                        )
                      else
                        const SizedBox(
                          width: AppSpacing.minTouchTarget,
                          height: AppSpacing.minTouchTarget,
                        ),
                      Expanded(
                        child: Text(
                          'Langkah ${_currentStep + 1} dari $_totalSteps',
                          style: textTheme.labelLarge?.copyWith(
                            color: semantic.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(
                        width: AppSpacing.minTouchTarget,
                        height: AppSpacing.minTouchTarget,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.25, end: progress),
                      duration: animDuration,
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return LinearProgressIndicator(
                          value: value,
                          minHeight: AppSpacing.sm,
                          backgroundColor: semantic.surfaceMuted,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            scheme.primary,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Isi langkah aktif
            Expanded(
              child: AnimatedSwitcher(
                duration: animDuration,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                child: SingleChildScrollView(
                  key: ValueKey<int>(_currentStep),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
                  child: switch (_currentStep) {
                    0 => _buildWelcomeStep(context),
                    1 => _buildProfileStep(context),
                    2 => _buildActivityStep(context),
                    _ => _buildGoalStep(context),
                  },
                ),
              ),
            ),

            // Area tombol bawah ramah satu tangan
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: semantic.cardSurface,
                border: Border(
                  top: BorderSide(color: scheme.outlineVariant),
                ),
              ),
              child: PrimaryButton(
                label: buttonLabel,
                isLoading: _isSubmitting,
                onPressed: _handleNext,
                icon: _currentStep == 3
                    ? Icons.check_circle_outline_rounded
                    : Icons.arrow_forward_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeStep(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final semantic = context.semanticColors;
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HeroBentoCard(
          accentGlowColor: semantic.heroAccent,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + 4,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: semantic.heroCardSurface,
                  borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                ),
                child: Text(
                  'Smart Nutrition & Weight Tracker',
                  style: textTheme.labelSmall?.copyWith(
                    color: semantic.heroAccent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Semantics(
                label: 'Logo ScaleUp',
                image: true,
                child: Image.asset(
                  'assets/branding/scaleup_logo.png',
                  width: 84,
                  height: 84,
                  errorBuilder: (_, _, _) => Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: semantic.heroCardSurface,
                    ),
                    child: Icon(
                      Icons.trending_up_rounded,
                      size: AppSpacing.iconHero,
                      color: semantic.heroAccent,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Selamat Datang di ${AppStrings.appName}',
                style: textTheme.headlineMedium?.copyWith(
                  color: semantic.heroCardFg,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                AppStrings.appTagline,
                style: textTheme.bodyMedium?.copyWith(
                  color: semantic.heroCardMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _FeatureHighlightRow(
          icon: Icons.monitor_weight_rounded,
          color: scheme.secondary,
          title: 'Pantau Berat Tanpa Cemas',
          subtitle:
              'Dilengkapi garis tren rata-rata 7 hari agar fluktuasi harian tidak membingungkan.',
        ),
        const SizedBox(height: AppSpacing.md),
        _FeatureHighlightRow(
          icon: Icons.restaurant_menu_rounded,
          color: scheme.tertiary,
          title: 'Database Makanan Indonesia',
          subtitle:
              'Catat nasi uduk, tempe, soto, hingga kopi susu lengkap dengan kalori dan makro.',
        ),
        const SizedBox(height: AppSpacing.md),
        _FeatureHighlightRow(
          icon: Icons.favorite_rounded,
          color: scheme.primary,
          title: 'Aman & Berbasis Kesehatan',
          subtitle:
              'Target disesuaikan secara suportif mengikuti batas kalori aman dan laju realistis.',
        ),
        const SizedBox(height: AppSpacing.xl),
        AppCard(
          backgroundColor: scheme.secondaryContainer.withValues(alpha: 0.45),
          borderColor: scheme.secondary.withValues(alpha: 0.3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.health_and_safety_outlined,
                color: scheme.secondary,
                size: AppSpacing.iconMd,
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
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      AppStrings.healthDisclaimerBody,
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
      ],
    );
  }

  Widget _buildProfileStep(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final semantic = context.semanticColors;
    final scheme = context.colorScheme;
    final age = _birthDate != null
        ? AppDateUtils.calculateAgeYears(_birthDate!)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kenalan Dulu, Yuk!', style: textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Data ini digunakan untuk menghitung kebutuhan energi harianmu secara akurat.',
          style: textTheme.bodyMedium?.copyWith(color: semantic.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),

        Text('Nama Panggilan', style: textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          key: const Key('onboarding_name_field'),
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            hintText: 'Contoh: Budi atau Sari',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
          onChanged: (_) {
            if (_step2Error != null) setState(() => _step2Error = null);
          },
        ),
        const SizedBox(height: AppSpacing.md),

        Text('Jenis Kelamin', style: textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: Gender.values.map((g) {
            final isSelected = _gender == g;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: g == Gender.male ? AppSpacing.sm : 0,
                  left: g == Gender.female ? AppSpacing.sm : 0,
                ),
                child: AppCard(
                  onTap: () => setState(() => _gender = g),
                  backgroundColor: isSelected
                      ? scheme.primaryContainer
                      : semantic.cardSurface,
                  borderColor:
                      isSelected ? scheme.primary : scheme.outlineVariant,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                    horizontal: AppSpacing.sm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        g == Gender.male
                            ? Icons.male_rounded
                            : Icons.female_rounded,
                        color: isSelected
                            ? scheme.primary
                            : semantic.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          g.label,
                          style: textTheme.titleSmall?.copyWith(
                            color: isSelected
                                ? scheme.onPrimaryContainer
                                : scheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.md),

        Text('Tanggal Lahir', style: textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          onTap: _pickBirthDate,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          semanticLabel: 'Pilih tanggal lahir',
          child: Row(
            children: [
              Icon(Icons.cake_outlined, color: scheme.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  _birthDate != null
                      ? '${AppFormatters.mediumDate(_birthDate!)} ($age tahun)'
                      : 'Pilih tanggal lahir',
                  style: textTheme.bodyLarge,
                ),
              ),
              Text(
                AppStrings.edit,
                style: textTheme.labelLarge?.copyWith(color: scheme.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tinggi (cm)', style: textTheme.labelLarge),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    key: const Key('onboarding_height_field'),
                    controller: _heightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      hintText: '165',
                      suffixText: AppStrings.unitCm,
                    ),
                    onChanged: (_) {
                      if (_step2Error != null) {
                        setState(() => _step2Error = null);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Berat Sekarang (kg)', style: textTheme.labelLarge),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    key: const Key('onboarding_weight_field'),
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      hintText: '68,0',
                      suffixText: AppStrings.unitKg,
                    ),
                    onChanged: (_) {
                      if (_step2Error != null) {
                        setState(() => _step2Error = null);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),

        if (_step2Error != null) ...[
          const SizedBox(height: AppSpacing.md),
          _ValidationBanner(
            message: _step2Error!,
            isError: true,
          ),
        ],
      ],
    );
  }

  Widget _buildActivityStep(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final semantic = context.semanticColors;
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tingkat Aktivitas Harian', style: textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Pilih gambaran aktivitas mingguan yang paling mendekati keseharianmu.',
          style: textTheme.bodyMedium?.copyWith(color: semantic.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        ...ActivityLevel.values.map((level) {
          final isSelected = _activityLevel == level;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm + AppSpacing.xs),
            child: AppCard(
              onTap: () => setState(() => _activityLevel = level),
              backgroundColor: isSelected
                  ? scheme.primaryContainer
                  : semantic.cardSurface,
              borderColor:
                  isSelected ? scheme.primary : scheme.outlineVariant,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: isSelected
                        ? scheme.primary
                        : semantic.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          level.label,
                          style: textTheme.titleMedium?.copyWith(
                            color: isSelected
                                ? scheme.onPrimaryContainer
                                : scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          level.description,
                          style: textTheme.bodySmall?.copyWith(
                            color: isSelected
                                ? scheme.onPrimaryContainer
                                : semantic.textSecondary,
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
    );
  }

  Widget _buildGoalStep(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final semantic = context.semanticColors;
    final scheme = context.colorScheme;

    final currentWeight = _parsedWeight;
    final heightCm = _parsedHeight;
    final ageYears = _birthDate != null
        ? AppDateUtils.calculateAgeYears(_birthDate!)
        : 25;
    final targetWeight =
        _goalType == GoalType.maintain ? currentWeight : _parsedTargetWeight;

    final validation = HealthCalculator.validateGoal(
      goalType: _goalType,
      currentWeightKg: currentWeight,
      targetWeightKg: targetWeight,
      heightCm: heightCm,
      weeklyRateKg: _weeklyRate,
    );

    final plan = HealthCalculator.calculateCompletePlan(
      gender: _gender,
      weightKg: currentWeight,
      heightCm: heightCm,
      ageYears: ageYears,
      activityLevel: _activityLevel,
      goalType: _goalType,
      targetWeightKg: targetWeight,
      requestedWeeklyRateKg: _weeklyRate,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pilih Tujuan Sehatmu', style: textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Kamu selalu bisa mengganti tujuan ini kapan saja melalui menu Profil.',
          style: textTheme.bodyMedium?.copyWith(color: semantic.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),

        ...GoalType.values.map((type) {
          final isSelected = _goalType == type;
          final accent = switch (type) {
            GoalType.lose => semantic.goalLose,
            GoalType.gain => semantic.goalGain,
            GoalType.maintain => semantic.goalMaintain,
          };
          final accentBg = switch (type) {
            GoalType.lose => semantic.goalLoseContainer,
            GoalType.gain => semantic.goalGainContainer,
            GoalType.maintain => semantic.goalMaintainContainer,
          };
          final icon = switch (type) {
            GoalType.lose => Icons.south_east_rounded,
            GoalType.gain => Icons.north_east_rounded,
            GoalType.maintain => Icons.balance_rounded,
          };

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm + AppSpacing.xs),
            child: AppCard(
              onTap: () {
                setState(() {
                  _goalType = type;
                  _step4Error = null;
                  if (type == GoalType.lose &&
                      _parsedTargetWeight >= currentWeight) {
                    final minSafe =
                        HealthCalculator.minHealthyWeightForHeight(heightCm);
                    final suggested = (currentWeight - 4.0)
                        .clamp(minSafe, currentWeight - 0.5);
                    _targetWeightController.text =
                        AppFormatters.decimal1(suggested);
                  } else if (type == GoalType.gain &&
                      _parsedTargetWeight <= currentWeight) {
                    _targetWeightController.text =
                        AppFormatters.decimal1(currentWeight + 4.0);
                  }
                });
              },
              backgroundColor: isSelected ? accentBg : semantic.cardSurface,
              borderColor: isSelected ? accent : scheme.outlineVariant,
              child: Row(
                children: [
                  Container(
                    width: AppSpacing.minTouchTarget,
                    height: AppSpacing.minTouchTarget,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.16),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.buttonRadius),
                    ),
                    child: Icon(icon, color: accent),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(type.label, style: textTheme.titleMedium),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          type.description,
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

        if (_goalType != GoalType.maintain) ...[
          const SizedBox(height: AppSpacing.sm),
          Text('Berat Target (kg)', style: textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            key: const Key('onboarding_target_weight_field'),
            controller: _targetWeightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: AppFormatters.decimal1(currentWeight - 4),
              suffixText: AppStrings.unitKg,
              helperText: _goalType == GoalType.lose
                  ? 'Batas sehat minimal (BMI 18,5): ${AppFormatters.decimal1(HealthCalculator.minHealthyWeightForHeight(heightCm))} kg'
                  : 'Saat ini: ${AppFormatters.weight(currentWeight)}',
            ),
            onChanged: (_) => setState(() => _step4Error = null),
          ),
          const SizedBox(height: AppSpacing.md),

          Text('Kecepatan Perubahan', style: textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          ...WeeklyRatePreset.values.map((preset) {
            final selected = (_weeklyRate - preset.rateKg).abs() < 0.01;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                onTap: () => setState(() {
                  _weeklyRate = preset.rateKg;
                  _step4Error = null;
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
                      color:
                          selected ? scheme.primary : semantic.textSecondary,
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

        if (_step4Error != null || !validation.isValid) ...[
          const SizedBox(height: AppSpacing.sm),
          _ValidationBanner(
            message: _step4Error ?? validation.errorMessage ?? '',
            isError: true,
          ),
        ] else if (validation.warningMessage != null ||
            plan.wasClampedToMinCalories) ...[
          const SizedBox(height: AppSpacing.sm),
          _ValidationBanner(
            message: plan.wasClampedToMinCalories
                ? 'Target kalori dijaga pada batas aman minimum ${plan.targetCalories} kkal/hari agar kebutuhan nutrisi harianmu tetap terpenuhi.'
                : validation.warningMessage!,
            isError: false,
          ),
        ],

        const SizedBox(height: AppSpacing.md),
        if (validation.isValid)
          HeroBentoCard(
            accentGlowColor: semantic.heroAccent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimasi Rencana Harianmu',
                  style: textTheme.titleMedium?.copyWith(
                    color: semantic.heroCardFg,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        AppFormatters.integer(plan.targetCalories),
                        style: AppTextStyles.heroNumber(
                          context,
                          fontSize: AppSpacing.heroNumberMd,
                          color: semantic.heroAccent,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '${AppStrings.unitKcal} / hari',
                        style: textTheme.titleSmall?.copyWith(
                          color: semantic.heroCardMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.xs,
                  children: [
                    Text(
                      'Protein ${plan.proteinGrams}g',
                      style: textTheme.labelMedium?.copyWith(
                        color: semantic.proteinColor,
                      ),
                    ),
                    Text(
                      'Karbo ${plan.carbsGrams}g',
                      style: textTheme.labelMedium?.copyWith(
                        color: semantic.heroAccent,
                      ),
                    ),
                    Text(
                      'Lemak ${plan.fatGrams}g',
                      style: textTheme.labelMedium?.copyWith(
                        color: semantic.fatColor,
                      ),
                    ),
                  ],
                ),
                if (_goalType != GoalType.maintain &&
                    plan.estimatedTargetDate != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Divider(color: semantic.dockBorder),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Icon(
                        Icons.event_available_rounded,
                        size: AppSpacing.iconSm,
                        color: semantic.heroAccent,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Estimasi tercapai: ${AppFormatters.mediumDate(plan.estimatedTargetDate!)}',
                          style: textTheme.labelLarge?.copyWith(
                            color: semantic.heroCardFg,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _FeatureHighlightRow extends StatelessWidget {
  const _FeatureHighlightRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final semantic = context.semanticColors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: AppSpacing.minTouchTarget,
          height: AppSpacing.minTouchTarget,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: semantic.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ValidationBanner extends StatelessWidget {
  const _ValidationBanner({
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bg = isError ? scheme.errorContainer : scheme.tertiaryContainer;
    final fg = isError ? scheme.onErrorContainer : scheme.onTertiaryContainer;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.info_outline_rounded : Icons.lightbulb_outline,
            color: fg,
            size: AppSpacing.iconMd,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: textTheme.bodySmall?.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}
