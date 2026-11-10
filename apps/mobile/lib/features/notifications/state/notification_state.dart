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
    this.page = 0,
    this.total = 0,
    this.totalPages = 0,
    this.unreadCount = 0,
    this.isLoadingMore = false,
    this.isMarkingAll = false,
    this.markingReadIds = const <String>{},
    this.errorMessage,
    this.actionErrorMessage,
    this.actionSuccessMessage,
  });

  static const _unset = Object();

  final NotificationLoadStatus status;
  final List<NotificationItem> items;
  final NotificationFilter currentFilter;
  final int page;
  final int total;
  final int totalPages;
  final int unreadCount;
  final bool isLoadingMore;
  final bool isMarkingAll;
  final Set<String> markingReadIds;
  final String? errorMessage;
  final String? actionErrorMessage;
  final String? actionSuccessMessage;

  List<NotificationItem> get visibleItems => items;
  bool get hasMore => page < totalPages;

  NotificationState copyWith({
    NotificationLoadStatus? status,
    List<NotificationItem>? items,
    NotificationFilter? currentFilter,
    int? page,
    int? total,
    int? totalPages,
    int? unreadCount,
    bool? isLoadingMore,
    bool? isMarkingAll,
    Set<String>? markingReadIds,
    Object? errorMessage = _unset,
    Object? actionErrorMessage = _unset,
    Object? actionSuccessMessage = _unset,
  }) {
    return NotificationState(
      status: status ?? this.status,
      items: items ?? this.items,
      currentFilter: currentFilter ?? this.currentFilter,
      page: page ?? this.page,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isMarkingAll: isMarkingAll ?? this.isMarkingAll,
      markingReadIds: markingReadIds ?? this.markingReadIds,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      actionErrorMessage: identical(actionErrorMessage, _unset)
          ? this.actionErrorMessage
          : actionErrorMessage as String?,
      actionSuccessMessage: identical(actionSuccessMessage, _unset)
          ? this.actionSuccessMessage
          : actionSuccessMessage as String?,
    );
  }
}
