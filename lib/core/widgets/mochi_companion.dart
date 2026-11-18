import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../constants/app_spacing.dart';
import '../theme/app_colors.dart';
import '../utils/reduce_motion.dart';

/// Koleksi stiker kucing meme asli berformat PNG transparan (non-AI, cutout murni).
enum MochiPose {
  welcome('assets/cats/cat_thumbsup.png', 'Mantap 👍'),
  think('assets/cats/cat_polite.png', 'Sopan~'),
  chef('assets/cats/cat_smudge.png', 'Cek Piring!'),
  shock('assets/cats/cat_ganbatte.png', 'Tahan Bos!'),
  cheer('assets/cats/cat_pop_closed.png', 'POP!'),
  popOpen('assets/cats/cat_pop_open.png', 'POP!! 😮'),
  nap('assets/cats/cat_apple.png', 'Segar 🍎');

  const MochiPose(this.assetPath, this.stickerTag);
  final String assetPath;
  final String stickerTag;
}

/// Maskot Kucing Meme PNG Transparan bergaya Die-Cut Vinyl Sticker:
/// - Tanpa kotak latar (100% alpha PNG cutout mengikuti lekuk telinga & kumis kucing)
/// - Dilengkapi garis tepi stiker putih otomatis (die-cut contour) + bayangan lembut
/// - Interaktif saat diketuk (efek Popcat membuka mulut & ganti ekspresi meme)
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
    if (!widget.cyclePosesOnTap) {
      // Jika pose Popcat diketuk, buka mulutnya sesaat seperti game Popcat!
      if (widget.pose == MochiPose.cheer && _isSquished) {
        return MochiPose.popOpen;
      }
      return widget.pose;
    }
    if (_tapCount == 0) {
      return widget.pose;
    }
    const all = MochiPose.values;
    final startIdx = all.indexOf(widget.pose);
    return all[(startIdx + _tapCount) % all.length];
  }

  void _handleTap() {
    MotionUtils.selectionClick();
    setState(() {
      _isSquished = true;
      _tapCount += 1;
    });
    Future<void>.delayed(const Duration(milliseconds: 180), () {
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

    Widget dieCutSticker = _DieCutCatPng(
      assetPath: activePose.assetPath,
      size: widget.size,
      strokeWidth: isCompact ? 2.4 : 4.5,
      showSoftHalo: widget.showFramedBadge,
    );

    if (!isCompact) {
      final tiltAngle = reduceMotion
          ? 0.0
          : (_tapCount.isEven ? -0.025 : 0.025);

      dieCutSticker = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomRight,
        children: [
          AnimatedRotation(
            turns: tiltAngle / (2 * math.pi),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: AnimatedSwitcher(
              duration: MotionUtils.duration(context, AppSpacing.animFast),
              child: KeyedSubtree(
                key: ValueKey<String>(activePose.assetPath),
                child: dieCutSticker,
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: 0,
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
              child: Text(
                activePose.stickerTag,
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.pureWhite,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
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
            scale: _isSquished && !reduceMotion ? 0.92 : 1.0,
            duration: const Duration(milliseconds: 130),
            curve: Curves.easeOutBack,
            child: Semantics(
              label: 'Stiker PNG kucing meme, ketuk untuk ganti ekspresi',
              button: true,
              child: dieCutSticker,
            ),
          ),
        ],
      ),
    );
  }
}

/// Merender PNG transparan dengan efek garis potong stiker putih (die-cut vinyl outline)
/// dan bayangan siluet lembut tanpa kotak latar sama sekali.
class _DieCutCatPng extends StatelessWidget {
  const _DieCutCatPng({
    required this.assetPath,
    required this.size,
    required this.strokeWidth,
    required this.showSoftHalo,
  });

  final String assetPath;
  final double size;
  final double strokeWidth;
  final bool showSoftHalo;

  Widget _rawImage(BuildContext context) {
    final semantic = context.semanticColors;
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => Icon(
        Icons.pets_rounded,
        size: size * 0.55,
        color: semantic.heroAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    const directions = <Offset>[
      Offset(-1, 0),
      Offset(1, 0),
      Offset(0, -1),
      Offset(0, 1),
      Offset(-0.72, -0.72),
      Offset(0.72, -0.72),
      Offset(-0.72, 0.72),
      Offset(0.72, 0.72),
    ];

    return SizedBox(
      width: size + strokeWidth * 2,
      height: size + strokeWidth * 2,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (showSoftHalo)
            Container(
              width: size * 0.88,
              height: size * 0.88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primaryContainer,
              ),
            ),
          // Bayangan siluet PNG transparan
          Transform.translate(
            offset: Offset(0, strokeWidth * 1.4),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                AppColors.carbonInk.withValues(alpha: 0.16),
                BlendMode.srcIn,
              ),
              child: _rawImage(context),
            ),
          ),
          // Garis tepi putih Die-Cut mengikuti bentuk transparan PNG kucing
          for (final dir in directions)
            Transform.translate(
              offset: Offset(dir.dx * strokeWidth, dir.dy * strokeWidth),
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  AppColors.pureWhite,
                  BlendMode.srcIn,
                ),
                child: _rawImage(context),
              ),
            ),
          // Gambar PNG transparan asli di atasnya
          _rawImage(context),
        ],
      ),
    );
  }
}
