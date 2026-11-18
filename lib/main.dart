import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'core/constants/app_constants.dart';
import 'core/constants/app_spacing.dart';
import 'core/constants/app_strings.dart';
import 'core/router/app_router.dart';
import 'core/services/firebase_config.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/data/settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting(AppConstants.localeId);
  await FirebaseConfig.initialize();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ProviderScope(child: ScaleUpApp()));
}

class ScaleUpApp extends ConsumerWidget {
  const ScaleUpApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeModeAsync = ref.watch(appThemeModeProvider);
    final themeMode = themeModeAsync.value ?? ThemeMode.light;

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final clampedScaler = mq.textScaler.clamp(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.35,
        );
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final overlayStyle =
            (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
                .copyWith(
                  statusBarColor: AppColors.milkPaper.withValues(alpha: 0),
                  systemNavigationBarColor: isDark
                      ? AppColors.darkSurface
                      : AppColors.milkPaper,
                  systemNavigationBarIconBrightness: isDark
                      ? Brightness.light
                      : Brightness.dark,
                );

        Widget content = child ?? const SizedBox.shrink();

        // Pada preview Web lebar (mis. panel preview Orca / desktop browser),
        // tampilkan dalam bingkai proporsi ponsel portrait (412dp) agar realistis.
        if (kIsWeb && mq.size.width > 500) {
          const mobileWidth = 412.0;
          final frameBg = isDark
              ? AppColors.darkBackground
              : AppColors.softGray;
          final borderColor = isDark
              ? AppColors.darkBorder
              : AppColors.borderStrong;

          content = ColoredBox(
            color: frameBg,
            child: Center(
              child: Container(
                width: mobileWidth,
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    AppSpacing.sheetTopRadius,
                  ),
                  border: Border.all(color: borderColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.carbonInk.withValues(alpha: 0.10),
                      offset: const Offset(0, 12),
                      blurRadius: 32,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: MediaQuery(
                  data: mq.copyWith(
                    size: Size(mobileWidth, mq.size.height - AppSpacing.md),
                    textScaler: clampedScaler,
                  ),
                  child: content,
                ),
              ),
            ),
          );
        } else {
          content = MediaQuery(
            data: mq.copyWith(textScaler: clampedScaler),
            child: content,
          );
        }

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyle,
          child: content,
        );
      },
      routerConfig: router,
    );
  }
}
