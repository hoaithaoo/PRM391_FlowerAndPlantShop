import 'notification_type.dart';

class NotificationItem {
  static const _unset = Object();

  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.timeLabel,
    this.badge,
    this.secondaryAction,
    this.amount,
    this.imageAsset,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? timeLabel;
  final String? badge;
  final String? secondaryAction;
  final String? amount;
  final String? imageAsset;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: _requiredString(json, 'id'),
      type: NotificationType.fromApiValue(_requiredString(json, 'type')),
      title: _requiredString(json, 'title'),
      message: _requiredString(json, 'message'),
      isRead: _requiredBool(json, 'isRead'),
      createdAt: _requiredDateTime(json, 'createdAt'),
      readAt: _optionalDateTime(json['readAt']),
      timeLabel: _optionalString(json['timeLabel']),
      badge: _optionalString(json['badge']),
      secondaryAction: _optionalString(json['secondaryAction']),
      amount: _optionalString(json['amount']),
      imageAsset: _optionalString(json['imageAsset']),
    );
  }

  NotificationItem copyWith({bool? isRead, Object? readAt = _unset}) {
    return NotificationItem(
      id: id,
      type: type,
      title: title,
      message: message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      readAt: identical(readAt, _unset) ? this.readAt : readAt as DateTime?,
      timeLabel: timeLabel,
      badge: badge,
      secondaryAction: secondaryAction,
      amount: amount,
      imageAsset: imageAsset,
    );
  }
}

String? _optionalString(Object? value) {
  return value is String && value.isNotEmpty ? value : null;
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
