import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../constants/app_spacing.dart';
import '../theme/app_colors.dart';
import '../utils/reduce_motion.dart';

/// Ring progres melingkar dengan animasi TweenAnimationBuilder dari 0 ke nilai.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 120.0,
    this.strokeWidth = AppSpacing.ringStrokeMd,
    this.color,
    this.trackColor,
    this.center,
    this.semanticLabel,
  });

  /// Nilai progres antara 0.0 hingga 1.0 (akan di-clamp dengan aman).
  final double progress;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? trackColor;
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
              painter: _RingPainter(
                progress: animatedValue,
                strokeWidth: strokeWidth,
                activeColor: activeColor,
                trackColor: bgTrackColor,
              ),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(strokeWidth + AppSpacing.xs),
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

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.activeColor,
    required this.trackColor,
  });

  final double progress;
  final double strokeWidth;
  final Color activeColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    if (radius <= 0) return;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0.001) {
      final activePaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final rect = Rect.fromCircle(center: center, radius: radius);
      const startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(rect, startAngle, sweepAngle, false, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.trackColor != trackColor;
  }
}
