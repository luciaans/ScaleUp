import 'package:material_ui/material_ui.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';

/// Layar Kalori & Catatan Makanan — fondasi Fase 1, akan dilengkapi di Fase 4.
class CaloriesScreen extends StatelessWidget {
  const CaloriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.navCalories),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.bottomNavClearance,
        ),
        children: [
          EmptyState(
            icon: Icons.restaurant_rounded,
            accentColor: context.colorScheme.tertiary,
            title: AppStrings.caloriesPlaceholderTitle,
            subtitle: AppStrings.caloriesPlaceholderSubtitle,
          ),
        ],
      ),
    );
  }
}
