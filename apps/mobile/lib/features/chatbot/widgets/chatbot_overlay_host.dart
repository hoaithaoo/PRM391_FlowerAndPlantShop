import 'package:flutter/material.dart';

import '../data/chatbot_repository.dart';
import '../models/chatbot_models.dart';
import '../state/chatbot_controller.dart';
import 'chatbot_launcher.dart';
import 'chatbot_panel.dart';

class ChatbotOverlayHost extends StatefulWidget {
  const ChatbotOverlayHost({
    super.key,
    required this.repository,
    required this.child,
    this.visible = true,
    this.launcherBottomInset = 16,
    this.contextProvider,
    this.onProductTap,
    this.onOpenIncidentReport,
    this.onCartAction,
    this.onFavoriteAction,
    this.favoriteIdsProvider,
  });

  final ChatbotRepository repository;
  final Widget child;
  final bool visible;
  final double launcherBottomInset;
  final ChatbotContextProvider? contextProvider;
  final ValueChanged<String>? onProductTap;
  final ValueChanged<IncidentReportDraft>? onOpenIncidentReport;
  final ChatbotCartHandler? onCartAction;

  /// Thao tác yêu thích từ chatbot; null thì chatbot báo chưa hỗ trợ.
  final ChatbotFavoriteHandler? onFavoriteAction;

  /// Id sản phẩm đang yêu thích, gửi kèm để chatbot biết danh sách hiện tại.
  final ChatbotFavoriteIdsProvider? favoriteIdsProvider;

  @override
  State<ChatbotOverlayHost> createState() => _ChatbotOverlayHostState();
}

class _ChatbotOverlayHostState extends State<ChatbotOverlayHost> {
  late ChatbotController _controller;
  bool _isPanelOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = _createController();
  }

  @override
  void didUpdateWidget(covariant ChatbotOverlayHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Ẩn host (đăng xuất) cũng bỏ hội thoại cũ để không lộ sang tài khoản khác.
    if (!identical(oldWidget.repository, widget.repository) ||
        !identical(oldWidget.contextProvider, widget.contextProvider) ||
        (oldWidget.visible && !widget.visible)) {
      _controller.dispose();
      _controller = _createController();
    }
    if (!widget.visible) {
      _isPanelOpen = false;
    }
  }

  ChatbotController _createController() => ChatbotController(
    repository: widget.repository,
    contextProvider: widget.contextProvider,
    onCartAction: widget.onCartAction,
    onFavoriteAction: widget.onFavoriteAction,
    favoriteIdsProvider: widget.favoriteIdsProvider,
  );

  void _openPanel() => setState(() => _isPanelOpen = true);

  void _closePanel() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isPanelOpen = false);
  }

  void _openProduct(String productId) {
    _closePanel();
    widget.onProductTap?.call(productId);
  }

  void _openIncidentReport(IncidentReportDraft draft) {
    _closePanel();
    widget.onOpenIncidentReport?.call(draft);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Host nằm ngoài Navigator để giữ controller khi màn hình bên dưới đổi route.
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        widget.child,
        if (widget.visible && _isPanelOpen) ...<Widget>[
          const Positioned.fill(
            child: ModalBarrier(color: Color(0x660D1E15), dismissible: false),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              widthFactor: 1,
              heightFactor: 0.84,
              child: Overlay(
                key: ValueKey<ChatbotController>(_controller),
                initialEntries: <OverlayEntry>[
                  OverlayEntry(
                    builder: (context) => ChatbotPanel(
                      controller: _controller,
                      onClose: _closePanel,
                      onProductTap: _openProduct,
                      onOpenIncidentReport: _openIncidentReport,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (widget.visible && !_isPanelOpen)
          Positioned(
            right: 16,
            bottom:
                MediaQuery.paddingOf(context).bottom +
                widget.launcherBottomInset,
            child: ChatbotLauncher(onPressed: _openPanel),
          ),
      ],
    );
  }
}
