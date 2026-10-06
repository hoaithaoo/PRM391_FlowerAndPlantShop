class NotificationReadResult {
  const NotificationReadResult({
    required this.id,
    required this.isRead,
    this.readAt,
  });

  final String id;
  final bool isRead;
  final DateTime? readAt;

  factory NotificationReadResult.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final isRead = json['isRead'];
    final rawReadAt = json['readAt'];

    if (id is! String || id.isEmpty || isRead is! bool) {
      throw const FormatException('Invalid notification read response');
    }

    return NotificationReadResult(
      id: id,
      isRead: isRead,
      readAt: rawReadAt is String ? DateTime.tryParse(rawReadAt) : null,
    );
  }
}
