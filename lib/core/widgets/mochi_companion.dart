import 'package:material_ui/material_ui.dart';

import '../constants/app_spacing.dart';
import '../theme/app_colors.dart';
import '../utils/reduce_motion.dart';

enum MochiPose {
  welcome('assets/cats/mochi_welcome.png'),
  chef('assets/cats/mochi_chef.png'),
  cheer('assets/cats/mochi_cheer.png'),
  nap('assets/cats/mochi_nap.png');

  const MochiPose(this.assetPath);
  final String assetPath;
}

/// Maskot kucing Mochi interaktif: membal lembut (squish) & mengganti balon sapaan saat diketuk.
class MochiCompanion extends StatefulWidget {
  const MochiCompanion({
    super.key,
    required this.pose,
    this.size = 180,
    this.quotes = const [],
    this.showFramedBadge = false,
  });

  final MochiPose pose;
  final double size;
  final List<String> quotes;
  final bool showFramedBadge;

  @override
  State<MochiCompanion> createState() => _MochiCompanionState();
}

class _MochiCompanionState extends State<MochiCompanion> {
  int _quoteIndex = 0;
  bool _isSquished = false;

  void _handleTap() {
    MotionUtils.selectionClick();
    setState(() {
      _isSquished = true;
      if (widget.quotes.isNotEmpty) {
        _quoteIndex = (_quoteIndex + 1) % widget.quotes.length;
      }
    });
    Future<void>.delayed(const Duration(milliseconds: 160), () {
      if (mounted) {
        setState(() => _isSquished = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = context.colorScheme;
    final reduceMotion = MotionUtils.shouldReduceMotion(context);

    Widget catArt = Image.asset(
      widget.pose.assetPath,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Container(
        width: widget.size,
        height: widget.size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.milkPaper,
        ),
        child: Icon(
          Icons.pets_rounded,
          size: widget.size * 0.45,
          color: AppColors.sumiInk,
        ),
      ),
    );

    if (widget.showFramedBadge) {
      catArt = Container(
        width: widget.size,
        height: widget.size,
        padding: EdgeInsets.all(widget.size * 0.06),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.milkPaper,
          border: Border.all(
            color: scheme.outlineVariant,
            width: AppSpacing.borderMedium,
          ),
        ),
        child: ClipOval(child: catArt),
      );
    }

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.quotes.isNotEmpty) ...[
            AnimatedSwitcher(
              duration: MotionUtils.duration(context, AppSpacing.animFast),
              child: Container(
                key: ValueKey<int>(_quoteIndex),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 2,
                ),
                decoration: BoxDecoration(
                  color: context.semanticColors.cardSurface,
                  borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                  border: Border.all(
                    color: scheme.onSurface,
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.pets_rounded,
                      size: 14,
                      color: AppColors.sakuraBlush,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        widget.quotes[_quoteIndex],
                        style: textTheme.labelMedium?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          AnimatedScale(
            scale: _isSquished && !reduceMotion ? 0.92 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutBack,
            child: Semantics(
              label: 'Maskot kucing Mochi, ketuk untuk menyapa',
              button: true,
              child: catArt,
            ),
          ),
        ],
      ),
    );
  }
}
