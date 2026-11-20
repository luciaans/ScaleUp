import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../constants/app_spacing.dart';

/// Sistem tipografi ScaleUp:
/// - Heading & angka: Manrope, tegas dengan bentuk yang tetap ramah.
/// - Teks isi & label: DM Sans, ringkas dan nyaman dibaca di layar kecil.
abstract final class AppTextStyles {
  static const bodyFontFamily = 'DM Sans';

  static TextTheme buildTextTheme(Color primaryText, Color secondaryText) {
    final baseBody = GoogleFonts.dmSansTextTheme();
    final headingFont = GoogleFonts.manrope;
    final bodyFont = GoogleFonts.dmSans;

    return baseBody.copyWith(
      displayLarge: headingFont(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        height: 1.12,
        letterSpacing: -0.6,
        color: primaryText,
      ),
      displayMedium: headingFont(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.5,
        color: primaryText,
      ),
      displaySmall: headingFont(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: primaryText,
      ),
      headlineLarge: headingFont(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.22,
        color: primaryText,
      ),
      headlineMedium: headingFont(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.26,
        color: primaryText,
      ),
      headlineSmall: headingFont(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: primaryText,
      ),
      titleLarge: headingFont(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.32,
        color: primaryText,
      ),
      titleMedium: headingFont(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.35,
        color: primaryText,
      ),
      titleSmall: bodyFont(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.38,
        color: primaryText,
      ),
      bodyLarge: bodyFont(
        fontSize: 15.5,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: primaryText,
      ),
      bodyMedium: bodyFont(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.48,
        color: primaryText,
      ),
      bodySmall: bodyFont(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.45,
        color: secondaryText,
      ),
      labelLarge: bodyFont(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.32,
        color: primaryText,
      ),
      labelMedium: bodyFont(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.32,
        color: secondaryText,
      ),
      labelSmall: bodyFont(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.28,
        color: secondaryText,
      ),
    );
  }

  /// Angka utama (berat, kalori) membulat tegas dengan tabular figures.
  static TextStyle heroNumber(
    BuildContext context, {
    double fontSize = AppSpacing.heroNumberLg,
    Color? color,
  }) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.onSurface;
    return GoogleFonts.manrope(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      height: 1.06,
      letterSpacing: -0.8,
      color: effectiveColor,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static TextStyle tabularValue(
    BuildContext context, {
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
  }) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.onSurface;
    return GoogleFonts.manrope(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: 1.18,
      color: effectiveColor,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}
