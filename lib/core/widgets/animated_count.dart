import 'package:material_ui/material_ui.dart';

import '../constants/app_spacing.dart';
import '../utils/reduce_motion.dart';

/// Widget angka yang beranimasi count-up secara mulus saat nilainya berubah.
class AnimatedCount extends StatelessWidget {
  const AnimatedCount({
    super.key,
    required this.value,
    required this.formatter,
    required this.style,
    this.duration = AppSpacing.animSlow,
    this.textAlign,
  });

  final double value;
  final String Function(double value) formatter;
  final TextStyle style;
  final Duration duration;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final effectiveDuration = MotionUtils.duration(context, duration);
    if (effectiveDuration == Duration.zero) {
      return Text(
        formatter(value),
        style: style,
        textAlign: textAlign,
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value),
      duration: effectiveDuration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        return Text(
          formatter(animatedValue),
          style: style,
          textAlign: textAlign,
        );
      },
    );
  }
}
