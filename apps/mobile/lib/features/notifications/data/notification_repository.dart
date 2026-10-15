import '../models/notification_list_result.dart';
import '../models/notification_read_result.dart';
import '../models/notification_item.dart';

abstract interface class NotificationRepository {
  Future<NotificationListResult> getNotifications({
    int page = 1,
    bool unreadOnly = false,
  });

  Future<NotificationReadResult> markAsRead(String notificationId);

  Future<int> markAllAsRead();

  Stream<NotificationItem> watchNotifications();
}
