import 'package:flutter/material.dart';

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
              size: 56,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
