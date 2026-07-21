import 'dart:async';

import 'package:flutter/material.dart';

import 'src/aura_app.dart';
import 'src/services/notification_service.dart';
import 'src/services/storage_service.dart';
import 'src/state/aura_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final notifications = NotificationService();
  final controller = AuraController(
    storage: StorageService(),
    notifications: notifications,
  );

  runApp(AuraApp(controller: controller));

  unawaited(_bootstrap(controller, notifications));
}

Future<void> _bootstrap(
  AuraController controller,
  NotificationService notifications,
) async {
  try {
    await notifications.initialize();
  } catch (_) {
    // Notifications are optional during app startup.
  }

  try {
    await controller.load();
  } catch (_) {
    // Keep the app usable even if local data or reminders fail.
  }
}
