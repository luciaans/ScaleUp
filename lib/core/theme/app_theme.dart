import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../constants/app_spacing.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Konfigurasi ThemeData "Mochi Neko — Cozy Sumi-Ink & Milk Paper".
abstract final class AppTheme {
  static ThemeData get lightTheme => _buildTheme(
        colorScheme: AppColors.lightColorScheme,
        semanticColors: AppSemanticColors.light,
        overlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: AppColors.milkPaper.withValues(alpha: 0),
          systemNavigationBarColor: AppColors.milkPaper,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );

  static ThemeData get darkTheme => _buildTheme(
        colorScheme: AppColors.darkColorScheme,
        semanticColors: AppSemanticColors.dark,
        overlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: AppColors.darkBackground.withValues(alpha: 0),
          systemNavigationBarColor: AppColors.darkBackground,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required AppSemanticColors semanticColors,
    required SystemUiOverlayStyle overlayStyle,
  }) {
    final textTheme = AppTextStyles.buildTextTheme(
      colorScheme.onSurface,
      semanticColors.textSecondary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: semanticColors.background,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[semanticColors],
      appBarTheme: AppBarTheme(
        backgroundColor: semanticColors.background,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: colorScheme.surface.withValues(alpha: 0),
        centerTitle: false,
        systemOverlayStyle: overlayStyle,
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: semanticColors.cardSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: semanticColors.dockBg.withValues(alpha: 0),
        indicatorColor: semanticColors.dockActivePill,
        indicatorShape: const StadiumBorder(),
        elevation: 0,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? semanticColors.dockActivePill
                : semanticColors.dockInactiveFg,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: AppSpacing.iconMd,
            color: isSelected
                ? semanticColors.dockActiveFg
                : semanticColors.dockInactiveFg,
          );
        }),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: semanticColors.background,
        surfaceTintColor: colorScheme.surface.withValues(alpha: 0),
        modalBackgroundColor: semanticColors.background,
        showDragHandle: true,
        dragHandleColor: colorScheme.outlineVariant,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.sheetTopRadius),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          minimumSize: const Size(
            AppSpacing.minTouchTarget,
            AppSpacing.buttonHeight,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          minimumSize: const Size(
            AppSpacing.minTouchTarget,
            AppSpacing.buttonHeight,
          ),
          side: BorderSide(
            color: colorScheme.onSurface,
            width: AppSpacing.borderMedium,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          minimumSize: const Size(
            AppSpacing.minTouchTarget,
            AppSpacing.minTouchTarget,
          ),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: semanticColors.surfaceMuted,
        selectedColor: colorScheme.primary,
        secondarySelectedColor: colorScheme.primary,
        labelStyle: textTheme.labelMedium!,
        secondaryLabelStyle: textTheme.labelMedium!.copyWith(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + AppSpacing.xs,
          vertical: AppSpacing.xs,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: semanticColors.cardSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md + AppSpacing.xs,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant,
            width: AppSpacing.borderMedium,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          borderSide: BorderSide(
            color: semanticColors.heroAccent,
            width: AppSpacing.borderThick,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: AppSpacing.borderThick,
          ),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: semanticColors.textSecondary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.sumiInk,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.milkPaper,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: AppSpacing.borderThin,
        space: AppSpacing.borderThin,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        shape: const CircleBorder(),
      ),
    );
  }
}
