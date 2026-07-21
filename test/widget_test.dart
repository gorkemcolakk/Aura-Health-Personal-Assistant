import 'package:flutter_test/flutter_test.dart';

import 'package:aura_health/src/aura_app.dart';
import 'package:aura_health/src/services/notification_service.dart';
import 'package:aura_health/src/services/storage_service.dart';
import 'package:aura_health/src/state/aura_controller.dart';

void main() {
  testWidgets('Aura dashboard renders health overview', (tester) async {
    final controller = AuraController(
      storage: StorageService(),
      notifications: NotificationService(),
    );

    await tester.pumpWidget(AuraApp(controller: controller));

    expect(find.text('Aura Health'), findsOneWidget);
    expect(find.text('Günün sağlık paneli'), findsOneWidget);
    expect(find.text('VKİ • Dengeli'), findsOneWidget);
  });
}
