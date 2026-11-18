import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_ui/material_ui.dart';

import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../theme/app_colors.dart';
import '../utils/reduce_motion.dart';
import 'app_card.dart';
import 'mochi_companion.dart';

enum QuickAddChoice { weight, food }

/// Bottom sheet "Catat Cepat" bergaya stiker kucing Mochi.
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
    final reduceMotion = MotionUtils.shouldReduceMotion(context);

    Widget weightCard = HeroBentoCard(
      onTap: () => Navigator.of(context).pop(QuickAddChoice.weight),
      padding: const EdgeInsets.all(AppSpacing.md + AppSpacing.xs),
      child: Row(
        children: [
          const MochiCompanion(
            pose: MochiPose.welcome,
            size: 54,
            showFramedBadge: true,
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
        ],
      ),
    );

    Widget foodCard = HeroBentoCard(
      onTap: () => Navigator.of(context).pop(QuickAddChoice.food),
      padding: const EdgeInsets.all(AppSpacing.md + AppSpacing.xs),
      child: Row(
        children: [
          const MochiCompanion(
            pose: MochiPose.chef,
            size: 54,
            showFramedBadge: true,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.quickAddFoodTitle,
                  style: textTheme.titleMedium?.copyWith(
                    color: semantic.heroCardFg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  AppStrings.quickAddFoodSubtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: semantic.heroCardMuted,
                  ),
                ),
              ],
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
