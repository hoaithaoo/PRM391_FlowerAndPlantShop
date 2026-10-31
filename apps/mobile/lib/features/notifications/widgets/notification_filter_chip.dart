import 'package:flutter/material.dart';

import '../models/notification_filter.dart';
import '../utils/notification_theme.dart';

class NotificationFilters extends StatelessWidget {
  const NotificationFilters({
    super.key,
    required this.selected,
    required this.countFor,
    required this.onSelected,
  });

  final NotificationFilter selected;
  final int Function(NotificationFilter filter) countFor;
  final ValueChanged<NotificationFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: NotificationFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = NotificationFilter.values[index];
          final active = filter == selected;
          return Semantics(
            selected: active,
            button: true,
            child: Material(
              color: active
                  ? NotificationColors.forest900
                  : NotificationColors.creamPastel,
              shape: StadiumBorder(
                side: BorderSide(
                  color: active
                      ? NotificationColors.forest900
                      : NotificationColors.cream200,
                ),
              ),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () => onSelected(filter),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Center(
                    child: Text(
                      '${filter.label} (${countFor(filter)})',
                      style: TextStyle(
                        fontFamily: NotificationTextStyles.sans,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: active
                            ? NotificationColors.white
                            : NotificationColors.charcoal700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
