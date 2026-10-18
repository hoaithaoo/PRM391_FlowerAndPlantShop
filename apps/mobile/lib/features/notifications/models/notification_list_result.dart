import 'notification_item.dart';

class NotificationListResult {
  const NotificationListResult({
    required this.items,
    required this.unreadCount,
  });

  final List<NotificationItem> items;
  final int unreadCount;

  factory NotificationListResult.fromApiResponse(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    final meta = json['meta'] is Map
        ? Map<String, dynamic>.from(json['meta'] as Map)
        : data['meta'] is Map
        ? Map<String, dynamic>.from(data['meta'] as Map)
        : const <String, dynamic>{};
    final rawItems = data['items'];
    if (rawItems is! List) {
      throw const FormatException('Invalid or missing field: items');
    }

    final unreadValue = meta['unreadCount'] ?? data['unreadCount'];
    if (unreadValue is! num || unreadValue < 0) {
      throw const FormatException('Invalid or missing field: unreadCount');
    }

    return NotificationListResult(
      items: rawItems
          .map(
            (item) => NotificationItem.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
      unreadCount: unreadValue.toInt(),
    );
  }
}
