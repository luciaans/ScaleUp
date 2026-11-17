import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils_ext.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/reduce_motion.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/calorie_models.dart';

/// Grafik batang (BarChart) riwayat asupan kalori harian selama 7 hari terakhir.
class WeeklyCalorieChartCard extends StatelessWidget {
  const WeeklyCalorieChartCard({
    super.key,
    required this.series,
    required this.targetCalories,
    required this.selectedDate,
  });

  final List<DailyCaloriePoint> series;
  final int targetCalories;
  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final semantic = context.semanticColors;
    final scheme = context.colorScheme;

    double maxBar = targetCalories.toDouble();
    for (final p in series) {
      maxBar = math.max(maxBar, p.totalCalories);
    }
    final maxY = math.max(1500.0, (maxBar * 1.2).ceilToDouble());
    final interval = (maxY / 3).ceilToDouble();

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Riwayat Kalori 7 Hari',
                  style: textTheme.titleMedium,
                ),
              ),
              Text(
                'Target ${AppFormatters.calories(targetCalories)}',
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            label: 'Grafik batang kalori harian selama 7 hari terakhir',
            child: SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: interval,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: scheme.outlineVariant,
                      strokeWidth: AppSpacing.borderThin,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: targetCalories.toDouble(),
                        color: scheme.primary,
                        strokeWidth: AppSpacing.borderMedium,
                        dashArray: [5, 5],
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
                        interval: interval,
                        getTitlesWidget: (value, meta) {
                          if (value == 0 || value >= meta.max) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            value.toInt().toString(),
                            style: textTheme.labelSmall,
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, _) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= series.length) {
                            return const SizedBox.shrink();
                          }
                          final isSelected = AppDateUtils.isSameDay(
                            series[idx].date,
                            selectedDate,
                          );
                          return Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xs),
                            child: Text(
                              AppFormatters.shortChartDate(series[idx].date),
                              style: textTheme.labelSmall?.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? scheme.tertiary
                                    : semantic.textSecondary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => scheme.inverseSurface,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final point = series[group.x];
                        return BarTooltipItem(
                          '${AppFormatters.shortChartDate(point.date)}\n${AppFormatters.calories(rod.toY)}',
                          textTheme.labelSmall!.copyWith(
                            color: scheme.onInverseSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      },
                    ),
                  ),
                  barGroups: List<BarChartGroupData>.generate(
                    series.length,
                    (idx) {
                      final point = series[idx];
                      final isSelected = AppDateUtils.isSameDay(
                        point.date,
                        selectedDate,
                      );
                      final isOver = point.totalCalories > targetCalories * 1.08;
                      final barColor = isOver
                          ? scheme.tertiary
                          : (isSelected
                              ? scheme.primary
                              : scheme.primary.withValues(alpha: 0.55));

                      return BarChartGroupData(
                        x: idx,
                        barRods: [
                          BarChartRodData(
                            toY: point.totalCalories,
                            width: 18,
                            color: barColor,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(AppSpacing.radiusSm),
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: maxY,
                              color: semantic.surfaceMuted,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                duration: MotionUtils.duration(context, AppSpacing.animNormal),
                curve: Curves.easeOutCubic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
