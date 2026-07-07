import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap if needed
      },
    );

    _initialized = true;
  }

  Future<void> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    // Request FCM permissions
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<String?> getFcmToken() async {
    return await FirebaseMessaging.instance.getToken();
  }

  /// Whether leave-related push notifications should be shown.
  /// Updated by the view model when the user toggles the setting.
  bool leaveNotificationsEnabled = true;

  void setupForegroundMessaging() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        // Check if this is a leave-related notification
        final dataType = message.data['type'] as String?;
        final isLeaveNotification = dataType == 'leave';

        // Suppress leave notifications if user disabled them
        if (isLeaveNotification && !leaveNotificationsEnabled) {
          return;
        }

        final notificationDetails = isLeaveNotification
            ? const NotificationDetails(
                android: AndroidNotificationDetails(
                  'leave_notifications',
                  'Leave Notifications',
                  channelDescription: 'Leave request status updates',
                  importance: Importance.max,
                  priority: Priority.high,
                ),
                iOS: DarwinNotificationDetails(
                  presentAlert: true,
                  presentBadge: true,
                  presentSound: true,
                ),
              )
            : const NotificationDetails(
                android: AndroidNotificationDetails(
                  'hr_notifications',
                  'HR Notifications',
                  channelDescription: 'Notifications from HR',
                  importance: Importance.max,
                  priority: Priority.high,
                ),
                iOS: DarwinNotificationDetails(
                  presentAlert: true,
                  presentBadge: true,
                  presentSound: true,
                ),
              );

        _notificationsPlugin.show(
          id: message.hashCode,
          title: message.notification!.title,
          body: message.notification!.body,
          notificationDetails: notificationDetails,
        );
      }
    });
  }

  Future<void> cancelAllReminders() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> scheduleAttendanceReminders(String startTime, String endTime) async {
    await cancelAllReminders();

    try {
      final startParts = startTime.split(':');
      final endParts = endTime.split(':');
      
      if (startParts.length != 2 || endParts.length != 2) return;

      final startHour = int.parse(startParts[0]);
      final startMinute = int.parse(startParts[1]);

      final endHour = int.parse(endParts[0]);
      final endMinute = int.parse(endParts[1]);

      // Calculate 15 mins before start
      int checkInHour = startHour;
      int checkInMin = startMinute - 15;
      if (checkInMin < 0) {
        checkInMin += 60;
        checkInHour -= 1;
        if (checkInHour < 0) checkInHour += 24;
      }

      // Calculate 15 mins after end
      int checkOutHour = endHour;
      int checkOutMin = endMinute + 15;
      if (checkOutMin >= 60) {
        checkOutMin -= 60;
        checkOutHour += 1;
        if (checkOutHour >= 24) checkOutHour -= 24;
      }

      // Schedule for Monday to Friday
      for (int i = DateTime.monday; i <= DateTime.friday; i++) {
        await _scheduleWeeklyNotification(
          id: i * 10 + 1,
          title: 'Upcoming Shift!',
          body: 'Don\'t forget to check in. Your shift starts at $startTime.',
          day: i,
          hour: checkInHour,
          minute: checkInMin,
        );

        await _scheduleWeeklyNotification(
          id: i * 10 + 2,
          title: 'Shift Ended!',
          body: 'Don\'t forget to check out. Your shift ended at $endTime.',
          day: i,
          hour: checkOutHour,
          minute: checkOutMin,
        );
      }
    } catch (e) {
      debugPrint('Failed to schedule reminders: $e');
    }
  }

  Future<void> _scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required int day,
    required int hour,
    required int minute,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOfDayAndTime(day, hour, minute),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'attendance_reminders',
          'Attendance Reminders',
          channelDescription: 'Reminders to check in and out',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> showTestNotification() async {
    try {
      await requestPermissions();
      await _notificationsPlugin.show(
        id: 999,
        title: 'Test Notification',
        body: 'It works! Notifications are fully configured.',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'attendance_reminders',
            'Attendance Reminders',
            channelDescription: 'Reminders to check in and out',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error showing test notification: $e');
    }
  }

  tz.TZDateTime _nextInstanceOfDayAndTime(int dayOfWeek, int hour, int minute) {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);
    while (scheduledDate.weekday != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
