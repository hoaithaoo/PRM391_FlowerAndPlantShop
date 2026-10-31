import 'package:flutter/material.dart';

import '../models/notification_type.dart';
import '../utils/notification_theme.dart';

class NotificationTypeIcon extends StatelessWidget {
  const NotificationTypeIcon({super.key, required this.type, this.size = 42});

  final NotificationType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (icon, foreground, background) = switch (type) {
      NotificationType.order => (
        Icons.local_florist_outlined,
        NotificationColors.forest700,
        NotificationColors.forest50,
      ),
      NotificationType.payment => (
        Icons.payments_outlined,
        NotificationColors.forest700,
        NotificationColors.forest100,
      ),
      NotificationType.promotion => (
        Icons.eco_outlined,
        const Color(0xFF9B762C),
        const Color(0xFFFFF3DC),
      ),
      NotificationType.system => (
        Icons.menu_book_outlined,
        NotificationColors.charcoal500,
        NotificationColors.forest50,
      ),
    };

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, color: foreground, size: size * 0.48),
    );
  }
}
