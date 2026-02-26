import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Expose notification taps if you want to navigate later
  final StreamController<String?> _tapStream = StreamController<String?>.broadcast();
  Stream<String?> get onNotificationTap => _tapStream.stream;

  static const int dailyReminderNotificationId = 1001;
  static const String studyChannelId = 'study_reminders_channel';
  static const String studyChannelName = 'Study Reminders';

  /// Background tap handler (required to be top-level / static entry point)
  @pragma('vm:entry-point')
  static void notificationTapBackground(NotificationResponse response) {
    // You can do lightweight handling here. Avoid heavy UI logic.
    debugPrint('Notification tapped in background: payload=${response.payload}');
  }

  Future<void> init() async {
    if (_initialized) return;

    // Timezone setup (recommended for scheduled notifications)
    tz.initializeTimeZones();
    await _configureLocalTimezone();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false, // request later explicitly
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        _tapStream.add(response.payload);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    _initialized = true;
  }

  Future<void> _configureLocalTimezone() async {
    if (kIsWeb) return;

    try {
      final dynamic tzInfo = await FlutterTimezone.getLocalTimezone();

      // flutter_timezone examples may return a TimezoneInfo object in newer versions,
      // while some examples/plugins expect a String timezone name.
      String? tzName;
      if (tzInfo is String) {
        tzName = tzInfo;
      } else {
        try {
          tzName = (tzInfo as dynamic).name as String?;
        } catch (_) {
          tzName = null;
        }
      }

      if (tzName != null && tzName.isNotEmpty) {
        tz.setLocalLocation(tz.getLocation(tzName));
      }
    } catch (_) {
      // Fallback: keep default tz.local if timezone lookup fails
    }
  }

  Future<bool> requestPermissions() async {
    await init();

    bool granted = true;

    // iOS/macOS
    if (Platform.isIOS || Platform.isMacOS) {
      final iosGranted = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );

      final macGranted = await _plugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );

      granted = (iosGranted ?? macGranted ?? false);
    }

    // Android 13+ notification runtime permission
    if (Platform.isAndroid) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      final androidGranted =
          await androidImpl?.requestNotificationsPermission();

      // Optional: exact alarms permission (Android 14+ behavior changes may require it
      // for exact timing, depending on your app/use case)
      try {
        await androidImpl?.requestExactAlarmsPermission();
      } catch (_) {
        // Ignore if API not available on device/plugin version/platform
      }

      granted = androidGranted ?? granted;
    }

    return granted;
  }

  NotificationDetails _defaultNotificationDetails() {
    const android = AndroidNotificationDetails(
      studyChannelId,
      studyChannelName,
      channelDescription: 'Reminders to continue your learning progress',
      importance: Importance.high,
      priority: Priority.high,
    );

    const darwin = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return const NotificationDetails(
      android: android,
      iOS: darwin,
      macOS: darwin,
    );
  }

  Future<void> showInstantStudyReminder({
    String title = 'Study reminder 📚',
    String body = 'Time to continue your lesson!',
    String? payload,
  }) async {
    await init();

    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: _defaultNotificationDetails(),
      payload: payload ?? 'instant_study_reminder',
    );
  }

  Future<void> scheduleDailyStudyReminder({
    required int hour,
    required int minute,
    String title = 'Daily learning reminder 📘',
    String body = 'Spend 15–30 minutes on your course today.',
  }) async {
    await init();

    final scheduledDate = _nextInstanceOfTime(hour, minute);

    await _plugin.zonedSchedule(
      id: dailyReminderNotificationId,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: _defaultNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
      payload: 'daily_study_reminder',
    );
  }

  Future<void> cancelDailyStudyReminder() async {
    await init();
    await _plugin.cancel(dailyReminderNotificationId);
  }

  Future<void> cancelAllNotifications() async {
    await init();
    await _plugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    await init();
    return _plugin.pendingNotificationRequests();
  }

  /// Sync service behavior with settings toggle
  /// Example policy:
  /// - enabled => schedule daily reminder at 20:00
  /// - disabled => cancel daily reminder
  Future<void> syncWithNotificationSetting({
    required bool enabled,
    int hour = 20,
    int minute = 0,
  }) async {
    final granted = await requestPermissions();

    if (!granted && enabled) {
      // Permission denied; don't schedule
      return;
    }

    if (enabled) {
      await scheduleDailyStudyReminder(hour: hour, minute: minute);
    } else {
      await cancelDailyStudyReminder();
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduled.isBefore(now) || scheduled.isAtSameMomentAs(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  Future<void> dispose() async {
    await _tapStream.close();
  }
}
