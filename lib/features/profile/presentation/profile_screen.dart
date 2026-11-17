import 'package:material_ui/material_ui.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/empty_state.dart';

/// Layar Profil, Tujuan & Pengaturan — fondasi Fase 1, akan dilengkapi di Fase 2 & 5.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.navProfile),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.bottomNavClearance,
        ),
        children: const [
          EmptyState(
            icon: Icons.person_rounded,
            title: AppStrings.profilePlaceholderTitle,
            subtitle: AppStrings.profilePlaceholderSubtitle,
          ),
        ],
      ),
    );
  }
}
