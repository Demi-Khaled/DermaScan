import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz_data.initializeTimeZones();
    try {
      final dynamic res = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = res is String ? res : res.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('Warning: Could not detect local timezone ($e). Falling back to UTC.');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
    
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification click
        debugPrint('Notification clicked: ${details.payload}');
      },
    );
  }

  static Future<void> scheduleFollowUp({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'follow_up_reminders',
        'Follow-up Reminders',
        channelDescription: 'Notifications for scan follow-ups',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    tz.TZDateTime tzDate;
    try {
      tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    } catch (e) {
      debugPrint('Timezone error in scheduling: $e. Falling back to UTC.');
      tzDate = tz.TZDateTime.from(scheduledDate, tz.UTC);
    }

    try {
      // Try exact scheduling first (requires SCHEDULE_EXACT_ALARM or USE_EXACT_ALARM permission)
      await _notifications.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'follow_up|$id|${scheduledDate.toIso8601String()}',
      );
    } on PlatformException catch (e) {
      if (e.code == 'exact_alarms_not_permitted') {
        // Fall back to inexact scheduling — fine for 14-day reminders
        await _notifications.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: tzDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'follow_up|$id|${scheduledDate.toIso8601String()}',
        );
      } else {
        rethrow;
      }
    }
  }

  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  static Future<void> cancelReminder(int id) async {
    await _notifications.cancel(id: id);
  }

  static Future<List<PendingNotificationRequest>> getPendingReminders() async {
    return await _notifications.pendingNotificationRequests();
  }
}
