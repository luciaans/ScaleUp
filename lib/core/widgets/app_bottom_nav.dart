import 'package:material_ui/material_ui.dart';

import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../theme/app_colors.dart';
import '../utils/reduce_motion.dart';

/// Kapsul Navigasi Bawah bergaya stiker monokrom Sumi-Ink & Kertas Susu.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  int get _mappedDestinationIndex =>
      currentIndex >= 2 ? currentIndex + 1 : currentIndex;

  void _handleSelect(int rawIndex) {
    if (rawIndex == 2) return;
    final targetBranch = rawIndex > 2 ? rawIndex - 1 : rawIndex;
    MotionUtils.selectionClick();
    onDestinationSelected(targetBranch);
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final scheme = context.colorScheme;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm + AppSpacing.xs,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: semantic.dockBg,
          borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
          border: Border.all(color: semantic.dockBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow,
              offset: const Offset(0, 8),
              blurRadius: 24,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: MediaQuery.removePadding(
          context: context,
          removeBottom: true,
          removeTop: true,
          child: NavigationBar(
            height: 64,
            backgroundColor: semantic.dockBg.withValues(alpha: 0),
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
                icon: Icon(Icons.scale_outlined),
                selectedIcon: Icon(Icons.scale_rounded),
                label: AppStrings.navWeight,
                tooltip: AppStrings.navWeight,
              ),
              IgnorePointer(
                child: SizedBox(width: AppSpacing.xxxl + AppSpacing.sm),
              ),
              NavigationDestination(
                icon: Icon(Icons.restaurant_menu_outlined),
                selectedIcon: Icon(Icons.restaurant_menu_rounded),
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
        ),
      ),
    );
  }
}

/// Tombol tengah bundar hitam Sumi-Ink dengan aksen pipi kucing Sakura Blush.
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
    final scheme = context.colorScheme;
    final semantic = context.semanticColors;
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
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: semantic.cardSurface,
              border: Border.all(color: semantic.dockBorder, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: scheme.shadow,
                  offset: const Offset(0, 6),
                  blurRadius: 16,
                ),
              ],
            ),
            child: SizedBox(
              width: 52,
              height: 52,
              child: FloatingActionButton(
                heroTag: 'quick_add_fab',
                tooltip: AppStrings.quickAddTooltip,
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                elevation: 0,
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
        ),
      ),
    );
  }
}
