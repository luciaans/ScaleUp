import 'package:material_ui/material_ui.dart';

import '../constants/app_spacing.dart';
import '../theme/app_colors.dart';
import '../utils/reduce_motion.dart';

/// Kartu standar ScaleUp dengan radius 22dp, border halus, dan bayangan tipis.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final scheme = context.colorScheme;
    final radius = BorderRadius.circular(AppSpacing.cardRadius);

    Widget cardContent = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? semantic.cardSurface,
        borderRadius: radius,
        border: Border.all(
          color: borderColor ?? scheme.outlineVariant,
          width: AppSpacing.borderThin,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow,
            blurRadius: AppSpacing.md,
            offset: const Offset(0, AppSpacing.xs),
          ),
        ],
      ),
      child: Material(
        color: scheme.surface.withValues(alpha: 0),
        borderRadius: radius,
        child: onTap != null
            ? InkWell(
                onTap: () {
                  MotionUtils.selectionClick();
                  onTap!();
                },
                borderRadius: radius,
                child: Padding(padding: padding, child: child),
              )
            : Padding(padding: padding, child: child),
      ),
    );

    if (semanticLabel != null) {
      cardContent = Semantics(
        label: semanticLabel,
        button: onTap != null,
        child: cardContent,
      );
    }

    return cardContent;
  }
}
