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
import '../../../core/widgets/mochi_companion.dart';
import '../../../core/widgets/primary_button.dart';
import '../../profile/data/goal_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../../settings/data/settings_repository.dart';
import '../../weight/data/weight_repository.dart';
import '../domain/health_calculator.dart';
import '../domain/user_enums.dart';

/// Alur Onboarding "Mochi Neko" (Cozy Sumi-Ink & Milk Paper):
/// (1) Layar Sambutan Hero Maskot Kucing Mochi + catatan kesehatan lembut
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
            // Header: Pada langkah 0 tampil sebagai brand cover header yang manis,
            // pada langkah 1-3 tampil dengan tombol kembali & indikator kapsul jejak kucing.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm + 2,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: _currentStep == 0
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm + 4,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.onSurface,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.pillRadius,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.pets_rounded,
                                size: 14,
                                color: AppColors.amberPop,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                AppStrings.appName,
                                style: textTheme.labelMedium?.copyWith(
                                  color: scheme.surface,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm + 2,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: semantic.cardSurface,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.pillRadius,
                              ),
                              border: Border.all(color: scheme.outlineVariant),
                            ),
                            child: Text(
                              'Langkah 1 dari $_totalSteps',
                              style: textTheme.labelSmall?.copyWith(
                                color: semantic.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: _isSubmitting ? null : _handleBack,
                              tooltip: AppStrings.back,
                              style: IconButton.styleFrom(
                                backgroundColor: semantic.cardSurface,
                                side: BorderSide(color: scheme.outlineVariant),
                              ),
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                            Expanded(
                              child: Text(
                                'Langkah ${_currentStep + 1} dari $_totalSteps',
                                style: textTheme.labelLarge?.copyWith(
                                  color: scheme.onSurface,
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
                        const SizedBox(height: AppSpacing.sm),
                        // 4 Kapsul progres bergaya buku sketsa
                        Row(
                          children: List.generate(_totalSteps, (idx) {
                            final isDoneOrActive = idx <= _currentStep;
                            return Expanded(
                              child: AnimatedContainer(
                                duration: animDuration,
                                height: 7,
                                margin: EdgeInsets.only(
                                  right: idx < _totalSteps - 1 ? 6 : 0,
                                ),
                                decoration: BoxDecoration(
                                  color: isDoneOrActive
                                      ? scheme.primary
                                      : semantic.surfaceMuted,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.pillRadius,
                                  ),
                                ),
                              ),
                            );
                          }),
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
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    _currentStep == 0 ? AppSpacing.sm : AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.lg,
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

            // Area tombol utama bawah (bersih, kapsul Sumi-Ink tanpa panah template)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: PrimaryButton(
                label: buttonLabel,
                isLoading: _isSubmitting,
                onPressed: _handleNext,
                icon: _currentStep == 3 ? Icons.pets_rounded : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Langkah 1: Layar Pembuka (Welcome Hero) dengan Stiker Foto Kucing Meme Interaktif
  Widget _buildWelcomeStep(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final semantic = context.semanticColors;
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: AppSpacing.xs),
        // Stiker Foto Kucing Meme interaktif (ketuk untuk ganti foto meme!)
        const Center(
          child: MochiCompanion(
            pose: MochiPose.welcome,
            size: 196,
            cyclePosesOnTap: true,
            quotes: [
              'Siap hidup sehat bos! (Ketuk stiker kucing buat ganti meme)',
              'Permisi~ Kenalan dulu yuk biar hitungan kalorinya pas!',
              'Makan nasi padang atau salad? Semua bisa dicatat di sini!',
              'Tahan godaan gorengan berlebih, pelan-pelan pasti bisa!',
              'Semangat pantau progres harian... siap-siap POP!',
              'POP!! Mantap banget udah mulai langkah sehat hari ini!',
              'Segar bugar bareng kucing apel, tanpa diet ekstrem~',
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md + 4),
        Text(
          'Pantau Berat & Kalori\nBareng Kucing Meme',
          style: textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            'Aplikasi pencatat berat badan & kalori harian yang bersih, santai, universal, dan ditemani reaksi kucing meme lucu setiap hari.',
            style: textTheme.bodyMedium?.copyWith(
              color: semantic.textSecondary,
              height: 1.48,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.lg - 4),

        // 3 Kartu Kapsul Fitur Universal
        const Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.center,
          children: [
            _StickerPillFeature(
              icon: Icons.rice_bowl_rounded,
              accent: AppColors.royalBlue,
              label: '92+ Menu Lokal',
            ),
            _StickerPillFeature(
              icon: Icons.insights_rounded,
              accent: AppColors.emeraldSafe,
              label: 'Tren 7 Hari Tenang',
            ),
            _StickerPillFeature(
              icon: Icons.pets_rounded,
              accent: AppColors.amberPop,
              label: 'Reaksi Kucing Lucu',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Catatan Kesehatan yang bersih & netral
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: semantic.cardSurface,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primaryContainer,
                ),
                child: Icon(
                  Icons.verified_user_outlined,
                  color: semantic.heroAccent,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.healthDisclaimerTitle,
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppStrings.healthDisclaimerBody,
                      style: textTheme.bodySmall?.copyWith(
                        color: semantic.textSecondary,
                        height: 1.42,
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
        const _MochiStepBanner(
          pose: MochiPose.welcome,
          title: 'Kenalan Dulu, Yuk!',
          subtitle:
              'Data ini dipakai menghitung kebutuhan energi harianmu secara akurat.',
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
            prefixIcon: Icon(Icons.face_rounded),
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
                      isSelected ? scheme.onSurface : scheme.outlineVariant,
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
                            ? scheme.onSurface
                            : semantic.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          g.label,
                          style: textTheme.titleSmall?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
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
              const Icon(Icons.cake_outlined, color: AppColors.sakuraBlush),
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
        const _MochiStepBanner(
          pose: MochiPose.cheer,
          title: 'Aktivitas Harianmu',
          subtitle:
              'Pilih gambaran gerak mingguan yang paling mirip keseharianmu.',
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
                  isSelected ? scheme.onSurface : scheme.outlineVariant,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isSelected
                        ? Icons.pets_rounded
                        : Icons.radio_button_off_rounded,
                    color: isSelected
                        ? AppColors.sakuraBlush
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
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
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
        const _MochiStepBanner(
          pose: MochiPose.think,
          title: 'Pilih Tujuan Sehatmu',
          subtitle:
              'Tenang, tujuan ini bisa kamu ubah kapan saja lewat tab Profil.',
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
              borderColor: isSelected ? scheme.onSurface : scheme.outlineVariant,
              child: Row(
                children: [
                  Container(
                    width: AppSpacing.minTouchTarget,
                    height: AppSpacing.minTouchTarget,
                    decoration: BoxDecoration(
                      color: semantic.cardSurface,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.buttonRadius),
                      border: Border.all(color: scheme.outlineVariant),
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
                    selected ? scheme.onSurface : scheme.outlineVariant,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Icon(
                      selected ? Icons.pets_rounded : Icons.circle_outlined,
                      color: selected
                          ? AppColors.sakuraBlush
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.pets_rounded,
                      size: 16,
                      color: AppColors.sakuraBlush,
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Estimasi Rencana Harianmu',
                      ),
                    ),
                  ],
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
                          color: semantic.heroCardFg,
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
                        color: semantic.heroCardFg,
                      ),
                    ),
                    Text(
                      'Karbo ${plan.carbsGrams}g',
                      style: textTheme.labelMedium?.copyWith(
                        color: semantic.heroCardFg,
                      ),
                    ),
                    Text(
                      'Lemak ${plan.fatGrams}g',
                      style: textTheme.labelMedium?.copyWith(
                        color: semantic.heroCardFg,
                      ),
                    ),
                  ],
                ),
                if (_goalType != GoalType.maintain &&
                    plan.estimatedTargetDate != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Divider(color: scheme.outlineVariant),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const Icon(
                        Icons.event_available_rounded,
                        size: AppSpacing.iconSm,
                        color: AppColors.sakuraBlush,
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

/// Banner kepala langkah dengan maskot Mochi mini untuk langkah 2-4.
class _MochiStepBanner extends StatelessWidget {
  const _MochiStepBanner({
    required this.pose,
    required this.title,
    required this.subtitle,
  });

  final MochiPose pose;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final semantic = context.semanticColors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        MochiCompanion(
          pose: pose,
          size: 76,
          showFramedBadge: true,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: semantic.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Kapsul stiker fitur ringkas untuk layar sambutan Mochi.
class _StickerPillFeature extends StatelessWidget {
  const _StickerPillFeature({
    required this.icon,
    required this.accent,
    required this.label,
  });

  final IconData icon;
  final Color accent;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = context.colorScheme;
    final semantic = context.semanticColors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 4,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: semantic.cardSurface,
        borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow,
            offset: const Offset(0, 3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: textTheme.labelMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
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
            isError ? Icons.info_outline_rounded : Icons.pets_rounded,
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
