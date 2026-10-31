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
    this.contextProvider,
    this.onProductTap,
    this.onOpenIncidentReport,
  });

  final ChatbotRepository repository;
  final Widget child;
  final bool visible;
  final ChatbotContextProvider? contextProvider;
  final ValueChanged<String>? onProductTap;
  final ValueChanged<IncidentReportDraft>? onOpenIncidentReport;

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
    if (!identical(oldWidget.repository, widget.repository) ||
        !identical(oldWidget.contextProvider, widget.contextProvider)) {
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
            bottom: MediaQuery.paddingOf(context).bottom + 16,
            child: ChatbotLauncher(onPressed: _openPanel),
          ),
      ],
    );
  }
}
