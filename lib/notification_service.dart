import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:math';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> setupDailyNotification() async {
  tzdata.initializeTimeZones();

  final now = DateTime.now();
  final hour = 9 + Random().nextInt(11); // 09–19
  final minute = Random().nextInt(60);

  final scheduledTime = tz.TZDateTime.local(
    now.year,
    now.month,
    now.day,
    hour,
    minute,
  );

  await notificationsPlugin.zonedSchedule(
    0,
    'Yeni Görev Zamanı!',
    '1 dakikanı ayır, bugünün görevini tamamla.',
    scheduledTime,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_tasks',
        'Günlük Görevler',
        importance: Importance.max,
        priority: Priority.high,
      ),
    ),
    androidAllowWhileIdle: true,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
  );
}
