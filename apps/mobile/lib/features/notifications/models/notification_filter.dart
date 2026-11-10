enum NotificationFilter {
  all,
  unread;

  bool get unreadOnly => switch (this) {
    NotificationFilter.all => false,
    NotificationFilter.unread => true,
  };

  String get label => switch (this) {
    NotificationFilter.all => 'Tất cả',
    NotificationFilter.unread => 'Chưa đọc',
  };
}
