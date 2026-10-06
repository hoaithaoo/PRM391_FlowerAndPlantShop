import 'package:flutter/material.dart';

import '../data/mock_notification_repository.dart';
import '../data/notification_repository.dart';
import '../state/notification_controller.dart';
import '../state/notification_state.dart';
import '../widgets/notification_card.dart';
import '../widgets/notifications_empty_state.dart';
import '../widgets/notifications_error_state.dart';
import '../widgets/unread_filter.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.repository});

  factory NotificationsScreen.withMockData({Key? key}) {
    return NotificationsScreen(
      key: key,
      repository: MockNotificationRepository(),
    );
  }

  final NotificationRepository repository;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();
  late NotificationController _notificationController;

  @override
  void initState() {
    super.initState();
    _notificationController = NotificationController(
      repository: widget.repository,
    );
    _scrollController.addListener(_handleScroll);
    _notificationController.loadInitial();
  }

  @override
  void didUpdateWidget(covariant NotificationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.repository, widget.repository)) {
      _notificationController.dispose();
      _notificationController = NotificationController(
        repository: widget.repository,
      );
      _notificationController.loadInitial();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _notificationController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      _notificationController.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Đăng ký NotificationsScreen vào router sau khi app shell hoàn tất
    return AnimatedBuilder(
      animation: _notificationController,
      builder: (context, _) {
        final state = _notificationController.state;
        final actionError = _visibleActionError(state);
        return Scaffold(
          // TODO: Hiển thị badge unreadCount trên app shell sau khi navigation được merge
          appBar: AppBar(
            title: const Text('Notifications'),
            actions: <Widget>[
              _MarkAllAction(
                enabled:
                    state.unreadCount > 0 &&
                    state.markingReadIds.isEmpty &&
                    !state.isMarkingAll,
                isLoading: state.isMarkingAll,
                onPressed: _notificationController.markAllAsRead,
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: UnreadFilter(
                    unreadOnly: state.unreadOnly,
                    unreadCount: state.unreadCount,
                    enabled: state.status != NotificationLoadStatus.loading,
                    onChanged: _notificationController.setUnreadOnly,
                  ),
                ),
                if (actionError != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _ActionErrorBanner(
                      message: actionError,
                      onDismiss: _notificationController.dismissActionError,
                    ),
                  ),
                const Divider(height: 1),
                Expanded(child: _buildBody(state)),
              ],
            ),
          ),
        );
      },
    );
  }

  String? _visibleActionError(NotificationState state) {
    if (state.actionErrorMessage != null) {
      return state.actionErrorMessage;
    }
    if (state.items.isNotEmpty &&
        (state.status == NotificationLoadStatus.error ||
            state.status == NotificationLoadStatus.authenticationRequired)) {
      return state.errorMessage;
    }
    return null;
  }

  Widget _buildBody(NotificationState state) {
    if ((state.status == NotificationLoadStatus.initial ||
            state.status == NotificationLoadStatus.loading) &&
        state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if ((state.status == NotificationLoadStatus.error ||
            state.status == NotificationLoadStatus.authenticationRequired) &&
        state.items.isEmpty) {
      return NotificationsErrorState(
        message:
            state.errorMessage ??
            'Unable to load notifications. Please try again.',
        authenticationRequired:
            state.status == NotificationLoadStatus.authenticationRequired,
        onRetry: _notificationController.loadInitial,
      );
    }

    if (state.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _notificationController.refresh,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: <Widget>[
                SizedBox(
                  height: constraints.maxHeight,
                  child: NotificationsEmptyState(
                    unreadOnly: state.unreadOnly,
                    onShowAll: state.unreadOnly
                        ? () => _notificationController.setUnreadOnly(false)
                        : null,
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    final showPaginationFooter = state.hasMore || state.isLoadingMore;
    return RefreshIndicator(
      onRefresh: _notificationController.refresh,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: state.items.length + (showPaginationFooter ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == state.items.length) {
            return _PaginationFooter(
              isLoading: state.isLoadingMore,
              onLoadMore: _notificationController.loadMore,
            );
          }

          final notification = state.items[index];
          return NotificationCard(
            notification: notification,
            isUpdating:
                state.isMarkingAll ||
                state.markingReadIds.contains(notification.id),
            onTap: () => _notificationController.markAsRead(notification),
          );
        },
      ),
    );
  }
}

class _MarkAllAction extends StatelessWidget {
  const _MarkAllAction({
    required this.enabled,
    required this.isLoading,
    required this.onPressed,
  });

  final bool enabled;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return IconButton(
      onPressed: enabled ? onPressed : null,
      tooltip: 'Mark all as read',
      icon: const Icon(Icons.done_all),
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({required this.isLoading, required this.onLoadMore});

  final bool isLoading;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: isLoading
            ? const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : OutlinedButton(
                onPressed: onLoadMore,
                child: const Text('Load more'),
              ),
      ),
    );
  }
}

class _ActionErrorBanner extends StatelessWidget {
  const _ActionErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(
          children: <Widget>[
            Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colorScheme.onErrorContainer),
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              tooltip: 'Dismiss',
              icon: const Icon(Icons.close),
              color: colorScheme.onErrorContainer,
            ),
          ],
        ),
      ),
    );
  }
}
