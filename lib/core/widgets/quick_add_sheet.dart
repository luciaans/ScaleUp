import 'package:material_ui/material_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../theme/app_colors.dart';
import '../utils/reduce_motion.dart';
import 'app_card.dart';

/// Pilihan aksi dari Bottom Sheet "Catat Cepat".
enum QuickAddChoice {
  weight,
  food,
}

/// Bottom sheet "Catat Cepat" dengan dua pilihan aksi beranimasi stagger.
class QuickAddSheet extends StatelessWidget {
  const QuickAddSheet({super.key});

  static Future<QuickAddChoice?> show(BuildContext context) {
    return showModalBottomSheet<QuickAddChoice>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const QuickAddSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final semantic = context.semanticColors;
    final scheme = context.colorScheme;
    final reduceMotion = MotionUtils.shouldReduceMotion(context);

    Widget weightTile = _QuickActionTile(
      icon: Icons.monitor_weight_rounded,
      accentColor: scheme.secondary,
      title: AppStrings.quickAddWeightTitle,
      subtitle: AppStrings.quickAddWeightSubtitle,
      onTap: () => Navigator.of(context).pop(QuickAddChoice.weight),
    );

    Widget foodTile = _QuickActionTile(
      icon: Icons.restaurant_rounded,
      accentColor: scheme.tertiary,
      title: AppStrings.quickAddFoodTitle,
      subtitle: AppStrings.quickAddFoodSubtitle,
      onTap: () => Navigator.of(context).pop(QuickAddChoice.food),
    );

    if (!reduceMotion) {
      weightTile = weightTile
          .animate()
          .fadeIn(duration: AppSpacing.animNormal, curve: Curves.easeOutCubic)
          .slideY(
            begin: 0.12,
            end: 0,
            duration: AppSpacing.animNormal,
            curve: Curves.easeOutCubic,
          );
      foodTile = foodTile
          .animate(delay: AppSpacing.staggerDelay)
          .fadeIn(duration: AppSpacing.animNormal, curve: Curves.easeOutCubic)
          .slideY(
            begin: 0.12,
            end: 0,
            duration: AppSpacing.animNormal,
            curve: Curves.easeOutCubic,
          );
    }

    return SafeArea(
      top: false,
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
            Text(AppStrings.quickAddTitle, style: textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              AppStrings.quickAddSubtitle,
              style: textTheme.bodyMedium?.copyWith(
                color: semantic.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            weightTile,
            const SizedBox(height: AppSpacing.md),
            foodTile,
          ],
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final semantic = context.semanticColors;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      semanticLabel: '$title. $subtitle',
      child: Row(
        children: [
          Container(
            width: AppSpacing.minTouchTarget,
            height: AppSpacing.minTouchTarget,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            ),
            child: Icon(icon, color: accentColor, size: AppSpacing.iconMd),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: semantic.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(
            Icons.chevron_right_rounded,
            color: semantic.textSecondary,
          ),
        ],
      ),
    );
  }
}
