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
    this.unreadCount = 0,
    this.unreadOnly = false,
    this.currentPage = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.isMarkingAll = false,
    this.markingReadIds = const <String>{},
    this.errorMessage,
    this.actionErrorMessage,
  });

  static const _unset = Object();

  final NotificationLoadStatus status;
  final List<NotificationItem> items;
  final int unreadCount;
  final bool unreadOnly;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isMarkingAll;
  final Set<String> markingReadIds;
  final String? errorMessage;
  final String? actionErrorMessage;

  NotificationState copyWith({
    NotificationLoadStatus? status,
    List<NotificationItem>? items,
    int? unreadCount,
    bool? unreadOnly,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isMarkingAll,
    Set<String>? markingReadIds,
    Object? errorMessage = _unset,
    Object? actionErrorMessage = _unset,
  }) {
    return NotificationState(
      status: status ?? this.status,
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      unreadOnly: unreadOnly ?? this.unreadOnly,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
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
