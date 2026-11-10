import 'package:flutter/material.dart';

import '../data/mock_notification_repository.dart';
import '../data/notification_repository.dart';
import '../models/notification_filter.dart';
import '../models/notification_item.dart';
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
  const NotificationsScreen({
    super.key,
    this.repository,
    this.controller,
    this.onOpenOrder,
    this.onOpenIncidents,
  }) : assert(repository != null || controller != null);

  factory NotificationsScreen.withMockData({Key? key}) {
    return NotificationsScreen(
      key: key,
      repository: MockNotificationRepository(),
    );
  }

  final NotificationRepository? repository;
  final NotificationController? controller;

  /// Mở chi tiết đơn khi thông báo gắn orderId.
  final ValueChanged<String>? onOpenOrder;

  /// Mở danh sách phiếu sự cố khi thông báo gắn incidentId.
  final VoidCallback? onOpenIncidents;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  late NotificationController _controller;
  late bool _ownsController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    _bindController();
  }

  @override
  void didUpdateWidget(covariant NotificationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.repository, widget.repository) ||
        !identical(oldWidget.controller, widget.controller)) {
      if (_ownsController) _controller.dispose();
      _bindController();
    }
  }

  void _bindController() {
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        NotificationController(repository: widget.repository!);
    final status = _controller.state.status;
    if (_ownsController || status == NotificationLoadStatus.initial) {
      _controller.loadInitial();
    } else if (status != NotificationLoadStatus.loading) {
      _controller.refresh();
    }
  }

  /// Đánh dấu đã đọc rồi mở sheet xem toàn bộ nội dung + nút tới đơn/phiếu.
  void _openDetail(NotificationItem notification) {
    if (!notification.isRead) _controller.markAsRead(notification);
    final orderId = notification.orderId;
    final onOpenOrder = widget.onOpenOrder;
    final onOpenIncidents = widget.onOpenIncidents;
    final VoidCallback? action;
    final String? actionLabel;
    if (orderId != null && onOpenOrder != null) {
      action = () => onOpenOrder(orderId);
      actionLabel = 'Xem đơn hàng';
    } else if (notification.incidentId != null && onOpenIncidents != null) {
      action = onOpenIncidents;
      actionLabel = 'Xem phiếu sự cố';
    } else {
      action = null;
      actionLabel = null;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                notification.title,
                style: const TextStyle(
                  fontFamily: NotificationTextStyles.serif,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: NotificationColors.charcoal900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _formatTime(notification.createdAt),
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 14),
              Text(
                notification.message,
                style: const TextStyle(fontSize: 15, height: 1.45),
              ),
              if (action != null) ...<Widget>[
                const SizedBox(height: 20),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: NotificationColors.forest700,
                  ),
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    action!();
                  },
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _formatTime(DateTime time) {
    final t = time.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)} - '
        '${two(t.day)}/${two(t.month)}/${t.year}';
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 240) {
      _controller.loadMore();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _controller.refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  onSelected: _controller.setFilter,
                ),
                const SizedBox(height: 10),
                if (state.actionErrorMessage != null)
                  _ActionMessageBanner(
                    message: state.actionErrorMessage!,
                    isError: true,
                    onDismiss: _controller.dismissActionMessage,
                  ),
                if (state.actionSuccessMessage != null)
                  _ActionMessageBanner(
                    message: state.actionSuccessMessage!,
                    isError: false,
                    onDismiss: _controller.dismissActionMessage,
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
            state.errorMessage ?? 'Không thể tải thông báo. Vui lòng thử lại.',
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
        itemCount: visibleItems.length + 1,
        itemBuilder: (context, index) {
          if (index == visibleItems.length) {
            if (state.isLoadingMore) {
              return const Padding(
                padding: EdgeInsets.all(18),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: NotificationColors.forest700,
                  ),
                ),
              );
            }
            if (state.hasMore) {
              return Center(
                child: TextButton(
                  onPressed: _controller.loadMore,
                  child: const Text('Tải thêm'),
                ),
              );
            }
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
              onTap: () => _openDetail(notification),
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

class _ActionMessageBanner extends StatelessWidget {
  const _ActionMessageBanner({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Material(
        color: isError
            ? NotificationColors.petal100
            : NotificationColors.forest100,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 2, 6),
          child: Row(
            children: <Widget>[
              Icon(
                isError ? Icons.info_outline : Icons.check_circle_outline,
                size: 17,
                color: isError
                    ? NotificationColors.petal500
                    : NotificationColors.forest700,
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
          SizedBox(height: 12),
          Text('Đang tải thông báo...', style: NotificationTextStyles.body),
        ],
      ),
    );
  }
}
