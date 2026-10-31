enum NotificationType {
  order,
  payment,
  promotion,
  system;

  factory NotificationType.fromApiValue(String value) {
    return switch (value) {
      'ORDER' => NotificationType.order,
      'PAYMENT' => NotificationType.payment,
      'PROMOTION' => NotificationType.promotion,
      'SYSTEM' => NotificationType.system,
      _ => throw FormatException('Unsupported notification type: $value'),
    };
  }

  String get apiValue => switch (this) {
    NotificationType.order => 'ORDER',
    NotificationType.payment => 'PAYMENT',
    NotificationType.promotion => 'PROMOTION',
    NotificationType.system => 'SYSTEM',
  };
}
