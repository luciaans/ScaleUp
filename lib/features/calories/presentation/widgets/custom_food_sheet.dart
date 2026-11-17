import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/number_parser.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/calories_repository.dart';

/// Bottom sheet untuk membuat makanan custom (nama, deskripsi porsi, kalori, makro).
class CustomFoodSheet extends ConsumerStatefulWidget {
  const CustomFoodSheet({super.key, this.initialName});

  final String? initialName;

  static Future<int?> show(BuildContext context, {String? initialName}) {
    return showModalBottomSheet<int>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => CustomFoodSheet(initialName: initialName),
    );
  }

  @override
  ConsumerState<CustomFoodSheet> createState() => _CustomFoodSheetState();
}

class _CustomFoodSheetState extends ConsumerState<CustomFoodSheet> {
  late final TextEditingController _nameController;
  final _servingController = TextEditingController(text: '1 porsi');
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController(text: '0');
  final _carbsController = TextEditingController(text: '0');
  final _fatController = TextEditingController(text: '0');

  String? _errorText;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _servingController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final serving = _servingController.text.trim();
    final kcal = NumberParser.tryParseDouble(_caloriesController.text);
    final protein = NumberParser.tryParseDouble(_proteinController.text) ?? 0;
    final carbs = NumberParser.tryParseDouble(_carbsController.text) ?? 0;
    final fat = NumberParser.tryParseDouble(_fatController.text) ?? 0;

    if (name.isEmpty) {
      setState(() => _errorText = 'Masukkan nama makanan terlebih dahulu.');
      return;
    }
    if (serving.isEmpty) {
      setState(() => _errorText = 'Masukkan deskripsi porsi (misal: 1 mangkuk).');
      return;
    }
    if (kcal == null || kcal < 0 || kcal > 5000) {
      setState(() => _errorText = 'Masukkan kalori per porsi (0 – 5.000 kkal).');
      return;
    }
    if (protein < 0 || carbs < 0 || fat < 0) {
      setState(() => _errorText = 'Nilai makro tidak boleh negatif.');
      return;
    }

    setState(() {
      _errorText = null;
      _isSaving = true;
    });

    try {
      final newId = await ref.read(caloriesRepositoryProvider).addCustomFood(
            name: name,
            servingDesc: serving,
            calories: kcal,
            protein: protein,
            carbs: carbs,
            fat: fat,
          );
      if (mounted) {
        Navigator.of(context).pop(newId);
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
            Text('Tambah Makanan Custom', style: textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Simpan menu favorit atau masakan rumah ke database lokalmu.',
              style: textTheme.bodySmall?.copyWith(
                color: semantic.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Text('Nama Makanan', style: textTheme.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              key: const Key('custom_food_name_field'),
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Contoh: Salad Buah Rumahan',
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Deskripsi Porsi', style: textTheme.labelLarge),
                      const SizedBox(height: AppSpacing.xs),
                      TextField(
                        controller: _servingController,
                        decoration: const InputDecoration(
                          hintText: '1 mangkuk (200 g)',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kalori (kkal)', style: textTheme.labelLarge),
                      const SizedBox(height: AppSpacing.xs),
                      TextField(
                        key: const Key('custom_food_kcal_field'),
                        controller: _caloriesController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          hintText: '220',
                          suffixText: AppStrings.unitKcal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            Row(
              children: [
                Expanded(
                  child: _MacroInputField(
                    label: 'Protein (g)',
                    controller: _proteinController,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _MacroInputField(
                    label: 'Karbo (g)',
                    controller: _carbsController,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _MacroInputField(
                    label: 'Lemak (g)',
                    controller: _fatController,
                  ),
                ),
              ],
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

            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              key: const Key('custom_food_save_button'),
              label: 'Simpan Makanan',
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

class _MacroInputField extends StatelessWidget {
  const _MacroInputField({
    required this.label,
    required this.controller,
  });

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            suffixText: AppStrings.unitGram,
          ),
        ),
      ],
    );
  }
}
