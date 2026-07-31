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
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      // Android 14+ için kesin alarm iznini açıkça iste:
      await androidPlugin.requestExactAlarmsPermission();
    }
    
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
    // Önce eski olası tüm bildirimleri iptal et (1'den 7'ye kadar tüm günler için)
    await cancelMedication(medication);

    if (!medication.enabled) {
      return;
    }

    final now = DateTime.now();

    for (final dayOfWeek in medication.daysOfWeek) {
      // Dart's DateTime.weekday (1=Mon, 7=Sun)
      // tz.TZDateTime weekday matches DateTime.weekday
      int daysToAdd = dayOfWeek - now.weekday;
      if (daysToAdd < 0) {
        daysToAdd += 7;
      }
      
      var scheduled = DateTime(
        now.year,
        now.month,
        now.day,
        medication.hour,
        medication.minute,
      ).add(Duration(days: daysToAdd));

      // If it's today but the time has passed, schedule for next week
      if (daysToAdd == 0 && !scheduled.isAfter(now)) {
        scheduled = scheduled.add(const Duration(days: 7));
      }

      final notifId = (medication.id.hashCode & 0x7fffffff) + dayOfWeek;

      await _plugin.zonedSchedule(
        id: notifId,
        title: 'İlaç zamanı',
        body: '${medication.name}',
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
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  Future<void> cancelMedication(Medication medication) async {
    final baseId = medication.id.hashCode & 0x7fffffff;
    for (int day = 1; day <= 7; day++) {
      await _plugin.cancel(id: baseId + day);
    }
  }

  Future<void> cancelAll() {
    return _plugin.cancelAll();
  }
}
