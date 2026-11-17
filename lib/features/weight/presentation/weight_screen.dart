import 'package:material_ui/material_ui.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';

/// Layar Berat Badan — fondasi Fase 1, akan dilengkapi di Fase 3.
class WeightScreen extends StatelessWidget {
  const WeightScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.navWeight),
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
            icon: Icons.monitor_weight_rounded,
            accentColor: context.colorScheme.secondary,
            title: AppStrings.weightPlaceholderTitle,
            subtitle: AppStrings.weightPlaceholderSubtitle,
          ),
        ],
      ),
    );
  }
}
