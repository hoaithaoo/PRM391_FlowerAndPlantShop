import 'package:flutter/material.dart';

class UnreadFilter extends StatelessWidget {
  const UnreadFilter({
    super.key,
    required this.unreadOnly,
    required this.unreadCount,
    required this.onChanged,
    this.enabled = true,
  });

  final bool unreadOnly;
  final int unreadCount;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '$unreadCount unread',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                unreadCount == 0
                    ? 'You are all caught up.'
                    : 'Tap an unread notification to mark it as read.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SegmentedButton<bool>(
          segments: const <ButtonSegment<bool>>[
            ButtonSegment<bool>(value: false, label: Text('All')),
            ButtonSegment<bool>(value: true, label: Text('Unread')),
          ],
          selected: <bool>{unreadOnly},
          onSelectionChanged: enabled
              ? (selection) {
                  if (selection.isNotEmpty) {
                    onChanged(selection.first);
                  }
                }
              : null,
          showSelectedIcon: false,
        ),
      ],
    );
  }
}
