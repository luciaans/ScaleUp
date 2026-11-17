import 'package:material_ui/material_ui.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/empty_state.dart';

/// Layar Beranda (Dashboard) — fondasi Fase 1, akan dilengkapi di Fase 5.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.navHome),
      ),
      body: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: AppSpacing.bottomNavClearance,
              ),
              child: const Center(
                child: EmptyState(
                  icon: Icons.favorite_rounded,
                  title: AppStrings.homePlaceholderTitle,
                  subtitle: AppStrings.homePlaceholderSubtitle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
