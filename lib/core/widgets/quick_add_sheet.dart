import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_ui/material_ui.dart';

import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../theme/app_colors.dart';
import '../utils/reduce_motion.dart';
import 'app_card.dart';

enum QuickAddChoice {
  weight,
  food,
}

/// Bottom sheet "Catat Cepat" bergaya Bento Action Cards Nixtio.
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

    Widget weightCard = HeroBentoCard(
      accentGlowColor: scheme.secondary,
      onTap: () => Navigator.of(context).pop(QuickAddChoice.weight),
      padding: const EdgeInsets.all(AppSpacing.md + AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.secondary.withValues(alpha: 0.2),
            ),
            child: Icon(
              Icons.monitor_weight_rounded,
              color: scheme.secondary,
              size: AppSpacing.iconMd + 2,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.quickAddWeightTitle,
                  style: textTheme.titleMedium?.copyWith(
                    color: semantic.heroCardFg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  AppStrings.quickAddWeightSubtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: semantic.heroCardMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: semantic.heroCardSurface,
            ),
            child: Icon(
              Icons.north_east_rounded,
              size: 18,
              color: semantic.heroAccent,
            ),
          ),
        ],
      ),
    );

    Widget foodCard = AppCard(
      backgroundColor: semantic.surfaceMuted,
      onTap: () => Navigator.of(context).pop(QuickAddChoice.food),
      padding: const EdgeInsets.all(AppSpacing.md + AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.tertiary.withValues(alpha: 0.16),
            ),
            child: Icon(
              Icons.local_dining_rounded,
              color: scheme.tertiary,
              size: AppSpacing.iconMd + 2,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.quickAddFoodTitle,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  AppStrings.quickAddFoodSubtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: semantic.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: semantic.cardSurface,
            ),
            child: Icon(
              Icons.north_east_rounded,
              size: 18,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );

    if (!reduceMotion) {
      weightCard = weightCard
          .animate()
          .fadeIn(duration: AppSpacing.animNormal, curve: Curves.easeOutCubic)
          .slideY(begin: 0.10, end: 0, duration: AppSpacing.animNormal);
      foodCard = foodCard
          .animate(delay: AppSpacing.staggerDelay)
          .fadeIn(duration: AppSpacing.animNormal, curve: Curves.easeOutCubic)
          .slideY(begin: 0.10, end: 0, duration: AppSpacing.animNormal);
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
            const SizedBox(height: AppSpacing.xxs),
            Text(
              AppStrings.quickAddSubtitle,
              style: textTheme.bodyMedium?.copyWith(
                color: semantic.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            weightCard,
            const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
            foodCard,
          ],
        ),
      ),
    );
  }
}
