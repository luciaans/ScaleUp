import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/constants/app_constants.dart';

part 'notification_service.g.dart';

/// Layanan penjadwalan notifikasi lokal pengingat timbang berat & catat makan.
class NotificationService {
  NotificationService([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<void> ensureInitialized() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    _configureLocalTimezone();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      await _plugin.initialize(settings: initSettings);
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      }
      _initialized = true;
    } catch (_) {
      throw const NotificationSetupException();
    }
  }

  void _configureLocalTimezone() {
    final offsetHours = DateTime.now().timeZoneOffset.inHours;
    final zoneName = switch (offsetHours) {
      7 => 'Asia/Jakarta',
      8 => 'Asia/Makassar',
      9 => 'Asia/Jayapura',
      _ => 'UTC',
    };
    try {
      tz.setLocalLocation(tz.getLocation(zoneName));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  }

  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    await ensureInitialized();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'scaleup_daily_reminders',
        'Pengingat Harian ScaleUp',
        channelDescription: 'Pengingat timbang berat dan catat makanan harian',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      throw const NotificationSetupException();
    }
  }

  Future<void> cancelReminder(int id) async {
    await ensureInitialized();
    try {
      await _plugin.cancel(id: id);
    } catch (_) {
      throw const NotificationSetupException();
    }
  }

  Future<void> cancelAll() async {
    await ensureInitialized();
    try {
      await _plugin.cancelAll();
    } catch (_) {
      throw const NotificationSetupException();
    }
  }

  Future<void> syncWeightReminder({
    required bool enabled,
    required TimeOfDay time,
  }) async {
    if (!enabled) {
      await cancelReminder(AppConstants.notificationIdWeight);
      return;
    }
    await scheduleDailyReminder(
      id: AppConstants.notificationIdWeight,
      title: 'Waktunya Timbang Berat Harian',
      body: 'Yuk, catat berat badanmu hari ini di ScaleUp!',
      time: time,
    );
  }

  Future<void> syncMealReminder({
    required bool enabled,
    required TimeOfDay time,
  }) async {
    if (!enabled) {
      await cancelReminder(AppConstants.notificationIdMeal);
      return;
    }
    await scheduleDailyReminder(
      id: AppConstants.notificationIdMeal,
      title: 'Jangan Lupa Catat Makananmu',
      body: 'Cek sisa kalori harianmu agar tetap sesuai rencana sehat.',
      time: time,
    );
  }
}

class NotificationSetupException implements Exception {
  const NotificationSetupException();

  @override
  String toString() => 'Notifikasi belum tersedia di perangkat ini.';
}

@Riverpod(keepAlive: true)
NotificationService notificationService(Ref ref) {
  return NotificationService();
}
