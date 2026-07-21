import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/medication.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: android,
        iOS: darwin,
        macOS: darwin,
      ),
    );

    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> scheduleMedication(Medication medication) async {
    if (!medication.enabled) {
      await cancelMedication(medication);
      return;
    }

    final now = DateTime.now();
    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      medication.hour,
      medication.minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: medication.notificationId,
      title: 'İlaç zamanı',
      body: '${medication.name} • ${medication.dosage}',
      scheduledDate: tz.TZDateTime.from(scheduled, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'aura_medication_reminders',
          'İlaç hatırlatmaları',
          channelDescription: 'Günlük ilaç saatleri için Aura Health uyarıları',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelMedication(Medication medication) {
    return _plugin.cancel(id: medication.notificationId);
  }
}
