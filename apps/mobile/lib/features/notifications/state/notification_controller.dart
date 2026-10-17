import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/notification_failure.dart';
import '../data/notification_repository.dart';
import '../models/notification_filter.dart';
import '../models/notification_item.dart';
import 'notification_state.dart';

class NotificationController extends ChangeNotifier {
  NotificationController({required NotificationRepository repository})
    : _repository = repository {
    _subscribeRealtime();
  }

  final NotificationRepository _repository;
  NotificationState _state = const NotificationState();
  StreamSubscription<NotificationItem>? _realtimeSubscription;
  int _requestGeneration = 0;
  bool _isDisposed = false;

  NotificationState get state => _state;

  Future<void> loadInitial() => _load(showFullLoader: true);

  Future<void> refresh() => _load(showFullLoader: false);

  void setFilter(NotificationFilter filter) {
    if (_state.currentFilter == filter) return;
    _setState(_state.copyWith(currentFilter: filter));
  }

  Future<void> _load({required bool showFullLoader}) async {
    final generation = ++_requestGeneration;
    _setState(
      _state.copyWith(
        status: showFullLoader ? NotificationLoadStatus.loading : _state.status,
        errorMessage: null,
        actionErrorMessage: null,
      ),
    );

    try {
      final result = await _repository.getNotifications();
      if (generation != _requestGeneration) return;
      _setState(
        _state.copyWith(
          status: NotificationLoadStatus.loaded,
          items: _mergeAndSort(result.items, _state.items),
          errorMessage: null,
          actionErrorMessage: null,
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

  Future<void> markAsRead(NotificationItem notification) async {
    if (notification.isRead ||
        _state.isMarkingAll ||
        _state.markingReadIds.contains(notification.id)) {
      return;
    }

    final before = notification;
    final readAt = DateTime.now();
    _setState(
      _state.copyWith(
        items: _replaceItem(
          _state.items,
          notification.copyWith(isRead: true, readAt: readAt),
        ),
        markingReadIds: <String>{..._state.markingReadIds, notification.id},
        actionErrorMessage: null,
      ),
    );

    try {
      final result = await _repository.markAsRead(notification.id);
      final current = _state.items.firstWhere(
        (item) => item.id == notification.id,
        orElse: () => notification,
      );
      _setState(
        _state.copyWith(
          items: _replaceItem(
            _state.items,
            current.copyWith(isRead: result.isRead, readAt: result.readAt),
          ),
          markingReadIds: _withoutPending(notification.id),
        ),
      );
    } on NotificationFailure catch (failure) {
      _rollbackRead(before, failure);
    } catch (_) {
      _rollbackRead(before, const NotificationFailure.network());
    }
  }

  Future<void> markAllAsRead() async {
    if (_state.unreadCount == 0 ||
        _state.isMarkingAll ||
        _state.markingReadIds.isNotEmpty) {
      return;
    }

    final before = _state.items;
    final readAt = DateTime.now();
    _setState(
      _state.copyWith(
        isMarkingAll: true,
        actionErrorMessage: null,
        items: _state.items
            .map(
              (item) => item.isRead
                  ? item
                  : item.copyWith(isRead: true, readAt: readAt),
            )
            .toList(growable: false),
      ),
    );

    try {
      await _repository.markAllAsRead();
      _setState(_state.copyWith(isMarkingAll: false));
    } on NotificationFailure catch (failure) {
      _setState(
        _state.copyWith(
          items: _restoreReadStates(_state.items, before),
          isMarkingAll: false,
          actionErrorMessage: _messageForFailure(failure),
        ),
      );
    } catch (_) {
      _setState(
        _state.copyWith(
          items: _restoreReadStates(_state.items, before),
          isMarkingAll: false,
          actionErrorMessage: _messageForFailure(
            const NotificationFailure.network(),
          ),
        ),
      );
    }
  }

  void dismissActionError() {
    _setState(_state.copyWith(actionErrorMessage: null));
  }

  void _subscribeRealtime() {
    // Đồng bộ sự kiện realtime vào state mà không thay đổi bộ lọc hiện tại.
    _realtimeSubscription = _repository.watchNotifications().listen(
      (incoming) {
        _setState(
          _state.copyWith(
            items: _mergeAndSort(_state.items, <NotificationItem>[incoming]),
          ),
        );
      },
      onError: (_) {
        _setState(
          _state.copyWith(
            actionErrorMessage:
                'Kết nối thông báo tạm gián đoạn. Danh sách hiện tại vẫn được giữ.',
          ),
        );
      },
    );
  }

  List<NotificationItem> _mergeAndSort(
    List<NotificationItem> current,
    List<NotificationItem> incoming,
  ) {
    final byId = <String, NotificationItem>{
      for (final item in current) item.id: item,
      for (final item in incoming) item.id: item,
    };
    final result = byId.values.toList(growable: false);
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  List<NotificationItem> _replaceItem(
    List<NotificationItem> items,
    NotificationItem replacement,
  ) {
    return items
        .map((item) => item.id == replacement.id ? replacement : item)
        .toList(growable: false);
  }

  List<NotificationItem> _restoreReadStates(
    List<NotificationItem> current,
    List<NotificationItem> snapshot,
  ) {
    final previousById = <String, NotificationItem>{
      for (final item in snapshot) item.id: item,
    };
    return current
        .map((item) {
          final previous = previousById[item.id];
          return previous == null
              ? item
              : item.copyWith(isRead: previous.isRead, readAt: previous.readAt);
        })
        .toList(growable: false);
  }

  Set<String> _withoutPending(String id) => <String>{
    ..._state.markingReadIds.where((pending) => pending != id),
  };

  void _rollbackRead(NotificationItem before, NotificationFailure failure) {
    _setState(
      _state.copyWith(
        items: _replaceItem(_state.items, before),
        markingReadIds: _withoutPending(before.id),
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
        errorMessage: hasContent ? null : _messageForFailure(failure),
        actionErrorMessage: hasContent ? _messageForFailure(failure) : null,
      ),
    );
  }

  bool _isAuthenticationFailure(NotificationFailure failure) {
    return failure.code == NotificationErrorCode.authTokenInvalid ||
        failure.code == NotificationErrorCode.authTokenMissing;
  }

  String _messageForFailure(NotificationFailure failure) {
    return switch (failure.code) {
      NotificationErrorCode.authTokenInvalid ||
      NotificationErrorCode.authTokenMissing =>
        'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
      NotificationErrorCode.notificationNotFound =>
        'Thông báo này không còn tồn tại.',
      _ => 'Chưa thể đồng bộ thông báo. Vui lòng thử lại.',
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
    // Hủy subscription khi controller bị dispose để tránh memory leak.
    unawaited(_realtimeSubscription?.cancel());
    super.dispose();
  }
}
