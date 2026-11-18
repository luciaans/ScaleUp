import 'package:material_ui/material_ui.dart';

/// Palet warna Universal Modern "Clean Slate & Meme Sticker Pop":
/// Netral bersih universal (#F5F7FA & #FFFFFF) + Carbon Ink (#111827)
/// dipadukan aksen Royal Blue, Emerald, dan Amber yang segar untuk semua pengguna.
abstract final class AppColors {
  // ================= UNIVERSAL CLEAN LIGHT PALETTE (DEFAULT) =================
  static const Color carbonInk = Color(0xFF111827);
  static const Color slateCanvas = Color(0xFFF5F7FA);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color softGray = Color(0xFFEEF2F6);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFFCBD5E1);
  static const Color slateMuted = Color(0xFF64748B);

  // Universal Accents
  static const Color royalBlue = Color(0xFF2563EB);
  static const Color royalBlueSoft = Color(0xFFEFF6FF);
  static const Color royalBlueDeep = Color(0xFF1E3A8A);

  static const Color skyCyan = Color(0xFF0284C7);
  static const Color skyCyanSoft = Color(0xFFE0F2FE);
  static const Color skyCyanDeep = Color(0xFF0C4A6E);

  static const Color amberPop = Color(0xFFF59E0B);
  static const Color amberSoft = Color(0xFFFEF3C7);
  static const Color amberDeep = Color(0xFF78350F);

  static const Color emeraldSafe = Color(0xFF10B981);
  static const Color emeraldSoft = Color(0xFFD1FAE5);

  static const Color coralWarm = Color(0xFFF97316);
  static const Color coralSoft = Color(0xFFFFEDD5);

  static const Color lavenderSnack = Color(0xFF8B5CF6);

  static const Color crimsonError = Color(0xFFEF4444);
  static const Color crimsonSoft = Color(0xFFFEE2E2);
  static const Color crimsonDeep = Color(0xFF7F1D1D);

  // ================= UNIVERSAL DARK PALETTE ("CARBON SLATE") =================
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceVariant = Color(0xFF334155);
  static const Color darkInkLight = Color(0xFFF8FAFC);
  static const Color darkMutedText = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF334155);

  static const Color shadowSoftLight = Color(0x120F172A);
  static const Color shadowSoftDark = Color(0x40000000);
  static const Color scrim = Color(0x660F172A);

  // Alias kompatibilitas komponen internal
  static const Color sumiInk = carbonInk;
  static const Color milkPaper = slateCanvas;
  static const Color snowCream = pureWhite;
  static const Color oatWash = softGray;
  static const Color sakuraBlush = royalBlue;
  static const Color skyFish = skyCyan;
  static const Color butterBell = amberPop;

  static ColorScheme get lightColorScheme => const ColorScheme(
        brightness: Brightness.light,
        primary: carbonInk,
        onPrimary: pureWhite,
        primaryContainer: royalBlueSoft,
        onPrimaryContainer: royalBlueDeep,
        secondary: skyCyan,
        onSecondary: pureWhite,
        secondaryContainer: skyCyanSoft,
        onSecondaryContainer: skyCyanDeep,
        tertiary: amberPop,
        onTertiary: carbonInk,
        tertiaryContainer: amberSoft,
        onTertiaryContainer: amberDeep,
        error: crimsonError,
        onError: pureWhite,
        errorContainer: crimsonSoft,
        onErrorContainer: crimsonDeep,
        surface: pureWhite,
        onSurface: carbonInk,
        surfaceContainerHighest: softGray,
        onSurfaceVariant: slateMuted,
        outline: borderStrong,
        outlineVariant: borderLight,
        shadow: shadowSoftLight,
        scrim: scrim,
      );

  static ColorScheme get darkColorScheme => const ColorScheme(
        brightness: Brightness.dark,
        primary: darkInkLight,
        onPrimary: darkBackground,
        primaryContainer: Color(0xFF1E3A5F),
        onPrimaryContainer: royalBlueSoft,
        secondary: Color(0xFF38BDF8),
        onSecondary: darkBackground,
        secondaryContainer: Color(0xFF0C4A6E),
        onSecondaryContainer: skyCyanSoft,
        tertiary: Color(0xFFFBBF24),
        onTertiary: darkBackground,
        tertiaryContainer: Color(0xFF452709),
        onTertiaryContainer: amberSoft,
        error: Color(0xFFF87171),
        onError: darkBackground,
        errorContainer: Color(0xFF451A1A),
        onErrorContainer: crimsonSoft,
        surface: darkSurface,
        onSurface: darkInkLight,
        surfaceContainerHighest: darkSurfaceVariant,
        onSurfaceVariant: darkMutedText,
        outline: darkBorder,
        outlineVariant: darkBorder,
        shadow: shadowSoftDark,
        scrim: scrim,
      );
}

/// Warna semantik terpusat untuk UI modern universal + stiker kucing meme.
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

  final Color heroCardBg;
  final Color heroCardSurface;
  final Color heroCardFg;
  final Color heroCardMuted;
  final Color heroAccent;

  final Color dockBg;
  final Color dockBorder;
  final Color dockActivePill;
  final Color dockActiveFg;
  final Color dockInactiveFg;

  static const AppSemanticColors light = AppSemanticColors(
    background: AppColors.slateCanvas,
    cardSurface: AppColors.pureWhite,
    surfaceMuted: AppColors.softGray,
    textSecondary: AppColors.slateMuted,
    success: AppColors.emeraldSafe,
    successContainer: AppColors.emeraldSoft,
    goalLose: AppColors.skyCyan,
    goalLoseContainer: AppColors.skyCyanSoft,
    goalGain: AppColors.coralWarm,
    goalGainContainer: AppColors.coralSoft,
    goalMaintain: AppColors.emeraldSafe,
    goalMaintainContainer: AppColors.emeraldSoft,
    proteinColor: AppColors.royalBlue,
    carbsColor: AppColors.amberPop,
    fatColor: AppColors.coralWarm,
    shimmerBase: AppColors.softGray,
    shimmerHighlight: AppColors.pureWhite,
    heroCardBg: AppColors.pureWhite,
    heroCardSurface: AppColors.softGray,
    heroCardFg: AppColors.carbonInk,
    heroCardMuted: AppColors.slateMuted,
    heroAccent: AppColors.royalBlue,
    dockBg: Color(0xF8FFFFFF),
    dockBorder: AppColors.borderLight,
    dockActivePill: AppColors.carbonInk,
    dockActiveFg: AppColors.pureWhite,
    dockInactiveFg: AppColors.slateMuted,
  );

  static const AppSemanticColors dark = AppSemanticColors(
    background: AppColors.darkBackground,
    cardSurface: AppColors.darkSurface,
    surfaceMuted: AppColors.darkSurfaceVariant,
    textSecondary: AppColors.darkMutedText,
    success: Color(0xFF34D399),
    successContainer: Color(0xFF064E3B),
    goalLose: Color(0xFF38BDF8),
    goalLoseContainer: Color(0xFF0C4A6E),
    goalGain: Color(0xFFFB923C),
    goalGainContainer: Color(0xFF431407),
    goalMaintain: Color(0xFF34D399),
    goalMaintainContainer: Color(0xFF064E3B),
    proteinColor: Color(0xFF60A5FA),
    carbsColor: Color(0xFFFBBF24),
    fatColor: Color(0xFFFB923C),
    shimmerBase: AppColors.darkSurfaceVariant,
    shimmerHighlight: AppColors.darkBorder,
    heroCardBg: AppColors.darkSurface,
    heroCardSurface: AppColors.darkSurfaceVariant,
    heroCardFg: AppColors.darkInkLight,
    heroCardMuted: AppColors.darkMutedText,
    heroAccent: Color(0xFF60A5FA),
    dockBg: Color(0xF51E293B),
    dockBorder: AppColors.darkBorder,
    dockActivePill: AppColors.darkInkLight,
    dockActiveFg: AppColors.darkBackground,
    dockInactiveFg: AppColors.darkMutedText,
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
