import 'notification_type.dart';

enum NotificationFilter {
  all,
  order,
  payment,
  promotion,
  system;

  NotificationType? get type => switch (this) {
    NotificationFilter.all => null,
    NotificationFilter.order => NotificationType.order,
    NotificationFilter.payment => NotificationType.payment,
    NotificationFilter.promotion => NotificationType.promotion,
    NotificationFilter.system => NotificationType.system,
  };

  String get label => switch (this) {
    NotificationFilter.all => 'Tất cả',
    NotificationFilter.order => 'Đơn hàng',
    NotificationFilter.payment => 'Thanh toán',
    NotificationFilter.promotion => 'Ưu đãi',
    NotificationFilter.system => 'Cẩm nang',
  };
}
