import 'notification_type.dart';

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: _requiredString(json, 'id'),
      type: NotificationType.fromApiValue(_requiredString(json, 'type')),
      title: _requiredString(json, 'title'),
      message: _requiredString(json, 'message'),
      isRead: _requiredBool(json, 'isRead'),
      createdAt: _requiredDateTime(json, 'createdAt'),
      readAt: _optionalDateTime(json['readAt']),
    );
  }

  NotificationItem copyWith({bool? isRead, DateTime? readAt}) {
    return NotificationItem(
      id: id,
      type: type,
      title: title,
      message: message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
    );
  }
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw FormatException('Invalid or missing field: $key');
}

bool _requiredBool(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is bool) {
    return value;
  }
  throw FormatException('Invalid or missing field: $key');
}

DateTime _requiredDateTime(Map<String, dynamic> json, String key) {
  final value = _optionalDateTime(json[key]);
  if (value != null) {
    return value;
  }
  throw FormatException('Invalid or missing field: $key');
}

DateTime? _optionalDateTime(Object? value) {
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}
