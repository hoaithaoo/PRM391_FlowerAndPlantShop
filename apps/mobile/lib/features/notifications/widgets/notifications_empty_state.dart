import 'package:flutter/material.dart';

class NotificationsEmptyState extends StatelessWidget {
  const NotificationsEmptyState({
    super.key,
    required this.unreadOnly,
    this.onShowAll,
  });

  final bool unreadOnly;
  final VoidCallback? onShowAll;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              unreadOnly
                  ? Icons.mark_email_read_outlined
                  : Icons.notifications_none_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              unreadOnly ? 'No unread notifications.' : 'No notifications yet.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (unreadOnly && onShowAll != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onShowAll,
                child: const Text('Show all notifications'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
