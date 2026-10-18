import '../models/notification_item.dart';

abstract interface class NotificationRealtimeDataSource {
  Stream<NotificationItem> watchNotifications();
}

class EmptyNotificationRealtimeDataSource
    implements NotificationRealtimeDataSource {
  const EmptyNotificationRealtimeDataSource();

  @override
  Stream<NotificationItem> watchNotifications() {
    // TODO: Kết nối WebSocket/SSE/Supabase/Firebase tại composition root.
    return const Stream<NotificationItem>.empty();
  }
}
