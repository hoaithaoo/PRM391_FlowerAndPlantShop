import 'package:flutter/material.dart';

import '../models/notification_type.dart';

class NotificationTypeIcon extends StatelessWidget {
  const NotificationTypeIcon({super.key, required this.type});

  final NotificationType type;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (icon, color) = switch (type) {
      NotificationType.order => (
        Icons.local_shipping_outlined,
        colorScheme.primary,
      ),
      NotificationType.payment => (
        Icons.payments_outlined,
        colorScheme.tertiary,
      ),
      NotificationType.promotion => (
        Icons.campaign_outlined,
        colorScheme.secondary,
      ),
      NotificationType.system => (
        Icons.info_outline,
        colorScheme.onSurfaceVariant,
      ),
    };

    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color),
    );
  }
}
