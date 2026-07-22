import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Daily workout reminder, scheduled fully on the device through the OS
/// notification system: no network is involved and the release build stays
/// free of the INTERNET permission.
class ReminderService {
  ReminderService._();

  static final ReminderService instance = ReminderService._();

  static const _notificationId = 1;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (error) {
      // Keep the bundled default: a reminder at a shifted hour is better
      // than no reminder at all.
      debugPrint('Sweatline: timezone lookup failed: $error');
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialized = true;
  }

  /// Asks the OS for notification permission. True when granted.
  Future<bool> requestPermission() async {
    await _ensureInitialized();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, sound: true) ?? false;
    }
    return false;
  }

  /// Schedules (or reschedules) the repeating daily reminder at [time].
  /// The inexact schedule mode avoids Android's exact-alarm permission:
  /// minute-level precision is not needed for a training nudge.
  Future<void> scheduleDaily(
    TimeOfDay time, {
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async {
    await _ensureInitialized();
    final now = tz.TZDateTime.now(tz.local);
    var first = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (!first.isAfter(now)) first = first.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      id: _notificationId,
      scheduledDate: first,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'workout_reminder',
          channelName,
          channelDescription: channelDescription,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Removes the scheduled reminder.
  Future<void> cancel() async {
    await _ensureInitialized();
    await _plugin.cancel(id: _notificationId);
  }
}
