import 'package:material_ui/material_ui.dart';

import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../theme/app_colors.dart';
import '../utils/reduce_motion.dart';

/// Bottom Navigation Bar Material 3 dengan 4 tab + celah tengah untuk FAB docked.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  /// Indeks branch aktif (0..3).
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  int get _mappedDestinationIndex =>
      currentIndex >= 2 ? currentIndex + 1 : currentIndex;

  void _handleSelect(int rawIndex) {
    if (rawIndex == 2) return; // Slot tengah milik FAB
    final targetBranch = rawIndex > 2 ? rawIndex - 1 : rawIndex;
    MotionUtils.selectionClick();
    onDestinationSelected(targetBranch);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: scheme.outlineVariant,
            width: AppSpacing.borderThin,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow,
            blurRadius: AppSpacing.md,
            offset: const Offset(0, -AppSpacing.xxs),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: _mappedDestinationIndex,
        onDestinationSelected: _handleSelect,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: AppStrings.navHome,
            tooltip: AppStrings.navHome,
          ),
          NavigationDestination(
            icon: Icon(Icons.monitor_weight_outlined),
            selectedIcon: Icon(Icons.monitor_weight_rounded),
            label: AppStrings.navWeight,
            tooltip: AppStrings.navWeight,
          ),
          IgnorePointer(
            child: SizedBox(width: AppSpacing.xxxl),
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_outlined),
            selectedIcon: Icon(Icons.restaurant_rounded),
            label: AppStrings.navCalories,
            tooltip: AppStrings.navCalories,
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: AppStrings.navProfile,
            tooltip: AppStrings.navProfile,
          ),
        ],
      ),
    );
  }
}

/// FloatingActionButton melingkar dengan animasi rotasi & scale saat ditekan.
class QuickAddFab extends StatefulWidget {
  const QuickAddFab({
    super.key,
    required this.onPressed,
    this.isSheetOpen = false,
  });

  final VoidCallback onPressed;
  final bool isSheetOpen;

  @override
  State<QuickAddFab> createState() => _QuickAddFabState();
}

class _QuickAddFabState extends State<QuickAddFab> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MotionUtils.shouldReduceMotion(context);
    final duration = MotionUtils.duration(context, AppSpacing.animNormal);

    return Semantics(
      button: true,
      label: AppStrings.quickAddTooltip,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed && !reduceMotion ? 0.92 : 1.0,
          duration: MotionUtils.duration(context, AppSpacing.animFast),
          curve: Curves.easeOutCubic,
          child: FloatingActionButton(
            heroTag: 'quick_add_fab',
            tooltip: AppStrings.quickAddTooltip,
            onPressed: () {
              MotionUtils.lightImpact();
              widget.onPressed();
            },
            child: AnimatedRotation(
              turns: widget.isSheetOpen && !reduceMotion ? 0.125 : 0.0,
              duration: duration,
              curve: Curves.easeOutCubic,
              child: const Icon(Icons.add_rounded, size: AppSpacing.iconLg),
            ),
          ),
        ),
      ),
    );
  }
}
