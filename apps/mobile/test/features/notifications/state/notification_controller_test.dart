import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/notifications/data/notification_failure.dart';
import 'package:plant_flower_mobile/features/notifications/data/notification_repository.dart';
import 'package:plant_flower_mobile/features/notifications/models/notification_filter.dart';
import 'package:plant_flower_mobile/features/notifications/models/notification_item.dart';
import 'package:plant_flower_mobile/features/notifications/models/notification_list_result.dart';
import 'package:plant_flower_mobile/features/notifications/models/notification_read_result.dart';
import 'package:plant_flower_mobile/features/notifications/models/notification_type.dart';
import 'package:plant_flower_mobile/features/notifications/state/notification_controller.dart';

void main() {
  group('NotificationController', () {
    test('tải trang kế tiếp và loại ID trùng', () async {
      final first = _item('1');
      final second = _item('2');
      final third = _item('3', isRead: true);
      final repository = _FakeNotificationRepository(
        responses: {
          (1, false): _result(
            items: [first, second],
            page: 1,
            total: 3,
            totalPages: 2,
            unreadCount: 2,
          ),
          (2, false): _result(
            items: [second, third],
            page: 2,
            total: 3,
            totalPages: 2,
            unreadCount: 2,
          ),
        },
      );
      final controller = NotificationController(repository: repository);
      addTearDown(controller.dispose);

      await controller.loadInitial();
      await controller.loadMore();

      expect(controller.state.items.map((item) => item.id), ['1', '2', '3']);
      expect(controller.state.page, 2);
      expect(controller.state.hasMore, isFalse);
      expect(repository.requests, [(1, false), (2, false)]);
    });

    test('bộ lọc Chưa đọc gọi server với unreadOnly=true', () async {
      final repository = _FakeNotificationRepository(
        responses: {
          (1, false): _result(items: [_item('1')], unreadCount: 1),
          (1, true): _result(items: [_item('1')], unreadCount: 1),
        },
      );
      final controller = NotificationController(repository: repository);
      addTearDown(controller.dispose);

      await controller.loadInitial();
      await controller.setFilter(NotificationFilter.unread);

      expect(controller.state.currentFilter, NotificationFilter.unread);
      expect(repository.requests.last, (1, true));
    });

    test('refresh thay danh sách trang đầu thay vì trộn dữ liệu cũ', () async {
      final repository = _FakeNotificationRepository(
        responses: {
          (1, false): _result(items: [_item('1')], unreadCount: 1),
        },
      );
      final controller = NotificationController(repository: repository);
      addTearDown(controller.dispose);

      await controller.loadInitial();
      repository.responses[(1, false)] = _result(
        items: [_item('2')],
        unreadCount: 1,
      );
      await controller.refresh();

      expect(controller.state.items.map((item) => item.id), ['2']);
    });

    test('đọc một thông báo cập nhật unreadCount và bỏ khỏi bộ lọc', () async {
      final item = _item('1');
      final repository = _FakeNotificationRepository(
        responses: {
          (1, true): _result(items: [item], unreadCount: 1),
        },
      );
      final controller = NotificationController(repository: repository);
      addTearDown(controller.dispose);

      await controller.setFilter(NotificationFilter.unread);
      await controller.markAsRead(item);

      expect(controller.state.items, isEmpty);
      expect(controller.state.unreadCount, 0);
      expect(repository.markedIds, ['1']);
    });

    test('không gọi PATCH lại cho thông báo đã đọc', () async {
      final item = _item('1', isRead: true);
      final repository = _FakeNotificationRepository(
        responses: const <(int, bool), NotificationListResult>{},
      );
      final controller = NotificationController(repository: repository);
      addTearDown(controller.dispose);

      await controller.markAsRead(item);

      expect(repository.markedIds, isEmpty);
    });

    test('PATCH thất bại giữ nguyên unread và hiển thị lỗi phù hợp', () async {
      final item = _item('1');
      final repository = _FakeNotificationRepository(
        responses: {
          (1, false): _result(items: [item], unreadCount: 1),
        },
        markReadFailure: const NotificationFailure(
          code: NotificationErrorCode.notificationNotFound,
          statusCode: 404,
        ),
      );
      final controller = NotificationController(repository: repository);
      addTearDown(controller.dispose);

      await controller.loadInitial();
      await controller.markAsRead(item);

      expect(controller.state.items.single.isRead, isFalse);
      expect(controller.state.unreadCount, 1);
      expect(controller.state.actionErrorMessage, 'Không tìm thấy thông báo.');
    });

    test('đọc tất cả cập nhật danh sách và phản hồi thành công', () async {
      final repository = _FakeNotificationRepository(
        responses: {
          (1, false): _result(
            items: [_item('1'), _item('2', isRead: true)],
            unreadCount: 1,
          ),
        },
      );
      final controller = NotificationController(repository: repository);
      addTearDown(controller.dispose);

      await controller.loadInitial();
      await controller.markAllAsRead();

      expect(controller.state.unreadCount, 0);
      expect(controller.state.items.every((item) => item.isRead), isTrue);
      expect(controller.state.actionSuccessMessage, isNotNull);
      expect(repository.markAllCalls, 1);
    });
  });
}

NotificationItem _item(String id, {bool isRead = false}) => NotificationItem(
  id: id,
  type: NotificationType.system,
  title: 'Thông báo $id',
  message: 'Nội dung',
  isRead: isRead,
  createdAt: DateTime.utc(
    2026,
    11,
    2,
  ).subtract(Duration(minutes: int.parse(id))),
);

NotificationListResult _result({
  required List<NotificationItem> items,
  int page = 1,
  int? total,
  int totalPages = 1,
  required int unreadCount,
}) => NotificationListResult(
  items: items,
  page: page,
  total: total ?? items.length,
  totalPages: totalPages,
  unreadCount: unreadCount,
);

class _FakeNotificationRepository implements NotificationRepository {
  _FakeNotificationRepository({required this.responses, this.markReadFailure});

  final Map<(int, bool), NotificationListResult> responses;
  final NotificationFailure? markReadFailure;
  final List<(int, bool)> requests = [];
  final List<String> markedIds = [];
  int markAllCalls = 0;

  @override
  Future<NotificationListResult> getNotifications({
    int page = 1,
    bool unreadOnly = false,
  }) async {
    requests.add((page, unreadOnly));
    return responses[(page, unreadOnly)]!;
  }

  @override
  Future<NotificationReadResult> markAsRead(String notificationId) async {
    markedIds.add(notificationId);
    final failure = markReadFailure;
    if (failure != null) throw failure;
    for (final entry in responses.entries.toList()) {
      if (!entry.key.$2) continue;
      final result = entry.value;
      final items = result.items
          .where((item) => item.id != notificationId)
          .toList(growable: false);
      responses[entry.key] = NotificationListResult(
        items: items,
        page: result.page,
        total: items.length,
        totalPages: items.isEmpty ? 0 : result.totalPages,
        unreadCount: (result.unreadCount - 1).clamp(0, result.unreadCount),
      );
    }
    return NotificationReadResult(
      id: notificationId,
      isRead: true,
      readAt: DateTime.utc(2026, 11, 2),
    );
  }

  @override
  Future<int> markAllAsRead() async {
    markAllCalls++;
    return 1;
  }

  @override
  Stream<NotificationItem> watchNotifications() => const Stream.empty();
}
