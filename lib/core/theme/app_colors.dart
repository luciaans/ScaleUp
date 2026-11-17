import 'package:material_ui/material_ui.dart';

/// Palet warna modern gaya Nixtio ("AI Nutrition & Health Tracking"):
/// Menggabungkan kanvas organik bersih, Hero Obsidian Bento Card kontras tinggi,
/// dan aksen segar Emerald-Lime, Electric Sky, serta Warm Coral.
abstract final class AppColors {
  // ================= LIGHT PALETTE =================
  static const Color lightPrimary = Color(0xFF16A34A);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightPrimaryContainer = Color(0xFFDCFCE7);
  static const Color lightOnPrimaryContainer = Color(0xFF052E16);

  static const Color lightSecondary = Color(0xFF0EA5E9);
  static const Color lightOnSecondary = Color(0xFFFFFFFF);
  static const Color lightSecondaryContainer = Color(0xFFE0F2FE);
  static const Color lightOnSecondaryContainer = Color(0xFF082F49);

  static const Color lightTertiary = Color(0xFFF97316);
  static const Color lightOnTertiary = Color(0xFFFFFFFF);
  static const Color lightTertiaryContainer = Color(0xFFFFEDD5);
  static const Color lightOnTertiaryContainer = Color(0xFF431407);

  // Kanvas organik lembut agar kartu putih & kartu obsidian menonjol tajam
  static const Color lightBackground = Color(0xFFF2F5F3);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFE7ECE9);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextMuted = Color(0xFF64748B);
  static const Color lightOutline = Color(0xFFE2E8E4);
  static const Color lightOutlineStrong = Color(0xFFCBD5CE);

  static const Color lightError = Color(0xFFEF4444);
  static const Color lightOnError = Color(0xFFFFFFFF);
  static const Color lightErrorContainer = Color(0xFFFEE2E2);
  static const Color lightOnErrorContainer = Color(0xFF7F1D1D);
  static const Color lightSuccess = Color(0xFF22C55E);

  // ================= DARK PALETTE =================
  static const Color darkPrimary = Color(0xFF84CC16); // Vibrant Lime-Green khas Nixtio dark mode
  static const Color darkOnPrimary = Color(0xFF0B1404);
  static const Color darkPrimaryContainer = Color(0xFF1E3512);
  static const Color darkOnPrimaryContainer = Color(0xFFECFCCB);

  static const Color darkSecondary = Color(0xFF38BDF8);
  static const Color darkOnSecondary = Color(0xFF082F49);
  static const Color darkSecondaryContainer = Color(0xFF0F2D44);
  static const Color darkOnSecondaryContainer = Color(0xFFE0F2FE);

  static const Color darkTertiary = Color(0xFFFB923C);
  static const Color darkOnTertiary = Color(0xFF431407);
  static const Color darkTertiaryContainer = Color(0xFF3B1D0E);
  static const Color darkOnTertiaryContainer = Color(0xFFFFEDD5);

  static const Color darkBackground = Color(0xFF090D12);
  static const Color darkSurface = Color(0xFF131922);
  static const Color darkSurfaceVariant = Color(0xFF1C2430);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkOutline = Color(0xFF222D3D);
  static const Color darkOutlineStrong = Color(0xFF334155);

  static const Color darkError = Color(0xFFF87171);
  static const Color darkOnError = Color(0xFF450A0A);
  static const Color darkErrorContainer = Color(0xFF451212);
  static const Color darkOnErrorContainer = Color(0xFFFEE2E2);
  static const Color darkSuccess = Color(0xFF84CC16);

  // ================= HERO OBSIDIAN & LIME ACCENTS =================
  static const Color obsidianCard = Color(0xFF111714);
  static const Color obsidianCardElevated = Color(0xFF1B2420);
  static const Color obsidianCardDarkTheme = Color(0xFF161F1B);
  static const Color electricLime = Color(0xFFA3E635);
  static const Color electricMint = Color(0xFF4ADE80);
  static const Color softViolet = Color(0xFFA78BFA);

  static const Color shadowLight = Color(0x0C0F172A);
  static const Color shadowDark = Color(0x40000000);
  static const Color scrim = Color(0x73090D12);

  static ColorScheme get lightColorScheme => const ColorScheme(
        brightness: Brightness.light,
        primary: lightPrimary,
        onPrimary: lightOnPrimary,
        primaryContainer: lightPrimaryContainer,
        onPrimaryContainer: lightOnPrimaryContainer,
        secondary: lightSecondary,
        onSecondary: lightOnSecondary,
        secondaryContainer: lightSecondaryContainer,
        onSecondaryContainer: lightOnSecondaryContainer,
        tertiary: lightTertiary,
        onTertiary: lightOnTertiary,
        tertiaryContainer: lightTertiaryContainer,
        onTertiaryContainer: lightOnTertiaryContainer,
        error: lightError,
        onError: lightOnError,
        errorContainer: lightErrorContainer,
        onErrorContainer: lightOnErrorContainer,
        surface: lightSurface,
        onSurface: lightTextPrimary,
        surfaceContainerHighest: lightSurfaceVariant,
        onSurfaceVariant: lightTextMuted,
        outline: lightOutlineStrong,
        outlineVariant: lightOutline,
        shadow: shadowLight,
        scrim: scrim,
      );

  static ColorScheme get darkColorScheme => const ColorScheme(
        brightness: Brightness.dark,
        primary: darkPrimary,
        onPrimary: darkOnPrimary,
        primaryContainer: darkPrimaryContainer,
        onPrimaryContainer: darkOnPrimaryContainer,
        secondary: darkSecondary,
        onSecondary: darkOnSecondary,
        secondaryContainer: darkSecondaryContainer,
        onSecondaryContainer: darkOnSecondaryContainer,
        tertiary: darkTertiary,
        onTertiary: darkOnTertiary,
        tertiaryContainer: darkTertiaryContainer,
        onTertiaryContainer: darkOnTertiaryContainer,
        error: darkError,
        onError: darkOnError,
        errorContainer: darkErrorContainer,
        onErrorContainer: darkOnErrorContainer,
        surface: darkSurface,
        onSurface: darkTextPrimary,
        surfaceContainerHighest: darkSurfaceVariant,
        onSurfaceVariant: darkTextSecondary,
        outline: darkOutlineStrong,
        outlineVariant: darkOutline,
        shadow: shadowDark,
        scrim: scrim,
      );
}

/// Warna semantik Bento & Hero agar seluruh widget bebas hardcode warna.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.background,
    required this.cardSurface,
    required this.surfaceMuted,
    required this.textSecondary,
    required this.success,
    required this.successContainer,
    required this.goalLose,
    required this.goalLoseContainer,
    required this.goalGain,
    required this.goalGainContainer,
    required this.goalMaintain,
    required this.goalMaintainContainer,
    required this.proteinColor,
    required this.carbsColor,
    required this.fatColor,
    required this.shimmerBase,
    required this.shimmerHighlight,
    required this.heroCardBg,
    required this.heroCardSurface,
    required this.heroCardFg,
    required this.heroCardMuted,
    required this.heroAccent,
    required this.dockBg,
    required this.dockBorder,
    required this.dockActivePill,
    required this.dockActiveFg,
    required this.dockInactiveFg,
  });

  final Color background;
  final Color cardSurface;
  final Color surfaceMuted;
  final Color textSecondary;
  final Color success;
  final Color successContainer;

  final Color goalLose;
  final Color goalLoseContainer;
  final Color goalGain;
  final Color goalGainContainer;
  final Color goalMaintain;
  final Color goalMaintainContainer;

  final Color proteinColor;
  final Color carbsColor;
  final Color fatColor;

  final Color shimmerBase;
  final Color shimmerHighlight;

  /// Kartu Hero kontras tinggi khas Nixtio (Obsidian + Electric Lime)
  final Color heroCardBg;
  final Color heroCardSurface;
  final Color heroCardFg;
  final Color heroCardMuted;
  final Color heroAccent;

  /// Floating Pill Dock Navigation Bar
  final Color dockBg;
  final Color dockBorder;
  final Color dockActivePill;
  final Color dockActiveFg;
  final Color dockInactiveFg;

  static const AppSemanticColors light = AppSemanticColors(
    background: AppColors.lightBackground,
    cardSurface: AppColors.lightSurface,
    surfaceMuted: AppColors.lightSurfaceVariant,
    textSecondary: AppColors.lightTextMuted,
    success: AppColors.lightSuccess,
    successContainer: AppColors.lightPrimaryContainer,
    goalLose: AppColors.lightSecondary,
    goalLoseContainer: AppColors.lightSecondaryContainer,
    goalGain: AppColors.lightTertiary,
    goalGainContainer: AppColors.lightTertiaryContainer,
    goalMaintain: AppColors.lightPrimary,
    goalMaintainContainer: AppColors.lightPrimaryContainer,
    proteinColor: Color(0xFF0EA5E9),
    carbsColor: Color(0xFF65A30D),
    fatColor: Color(0xFFF97316),
    shimmerBase: Color(0xFFE2E8E4),
    shimmerHighlight: Color(0xFFF8FAF9),
    heroCardBg: AppColors.obsidianCard,
    heroCardSurface: AppColors.obsidianCardElevated,
    heroCardFg: Color(0xFFF8FAFC),
    heroCardMuted: Color(0xFF94A39B),
    heroAccent: AppColors.electricLime,
    dockBg: Color(0xF0111714),
    dockBorder: Color(0xFF26312B),
    dockActivePill: Color(0xFF233029),
    dockActiveFg: AppColors.electricLime,
    dockInactiveFg: Color(0xFF94A39B),
  );

  static const AppSemanticColors dark = AppSemanticColors(
    background: AppColors.darkBackground,
    cardSurface: AppColors.darkSurface,
    surfaceMuted: AppColors.darkSurfaceVariant,
    textSecondary: AppColors.darkTextSecondary,
    success: AppColors.darkSuccess,
    successContainer: AppColors.darkPrimaryContainer,
    goalLose: AppColors.darkSecondary,
    goalLoseContainer: AppColors.darkSecondaryContainer,
    goalGain: AppColors.darkTertiary,
    goalGainContainer: AppColors.darkTertiaryContainer,
    goalMaintain: AppColors.darkPrimary,
    goalMaintainContainer: AppColors.darkPrimaryContainer,
    proteinColor: Color(0xFF38BDF8),
    carbsColor: AppColors.electricLime,
    fatColor: Color(0xFFFB923C),
    shimmerBase: Color(0xFF1B2430),
    shimmerHighlight: Color(0xFF263344),
    heroCardBg: AppColors.obsidianCardDarkTheme,
    heroCardSurface: Color(0xFF212D27),
    heroCardFg: Color(0xFFF8FAFC),
    heroCardMuted: Color(0xFF9CA3AF),
    heroAccent: AppColors.electricLime,
    dockBg: Color(0xF2151C26),
    dockBorder: Color(0xFF273446),
    dockActivePill: Color(0xFF233029),
    dockActiveFg: AppColors.electricLime,
    dockInactiveFg: Color(0xFF94A3B8),
  );

  @override
  AppSemanticColors copyWith({
    Color? background,
    Color? cardSurface,
    Color? surfaceMuted,
    Color? textSecondary,
    Color? success,
    Color? successContainer,
    Color? goalLose,
    Color? goalLoseContainer,
    Color? goalGain,
    Color? goalGainContainer,
    Color? goalMaintain,
    Color? goalMaintainContainer,
    Color? proteinColor,
    Color? carbsColor,
    Color? fatColor,
    Color? shimmerBase,
    Color? shimmerHighlight,
    Color? heroCardBg,
    Color? heroCardSurface,
    Color? heroCardFg,
    Color? heroCardMuted,
    Color? heroAccent,
    Color? dockBg,
    Color? dockBorder,
    Color? dockActivePill,
    Color? dockActiveFg,
    Color? dockInactiveFg,
  }) {
    return AppSemanticColors(
      background: background ?? this.background,
      cardSurface: cardSurface ?? this.cardSurface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      textSecondary: textSecondary ?? this.textSecondary,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      goalLose: goalLose ?? this.goalLose,
      goalLoseContainer: goalLoseContainer ?? this.goalLoseContainer,
      goalGain: goalGain ?? this.goalGain,
      goalGainContainer: goalGainContainer ?? this.goalGainContainer,
      goalMaintain: goalMaintain ?? this.goalMaintain,
      goalMaintainContainer:
          goalMaintainContainer ?? this.goalMaintainContainer,
      proteinColor: proteinColor ?? this.proteinColor,
      carbsColor: carbsColor ?? this.carbsColor,
      fatColor: fatColor ?? this.fatColor,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
      heroCardBg: heroCardBg ?? this.heroCardBg,
      heroCardSurface: heroCardSurface ?? this.heroCardSurface,
      heroCardFg: heroCardFg ?? this.heroCardFg,
      heroCardMuted: heroCardMuted ?? this.heroCardMuted,
      heroAccent: heroAccent ?? this.heroAccent,
      dockBg: dockBg ?? this.dockBg,
      dockBorder: dockBorder ?? this.dockBorder,
      dockActivePill: dockActivePill ?? this.dockActivePill,
      dockActiveFg: dockActiveFg ?? this.dockActiveFg,
      dockInactiveFg: dockInactiveFg ?? this.dockInactiveFg,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      background: Color.lerp(background, other.background, t)!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer:
          Color.lerp(successContainer, other.successContainer, t)!,
      goalLose: Color.lerp(goalLose, other.goalLose, t)!,
      goalLoseContainer:
          Color.lerp(goalLoseContainer, other.goalLoseContainer, t)!,
      goalGain: Color.lerp(goalGain, other.goalGain, t)!,
      goalGainContainer:
          Color.lerp(goalGainContainer, other.goalGainContainer, t)!,
      goalMaintain: Color.lerp(goalMaintain, other.goalMaintain, t)!,
      goalMaintainContainer:
          Color.lerp(goalMaintainContainer, other.goalMaintainContainer, t)!,
      proteinColor: Color.lerp(proteinColor, other.proteinColor, t)!,
      carbsColor: Color.lerp(carbsColor, other.carbsColor, t)!,
      fatColor: Color.lerp(fatColor, other.fatColor, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight:
          Color.lerp(shimmerHighlight, other.shimmerHighlight, t)!,
      heroCardBg: Color.lerp(heroCardBg, other.heroCardBg, t)!,
      heroCardSurface: Color.lerp(heroCardSurface, other.heroCardSurface, t)!,
      heroCardFg: Color.lerp(heroCardFg, other.heroCardFg, t)!,
      heroCardMuted: Color.lerp(heroCardMuted, other.heroCardMuted, t)!,
      heroAccent: Color.lerp(heroAccent, other.heroAccent, t)!,
      dockBg: Color.lerp(dockBg, other.dockBg, t)!,
      dockBorder: Color.lerp(dockBorder, other.dockBorder, t)!,
      dockActivePill: Color.lerp(dockActivePill, other.dockActivePill, t)!,
      dockActiveFg: Color.lerp(dockActiveFg, other.dockActiveFg, t)!,
      dockInactiveFg: Color.lerp(dockInactiveFg, other.dockInactiveFg, t)!,
    );
  }
}

extension AppThemeColorsX on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  AppSemanticColors get semanticColors =>
      Theme.of(this).extension<AppSemanticColors>() ?? AppSemanticColors.light;
}
