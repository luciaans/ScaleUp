import 'package:material_ui/material_ui.dart';

/// Palet warna "Mochi Neko — Cozy Sumi-Ink & Milk Paper":
/// Monokrom hangat (Kertas Susu #FCF9F4 & Tinta Arang #24211F)
/// dipadukan dengan aksen lembut Sakura Blush, Butter Bell, dan Sky Fish.
abstract final class AppColors {
  // ================= COZY LIGHT PALETTE (DEFAULT) =================
  static const Color sumiInk = Color(0xFF24211F);
  static const Color milkPaper = Color(0xFFF9F4E8);
  static const Color snowCream = Color(0xFFFFFFFF);
  static const Color oatWash = Color(0xFFF1EAE0);
  static const Color biscuitBorder = Color(0xFFDDD4C6);
  static const Color warmGreyText = Color(0xFF6B635B);

  static const Color sakuraBlush = Color(0xFFFF9B8E);
  static const Color sakuraSoft = Color(0xFFFFE8E4);
  static const Color sakuraDeep = Color(0xFF6E241C);

  static const Color skyFish = Color(0xFF5BA8E6);
  static const Color skySoft = Color(0xFFE3F2FD);
  static const Color skyDeep = Color(0xFF10375C);

  static const Color butterBell = Color(0xFFF4B942);
  static const Color butterSoft = Color(0xFFFFF3D1);
  static const Color butterDeep = Color(0xFF593B04);

  static const Color matchaSafe = Color(0xFF4F9D69);
  static const Color matchaSoft = Color(0xFFE3F4E8);

  static const Color lavenderSnack = Color(0xFF9A7CE8);

  static const Color berryError = Color(0xFFD9534F);
  static const Color berryErrorSoft = Color(0xFFFDE8E8);

  // ================= COZY DARK PALETTE ("MIDNIGHT FUR") =================
  static const Color darkBackground = Color(0xFF1B1918);
  static const Color darkSurface = Color(0xFF262321);
  static const Color darkSurfaceVariant = Color(0xFF332E2B);
  static const Color darkInkCream = Color(0xFFF7F3EC);
  static const Color darkMutedText = Color(0xFFA89F96);
  static const Color darkBorder = Color(0xFF3D3734);

  static const Color shadowStickerLight = Color(0xFFE6DFD4);
  static const Color shadowStickerDark = Color(0xFF110F0E);
  static const Color scrim = Color(0x6624211F);

  static ColorScheme get lightColorScheme => const ColorScheme(
        brightness: Brightness.light,
        primary: sumiInk,
        onPrimary: milkPaper,
        primaryContainer: sakuraSoft,
        onPrimaryContainer: sumiInk,
        secondary: skyFish,
        onSecondary: snowCream,
        secondaryContainer: skySoft,
        onSecondaryContainer: skyDeep,
        tertiary: butterBell,
        onTertiary: sumiInk,
        tertiaryContainer: butterSoft,
        onTertiaryContainer: butterDeep,
        error: berryError,
        onError: snowCream,
        errorContainer: berryErrorSoft,
        onErrorContainer: sakuraDeep,
        surface: snowCream,
        onSurface: sumiInk,
        surfaceContainerHighest: oatWash,
        onSurfaceVariant: warmGreyText,
        outline: sumiInk,
        outlineVariant: biscuitBorder,
        shadow: shadowStickerLight,
        scrim: scrim,
      );

  static ColorScheme get darkColorScheme => const ColorScheme(
        brightness: Brightness.dark,
        primary: darkInkCream,
        onPrimary: darkBackground,
        primaryContainer: darkSurfaceVariant,
        onPrimaryContainer: darkInkCream,
        secondary: Color(0xFF7CC2F8),
        onSecondary: darkBackground,
        secondaryContainer: Color(0xFF1E3446),
        onSecondaryContainer: skySoft,
        tertiary: Color(0xFFF7CA65),
        onTertiary: darkBackground,
        tertiaryContainer: Color(0xFF423416),
        onTertiaryContainer: butterSoft,
        error: Color(0xFFF28B82),
        onError: darkBackground,
        errorContainer: Color(0xFF4A201E),
        onErrorContainer: berryErrorSoft,
        surface: darkSurface,
        onSurface: darkInkCream,
        surfaceContainerHighest: darkSurfaceVariant,
        onSurfaceVariant: darkMutedText,
        outline: darkInkCream,
        outlineVariant: darkBorder,
        shadow: shadowStickerDark,
        scrim: scrim,
      );
}

/// Warna semantik terpusat untuk gaya buku sketsa kucing monokrom-pastel.
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

  /// Kartu Panggung Utama Mochi (Krem Hangat & Sumi Ink)
  final Color heroCardBg;
  final Color heroCardSurface;
  final Color heroCardFg;
  final Color heroCardMuted;
  final Color heroAccent;

  /// Kapsul Navigasi Bawah (Monokrom Kertas Susu & Tinta)
  final Color dockBg;
  final Color dockBorder;
  final Color dockActivePill;
  final Color dockActiveFg;
  final Color dockInactiveFg;

  static const AppSemanticColors light = AppSemanticColors(
    background: AppColors.milkPaper,
    cardSurface: AppColors.snowCream,
    surfaceMuted: AppColors.oatWash,
    textSecondary: AppColors.warmGreyText,
    success: AppColors.matchaSafe,
    successContainer: AppColors.matchaSoft,
    goalLose: AppColors.skyFish,
    goalLoseContainer: AppColors.skySoft,
    goalGain: AppColors.sakuraBlush,
    goalGainContainer: AppColors.sakuraSoft,
    goalMaintain: AppColors.matchaSafe,
    goalMaintainContainer: AppColors.matchaSoft,
    proteinColor: AppColors.skyFish,
    carbsColor: AppColors.butterBell,
    fatColor: AppColors.sakuraBlush,
    shimmerBase: AppColors.oatWash,
    shimmerHighlight: AppColors.snowCream,
    heroCardBg: AppColors.snowCream,
    heroCardSurface: AppColors.oatWash,
    heroCardFg: AppColors.sumiInk,
    heroCardMuted: AppColors.warmGreyText,
    heroAccent: AppColors.sakuraBlush,
    dockBg: Color(0xF5FFFFFF),
    dockBorder: AppColors.sumiInk,
    dockActivePill: AppColors.sumiInk,
    dockActiveFg: AppColors.milkPaper,
    dockInactiveFg: AppColors.warmGreyText,
  );

  static const AppSemanticColors dark = AppSemanticColors(
    background: AppColors.darkBackground,
    cardSurface: AppColors.darkSurface,
    surfaceMuted: AppColors.darkSurfaceVariant,
    textSecondary: AppColors.darkMutedText,
    success: Color(0xFF74C69D),
    successContainer: Color(0xFF1F382B),
    goalLose: Color(0xFF7CC2F8),
    goalLoseContainer: Color(0xFF1E3446),
    goalGain: AppColors.sakuraBlush,
    goalGainContainer: Color(0xFF472622),
    goalMaintain: Color(0xFF74C69D),
    goalMaintainContainer: Color(0xFF1F382B),
    proteinColor: Color(0xFF7CC2F8),
    carbsColor: Color(0xFFF7CA65),
    fatColor: AppColors.sakuraBlush,
    shimmerBase: AppColors.darkSurfaceVariant,
    shimmerHighlight: AppColors.darkBorder,
    heroCardBg: AppColors.darkSurface,
    heroCardSurface: AppColors.darkSurfaceVariant,
    heroCardFg: AppColors.darkInkCream,
    heroCardMuted: AppColors.darkMutedText,
    heroAccent: AppColors.sakuraBlush,
    dockBg: Color(0xF5262321),
    dockBorder: AppColors.darkBorder,
    dockActivePill: AppColors.darkInkCream,
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
