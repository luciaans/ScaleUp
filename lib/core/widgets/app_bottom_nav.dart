import 'dart:ui' show ImageFilter;

import 'package:material_ui/material_ui.dart';

import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../theme/app_colors.dart';
import '../utils/reduce_motion.dart';

/// Floating Obsidian Glass Pill Dock khas Nixtio dengan 4 destinasi + slot FAB tengah.
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
          borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
          boxShadow: [
            BoxShadow(
              color: semantic.heroCardBg.withValues(alpha: 0.28),
              blurRadius: 28,
              spreadRadius: -4,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: semantic.dockBg,
                borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                border: Border.all(
                  color: semantic.dockBorder,
                  width: AppSpacing.borderThin,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: MediaQuery.removePadding(
                context: context,
                removeBottom: true,
                removeTop: true,
                child: NavigationBar(
                  height: 66,
                  backgroundColor: semantic.dockBg.withValues(alpha: 0),
                  selectedIndex: _mappedDestinationIndex,
                  onDestinationSelected: _handleSelect,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.grid_view_outlined),
                      selectedIcon: Icon(Icons.grid_view_rounded),
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
                      child: SizedBox(width: AppSpacing.xxxl + AppSpacing.sm),
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.local_dining_outlined),
                      selectedIcon: Icon(Icons.local_dining_rounded),
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
          ),
        ),
      ),
    );
  }
}

/// FloatingActionButton Electric Lime bercahaya yang duduk menyatu di tengah Floating Pill Dock.
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
              color: semantic.heroCardBg,
              border: Border.all(
                color: semantic.dockBorder,
                width: AppSpacing.borderThin,
              ),
              boxShadow: [
                BoxShadow(
                  color: semantic.heroAccent.withValues(alpha: 0.35),
                  blurRadius: 18,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: SizedBox(
              width: 52,
              height: 52,
              child: FloatingActionButton(
                heroTag: 'quick_add_fab',
                tooltip: AppStrings.quickAddTooltip,
                backgroundColor: semantic.heroAccent,
                foregroundColor: AppColors.darkOnPrimary,
                elevation: 0,
                onPressed: () {
                  MotionUtils.lightImpact();
                  widget.onPressed();
                },
                child: AnimatedRotation(
                  turns: widget.isSheetOpen && !reduceMotion ? 0.125 : 0.0,
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  child: const Icon(
                    Icons.add_rounded,
                    size: AppSpacing.iconLg,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
