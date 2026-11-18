import 'package:material_ui/material_ui.dart';

import '../constants/app_spacing.dart';
import '../theme/app_colors.dart';
import '../utils/reduce_motion.dart';

/// Kartu lembut bergaya buku sketsa Mochi (kertas putih bersih + tepi biskuit hangat).
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
    final radius = BorderRadius.circular(borderRadius);

    Widget cardContent = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? semantic.cardSurface,
        borderRadius: radius,
        border: Border.all(
          color: borderColor ?? scheme.outlineVariant,
          width: AppSpacing.borderMedium,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow,
            offset: const Offset(0, 3),
            blurRadius: 0,
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

/// Kartu Panggung Utama (Hero Sticker Card):
/// Garis tinta arang tegas 1.8px + bayangan stiker buku gambar Jepang yang cerah & menggemaskan.
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
    final scheme = context.colorScheme;
    final radius = BorderRadius.circular(AppSpacing.heroRadius);

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        color: semantic.heroCardBg,
        border: Border.all(
          color: scheme.onSurface,
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.onSurface.withValues(alpha: 0.12),
            offset: const Offset(0, 5),
            blurRadius: 0,
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
