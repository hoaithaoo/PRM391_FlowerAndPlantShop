String formatNotificationTime(DateTime createdAt, {DateTime? now}) {
  final referenceTime = now ?? DateTime.now();
  final difference = referenceTime.difference(createdAt.toLocal());

  if (difference.isNegative || difference.inMinutes < 1) {
    return 'Vừa xong';
  }
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes} phút trước';
  }
  if (difference.inHours < 24) {
    return '${difference.inHours} giờ trước';
  }
  if (difference.inDays == 1) {
    return 'Hôm qua';
  }
  if (difference.inDays < 7) {
    return '${difference.inDays} ngày trước';
  }

  final localDate = createdAt.toLocal();
  final day = localDate.day.toString().padLeft(2, '0');
  final month = localDate.month.toString().padLeft(2, '0');
  final hour = localDate.hour.toString().padLeft(2, '0');
  final minute = localDate.minute.toString().padLeft(2, '0');
  return '$day/$month/${localDate.year} $hour:$minute';
}
