import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_spacing.dart';

/// Sistem tipografi ScaleUp:
/// - Heading: Plus Jakarta Sans
/// - Body & Label: Inter
/// - Angka besar: 40-56 sp, bold, tabular figures
abstract final class AppTextStyles {
  static TextTheme buildTextTheme(Color primaryText, Color secondaryText) {
    final baseBody = GoogleFonts.interTextTheme();
    final headingFont = GoogleFonts.plusJakartaSans;
    final bodyFont = GoogleFonts.inter;

    return baseBody.copyWith(
      displayLarge: headingFont(
        fontSize: 52,
        fontWeight: FontWeight.w800,
        height: 1.12,
        letterSpacing: -1.0,
        color: primaryText,
      ),
      displayMedium: headingFont(
        fontSize: 44,
        fontWeight: FontWeight.w800,
        height: 1.15,
        letterSpacing: -0.8,
        color: primaryText,
      ),
      displaySmall: headingFont(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
        color: primaryText,
      ),
      headlineLarge: headingFont(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.4,
        color: primaryText,
      ),
      headlineMedium: headingFont(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.28,
        letterSpacing: -0.3,
        color: primaryText,
      ),
      headlineSmall: headingFont(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: -0.2,
        color: primaryText,
      ),
      titleLarge: headingFont(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.35,
        color: primaryText,
      ),
      titleMedium: headingFont(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: primaryText,
      ),
      titleSmall: headingFont(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: primaryText,
      ),
      bodyLarge: bodyFont(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: primaryText,
      ),
      bodyMedium: bodyFont(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.48,
        color: primaryText,
      ),
      bodySmall: bodyFont(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: secondaryText,
      ),
      labelLarge: bodyFont(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: primaryText,
      ),
      labelMedium: bodyFont(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: secondaryText,
      ),
      labelSmall: bodyFont(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: secondaryText,
      ),
    );
  }

  /// Gaya angka utama (berat, kalori): 40-56 sp, bold, tabular figures.
  static TextStyle heroNumber(
    BuildContext context, {
    double fontSize = AppSpacing.heroNumberLg,
    Color? color,
  }) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.onSurface;
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      height: 1.08,
      letterSpacing: -1.0,
      color: effectiveColor,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Gaya angka statistik sedang dengan tabular figures.
  static TextStyle tabularValue(
    BuildContext context, {
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
  }) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.onSurface;
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: 1.2,
      color: effectiveColor,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}
