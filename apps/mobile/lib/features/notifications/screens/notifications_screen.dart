import 'package:flutter/material.dart';

import '../data/mock_notification_repository.dart';
import '../data/notification_repository.dart';
import '../models/notification_filter.dart';
import '../state/notification_controller.dart';
import '../state/notification_state.dart';
import '../utils/notification_theme.dart';
import '../widgets/notification_card.dart';
import '../widgets/notification_end_section.dart';
import '../widgets/notification_filter_chip.dart';
import '../widgets/notification_header.dart';
import '../widgets/notifications_empty_state.dart';
import '../widgets/notifications_error_state.dart';

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
  late NotificationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = NotificationController(repository: widget.repository);
    _controller.loadInitial();
  }

  @override
  void didUpdateWidget(covariant NotificationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.repository, widget.repository)) {
      _controller.dispose();
      _controller = NotificationController(repository: widget.repository);
      _controller.loadInitial();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Đăng ký NotificationsScreen vào router sau khi app shell hoàn tất.
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;
        return Scaffold(
          backgroundColor: NotificationColors.cream100,
          body: SafeArea(
            child: Column(
              children: <Widget>[
                const NotificationHeader(),
                _InboxToolbar(
                  unreadCount: state.unreadCount,
                  isMarkingAll: state.isMarkingAll,
                  onMarkAll: state.unreadCount == 0
                      ? null
                      : _controller.markAllAsRead,
                ),
                NotificationFilters(
                  selected: state.currentFilter,
                  countFor: state.countFor,
                  onSelected: _controller.setFilter,
                ),
                const SizedBox(height: 10),
                if (state.actionErrorMessage != null)
                  _ActionErrorBanner(
                    message: state.actionErrorMessage!,
                    onDismiss: _controller.dismissActionError,
                  ),
                Expanded(child: _buildBody(state)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(NotificationState state) {
    if ((state.status == NotificationLoadStatus.initial ||
            state.status == NotificationLoadStatus.loading) &&
        state.items.isEmpty) {
      return const _ElegantLoadingState();
    }

    if ((state.status == NotificationLoadStatus.error ||
            state.status == NotificationLoadStatus.authenticationRequired) &&
        state.items.isEmpty) {
      return NotificationsErrorState(
        message:
            state.errorMessage ?? 'Chưa thể tải thông báo. Vui lòng thử lại.',
        authenticationRequired:
            state.status == NotificationLoadStatus.authenticationRequired,
        onRetry: _controller.loadInitial,
      );
    }

    final visibleItems = state.visibleItems;
    if (visibleItems.isEmpty) {
      return RefreshIndicator(
        onRefresh: _controller.refresh,
        color: NotificationColors.forest700,
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          children: <Widget>[
            NotificationsEmptyState(
              filterLabel: state.currentFilter == NotificationFilter.all
                  ? ''
                  : state.currentFilter.label.toLowerCase(),
              onShowAll: state.currentFilter == NotificationFilter.all
                  ? null
                  : () => _controller.setFilter(NotificationFilter.all),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _controller.refresh,
      color: NotificationColors.forest700,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        itemCount:
            visibleItems.length +
            (state.currentFilter == NotificationFilter.all ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == visibleItems.length) {
            return const NotificationEndSection();
          }
          final notification = visibleItems[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: NotificationCard(
              notification: notification,
              isUpdating:
                  state.isMarkingAll ||
                  state.markingReadIds.contains(notification.id),
              onTap: notification.isRead
                  ? null
                  : () => _controller.markAsRead(notification),
            ),
          );
        },
      ),
    );
  }
}

class _InboxToolbar extends StatelessWidget {
  const _InboxToolbar({
    required this.unreadCount,
    required this.isMarkingAll,
    required this.onMarkAll,
  });

  final int unreadCount;
  final bool isMarkingAll;
  final VoidCallback? onMarkAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 13, 10, 11),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Row(
              children: <Widget>[
                const Flexible(
                  child: Text(
                    'Tin nhắn hộp thư',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: NotificationTextStyles.serif,
                      fontSize: 18,
                      height: 1,
                      fontWeight: FontWeight.w600,
                      color: NotificationColors.charcoal900,
                    ),
                  ),
                ),
                if (unreadCount > 0) ...<Widget>[
                  const SizedBox(width: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: NotificationColors.petal100,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$unreadCount mới',
                      style: NotificationTextStyles.caption.copyWith(
                        fontSize: 9.5,
                        color: NotificationColors.petal500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isMarkingAll)
            const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                strokeWidth: 1.8,
                color: NotificationColors.forest700,
              ),
            )
          else
            TextButton.icon(
              onPressed: onMarkAll,
              style: TextButton.styleFrom(
                foregroundColor: NotificationColors.charcoal700,
                minimumSize: const Size(0, 30),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.done_all, size: 14),
              label: const Text(
                'Đọc tất cả',
                style: TextStyle(
                  fontFamily: NotificationTextStyles.sans,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Material(
        color: NotificationColors.petal100,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 2, 6),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.info_outline,
                size: 17,
                color: NotificationColors.petal500,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(message, style: NotificationTextStyles.caption),
              ),
              IconButton(
                onPressed: onDismiss,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ElegantLoadingState extends StatelessWidget {
  const _ElegantLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.local_florist_outlined,
            color: NotificationColors.forest700,
            size: 30,
          ),
          SizedBox(height: 12),
          SizedBox(
            width: 80,
            child: LinearProgressIndicator(
              minHeight: 2,
              color: NotificationColors.forest700,
              backgroundColor: NotificationColors.forest100,
            ),
          ),
        ],
      ),
    );
  }
}
