import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import '../models/project.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
    InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings);

    // Запрос разрешений (особенно для iOS, если нужно)
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    tz_data.initializeTimeZones();
  }

  Future<void> scheduleDeadline(Project project) async {
    final now = tz.TZDateTime.now(tz.local);
    final due = tz.TZDateTime.from(project.deadline, tz.local).subtract(const Duration(hours: 2));

    if (due.isBefore(now)) {
      return; // Не планировать прошедшие уведомления
    }

    await _plugin.zonedSchedule(
      project.id.hashCode & 0x7fffffff, // безопасный положительный ID
      'Срок проекта приближается',
      '${project.title} истекает в ${project.deadline}',
      due,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'deadline_channel',
          'Дедлайны',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }
}
