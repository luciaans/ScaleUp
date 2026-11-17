import 'package:material_ui/material_ui.dart';
import 'package:shimmer/shimmer.dart';

import '../constants/app_spacing.dart';
import '../theme/app_colors.dart';
import '../utils/reduce_motion.dart';

/// Kotak kerangka loading (skeleton shimmer) yang menghormati tema dan reduce motion.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = AppSpacing.cardRadius,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final box = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: semantic.shimmerBase,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );

    if (MotionUtils.shouldReduceMotion(context)) {
      return Semantics(label: 'Memuat data', child: box);
    }

    return Semantics(
      label: 'Memuat data',
      child: Shimmer.fromColors(
        baseColor: semantic.shimmerBase,
        highlightColor: semantic.shimmerHighlight,
        child: box,
      ),
    );
  }
}
