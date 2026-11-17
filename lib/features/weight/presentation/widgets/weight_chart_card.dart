import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/reduce_motion.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/weight_analytics.dart';

/// Kartu grafik progres berat badan menggunakan fl_chart:
/// - Filter 7H / 30H / 90H / Semua
/// - Garis berat harian halus + gradien area bawah + sorotan titik terakhir
/// - Garis tren Moving Average 7 hari
/// - Garis target putus-putus horizontal
/// - Animasi tergambar dari kiri ke kanan saat muncul (menghormati reduce motion)
class WeightChartCard extends StatelessWidget {
  const WeightChartCard({
    super.key,
    required this.points,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.unit,
    this.targetWeightKg,
  });

  final List<WeightChartPoint> points;
  final WeightRangeFilter selectedFilter;
  final ValueChanged<WeightRangeFilter> onFilterChanged;
  final WeightUnit unit;
  final double? targetWeightKg;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final semantic = context.semanticColors;
    final scheme = context.colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Segmented filter 7H / 30H / 90H / Semua
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: semantic.surfaceMuted,
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            ),
            child: Row(
              children: WeightRangeFilter.values.map((filter) {
                final selected = filter == selectedFilter;
                return Expanded(
                  child: Semantics(
                    button: true,
                    selected: selected,
                    label: 'Filter grafik ${filter.label}',
                    child: GestureDetector(
                      onTap: () {
                        MotionUtils.selectionClick();
                        onFilterChanged(filter);
                      },
                      child: AnimatedContainer(
                        duration: MotionUtils.duration(
                          context,
                          AppSpacing.animFast,
                        ),
                        curve: Curves.easeOutCubic,
                        constraints: const BoxConstraints(minHeight: 40),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? semantic.cardSurface
                              : semantic.surfaceMuted.withValues(alpha: 0),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: scheme.shadow,
                                    blurRadius: AppSpacing.xs,
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          filter.label,
                          style: textTheme.labelLarge?.copyWith(
                            color: selected
                                ? scheme.primary
                                : semantic.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Legenda garis grafik
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              _LegendDot(
                color: scheme.secondary,
                label: 'Berat Harian',
              ),
              _LegendDot(
                color: scheme.primary,
                label: 'Tren 7 Hari',
              ),
              if (targetWeightKg != null)
                _LegendDot(
                  color: scheme.tertiary,
                  label: 'Target',
                  isDashed: true,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          if (points.isEmpty)
            SizedBox(
              height: 180,
              child: Center(
                child: Text(
                  'Belum ada catatan pada rentang waktu ini.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: semantic.textSecondary,
                  ),
                ),
              ),
            )
          else
            Semantics(
              label:
                  'Grafik berat badan berisi ${points.length} titik data. Berat terakhir ${AppFormatters.weight(points.last.weightKg, unit: unit)}.',
              child: SizedBox(
                height: 220,
                child: _LeftToRightReveal(
                  revealKey: ValueKey<String>(
                    '${selectedFilter.name}_${points.length}',
                  ),
                  child: _buildLineChart(context),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLineChart(BuildContext context) {
    final scheme = context.colorScheme;
    final semantic = context.semanticColors;
    final textTheme = Theme.of(context).textTheme;

    final weightSpots = <FlSpot>[];
    final maSpots = <FlSpot>[];
    double minVal = double.infinity;
    double maxVal = double.negativeInfinity;

    for (int i = 0; i < points.length; i++) {
      final w = AppFormatters.kgToDisplay(points[i].weightKg, unit);
      final ma = AppFormatters.kgToDisplay(points[i].movingAverage7dKg, unit);
      weightSpots.add(FlSpot(i.toDouble(), w));
      maSpots.add(FlSpot(i.toDouble(), ma));
      minVal = math.min(minVal, math.min(w, ma));
      maxVal = math.max(maxVal, math.max(w, ma));
    }

    double? targetDisplay;
    if (targetWeightKg != null) {
      targetDisplay = AppFormatters.kgToDisplay(targetWeightKg!, unit);
      minVal = math.min(minVal, targetDisplay);
      maxVal = math.max(maxVal, targetDisplay);
    }

    final span = math.max(2.0, maxVal - minVal);
    final minY = (minVal - span * 0.2).floorToDouble();
    final maxY = (maxVal + span * 0.2).ceilToDouble();
    final yInterval = math.max(1.0, ((maxY - minY) / 4).ceilToDouble());
    final xInterval = points.length <= 5
        ? 1.0
        : (points.length / 4).ceilToDouble();

    final maxX = points.length == 1 ? 1.0 : (points.length - 1).toDouble();
    if (points.length == 1) {
      // Untuk 1 titik, tambahkan titik bayangan agar garis & sorotan tetap proporsional
      weightSpots.add(FlSpot(1.0, weightSpots.first.y));
      maSpots.add(FlSpot(1.0, maSpots.first.y));
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (_) => FlLine(
            color: scheme.outlineVariant,
            strokeWidth: AppSpacing.borderThin,
          ),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            if (targetDisplay != null)
              HorizontalLine(
                y: targetDisplay,
                color: scheme.tertiary,
                strokeWidth: AppSpacing.borderMedium,
                dashArray: [6, 5],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.tertiary,
                    fontWeight: FontWeight.w700,
                  ),
                  labelResolver: (_) =>
                      'Target ${AppFormatters.decimal1(targetDisplay!)}',
                ),
              ),
          ],
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              interval: yInterval,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) {
                  return const SizedBox.shrink();
                }
                return Text(
                  value.toStringAsFixed(0),
                  style: textTheme.labelSmall,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: xInterval,
              getTitlesWidget: (value, meta) {
                final idx = value.round();
                if (idx < 0 || idx >= points.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    AppFormatters.shortChartDate(points[idx].date),
                    style: textTheme.labelSmall,
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => scheme.inverseSurface,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.x.round().clamp(0, points.length - 1);
                final point = points[idx];
                if (spot.barIndex == 0) {
                  return LineTooltipItem(
                    '${AppFormatters.shortChartDate(point.date)}\n${AppFormatters.decimal1(spot.y)} ${unit.label}',
                    textTheme.labelSmall!.copyWith(
                      color: scheme.onInverseSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }
                return LineTooltipItem(
                  'Tren 7H: ${AppFormatters.decimal1(spot.y)} ${unit.label}',
                  textTheme.labelSmall!.copyWith(
                    color: scheme.primaryContainer,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          // Bar 0: Berat harian + gradien bawah + titik terakhir disorot
          LineChartBarData(
            spots: weightSpots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: scheme.secondary,
            barWidth: 3.0,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final isLast = index == weightSpots.length - 1;
                return FlDotCirclePainter(
                  radius: isLast ? 5.5 : (points.length <= 14 ? 3.0 : 0.0),
                  color: isLast ? scheme.secondary : semantic.cardSurface,
                  strokeWidth: isLast ? 2.5 : 2.0,
                  strokeColor: isLast ? semantic.cardSurface : scheme.secondary,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  scheme.secondary.withValues(alpha: 0.24),
                  scheme.secondary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          // Bar 1: Garis tren Moving Average 7 Hari
          LineChartBarData(
            spots: maSpots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: scheme.primary.withValues(alpha: 0.85),
            barWidth: 2.0,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
      duration: MotionUtils.duration(context, AppSpacing.animNormal),
      curve: Curves.easeOutCubic,
    );
  }
}

class _LeftToRightReveal extends StatelessWidget {
  const _LeftToRightReveal({
    required this.revealKey,
    required this.child,
  });

  final Key revealKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = MotionUtils.duration(context, AppSpacing.animSlow);
    if (duration == Duration.zero) return child;

    return TweenAnimationBuilder<double>(
      key: revealKey,
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, factor, content) {
        return ClipRect(
          clipper: _WidthFactorClipper(factor),
          child: content,
        );
      },
      child: child,
    );
  }
}

class _WidthFactorClipper extends CustomClipper<Rect> {
  const _WidthFactorClipper(this.factor);
  final double factor;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * factor.clamp(0.0, 1.0), size.height);

  @override
  bool shouldReclip(covariant _WidthFactorClipper oldClipper) =>
      oldClipper.factor != factor;
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    this.isDashed = false,
  });

  final Color color;
  final String label;
  final bool isDashed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: isDashed ? 2.5 : 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
          ),
        ),
        const SizedBox(width: AppSpacing.xs + AppSpacing.xxs),
        Text(label, style: textTheme.labelSmall),
      ],
    );
  }
}
