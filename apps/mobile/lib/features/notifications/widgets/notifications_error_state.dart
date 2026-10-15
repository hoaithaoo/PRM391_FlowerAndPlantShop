import 'package:flutter/material.dart';

import '../utils/notification_theme.dart';

class NotificationsErrorState extends StatelessWidget {
  const NotificationsErrorState({
    super.key,
    required this.message,
    required this.onRetry,
    this.authenticationRequired = false,
  });

  final String message;
  final VoidCallback onRetry;
  final bool authenticationRequired;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              authenticationRequired
                  ? Icons.lock_clock_outlined
                  : Icons.cloud_off_outlined,
              size: 50,
              color: NotificationColors.petal500,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: NotificationTextStyles.body,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
