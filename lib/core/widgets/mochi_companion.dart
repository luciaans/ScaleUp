import 'package:material_ui/material_ui.dart';

import '../constants/app_spacing.dart';
import '../theme/app_colors.dart';
import '../utils/reduce_motion.dart';

///Koleksi foto stiker Kucing Meme ekspresif bergaya internet/Pinterest meme.
enum MochiPose {
  welcome('assets/cats/meme_welcome.jpg', 'Mantap!'),
  think('assets/cats/meme_think.jpg', 'Mikir Dulu'),
  chef('assets/cats/meme_eat.jpg', 'Makan Enak'),
  shock('assets/cats/meme_shock.jpg', 'Waduh!'),
  cheer('assets/cats/meme_active.jpg', 'Gas Otw!'),
  nap('assets/cats/meme_chill.jpg', 'Santai~');

  const MochiPose(this.assetPath, this.stickerTag);
  final String assetPath;
  final String stickerTag;
}

/// Stiker Foto Kucing Meme interaktif:
/// - Bingkai foto-stiker putih glossy dengan sudut membulat & bayangan lembut
/// - Saat diketuk pada mode Hero, membal ringan & mengganti ekspresi meme + teks reaksi
class MochiCompanion extends StatefulWidget {
  const MochiCompanion({
    super.key,
    required this.pose,
    this.size = 180,
    this.quotes = const [],
    this.showFramedBadge = false,
    this.cyclePosesOnTap = false,
  });

  final MochiPose pose;
  final double size;
  final List<String> quotes;
  final bool showFramedBadge;
  final bool cyclePosesOnTap;

  @override
  State<MochiCompanion> createState() => _MochiCompanionState();
}

class _MochiCompanionState extends State<MochiCompanion> {
  int _tapCount = 0;
  bool _isSquished = false;

  MochiPose get _activePose {
    if (!widget.cyclePosesOnTap || _tapCount == 0) {
      return widget.pose;
    }
    final all = MochiPose.values;
    final startIdx = all.indexOf(widget.pose);
    return all[(startIdx + _tapCount) % all.length];
  }

  void _handleTap() {
    MotionUtils.selectionClick();
    setState(() {
      _isSquished = true;
      _tapCount += 1;
    });
    Future<void>.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() => _isSquished = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = context.colorScheme;
    final semantic = context.semanticColors;
    final reduceMotion = MotionUtils.shouldReduceMotion(context);
    final activePose = _activePose;
    final isCompact = widget.showFramedBadge || widget.size < 100;

    final activeQuote = widget.quotes.isNotEmpty
        ? widget.quotes[_tapCount % widget.quotes.length]
        : null;

    final framePadding = isCompact ? 3.0 : 7.0;
    final outerRadius = isCompact
        ? (widget.size * 0.30).clamp(12.0, 22.0)
        : 28.0;
    final innerRadius = (outerRadius - framePadding).clamp(8.0, 22.0);

    Widget photoSticker = Container(
      width: widget.size,
      height: widget.size,
      padding: EdgeInsets.all(framePadding),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(outerRadius),
        border: Border.all(
          color: scheme.outlineVariant,
          width: isCompact ? 1.0 : 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.carbonInk.withValues(alpha: isCompact ? 0.10 : 0.14),
            offset: Offset(0, isCompact ? 3 : 10),
            blurRadius: isCompact ? 8 : 24,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(innerRadius),
        child: AnimatedSwitcher(
          duration: MotionUtils.duration(context, AppSpacing.animFast),
          child: Image.asset(
            activePose.assetPath,
            key: ValueKey<String>(activePose.assetPath),
            width: widget.size,
            height: widget.size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => ColoredBox(
              color: semantic.surfaceMuted,
              child: Icon(
                Icons.pets_rounded,
                size: widget.size * 0.45,
                color: semantic.heroAccent,
              ),
            ),
          ),
        ),
      ),
    );

    if (!isCompact) {
      final tiltAngle = reduceMotion
          ? 0.0
          : (_tapCount.isEven ? -0.022 : 0.022);

      photoSticker = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomRight,
        children: [
          AnimatedRotation(
            turns: tiltAngle / (2 * 3.14159265),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            child: photoSticker,
          ),
          Positioned(
            right: -6,
            bottom: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + 4,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: AppColors.carbonInk,
                borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                border: Border.all(color: AppColors.pureWhite, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.carbonInk.withValues(alpha: 0.18),
                    offset: const Offset(0, 4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.pets_rounded,
                    size: 13,
                    color: AppColors.amberPop,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    activePose.stickerTag,
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.pureWhite,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (activeQuote != null) ...[
            AnimatedSwitcher(
              duration: MotionUtils.duration(context, AppSpacing.animFast),
              child: Container(
                key: ValueKey<String>(activeQuote),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 2,
                ),
                decoration: BoxDecoration(
                  color: semantic.cardSurface,
                  borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                  border: Border.all(color: scheme.outlineVariant),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.shadow,
                      offset: const Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.chat_bubble_rounded,
                      size: 14,
                      color: semantic.heroAccent,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        activeQuote,
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
            const SizedBox(height: AppSpacing.sm + 4),
          ],
          AnimatedScale(
            scale: _isSquished && !reduceMotion ? 0.93 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutBack,
            child: Semantics(
              label: 'Stiker kucing meme, ketuk untuk ganti ekspresi',
              button: true,
              child: photoSticker,
            ),
          ),
        ],
      ),
    );
  }
}
