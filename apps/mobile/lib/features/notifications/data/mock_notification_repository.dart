import '../models/notification_item.dart';
import '../models/notification_list_result.dart';
import '../models/notification_read_result.dart';
import '../models/notification_type.dart';
import 'notification_failure.dart';
import 'notification_repository.dart';

class MockNotificationRepository implements NotificationRepository {
  MockNotificationRepository({
    List<NotificationItem>? seedItems,
    this.delay = const Duration(milliseconds: 450),
    this.pageSize = 4,
  }) : _items = List<NotificationItem>.of(seedItems ?? _buildSeedItems());

  final List<NotificationItem> _items;
  final Duration delay;
  final int pageSize;

  @override
  Future<NotificationListResult> getNotifications({
    int page = 1,
    bool unreadOnly = false,
  }) async {
    await Future<void>.delayed(delay);
    final filteredItems = unreadOnly
        ? _items.where((item) => !item.isRead).toList(growable: false)
        : List<NotificationItem>.of(_items);
    final start = (page - 1) * pageSize;
    final requestedEnd = start + pageSize;
    final end = requestedEnd > filteredItems.length
        ? filteredItems.length
        : requestedEnd;
    final pageItems = start >= filteredItems.length
        ? const <NotificationItem>[]
        : filteredItems.sublist(start, end);

    return NotificationListResult(
      items: pageItems,
      unreadCount: _items.where((item) => !item.isRead).length,
    );
  }

  @override
  Future<NotificationReadResult> markAsRead(String notificationId) async {
    await Future<void>.delayed(delay);
    final index = _items.indexWhere((item) => item.id == notificationId);
    if (index < 0) {
      throw const NotificationFailure(
        code: NotificationErrorCode.notificationNotFound,
        statusCode: 404,
      );
    }

    final readAt = DateTime.now();
    _items[index] = _items[index].copyWith(isRead: true, readAt: readAt);
    return NotificationReadResult(
      id: notificationId,
      isRead: true,
      readAt: readAt,
    );
  }

  @override
  Future<int> markAllAsRead() async {
    await Future<void>.delayed(delay);
    final readAt = DateTime.now();
    var updatedCount = 0;

    for (var index = 0; index < _items.length; index++) {
      if (!_items[index].isRead) {
        _items[index] = _items[index].copyWith(isRead: true, readAt: readAt);
        updatedCount++;
      }
    }

    return updatedCount;
  }

  static List<NotificationItem> _buildSeedItems() {
    final now = DateTime.now();
    return <NotificationItem>[
      NotificationItem(
        id: 'mock-order-1',
        type: NotificationType.order,
        title: 'Order confirmed',
        message: 'Your order PFS-1024 has been confirmed.',
        isRead: false,
        createdAt: now.subtract(const Duration(minutes: 4)),
      ),
      NotificationItem(
        id: 'mock-payment-1',
        type: NotificationType.payment,
        title: 'Payment received',
        message: 'Your SePay payment was received successfully.',
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      NotificationItem(
        id: 'mock-promotion-1',
        type: NotificationType.promotion,
        title: 'Weekend flower offer',
        message: 'Enjoy a special offer on selected flower bouquets.',
        isRead: true,
        createdAt: now.subtract(const Duration(days: 1)),
        readAt: now.subtract(const Duration(hours: 20)),
      ),
      NotificationItem(
        id: 'mock-system-1',
        type: NotificationType.system,
        title: 'Welcome to Plant & Flower',
        message: 'Your notification preferences are ready.',
        isRead: true,
        createdAt: now.subtract(const Duration(days: 2)),
        readAt: now.subtract(const Duration(days: 1)),
      ),
      NotificationItem(
        id: 'mock-order-2',
        type: NotificationType.order,
        title: 'Order is being prepared',
        message: 'We are preparing your plants for delivery.',
        isRead: false,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      NotificationItem(
        id: 'mock-system-2',
        type: NotificationType.system,
        title: 'Store hours updated',
        message: 'Our weekend opening hours have changed.',
        isRead: true,
        createdAt: now.subtract(const Duration(days: 5)),
        readAt: now.subtract(const Duration(days: 4)),
      ),
    ];
  }
}
