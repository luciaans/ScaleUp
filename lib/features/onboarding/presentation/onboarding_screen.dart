import 'package:material_ui/material_ui.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/empty_state.dart';

/// Kerangka rute Onboarding Fase 1 — alur 4 langkah dibangun penuh pada Fase 2.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: EmptyState(
            icon: Icons.flag_rounded,
            title: AppStrings.appName,
            subtitle: AppStrings.appTagline,
          ),
        ),
      ),
    );
  }
}
