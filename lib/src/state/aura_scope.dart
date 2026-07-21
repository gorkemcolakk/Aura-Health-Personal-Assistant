import 'package:flutter/widgets.dart';

import 'aura_controller.dart';

class AuraScope extends InheritedNotifier<AuraController> {
  const AuraScope({
    super.key,
    required AuraController controller,
    required super.child,
  }) : super(notifier: controller);

  static AuraController of(BuildContext context, {bool listen = true}) {
    final scope = listen
        ? context.dependOnInheritedWidgetOfExactType<AuraScope>()
        : context.getInheritedWidgetOfExactType<AuraScope>();
    assert(scope != null, 'AuraScope bulunamadı');
    return scope!.notifier!;
  }
}
