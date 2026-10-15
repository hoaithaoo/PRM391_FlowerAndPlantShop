import '../models/notification_filter.dart';
import '../models/notification_item.dart';

enum NotificationLoadStatus {
  initial,
  loading,
  loaded,
  error,
  authenticationRequired,
}

class NotificationState {
  const NotificationState({
    this.status = NotificationLoadStatus.initial,
    this.items = const <NotificationItem>[],
    this.currentFilter = NotificationFilter.all,
    this.isMarkingAll = false,
    this.markingReadIds = const <String>{},
    this.errorMessage,
    this.actionErrorMessage,
  });

  static const _unset = Object();

  final NotificationLoadStatus status;
  final List<NotificationItem> items;
  final NotificationFilter currentFilter;
  final bool isMarkingAll;
  final Set<String> markingReadIds;
  final String? errorMessage;
  final String? actionErrorMessage;

  int get unreadCount => items.where((item) => !item.isRead).length;

  List<NotificationItem> get visibleItems {
    final type = currentFilter.type;
    if (type == null) return items;
    return items.where((item) => item.type == type).toList(growable: false);
  }

  int countFor(NotificationFilter filter) {
    final type = filter.type;
    return type == null
        ? items.length
        : items.where((item) => item.type == type).length;
  }

  NotificationState copyWith({
    NotificationLoadStatus? status,
    List<NotificationItem>? items,
    NotificationFilter? currentFilter,
    bool? isMarkingAll,
    Set<String>? markingReadIds,
    Object? errorMessage = _unset,
    Object? actionErrorMessage = _unset,
  }) {
    return NotificationState(
      status: status ?? this.status,
      items: items ?? this.items,
      currentFilter: currentFilter ?? this.currentFilter,
      isMarkingAll: isMarkingAll ?? this.isMarkingAll,
      markingReadIds: markingReadIds ?? this.markingReadIds,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      actionErrorMessage: identical(actionErrorMessage, _unset)
          ? this.actionErrorMessage
          : actionErrorMessage as String?,
    );
  }
}
