import 'package:material_ui/material_ui.dart';

import '../constants/app_spacing.dart';
import '../theme/app_colors.dart';
import '../utils/reduce_motion.dart';

/// Kartu Bento halus gaya Nixtio dengan radius squircle 28dp dan bayangan ambient lembut.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md + 2),
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = AppSpacing.cardRadius,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final scheme = context.colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(borderRadius);

    Widget cardContent = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? semantic.cardSurface,
        borderRadius: radius,
        border: Border.all(
          color: borderColor ??
              (isDark
                  ? scheme.outlineVariant
                  : scheme.outlineVariant.withValues(alpha: 0.65)),
          width: AppSpacing.borderThin,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow,
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(0, 8),
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

/// Kartu Hero Obsidian kontras tinggi khas Nixtio dengan pendaran gradien radial lembut.
class HeroBentoCard extends StatelessWidget {
  const HeroBentoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg - 4),
    this.accentGlowColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? accentGlowColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final glow = accentGlowColor ?? semantic.heroAccent;
    final radius = BorderRadius.circular(AppSpacing.heroRadius);

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        color: semantic.heroCardBg,
        border: Border.all(
          color: semantic.dockBorder,
          width: AppSpacing.borderThin,
        ),
        gradient: RadialGradient(
          center: const Alignment(0.85, -0.85),
          radius: 1.25,
          colors: [
            glow.withValues(alpha: 0.18),
            semantic.heroCardBg,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: semantic.heroCardBg.withValues(alpha: 0.22),
            blurRadius: 28,
            spreadRadius: -6,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Material(
        color: semantic.heroCardBg.withValues(alpha: 0),
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
  }
}
