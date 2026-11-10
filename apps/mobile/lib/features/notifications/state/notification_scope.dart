import 'package:flutter/widgets.dart';

import 'notification_controller.dart';

class NotificationScope extends InheritedNotifier<NotificationController> {
  const NotificationScope({
    super.key,
    required NotificationController controller,
    required this.onOpen,
    required super.child,
  }) : super(notifier: controller);

  final VoidCallback onOpen;

  static NotificationScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<NotificationScope>();
  }
}
