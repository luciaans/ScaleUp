import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_utils_ext.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/reduce_motion.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/mochi_companion.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../data/database/app_database.dart';
import '../../data/calories_repository.dart';
import '../../data/food_photo_analyzer.dart';
import '../../domain/calorie_models.dart';
import 'custom_food_sheet.dart';

enum _FoodTabFilter {
  all('Semua'),
  favorites('Favorit'),
  recent('Terakhir');

  const _FoodTabFilter(this.label);
  final String label;
}

/// Bottom sheet pencarian makanan instan, favorit, terakhir dipakai, buat custom,
/// dan pemilihan jumlah porsi untuk dicatat ke waktu makan.
class FoodPickerSheet extends ConsumerStatefulWidget {
  const FoodPickerSheet({
    super.key,
    required this.targetDate,
    required this.initialMealType,
  });

  final DateTime targetDate;
  final MealType initialMealType;

  static Future<bool?> show(
    BuildContext context, {
    DateTime? targetDate,
    MealType? initialMealType,
  }) {
    final effectiveDate = targetDate ?? AppDateUtils.today();
    final effectiveMeal =
        initialMealType ?? MealType.suggestedForHour(DateTime.now().hour);

    return showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.90,
        child: FoodPickerSheet(
          targetDate: effectiveDate,
          initialMealType: effectiveMeal,
        ),
      ),
    );
  }

  @override
  ConsumerState<FoodPickerSheet> createState() => _FoodPickerSheetState();
}

class _FoodPickerSheetState extends ConsumerState<FoodPickerSheet> {
  final _searchController = TextEditingController();
  late MealType _selectedMeal;
  _FoodTabFilter _tabFilter = _FoodTabFilter.all;
  String _query = '';

  FoodItem? _selectedFood;
  double _quantity = 1.0;
  bool _isSaving = false;
  bool _isAnalyzingPhoto = false;

  @override
  void initState() {
    super.initState();
    _selectedMeal = widget.initialMealType;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openCreateCustomFood() async {
    final createdId = await CustomFoodSheet.show(
      context,
      initialName: _query.trim(),
    );
    if (createdId == null || !mounted) return;

    final allFoods = ref.read(allFoodItemsProvider).value ?? const [];
    final createdItem = allFoods.where((f) => f.id == createdId).firstOrNull;
    if (createdItem != null) {
      setState(() {
        _selectedFood = createdItem;
        _quantity = 1.0;
      });
    }
  }

  Future<void> _confirmLogFood() async {
    final food = _selectedFood;
    if (food == null || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      await ref
          .read(caloriesRepositoryProvider)
          .addFoodLog(
            date: widget.targetDate,
            mealType: _selectedMeal,
            foodItemId: food.id,
            quantity: _quantity,
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

  Future<void> _scanFoodPhoto(ImageSource source) async {
    if (_isAnalyzingPhoto) return;
    try {
      final photo = await ImagePicker().pickImage(
        source: source,
        imageQuality: 78,
        maxWidth: 1600,
      );
      if (photo == null || !mounted) return;

      setState(() => _isAnalyzingPhoto = true);
      final mimeType = _mimeTypeFor(photo);
      final estimate = await const FoodPhotoAnalyzer().estimate(
        imageBytes: await photo.readAsBytes(),
        mimeType: mimeType,
      );
      final repository = ref.read(caloriesRepositoryProvider);
      final foodId = await repository.addCustomFood(
        name: estimate.name,
        servingDesc: '${estimate.servingDescription} (perkiraan AI)',
        calories: estimate.calories,
        protein: estimate.protein,
        carbs: estimate.carbs,
        fat: estimate.fat,
      );
      final logId = await repository.addFoodLog(
        date: widget.targetDate,
        mealType: _selectedMeal,
        foodItemId: foodId,
        quantity: 1,
      );

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(true);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '${estimate.name} dicatat • ±${estimate.calories.round()} kkal',
            ),
            action: SnackBarAction(
              label: 'Urungkan',
              onPressed: () => repository.deleteFoodLog(logId),
            ),
          ),
        );
    } on FoodPhotoSetupException catch (error) {
      _showPhotoError(error.toString());
    } on FirebaseException catch (error) {
      _showPhotoError(
        error.message ?? 'Analisis foto gagal. Coba lagi beberapa saat.',
      );
    } on FoodPhotoAnalysisException catch (error) {
      _showPhotoError(error.message);
    } catch (_) {
      _showPhotoError('Foto belum bisa dianalisis. Coba pilih foto lain.');
    } finally {
      if (mounted) setState(() => _isAnalyzingPhoto = false);
    }
  }

  String _mimeTypeFor(XFile photo) {
    final detected = photo.mimeType?.toLowerCase();
    if (detected == 'image/jpeg' ||
        detected == 'image/png' ||
        detected == 'image/webp') {
      return detected!;
    }
    final name = photo.name;
    final extension = name.split('.').last.toLowerCase();
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }

  void _showPhotoError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final semantic = context.semanticColors;
    final scheme = context.colorScheme;

    if (_selectedFood != null) {
      return _buildPortionSelector(context, _selectedFood!);
    }

    final allFoods = ref.watch(allFoodItemsProvider).value ?? const [];
    final recentFoods = ref.watch(recentFoodItemsProvider).value ?? const [];

    List<FoodItem> baseList = switch (_tabFilter) {
      _FoodTabFilter.all => allFoods,
      _FoodTabFilter.favorites =>
        allFoods.where((item) => item.isFavorite).toList(),
      _FoodTabFilter.recent => recentFoods,
    };

    final normalizedQuery = _query.trim().toLowerCase();
    if (normalizedQuery.isNotEmpty) {
      baseList = baseList
          .where((item) => item.name.toLowerCase().contains(normalizedQuery))
          .toList();
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                const MochiCompanion(
                  pose: MochiPose.chef,
                  size: 40,
                  showFramedBadge: true,
                ),
                const SizedBox(width: AppSpacing.sm + 2),
                Expanded(
                  child: Text('Tambah Makanan', style: textTheme.headlineSmall),
                ),
                TextButton.icon(
                  onPressed: _openCreateCustomFood,
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                  label: const Text('Custom'),
                ),
              ],
            ),
          ),

          // Pilihan waktu makan membungkus ke baris berikutnya agar semua
          // pilihan tetap terlihat pada layar sempit.
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: MealType.values.map((meal) {
                final selected = meal == _selectedMeal;
                return ChoiceChip(
                  label: Text(meal.label),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedMeal = meal),
                );
              }).toList(),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isAnalyzingPhoto
                        ? null
                        : () => _scanFoodPhoto(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_rounded),
                    label: const Text('Foto makanan'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: _isAnalyzingPhoto
                      ? null
                      : () => _scanFoodPhoto(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galeri'),
                ),
              ],
            ),
          ),
          if (_isAnalyzingPhoto)
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(),
                  SizedBox(height: AppSpacing.xs),
                  Text('Menghitung perkiraan kalori dan nutrisi...'),
                ],
              ),
            ),

          // Pencarian instan
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: TextField(
              key: const Key('food_search_field'),
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nasi goreng, tempe, telur, soto...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        tooltip: 'Hapus pencarian',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.clear_rounded),
                      )
                    : null,
              ),
              onChanged: (val) => setState(() => _query = val),
            ),
          ),

          // Filter Semua / Favorit / Terakhir
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: semantic.surfaceMuted,
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              ),
              child: Row(
                children: _FoodTabFilter.values.map((tab) {
                  final selected = tab == _tabFilter;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        MotionUtils.selectionClick();
                        setState(() => _tabFilter = tab);
                      },
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 38),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? semantic.cardSurface
                              : semantic.surfaceMuted.withValues(alpha: 0),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                        child: Text(
                          tab.label,
                          style: textTheme.labelLarge?.copyWith(
                            color: selected
                                ? scheme.primary
                                : semantic.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          Expanded(
            child: baseList.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      child: EmptyState(
                        icon: Icons.search_off_rounded,
                        accentColor: scheme.tertiary,
                        title: _tabFilter == _FoodTabFilter.favorites
                            ? 'Belum Ada Makanan Favorit'
                            : 'Makanan Tidak Ditemukan',
                        subtitle: _tabFilter == _FoodTabFilter.favorites
                            ? 'Ketuk ikon hati pada daftar makanan agar mudah diakses kembali.'
                            : 'Tidak ketemu menu yang dicari? Buat makanan custom sendiri dalam hitungan detik.',
                        actionLabel: 'Tambah Makanan Custom',
                        onAction: _openCreateCustomFood,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.lg,
                    ),
                    itemCount: baseList.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final food = baseList[index];
                      return AppCard(
                        onTap: () {
                          setState(() {
                            _selectedFood = food;
                            _quantity = 1.0;
                          });
                        },
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm + AppSpacing.xs,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          food.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: textTheme.titleSmall,
                                        ),
                                      ),
                                      if (food.isCustom) ...[
                                        const SizedBox(width: AppSpacing.xs),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.xs + 2,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: scheme.secondaryContainer,
                                            borderRadius: BorderRadius.circular(
                                              AppSpacing.radiusSm,
                                            ),
                                          ),
                                          child: Text(
                                            'Custom',
                                            style: textTheme.labelSmall
                                                ?.copyWith(
                                                  color: scheme
                                                      .onSecondaryContainer,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: AppSpacing.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: scheme.tertiaryContainer,
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusSm,
                                    ),
                                  ),
                                  child: Text(
                                    AppFormatters.calories(food.calories),
                                    style: textTheme.labelLarge?.copyWith(
                                      color: scheme.onTertiaryContainer,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: food.isFavorite
                                      ? 'Hapus dari favorit'
                                      : 'Jadikan favorit',
                                  onPressed: () {
                                    MotionUtils.selectionClick();
                                    ref
                                        .read(caloriesRepositoryProvider)
                                        .toggleFavorite(
                                          food.id,
                                          !food.isFavorite,
                                        );
                                  },
                                  icon: Icon(
                                    food.isFavorite
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: food.isFavorite
                                        ? scheme.error
                                        : semantic.textSecondary,
                                    size: AppSpacing.iconMd,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              food.servingDesc,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                color: semantic.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              children: [
                                _buildMacroChip(
                                  context,
                                  'Protein',
                                  food.protein,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                _buildMacroChip(context, 'Karbo', food.carbs),
                                const SizedBox(width: AppSpacing.xs),
                                _buildMacroChip(context, 'Lemak', food.fat),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroChip(BuildContext context, String label, double grams) {
    final semantic = context.semanticColors;
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: semantic.surfaceMuted,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Text(
          '$label ${AppFormatters.compactDecimal(grams)}g',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: textTheme.labelSmall?.copyWith(color: semantic.textSecondary),
        ),
      ),
    );
  }

  Widget _buildPortionSelector(BuildContext context, FoodItem food) {
    final textTheme = Theme.of(context).textTheme;
    final semantic = context.semanticColors;
    final scheme = context.colorScheme;

    final totalKcal = food.calories * _quantity;
    final totalP = food.protein * _quantity;
    final totalC = food.carbs * _quantity;
    final totalF = food.fat * _quantity;
    const quickPresets = [0.5, 1.0, 1.5, 2.0];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _selectedFood = null),
                tooltip: 'Kembali ke daftar makanan',
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              Expanded(
                child: Text(
                  food.name,
                  style: textTheme.headlineSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              'Takaran saji: ${food.servingDesc} (${AppFormatters.calories(food.calories)} / porsi)',
              style: textTheme.bodySmall?.copyWith(
                color: semantic.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Jumlah porsi besar + tombol -/+ 0,25
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: _quantity > 0.25
                    ? () {
                        MotionUtils.selectionClick();
                        setState(
                          () =>
                              _quantity = (_quantity - 0.25).clamp(0.25, 20.0),
                        );
                      }
                    : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              const SizedBox(width: AppSpacing.lg),
              Column(
                children: [
                  Text(
                    AppFormatters.rateDecimal(_quantity),
                    style: AppTextStyles.heroNumber(
                      context,
                      fontSize: AppSpacing.heroNumberMd,
                      color: scheme.tertiary,
                    ),
                  ),
                  Text('porsi', style: textTheme.labelMedium),
                ],
              ),
              const SizedBox(width: AppSpacing.lg),
              IconButton.filledTonal(
                onPressed: () {
                  MotionUtils.selectionClick();
                  setState(
                    () => _quantity = (_quantity + 0.25).clamp(0.25, 20.0),
                  );
                },
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Pilihan cepat porsi
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.sm,
            children: quickPresets.map((preset) {
              final selected = (_quantity - preset).abs() < 0.01;
              return ChoiceChip(
                label: Text('${AppFormatters.rateDecimal(preset)} porsi'),
                selected: selected,
                onSelected: (_) => setState(() => _quantity = preset),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),

          AppCard(
            backgroundColor: semantic.surfaceMuted,
            child: Row(
              children: [
                Expanded(
                  child: _NutrientColumn(
                    label: 'Kalori',
                    value: AppFormatters.calories(totalKcal),
                    color: scheme.tertiary,
                  ),
                ),
                Expanded(
                  child: _NutrientColumn(
                    label: 'Protein',
                    value: '${AppFormatters.compactDecimal(totalP)}g',
                    color: semantic.proteinColor,
                  ),
                ),
                Expanded(
                  child: _NutrientColumn(
                    label: 'Karbo',
                    value: '${AppFormatters.compactDecimal(totalC)}g',
                    color: semantic.carbsColor,
                  ),
                ),
                Expanded(
                  child: _NutrientColumn(
                    label: 'Lemak',
                    value: '${AppFormatters.compactDecimal(totalF)}g',
                    color: semantic.fatColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          PrimaryButton(
            key: const Key('confirm_add_food_log_button'),
            label: 'Tambahkan ke ${_selectedMeal.label}',
            isLoading: _isSaving,
            icon: Icons.add_task_rounded,
            onPressed: _confirmLogFood,
          ),
        ],
      ),
    );
  }
}

class _NutrientColumn extends StatelessWidget {
  const _NutrientColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: textTheme.labelSmall),
        const SizedBox(height: AppSpacing.xxs),
        Text(value, style: textTheme.titleSmall?.copyWith(color: color)),
      ],
    );
  }
}
