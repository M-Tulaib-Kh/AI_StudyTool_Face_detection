import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static late FlutterLocalNotificationsPlugin _plugin;

  static Future<void> initialize(FlutterLocalNotificationsPlugin plugin) async {
    _plugin = plugin;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'studylock_main',
          'StudyLock',
          channelDescription: 'StudyLock notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
            presentAlert: true, presentBadge: true, presentSound: true),
      ),
      payload: payload,
    );
  }

  static Future<void> scheduleStudyReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'studylock_reminders',
          'Study Reminders',
          channelDescription: 'Daily study reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelAll() => _plugin.cancelAll();
  static Future<void> cancel(int id) => _plugin.cancel(id);

  static Future<void> showViolationWarning(int violationCount) =>
      showNotification(
        id: 999,
        title: '⚠️ Focus Violation $violationCount/3',
        body: violationCount >= 3
            ? 'Session failed — too many violations!'
            : 'Return to study! $violationCount/3 warnings used.',
      );

  static Future<void> showSessionComplete(int xpEarned) => showNotification(
        id: 998,
        title: '✅ Session Complete!',
        body: 'Great work! You earned $xpEarned XP.',
      );

  static Future<void> showAssignmentDeadline({
    required String assignmentTitle,
    required int daysLeft,
  }) =>
      showNotification(
        id: assignmentTitle.hashCode.abs() % 900,
        title: '📋 Assignment Due Soon',
        body:
            '$assignmentTitle is due in $daysLeft day${daysLeft == 1 ? '' : 's'}.',
      );

  static Future<void> showAttendanceWarning(double percentage) =>
      showNotification(
        id: 997,
        title: '⚠️ Low Attendance Warning',
        body:
            'Your attendance is ${percentage.toStringAsFixed(1)}%. Minimum 75% required.',
      );

  static Future<void> showNewContent(
          {required String type, required String title}) =>
      showNotification(
        id: title.hashCode.abs() % 800,
        title: '📚 New ${type[0].toUpperCase()}${type.substring(1)} Posted',
        body: title,
      );
}
