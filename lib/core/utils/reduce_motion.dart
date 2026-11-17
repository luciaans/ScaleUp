import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

/// Helper aksesibilitas untuk menghormati preferensi "Reduce Motion" pengguna
/// dan memberikan umpan balik haptik lembut.
abstract final class MotionUtils {
  /// Mengembalikan `true` jika pengguna mengaktifkan "kurangi animasi" pada OS.
  static bool shouldReduceMotion(BuildContext context) {
    return MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  }

  /// Mengembalikan [Duration.zero] jika reduce motion aktif, atau [normal] jika tidak.
  static Duration duration(BuildContext context, Duration normal) {
    return shouldReduceMotion(context) ? Duration.zero : normal;
  }

  /// Memicu haptic ringan yang aman untuk interaksi tombol utama.
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }

  /// Memicu haptic seleksi untuk kontrol tambah/kurang atau slider.
  static void selectionClick() {
    HapticFeedback.selectionClick();
  }
}
