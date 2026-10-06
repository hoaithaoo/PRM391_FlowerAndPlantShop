import 'package:flutter/foundation.dart';

import '../data/notification_failure.dart';
import '../data/notification_repository.dart';
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

  Future<void> loadInitial() {
    return _loadFirstPage(showFullLoader: true);
  }

  Future<void> refresh() {
    return _loadFirstPage(showFullLoader: false);
  }

  Future<void> setUnreadOnly(bool unreadOnly) async {
    if (_state.unreadOnly == unreadOnly) {
      return;
    }
    _setState(_state.copyWith(unreadOnly: unreadOnly));
    await _loadFirstPage(showFullLoader: true);
  }

  Future<void> _loadFirstPage({required bool showFullLoader}) async {
    final generation = ++_requestGeneration;
    final unreadOnly = _state.unreadOnly;

    _setState(
      _state.copyWith(
        status: showFullLoader ? NotificationLoadStatus.loading : _state.status,
        items: showFullLoader ? const <NotificationItem>[] : _state.items,
        currentPage: 1,
        hasMore: true,
        isLoadingMore: false,
        errorMessage: null,
        actionErrorMessage: null,
      ),
    );

    try {
      // Tải lại trang đầu theo bộ lọc hiện tại
      final result = await _repository.getNotifications(
        page: 1,
        unreadOnly: unreadOnly,
      );
      if (generation != _requestGeneration) {
        return;
      }

      _setState(
        _state.copyWith(
          status: NotificationLoadStatus.loaded,
          items: _deduplicate(result.items),
          unreadCount: result.unreadCount,
          currentPage: 1,
          hasMore: result.items.isNotEmpty,
          errorMessage: null,
          actionErrorMessage: null,
        ),
      );
    } on NotificationFailure catch (failure) {
      if (generation == _requestGeneration) {
        _setLoadFailure(failure);
      }
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
    final nextPage = _state.currentPage + 1;
    _setState(_state.copyWith(isLoadingMore: true, actionErrorMessage: null));

    try {
      final result = await _repository.getNotifications(
        page: nextPage,
        unreadOnly: _state.unreadOnly,
      );
      if (generation != _requestGeneration) {
        return;
      }

      final existingIds = _state.items.map((item) => item.id).toSet();
      final uniqueIncoming = result.items
          .where((item) => !existingIds.contains(item.id))
          .toList(growable: false);

      _setState(
        _state.copyWith(
          items: <NotificationItem>[..._state.items, ...uniqueIncoming],
          unreadCount: result.unreadCount,
          currentPage: nextPage,
          hasMore: uniqueIncoming.isNotEmpty,
          isLoadingMore: false,
        ),
      );
    } on NotificationFailure catch (failure) {
      if (generation == _requestGeneration) {
        final requiresAuthentication = _isAuthenticationFailure(failure);
        _setState(
          _state.copyWith(
            status: requiresAuthentication
                ? NotificationLoadStatus.authenticationRequired
                : _state.status,
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
            actionErrorMessage:
                'Unable to load more notifications. Please try again.',
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

    final pendingIds = <String>{..._state.markingReadIds, notification.id};
    _setState(
      _state.copyWith(markingReadIds: pendingIds, actionErrorMessage: null),
    );

    try {
      // Cập nhật cục bộ sau khi backend xác nhận thông báo đã được đọc
      final result = await _repository.markAsRead(notification.id);
      final updatedItems = _state.items
          .map((item) {
            if (item.id != notification.id) {
              return item;
            }
            return item.copyWith(isRead: result.isRead, readAt: result.readAt);
          })
          .toList(growable: false);
      final nextUnreadCount = result.isRead && _state.unreadCount > 0
          ? _state.unreadCount - 1
          : _state.unreadCount;

      _setState(
        _state.copyWith(
          items: updatedItems,
          unreadCount: nextUnreadCount,
          markingReadIds: <String>{
            ..._state.markingReadIds.where((id) => id != notification.id),
          },
        ),
      );
    } on NotificationFailure catch (failure) {
      _finishItemMutation(notification.id, failure);
    } catch (_) {
      _finishItemMutation(notification.id, const NotificationFailure.network());
    }
  }

  Future<void> markAllAsRead() async {
    if (_state.unreadCount == 0 ||
        _state.isMarkingAll ||
        _state.markingReadIds.isNotEmpty) {
      return;
    }

    _setState(_state.copyWith(isMarkingAll: true, actionErrorMessage: null));
    try {
      await _repository.markAllAsRead();
      final readAt = DateTime.now();
      final updatedItems = _state.items
          .map(
            (item) => item.isRead
                ? item
                : item.copyWith(isRead: true, readAt: readAt),
          )
          .toList(growable: false);

      // Đồng bộ toàn bộ danh sách đang hiển thị và đưa unreadCount về 0
      _setState(
        _state.copyWith(
          items: updatedItems,
          unreadCount: 0,
          isMarkingAll: false,
          markingReadIds: const <String>{},
        ),
      );
    } on NotificationFailure catch (failure) {
      _finishMarkAll(failure);
    } catch (_) {
      _finishMarkAll(const NotificationFailure.network());
    }
  }

  void dismissActionError() {
    final hasRecoverableContent =
        _state.items.isNotEmpty &&
        (_state.status == NotificationLoadStatus.error ||
            _state.status == NotificationLoadStatus.authenticationRequired);
    _setState(
      _state.copyWith(
        status: hasRecoverableContent
            ? NotificationLoadStatus.loaded
            : _state.status,
        errorMessage: hasRecoverableContent ? null : _state.errorMessage,
        actionErrorMessage: null,
      ),
    );
  }

  void _setLoadFailure(NotificationFailure failure) {
    final requiresAuthentication = _isAuthenticationFailure(failure);
    _setState(
      _state.copyWith(
        status: requiresAuthentication
            ? NotificationLoadStatus.authenticationRequired
            : NotificationLoadStatus.error,
        errorMessage: _messageForFailure(failure),
        isLoadingMore: false,
      ),
    );
  }

  void _finishItemMutation(String notificationId, NotificationFailure failure) {
    final requiresAuthentication = _isAuthenticationFailure(failure);
    _setState(
      _state.copyWith(
        status: requiresAuthentication
            ? NotificationLoadStatus.authenticationRequired
            : _state.status,
        markingReadIds: <String>{
          ..._state.markingReadIds.where((id) => id != notificationId),
        },
        actionErrorMessage: _messageForFailure(failure),
      ),
    );
  }

  void _finishMarkAll(NotificationFailure failure) {
    final requiresAuthentication = _isAuthenticationFailure(failure);
    _setState(
      _state.copyWith(
        status: requiresAuthentication
            ? NotificationLoadStatus.authenticationRequired
            : _state.status,
        isMarkingAll: false,
        actionErrorMessage: _messageForFailure(failure),
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
        'Your session has expired. Please sign in again.',
      NotificationErrorCode.notificationNotFound =>
        'This notification is no longer available.',
      _ => 'Unable to load notifications. Please try again.',
    };
  }

  List<NotificationItem> _deduplicate(List<NotificationItem> items) {
    final seenIds = <String>{};
    return items.where((item) => seenIds.add(item.id)).toList(growable: false);
  }

  void _setState(NotificationState nextState) {
    if (_isDisposed) {
      return;
    }
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
