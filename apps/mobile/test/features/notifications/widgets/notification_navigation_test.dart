import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/notifications/data/mock_notification_repository.dart';
import 'package:plant_flower_mobile/features/notifications/models/notification_item.dart';
import 'package:plant_flower_mobile/features/notifications/models/notification_type.dart';
import 'package:plant_flower_mobile/features/notifications/state/notification_controller.dart';
import 'package:plant_flower_mobile/features/notifications/state/notification_scope.dart';
import 'package:plant_flower_mobile/features/products/widgets/common/brand_header.dart';

void main() {
  testWidgets('chuông dùng unreadCount thật và gọi điều hướng từ scope', (
    tester,
  ) async {
    final repository = MockNotificationRepository(
      delay: Duration.zero,
      seedItems: [
        NotificationItem(
          id: 'unread-1',
          type: NotificationType.system,
          title: 'Thông báo',
          message: 'Nội dung',
          isRead: false,
          createdAt: DateTime.utc(2026, 11, 2),
        ),
      ],
    );
    final controller = NotificationController(repository: repository);
    addTearDown(controller.dispose);
    addTearDown(repository.close);
    await tester.runAsync(controller.loadInitial);
    var openCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: NotificationScope(
          controller: controller,
          onOpen: () => openCount++,
          child: const Scaffold(appBar: BrandHeader()),
        ),
      ),
    );

    final button = find.byKey(const Key('header-notifications'));
    expect(button, findsOneWidget);
    expect(find.byType(Positioned), findsOneWidget);
    await tester.tap(button);
    expect(openCount, 1);

    await tester.runAsync(controller.markAllAsRead);
    await tester.pump();
    expect(find.byType(Positioned), findsNothing);
  });
}
