import 'package:material_ui/material_ui.dart';

/// Konstanta ukuran, jarak, radius Bento squircle, dan durasi animasi gaya studio modern.
abstract final class AppSpacing {
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

  // Jarak aman bawah agar seluruh daftar bebas dari Floating Pill Dock + FAB
  static const double bottomNavClearance = 128.0;

  // Radius Bento modern (gaya Nixtio)
  static const double radiusSm = 10.0;
  static const double radiusMd = 16.0;
  static const double buttonRadius = 20.0;
  static const double cardRadius = 28.0;
  static const double heroRadius = 32.0;
  static const double sheetTopRadius = 32.0;
  static const double pillRadius = 999.0;

  // Area sentuh aksesibilitas
  static const double minTouchTarget = 48.0;
  static const double buttonHeight = 54.0;

  // Ukuran ikon
  static const double iconSm = 18.0;
  static const double iconMd = 22.0;
  static const double iconLg = 30.0;
  static const double iconHero = 56.0;

  // Ukuran angka besar (tabular figures)
  static const double heroNumberMd = 40.0;
  static const double heroNumberLg = 50.0;

  // Ketebalan garis & dial
  static const double borderThin = 1.0;
  static const double borderMedium = 1.5;
  static const double borderThick = 2.0;
  static const double ringStrokeMd = 11.0;
  static const double ringStrokeLg = 14.0;

  // Durasi animasi
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 420);
  static const Duration staggerDelay = Duration(milliseconds: 55);
  static const double slideOffsetPx = 18.0;
  static const double pressedScale = 0.96;
}
