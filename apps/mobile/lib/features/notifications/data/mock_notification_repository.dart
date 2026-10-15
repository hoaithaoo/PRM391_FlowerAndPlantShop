import 'dart:async';

import '../models/notification_item.dart';
import '../models/notification_list_result.dart';
import '../models/notification_read_result.dart';
import '../models/notification_type.dart';
import 'notification_failure.dart';
import 'notification_repository.dart';

class MockNotificationRepository implements NotificationRepository {
  MockNotificationRepository({
    List<NotificationItem>? seedItems,
    this.delay = const Duration(milliseconds: 220),
    this.pageSize = 20,
  }) : _items = List<NotificationItem>.of(seedItems ?? _buildSeedItems());

  final List<NotificationItem> _items;
  final Duration delay;
  final int pageSize;
  final StreamController<NotificationItem> _realtimeController =
      StreamController<NotificationItem>.broadcast();

  @override
  Future<NotificationListResult> getNotifications({
    int page = 1,
    bool unreadOnly = false,
  }) async {
    await Future<void>.delayed(delay);
    final sorted = List<NotificationItem>.of(_items)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final filteredItems = unreadOnly
        ? sorted.where((item) => !item.isRead).toList(growable: false)
        : sorted;
    final start = (page - 1) * pageSize;
    final end = (start + pageSize).clamp(0, filteredItems.length).toInt();
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

  @override
  Stream<NotificationItem> watchNotifications() => _realtimeController.stream;

  void emitRealtime(NotificationItem notification) {
    final index = _items.indexWhere((item) => item.id == notification.id);
    if (index == -1) {
      _items.add(notification);
    } else {
      _items[index] = notification;
    }
    _realtimeController.add(notification);
  }

  Future<void> close() => _realtimeController.close();

  static List<NotificationItem> _buildSeedItems() {
    final now = DateTime.now();
    return <NotificationItem>[
      NotificationItem(
        id: 'mock-order-9281',
        type: NotificationType.order,
        title: 'Đơn hàng #ORD-9281',
        message:
            'Nghệ nhân xưởng hoa Fleuré đang chăm sóc từng nhánh hoa cho tác phẩm của bạn.',
        isRead: true,
        createdAt: now.subtract(const Duration(minutes: 15)),
        readAt: now.subtract(const Duration(minutes: 4)),
        timeLabel: '15 phút trước',
        badge: 'Xưởng hoa đang cắm',
        secondaryAction: 'Theo dõi tiến độ',
        imageAsset: 'assets/notifications/order_workshop.png',
      ),
      NotificationItem(
        id: 'mock-payment-1525800',
        type: NotificationType.payment,
        title: 'Thanh toán thành công',
        message:
            'Hệ thống SePay đã xác nhận giao dịch 1.525.800 đ cho đơn hàng #ORD-9281.',
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 2)),
        timeLabel: '10:46 AM',
        badge: 'SePay QR Verified',
        amount: '1.525.800 đ',
      ),
      NotificationItem(
        id: 'mock-autumn-collection',
        type: NotificationType.promotion,
        title: 'Bộ sưu tập hoa Mùa Thu',
        message:
            'Khám phá các giống hoa nhập khẩu độc bản với tông màu ấm áp tự nhiên.',
        isRead: true,
        createdAt: now.subtract(const Duration(days: 1)),
        readAt: now.subtract(const Duration(hours: 18)),
        timeLabel: 'Hôm qua',
        badge: 'BST Mùa Vàng 2024',
        secondaryAction: 'Khám phá BST ngay',
        imageAsset: 'assets/notifications/autumn_collection.png',
      ),
      NotificationItem(
        id: 'mock-policy-update',
        type: NotificationType.system,
        title: 'Cập nhật chính sách',
        message:
            'Hướng dẫn mới giúp giữ hoa tươi lâu hơn từ các nghệ nhân chuyên nghiệp.',
        isRead: true,
        createdAt: now.subtract(const Duration(days: 3)),
        readAt: now.subtract(const Duration(days: 2)),
        timeLabel: '3 ngày trước',
        badge: 'Cẩm nang xưởng hoa',
      ),
    ];
  }
}
