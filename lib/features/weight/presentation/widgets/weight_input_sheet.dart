import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_utils_ext.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/reduce_motion.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../data/database/app_database.dart';
import '../../../settings/data/settings_repository.dart';
import '../../data/weight_repository.dart';

/// Bottom sheet input cepat berat badan:
/// - Angka besar di tengah (tabular figures)
/// - Tombol -/+ 0,1 (kg/lb)
/// - Slider halus
/// - Pilihan tanggal (hari ini / tanggal sebelumnya)
/// - Catatan opsional & tombol Simpan lebar penuh + animasi centang saat berhasil
class WeightInputSheet extends ConsumerStatefulWidget {
  const WeightInputSheet({
    super.key,
    this.initialEntry,
    this.fallbackWeightKg,
  });

  final WeightEntry? initialEntry;
  final double? fallbackWeightKg;

  static Future<bool?> show(
    BuildContext context, {
    WeightEntry? initialEntry,
    double? fallbackWeightKg,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => WeightInputSheet(
        initialEntry: initialEntry,
        fallbackWeightKg: fallbackWeightKg,
      ),
    );
  }

  @override
  ConsumerState<WeightInputSheet> createState() => _WeightInputSheetState();
}

class _WeightInputSheetState extends ConsumerState<WeightInputSheet> {
  late DateTime _selectedDate;
  late double _weightKg;
  late final TextEditingController _noteController;
  bool _isSaving = false;
  bool _showSuccessCheck = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = AppDateUtils.dateOnly(
      widget.initialEntry?.date ?? AppDateUtils.today(),
    );
    _weightKg = widget.initialEntry?.weightKg ??
        widget.fallbackWeightKg ??
        68.0;
    _noteController = TextEditingController(
      text: widget.initialEntry?.note ?? '',
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _stepWeight(double deltaDisplay, WeightUnit unit) {
    final currentDisplay = AppFormatters.kgToDisplay(_weightKg, unit);
    final nextDisplay = ((currentDisplay + deltaDisplay) * 10).round() / 10.0;
    final nextKg = AppFormatters.displayToKg(nextDisplay, unit).clamp(
      AppConstants.minWeightKg,
      AppConstants.maxWeightKg,
    );
    MotionUtils.selectionClick();
    setState(() => _weightKg = nextKg);
  }

  Future<void> _pickDate(List<WeightEntry> existingEntries) async {
    final today = AppDateUtils.today();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(today) ? today : _selectedDate,
      firstDate: DateTime(today.year - 5, 1, 1),
      lastDate: today,
      helpText: 'Pilih Tanggal Pencatatan',
      cancelText: AppStrings.cancel,
      confirmText: 'Pilih',
    );
    if (picked == null || !mounted) return;

    final normalized = AppDateUtils.dateOnly(picked);
    final match = existingEntries
        .where((e) => AppDateUtils.isSameDay(e.date, normalized))
        .firstOrNull;

    setState(() {
      _selectedDate = normalized;
      if (match != null) {
        _weightKg = match.weightKg;
        _noteController.text = match.note ?? '';
      }
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final recalculated = await ref.read(weightRepositoryProvider).upsertWeight(
            date: _selectedDate,
            weightKg: (_weightKg * 10).round() / 10.0,
            note: _noteController.text,
          );

      if (!mounted) return;
      if (!MotionUtils.shouldReduceMotion(context)) {
        setState(() => _showSuccessCheck = true);
        await Future<void>.delayed(AppSpacing.animNormal);
      }

      if (!mounted) return;
      Navigator.of(context).pop(recalculated);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final unit = ref.watch(appWeightUnitProvider).value ?? WeightUnit.kg;
    final entries = ref.watch(weightEntriesDescProvider).value ?? const [];
    final latest = ref.watch(latestWeightEntryProvider).value;

    // Jika dibuka dari Quick Add tanpa initialEntry & tanpa fallback, gunakan berat terbaru bila tersedia
    if (widget.initialEntry == null &&
        widget.fallbackWeightKg == null &&
        latest != null &&
        (_weightKg - 68.0).abs() < 0.001 &&
        !_isSaving) {
      final todayMatch = entries
          .where((e) => AppDateUtils.isSameDay(e.date, _selectedDate))
          .firstOrNull;
      _weightKg = todayMatch?.weightKg ?? latest.weightKg;
    }

    final existingForDate = entries
        .where((e) => AppDateUtils.isSameDay(e.date, _selectedDate))
        .firstOrNull;

    final displayVal = AppFormatters.kgToDisplay(_weightKg, unit);
    final minSliderKg = (_weightKg - 15.0).clamp(
      AppConstants.minWeightKg,
      AppConstants.maxWeightKg - 5.0,
    );
    final maxSliderKg = (_weightKg + 15.0).clamp(
      minSliderKg + 5.0,
      AppConstants.maxWeightKg,
    );

    final textTheme = Theme.of(context).textTheme;
    final semantic = context.semanticColors;
    final scheme = context.colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: _showSuccessCheck
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: semantic.successContainer,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: AppSpacing.iconLg + AppSpacing.sm,
                          color: semantic.success,
                        ),
                      )
                          .animate()
                          .scale(
                            begin: const Offset(0.6, 0.6),
                            end: const Offset(1.0, 1.0),
                            duration: AppSpacing.animFast,
                            curve: Curves.easeOutCubic,
                          )
                          .fadeIn(duration: AppSpacing.animFast),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Berat Tersimpan!',
                        style: textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          existingForDate != null
                              ? 'Perbarui Berat Badan'
                              : 'Catat Berat Badan',
                          style: textTheme.headlineSmall,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _pickDate(entries),
                        icon: const Icon(
                          Icons.calendar_today_rounded,
                          size: AppSpacing.iconSm,
                        ),
                        label: Text(AppFormatters.relativeDate(_selectedDate)),
                      ),
                    ],
                  ),
                  if (existingForDate != null)
                    Text(
                      'Sudah ada catatan pada tanggal ini — menyimpan akan memperbaruinya.',
                      style: textTheme.bodySmall?.copyWith(
                        color: semantic.textSecondary,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),

                  // Kontrol angka besar di tengah + tombol -/+ 0,1
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StepCircleButton(
                        icon: Icons.remove_rounded,
                        semanticLabel: 'Kurangi 0,1 ${unit.label}',
                        onTap: () => _stepWeight(-0.1, unit),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                AppFormatters.decimal1(displayVal),
                                key: const Key('weight_sheet_hero_value'),
                                style: AppTextStyles.heroNumber(
                                  context,
                                  fontSize: AppSpacing.heroNumberLg,
                                  color: scheme.secondary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                unit.label,
                                style: textTheme.titleLarge?.copyWith(
                                  color: semantic.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      _StepCircleButton(
                        icon: Icons.add_rounded,
                        semanticLabel: 'Tambah 0,1 ${unit.label}',
                        onTap: () => _stepWeight(0.1, unit),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Slider presisi 0,1 kg
                  AppCard(
                    backgroundColor: semantic.surfaceMuted,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    child: Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: scheme.secondary,
                            thumbColor: scheme.secondary,
                            inactiveTrackColor:
                                scheme.secondary.withValues(alpha: 0.2),
                          ),
                          child: Slider(
                            value: _weightKg.clamp(minSliderKg, maxSliderKg),
                            min: minSliderKg,
                            max: maxSliderKg,
                            divisions:
                                ((maxSliderKg - minSliderKg) * 10).round(),
                            label: AppFormatters.weight(_weightKg, unit: unit),
                            onChanged: (val) {
                              setState(() {
                                _weightKg = (val * 10).round() / 10.0;
                              });
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppFormatters.weight(minSliderKg, unit: unit),
                                style: textTheme.labelSmall,
                              ),
                              Text(
                                'Geser untuk menyesuaikan',
                                style: textTheme.labelSmall,
                              ),
                              Text(
                                AppFormatters.weight(maxSliderKg, unit: unit),
                                style: textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  TextField(
                    key: const Key('weight_note_field'),
                    controller: _noteController,
                    textInputAction: TextInputAction.done,
                    maxLength: 80,
                    decoration: const InputDecoration(
                      labelText: 'Catatan (opsional)',
                      hintText: 'Contoh: Pagi sebelum sarapan',
                      prefixIcon: Icon(Icons.notes_rounded),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  PrimaryButton(
                    key: const Key('weight_save_button'),
                    label: AppStrings.save,
                    isLoading: _isSaving,
                    icon: Icons.check_rounded,
                    onPressed: _save,
                  ),
                ],
              ),
      ),
    );
  }
}

class _StepCircleButton extends StatelessWidget {
  const _StepCircleButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final semantic = context.semanticColors;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: semantic.surfaceMuted,
        shape: CircleBorder(
          side: BorderSide(color: scheme.outlineVariant),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: AppSpacing.buttonHeight,
            height: AppSpacing.buttonHeight,
            child: Icon(
              icon,
              size: AppSpacing.iconMd,
              color: scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
