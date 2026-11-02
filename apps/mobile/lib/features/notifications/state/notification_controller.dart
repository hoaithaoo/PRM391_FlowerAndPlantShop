import 'package:flutter/foundation.dart';

import '../data/notification_failure.dart';
import '../data/notification_repository.dart';
import '../models/notification_filter.dart';
import '../models/notification_item.dart';
import 'notification_state.dart';

class NotificationController extends ChangeNotifier {
  NotificationController({required NotificationRepository repository})
    : _repository = repository;

  final NotificationRepository _repository;
  NotificationState _state = const NotificationState();
  int _requestGeneration = 0;
  bool _isDisposed = false;

  NotificationState get state => _state;

  Future<void> loadInitial() => _loadFirstPage(showFullLoader: true);

  Future<void> refresh() => _loadFirstPage(showFullLoader: false);

  Future<void> setFilter(NotificationFilter filter) async {
    if (_state.currentFilter == filter) return;
    _setState(
      _state.copyWith(
        currentFilter: filter,
        items: const <NotificationItem>[],
        page: 0,
        total: 0,
        totalPages: 0,
        status: NotificationLoadStatus.loading,
        errorMessage: null,
        actionErrorMessage: null,
        actionSuccessMessage: null,
      ),
    );
    await _loadFirstPage(showFullLoader: true);
  }

  Future<void> _loadFirstPage({required bool showFullLoader}) async {
    final generation = ++_requestGeneration;
    _setState(
      _state.copyWith(
        status: showFullLoader ? NotificationLoadStatus.loading : _state.status,
        isLoadingMore: false,
        errorMessage: null,
        actionErrorMessage: null,
        actionSuccessMessage: null,
      ),
    );

    try {
      final result = await _repository.getNotifications(
        page: 1,
        unreadOnly: _state.currentFilter.unreadOnly,
      );
      if (generation != _requestGeneration) return;
      _setState(
        _state.copyWith(
          status: NotificationLoadStatus.loaded,
          items: result.items,
          page: result.page,
          total: result.total,
          totalPages: result.totalPages,
          unreadCount: result.unreadCount,
          errorMessage: null,
        ),
      );
    } on NotificationFailure catch (failure) {
      if (generation == _requestGeneration) _setLoadFailure(failure);
    } catch (_) {
      if (generation == _requestGeneration) {
        _setLoadFailure(const NotificationFailure.network());
      }
    }
  }

  Future<void> loadMore() async {
    if (_state.status != NotificationLoadStatus.loaded ||
        _state.isLoadingMore ||
        !_state.hasMore) {
      return;
    }

    final generation = _requestGeneration;
    final nextPage = _state.page + 1;
    _setState(
      _state.copyWith(
        isLoadingMore: true,
        actionErrorMessage: null,
        actionSuccessMessage: null,
      ),
    );

    try {
      final result = await _repository.getNotifications(
        page: nextPage,
        unreadOnly: _state.currentFilter.unreadOnly,
      );
      if (generation != _requestGeneration) return;
      _setState(
        _state.copyWith(
          items: _appendUnique(_state.items, result.items),
          page: result.page,
          total: result.total,
          totalPages: result.totalPages,
          unreadCount: result.unreadCount,
          isLoadingMore: false,
        ),
      );
    } on NotificationFailure catch (failure) {
      if (generation == _requestGeneration) {
        _setState(
          _state.copyWith(
            isLoadingMore: false,
            actionErrorMessage: _messageForFailure(failure),
          ),
        );
      }
    } catch (_) {
      if (generation == _requestGeneration) {
        _setState(
          _state.copyWith(
            isLoadingMore: false,
            actionErrorMessage: _messageForFailure(
              const NotificationFailure.network(),
            ),
          ),
        );
      }
    }
  }

  Future<void> markAsRead(NotificationItem notification) async {
    if (notification.isRead ||
        _state.isMarkingAll ||
        _state.markingReadIds.contains(notification.id)) {
      return;
    }

    _setState(
      _state.copyWith(
        markingReadIds: <String>{..._state.markingReadIds, notification.id},
        actionErrorMessage: null,
        actionSuccessMessage: null,
      ),
    );

    try {
      final result = await _repository.markAsRead(notification.id);
      final updated = notification.copyWith(
        isRead: result.isRead,
        readAt: result.readAt,
      );
      final unreadCount = result.isRead
          ? (_state.unreadCount - 1).clamp(0, _state.unreadCount)
          : _state.unreadCount;
      final isUnreadFilter =
          _state.currentFilter == NotificationFilter.unread && result.isRead;
      _setState(
        _state.copyWith(
          items: isUnreadFilter
              ? _state.items
                    .where((item) => item.id != notification.id)
                    .toList(growable: false)
              : _replaceItem(_state.items, updated),
          total: isUnreadFilter
              ? (_state.total - 1).clamp(0, _state.total)
              : _state.total,
          unreadCount: unreadCount,
          markingReadIds: _withoutPending(notification.id),
        ),
      );
      if (isUnreadFilter) await refresh();
    } on NotificationFailure catch (failure) {
      _setActionFailure(notification.id, failure);
    } catch (_) {
      _setActionFailure(notification.id, const NotificationFailure.network());
    }
  }

  Future<void> markAllAsRead() async {
    if (_state.unreadCount == 0 ||
        _state.isMarkingAll ||
        _state.markingReadIds.isNotEmpty) {
      return;
    }

    _setState(
      _state.copyWith(
        isMarkingAll: true,
        actionErrorMessage: null,
        actionSuccessMessage: null,
      ),
    );

    try {
      await _repository.markAllAsRead();
      final readAt = DateTime.now();
      final isUnreadFilter = _state.currentFilter == NotificationFilter.unread;
      _setState(
        _state.copyWith(
          items: isUnreadFilter
              ? const <NotificationItem>[]
              : _state.items
                    .map(
                      (item) => item.isRead
                          ? item
                          : item.copyWith(isRead: true, readAt: readAt),
                    )
                    .toList(growable: false),
          total: isUnreadFilter ? 0 : _state.total,
          totalPages: isUnreadFilter ? 0 : _state.totalPages,
          unreadCount: 0,
          isMarkingAll: false,
          actionSuccessMessage: 'Đã đánh dấu tất cả thông báo là đã đọc.',
        ),
      );
    } on NotificationFailure catch (failure) {
      _setState(
        _state.copyWith(
          isMarkingAll: false,
          actionErrorMessage: _messageForFailure(failure),
        ),
      );
    } catch (_) {
      _setState(
        _state.copyWith(
          isMarkingAll: false,
          actionErrorMessage: _messageForFailure(
            const NotificationFailure.network(),
          ),
        ),
      );
    }
  }

  void dismissActionMessage() {
    _setState(
      _state.copyWith(actionErrorMessage: null, actionSuccessMessage: null),
    );
  }

  List<NotificationItem> _appendUnique(
    List<NotificationItem> current,
    List<NotificationItem> incoming,
  ) {
    final seen = current.map((item) => item.id).toSet();
    return <NotificationItem>[
      ...current,
      ...incoming.where((item) => seen.add(item.id)),
    ];
  }

  List<NotificationItem> _replaceItem(
    List<NotificationItem> items,
    NotificationItem replacement,
  ) {
    return items
        .map((item) => item.id == replacement.id ? replacement : item)
        .toList(growable: false);
  }

  Set<String> _withoutPending(String id) => <String>{
    ..._state.markingReadIds.where((pending) => pending != id),
  };

  void _setActionFailure(String id, NotificationFailure failure) {
    _setState(
      _state.copyWith(
        markingReadIds: _withoutPending(id),
        actionErrorMessage: _messageForFailure(failure),
      ),
    );
  }

  void _setLoadFailure(NotificationFailure failure) {
    final hasContent = _state.items.isNotEmpty;
    _setState(
      _state.copyWith(
        status: hasContent
            ? NotificationLoadStatus.loaded
            : _isAuthenticationFailure(failure)
            ? NotificationLoadStatus.authenticationRequired
            : NotificationLoadStatus.error,
        isLoadingMore: false,
        errorMessage: hasContent ? null : _messageForFailure(failure),
        actionErrorMessage: hasContent ? _messageForFailure(failure) : null,
      ),
    );
  }

  bool _isAuthenticationFailure(NotificationFailure failure) {
    return failure.statusCode == 401 ||
        failure.code == NotificationErrorCode.authTokenInvalid ||
        failure.code == NotificationErrorCode.authTokenMissing;
  }

  String _messageForFailure(NotificationFailure failure) {
    return switch (failure.statusCode) {
      400 => 'Yêu cầu không hợp lệ.',
      401 => 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
      403 => 'Bạn không có quyền thực hiện thao tác này.',
      404 => 'Không tìm thấy thông báo.',
      _ => switch (failure.code) {
        NotificationErrorCode.authTokenInvalid ||
        NotificationErrorCode.authTokenMissing =>
          'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
        NotificationErrorCode.notificationNotFound =>
          'Không tìm thấy thông báo.',
        NotificationErrorCode.malformedResponse =>
          'Dữ liệu thông báo không hợp lệ. Vui lòng thử lại.',
        NotificationErrorCode.network => 'Không thể kết nối đến máy chủ.',
        _ => 'Đã xảy ra lỗi. Vui lòng thử lại.',
      },
    };
  }

  void _setState(NotificationState nextState) {
    if (_isDisposed) return;
    _state = nextState;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _requestGeneration++;
    super.dispose();
  }
}
