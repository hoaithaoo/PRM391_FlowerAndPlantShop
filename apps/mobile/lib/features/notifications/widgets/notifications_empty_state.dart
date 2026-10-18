import 'package:flutter/material.dart';

import '../utils/notification_theme.dart';

class NotificationsEmptyState extends StatelessWidget {
  const NotificationsEmptyState({
    super.key,
    required this.filterLabel,
    this.onShowAll,
  });

  final String filterLabel;
  final VoidCallback? onShowAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: NotificationColors.forest50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_florist_outlined,
              color: NotificationColors.forest700,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có thông báo $filterLabel',
            textAlign: TextAlign.center,
            style: NotificationTextStyles.cardTitle,
          ),
          const SizedBox(height: 7),
          const Text(
            'Khi có tin mới, những cánh hoa nhỏ sẽ mang lời nhắn đến bạn tại đây.',
            textAlign: TextAlign.center,
            style: NotificationTextStyles.body,
          ),
          if (onShowAll != null) ...<Widget>[
            const SizedBox(height: 18),
            TextButton(
              onPressed: onShowAll,
              child: const Text('Xem tất cả thông báo'),
            ),
          ],
        ],
      ),
    );
  }
}
