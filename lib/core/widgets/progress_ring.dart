import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../constants/app_spacing.dart';
import '../theme/app_colors.dart';
import '../utils/reduce_motion.dart';

/// Dial radial presisi bergaya Nixtio dengan tick marks halus, busur halus,
/// dan titik indikator bercahaya di ujung progres.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 120.0,
    this.strokeWidth = AppSpacing.ringStrokeMd,
    this.color,
    this.trackColor,
    this.showTicks = true,
    this.center,
    this.semanticLabel,
  });

  final double progress;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? trackColor;
  final bool showTicks;
  final Widget? center;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.isNaN || progress.isInfinite
        ? 0.0
        : progress.clamp(0.0, 1.0);
    final activeColor = color ?? context.colorScheme.primary;
    final bgTrackColor = trackColor ?? context.semanticColors.surfaceMuted;
    final duration = MotionUtils.duration(context, AppSpacing.animSlow);

    return Semantics(
      label: semanticLabel ?? 'Progres ${(clamped * 100).round()} persen',
      child: SizedBox(
        width: size,
        height: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: clamped),
          duration: duration,
          curve: Curves.easeOutCubic,
          builder: (context, animatedValue, child) {
            return CustomPaint(
              painter: _NixtioGaugePainter(
                progress: animatedValue,
                strokeWidth: strokeWidth,
                activeColor: activeColor,
                trackColor: bgTrackColor,
                showTicks: showTicks,
              ),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(strokeWidth + AppSpacing.sm),
                  child: child,
                ),
              ),
            );
          },
          child: center,
        ),
      ),
    );
  }
}

class _NixtioGaugePainter extends CustomPainter {
  const _NixtioGaugePainter({
    required this.progress,
    required this.strokeWidth,
    required this.activeColor,
    required this.trackColor,
    required this.showTicks,
  });

  final double progress;
  final double strokeWidth;
  final Color activeColor;
  final Color trackColor;
  final bool showTicks;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = (math.min(size.width, size.height) - strokeWidth) / 2;
    if (outerRadius <= 0) return;

    // 1. Tick marks radial halus di bagian dalam dial (gaya smartwatch / bio-gauge)
    if (showTicks && outerRadius > 32) {
      const tickCount = 36;
      final tickOuter = outerRadius - strokeWidth * 0.85;
      final tickInner = tickOuter - 4.0;
      final tickPaint = Paint()
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < tickCount; i++) {
        final fraction = i / tickCount;
        final angle = -math.pi / 2 + (2 * math.pi * fraction);
        final isLit = fraction <= progress && progress > 0.005;
        tickPaint.color = isLit
            ? activeColor.withValues(alpha: 0.55)
            : trackColor.withValues(alpha: 0.65);

        final p1 = Offset(
          center.dx + tickInner * math.cos(angle),
          center.dy + tickInner * math.sin(angle),
        );
        final p2 = Offset(
          center.dx + tickOuter * math.cos(angle),
          center.dy + tickOuter * math.sin(angle),
        );
        canvas.drawLine(p1, p2, tickPaint);
      }
    }

    // 2. Track lingkaran dasar
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, outerRadius, trackPaint);

    // 3. Busur aktif bercahaya + glowing bead di ujungnya
    if (progress > 0.002) {
      const startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * progress;
      final rect = Rect.fromCircle(center: center, radius: outerRadius);

      // Soft outer glow tipis
      final glowPaint = Paint()
        ..color = activeColor.withValues(alpha: 0.24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 4
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);

      final activePaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, sweepAngle, false, activePaint);

      // Titik indikator putih kecil di ujung busur progres
      if (strokeWidth >= 8) {
        final endAngle = startAngle + sweepAngle;
        final tipCenter = Offset(
          center.dx + outerRadius * math.cos(endAngle),
          center.dy + outerRadius * math.sin(endAngle),
        );
        final dotPaint = Paint()..color = AppColors.snowCream;
        canvas.drawCircle(tipCenter, strokeWidth * 0.24, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NixtioGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.showTicks != showTicks;
  }
}
