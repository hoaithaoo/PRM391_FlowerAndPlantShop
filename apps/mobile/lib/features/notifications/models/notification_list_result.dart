import 'notification_item.dart';

class NotificationListResult {
  const NotificationListResult({
    required this.items,
    required this.page,
    required this.total,
    required this.totalPages,
    required this.unreadCount,
  });

  final List<NotificationItem> items;
  final int page;
  final int total;
  final int totalPages;
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

    final page = _nonNegativeInt(meta['page'] ?? data['page'], 'page');
    final total = _nonNegativeInt(meta['total'] ?? data['total'], 'total');
    final totalPages = _nonNegativeInt(
      meta['totalPages'] ?? data['totalPages'],
      'totalPages',
    );
    final unreadCount = _nonNegativeInt(
      meta['unreadCount'] ?? data['unreadCount'],
      'unreadCount',
    );

    return NotificationListResult(
      items: rawItems
          .map(
            (item) => NotificationItem.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
      page: page,
      total: total,
      totalPages: totalPages,
      unreadCount: unreadCount,
    );
  }
}

int _nonNegativeInt(Object? value, String field) {
  if (value is num && value >= 0 && value == value.roundToDouble()) {
    return value.toInt();
  }
  throw FormatException('Invalid or missing field: $field');
}
