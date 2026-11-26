import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/reduce_motion.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../data/database/app_database.dart';
import '../../data/csv_export_service.dart';
import '../../data/notification_service.dart';
import '../../data/settings_repository.dart';

/// Kumpulan kartu pengaturan aplikasi (Tema, Satuan, Pengingat Harian, Ekspor CSV & Reset Data).
class SettingsCards extends ConsumerStatefulWidget {
  const SettingsCards({super.key});

  @override
  ConsumerState<SettingsCards> createState() => _SettingsCardsState();
}

class _SettingsCardsState extends ConsumerState<SettingsCards> {
  bool _isExporting = false;

  Future<void> _pickReminderTime({
    required bool isWeight,
    required ReminderPreferences prefs,
  }) async {
    final initial = isWeight ? prefs.weightTime : prefs.mealTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: isWeight
          ? 'Jam Pengingat Timbang Berat'
          : 'Jam Pengingat Catat Makanan',
      cancelText: AppStrings.cancel,
      confirmText: AppStrings.save,
    );
    if (picked == null || !mounted) return;

    final settingsRepo = ref.read(settingsRepositoryProvider);
    final notif = ref.read(notificationServiceProvider);

    try {
      if (isWeight) {
        await notif.syncWeightReminder(enabled: true, time: picked);
        await settingsRepo.setWeightReminder(enabled: true, time: picked);
      } else {
        await notif.syncMealReminder(enabled: true, time: picked);
        await settingsRepo.setMealReminder(enabled: true, time: picked);
      }
    } on NotificationSetupException catch (error) {
      _showReminderError(error.toString());
    }
  }

  void _showReminderError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleExportCsv() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      await ref.read(csvExportServiceProvider).exportAndShareCsv();
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('File CSV siap dibagikan!')),
          );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Gagal mengekspor CSV. Silakan coba lagi.'),
            ),
          );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _confirmClearAllData() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      builder: (sheetCtx) {
        final textTheme = Theme.of(sheetCtx).textTheme;
        final scheme = sheetCtx.colorScheme;
        final semantic = sheetCtx.semanticColors;

        return Padding(
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
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: scheme.error,
                    size: AppSpacing.iconLg,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Hapus Semua Data?',
                      style: textTheme.headlineSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Seluruh profil, riwayat berat badan, tujuan, dan catatan makanan akan dihapus permanen dari perangkat ini. Tindakan ini tidak dapat dibatalkan.',
                style: textTheme.bodyMedium?.copyWith(
                  color: semantic.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(sheetCtx).pop(false),
                      child: const Text(AppStrings.cancel),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: PrimaryButton(
                      key: const Key('confirm_delete_all_data_button'),
                      label: 'Ya, Hapus Semua',
                      backgroundColor: scheme.error,
                      foregroundColor: scheme.onError,
                      onPressed: () => Navigator.of(sheetCtx).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true || !mounted) return;
    try {
      await ref.read(notificationServiceProvider).cancelAll();
    } on NotificationSetupException {
      // Data reset tetap harus berhasil walau platform notifikasi tidak tersedia.
    }
    await ref.read(appDatabaseProvider).clearAllUserData();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(appThemeModeProvider).value ?? ThemeMode.system;
    final unit = ref.watch(appWeightUnitProvider).value ?? WeightUnit.kg;
    final reminders =
        ref.watch(reminderPreferencesProvider).value ??
        const ReminderPreferences(
          weightEnabled: false,
          weightTime: TimeOfDay(hour: 7, minute: 0),
          mealEnabled: false,
          mealTime: TimeOfDay(hour: 12, minute: 30),
        );

    final textTheme = Theme.of(context).textTheme;
    final semantic = context.semanticColors;
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Preferensi & Tampilan', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tema Aplikasi', style: textTheme.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              _SegmentedOptionRow<ThemeMode>(
                options: const [
                  (value: ThemeMode.system, label: 'Sistem'),
                  (value: ThemeMode.light, label: 'Terang'),
                  (value: ThemeMode.dark, label: 'Gelap'),
                ],
                selected: themeMode,
                onChanged: (mode) {
                  ref.read(settingsRepositoryProvider).setThemeMode(mode);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Satuan Berat', style: textTheme.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              _SegmentedOptionRow<WeightUnit>(
                options: const [
                  (value: WeightUnit.kg, label: 'Kilogram (kg)'),
                  (value: WeightUnit.lb, label: 'Pound (lb)'),
                ],
                selected: unit,
                onChanged: (newUnit) {
                  ref.read(settingsRepositoryProvider).setWeightUnit(newUnit);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        Text('Pengingat Harian', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            children: [
              _ReminderRow(
                icon: Icons.scale_outlined,
                title: 'Timbang Berat Badan',
                timeLabel: ReminderPreferences.formatTime(reminders.weightTime),
                enabled: reminders.weightEnabled,
                 onToggle: (val) async {
                  try {
                    await ref
                        .read(notificationServiceProvider)
                        .syncWeightReminder(
                          enabled: val,
                          time: reminders.weightTime,
                        );
                    await ref
                        .read(settingsRepositoryProvider)
                        .setWeightReminder(
                          enabled: val,
                          time: reminders.weightTime,
                        );
                  } on NotificationSetupException catch (error) {
                    _showReminderError(error.toString());
                  }
                },
                onTapTime: () =>
                    _pickReminderTime(isWeight: true, prefs: reminders),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Divider(),
              ),
              _ReminderRow(
                icon: Icons.restaurant_outlined,
                title: 'Catat Asupan Makanan',
                timeLabel: ReminderPreferences.formatTime(reminders.mealTime),
                enabled: reminders.mealEnabled,
                 onToggle: (val) async {
                  try {
                    await ref
                        .read(notificationServiceProvider)
                        .syncMealReminder(
                          enabled: val,
                          time: reminders.mealTime,
                        );
                    await ref
                        .read(settingsRepositoryProvider)
                        .setMealReminder(
                          enabled: val,
                          time: reminders.mealTime,
                        );
                  } on NotificationSetupException catch (error) {
                    _showReminderError(error.toString());
                  }
                },
                onTapTime: () =>
                    _pickReminderTime(isWeight: false, prefs: reminders),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        Text('Data & Privasi', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(Icons.download_rounded, color: scheme.secondary),
                ),
                title: Text('Ekspor Data ke CSV', style: textTheme.titleSmall),
                subtitle: Text(
                  'Simpan atau bagikan riwayat berat & log makanan',
                  style: textTheme.bodySmall?.copyWith(
                    color: semantic.textSecondary,
                  ),
                ),
                trailing: _isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right_rounded),
                onTap: _handleExportCsv,
              ),
              const Divider(),
              ListTile(
                key: const Key('delete_all_data_tile'),
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: scheme.errorContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(
                    Icons.delete_forever_outlined,
                    color: scheme.error,
                  ),
                ),
                title: Text(
                  'Hapus Semua Data',
                  style: textTheme.titleSmall?.copyWith(color: scheme.error),
                ),
                subtitle: Text(
                  'Reset aplikasi ke kondisi baru dari awal',
                  style: textTheme.bodySmall?.copyWith(
                    color: semantic.textSecondary,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.error,
                ),
                onTap: _confirmClearAllData,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SegmentedOptionRow<T> extends StatelessWidget {
  const _SegmentedOptionRow({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<({T value, String label})> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: semantic.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
      ),
      child: Row(
        children: options.map((opt) {
          final isSelected = opt.value == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                MotionUtils.selectionClick();
                onChanged(opt.value);
              },
              child: AnimatedContainer(
                duration: MotionUtils.duration(context, AppSpacing.animFast),
                constraints: const BoxConstraints(minHeight: 40),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: isSelected
                      ? semantic.heroCardBg
                      : semantic.surfaceMuted.withValues(alpha: 0),
                  borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    opt.label,
                    style: textTheme.labelLarge?.copyWith(
                      color: isSelected
                          ? semantic.heroAccent
                          : semantic.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({
    required this.icon,
    required this.title,
    required this.timeLabel,
    required this.enabled,
    required this.onToggle,
    required this.onTapTime,
  });

  final IconData icon;
  final String title;
  final String timeLabel;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTapTime;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = context.colorScheme;
    final semantic = context.semanticColors;

    return Row(
      children: [
        Icon(icon, color: scheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xxs),
              InkWell(
                onTap: onTapTime,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    'Setiap hari pukul $timeLabel • Ubah jam',
                    style: textTheme.bodySmall?.copyWith(
                      color: enabled ? scheme.primary : semantic.textSecondary,
                      fontWeight: enabled ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Switch(value: enabled, onChanged: onToggle),
      ],
    );
  }
}
