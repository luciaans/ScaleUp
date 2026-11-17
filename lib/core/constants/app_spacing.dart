import 'package:material_ui/material_ui.dart';

/// Konstanta ukuran, jarak (kelipatan 8dp), radius, dan durasi animasi terpusat.
abstract final class AppSpacing {
  // Spacing dasar (kelipatan 8dp, plus unit mikro 4dp untuk celah rapat)
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 40.0;
  static const double xxxl = 48.0;

  // Padding layar standar
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: md,
  );

  // Jarak aman bawah agar daftar tidak tertutup NavigationBar + FAB
  static const double bottomNavClearance = 112.0;

  // Radius komponen sesuai spesifikasi desain
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double buttonRadius = 16.0;
  static const double cardRadius = 22.0;
  static const double sheetTopRadius = 28.0;
  static const double pillRadius = 999.0;

  // Ukuran minimum area sentuh aksesibilitas (48x48dp)
  static const double minTouchTarget = 48.0;
  static const double buttonHeight = 52.0;

  // Ukuran ikon standar
  static const double iconSm = 18.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconHero = 56.0;

  // Ukuran angka besar (40-56 sp)
  static const double heroNumberMd = 42.0;
  static const double heroNumberLg = 52.0;

  // Ketebalan garis / border / ring
  static const double borderThin = 1.0;
  static const double borderMedium = 1.5;
  static const double borderThick = 2.0;
  static const double ringStrokeMd = 10.0;
  static const double ringStrokeLg = 14.0;

  // Durasi animasi standar (200-400 ms)
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 400);
  static const Duration staggerDelay = Duration(milliseconds: 60);
  static const double slideOffsetPx = 20.0;
  static const double pressedScale = 0.96;
}
