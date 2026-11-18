import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../constants/app_constants.dart';
import '../constants/app_spacing.dart';
import '../theme/app_colors.dart';
import '../utils/date_utils_ext.dart';
import '../utils/reduce_motion.dart';

/// Strip kalender 7 hari berbentuk kapsul stiker hitam-krem dengan titik Sakura Blush.
class DateStripSelector extends StatelessWidget {
  const DateStripSelector({
    super.key,
    required this.selectedDate,
    this.loggedIsoDates = const <String>{},
    this.onDateSelected,
  });

  final DateTime selectedDate;
  final Set<String> loggedIsoDates;
  final ValueChanged<DateTime>? onDateSelected;

  @override
  Widget build(BuildContext context) {
    final today = AppDateUtils.today();
    final semantic = context.semanticColors;
    final scheme = context.colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final anchorEnd = selectedDate.isBefore(
      DateTime(today.year, today.month, today.day - 6),
    )
        ? selectedDate
        : today;

    final days = List<DateTime>.generate(7, (idx) {
      final offset = 6 - idx;
      return DateTime(anchorEnd.year, anchorEnd.month, anchorEnd.day - offset);
    });

    return Row(
      children: days.map((date) {
        final isSelected = AppDateUtils.isSameDay(date, selectedDate);
        final isToday = AppDateUtils.isSameDay(date, today);
        final isoKey = AppDateUtils.toIsoDateKey(date);
        final hasLog = loggedIsoDates.contains(isoKey);
        final dayLabel = DateFormat('EEE', AppConstants.localeId)
            .format(date)
            .replaceAll('.', '');

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.5),
            child: GestureDetector(
              onTap: onDateSelected != null
                  ? () {
                      MotionUtils.selectionClick();
                      onDateSelected!(date);
                    }
                  : null,
              child: AnimatedContainer(
                duration: MotionUtils.duration(context, AppSpacing.animFast),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm + 2,
                  horizontal: 2,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? scheme.primary : semantic.cardSurface,
                  borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                  border: Border.all(
                    color: isSelected
                        ? scheme.primary
                        : (isToday ? scheme.onSurface : scheme.outlineVariant),
                    width: isSelected || isToday ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        dayLabel,
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 10.5,
                          color: isSelected
                              ? scheme.onPrimary.withValues(alpha: 0.85)
                              : semantic.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? scheme.onPrimary
                            : semantic.surfaceMuted,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${date.day}',
                          style: textTheme.labelLarge?.copyWith(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasLog
                            ? AppColors.sakuraBlush
                            : semantic.cardSurface.withValues(alpha: 0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
