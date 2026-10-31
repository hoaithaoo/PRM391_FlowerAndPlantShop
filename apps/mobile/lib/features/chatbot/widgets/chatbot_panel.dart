import 'package:flutter/material.dart';

import '../models/chatbot_models.dart';
import '../state/chatbot_controller.dart';
import '../state/chatbot_state.dart';
import 'chat_message_bubble.dart';

class ChatbotPanel extends StatefulWidget {
  const ChatbotPanel({
    super.key,
    required this.controller,
    required this.onClose,
    this.onProductTap,
    this.onOpenIncidentReport,
  });

  final ChatbotController controller;
  final VoidCallback onClose;
  final ValueChanged<String>? onProductTap;
  final ValueChanged<IncidentReportDraft>? onOpenIncidentReport;

  @override
  State<ChatbotPanel> createState() => _ChatbotPanelState();
}

class _ChatbotPanelState extends State<ChatbotPanel> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_refreshInput);
  }

  @override
  void dispose() {
    _messageController
      ..removeListener(_refreshInput)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _refreshInput() => setState(() {});

  Future<void> _send([String? prompt]) async {
    final message = (prompt ?? _messageController.text).trim();
    if (message.isEmpty || widget.controller.state.isBusy) return;
    _messageController.clear();
    await widget.controller.send(message);
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final state = widget.controller.state;
        // Mỗi thay đổi state có thể tăng chiều cao danh sách tin nhắn.
        _scrollToEnd();
        return Material(
          color: const Color(0xFFFFF8FA),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                children: <Widget>[
                  _PanelHeader(
                    onNewConversation: widget.controller.startNewConversation,
                    onClose: widget.onClose,
                  ),
                  Expanded(child: _buildConversation(state)),
                  if (state.errorMessage case final error?)
                    _ErrorBanner(
                      message: error,
                      onDismiss: widget.controller.dismissError,
                    ),
                  _MessageComposer(
                    controller: _messageController,
                    enabled: !state.isBusy,
                    onSend: _send,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConversation(ChatbotState state) {
    if (state.status == ChatbotStatus.loadingHistory &&
        state.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.messages.isEmpty) {
      return _EmptyConversation(onPromptSelected: _send);
    }
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      itemCount: state.messages.length + (state.isSending ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == state.messages.length) return const _TypingIndicator();
        return ChatMessageBubble(
          message: state.messages[index],
          onProductTap: widget.onProductTap,
          onOpenIncidentReport: widget.onOpenIncidentReport,
        );
      },
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.onNewConversation, required this.onClose});

  final VoidCallback onNewConversation;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFFFFFDF9),
        border: Border(bottom: BorderSide(color: Color(0xFFFCEEF2))),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        child: Row(
          children: <Widget>[
            const CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFFE2F0E9),
              child: Icon(Icons.auto_awesome, color: Color(0xFF132B1E)),
            ),
            const SizedBox(width: 11),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Trợ lý Nhà Có Hoa',
                    style: TextStyle(
                      color: Color(0xFF171C19),
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Tư vấn sản phẩm và hỗ trợ sự cố',
                    style: TextStyle(color: Color(0xFF6B7770), fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onNewConversation,
              tooltip: 'Cuộc trò chuyện mới',
              icon: const Icon(Icons.add_comment_outlined),
            ),
            IconButton(
              key: const Key('chatbot-close-button'),
              onPressed: onClose,
              tooltip: 'Đóng trợ lý',
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyConversation extends StatelessWidget {
  const _EmptyConversation({required this.onPromptSelected});

  final ValueChanged<String> onPromptSelected;

  static const prompts = <String>[
    'Tư vấn hoa theo dịp',
    'Gợi ý theo ngân sách',
    'Tôi cần hỗ trợ thanh toán',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 18),
          const Icon(
            Icons.local_florist_outlined,
            size: 46,
            color: Color(0xFFA84366),
          ),
          const SizedBox(height: 14),
          const Text(
            'Mình có thể giúp gì cho bạn?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF171C19),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Hỏi về mẫu hoa, ngân sách hoặc sự cố đơn hàng.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6B7770), height: 1.45),
          ),
          const SizedBox(height: 22),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final prompt in prompts)
                ActionChip(
                  label: Text(prompt),
                  onPressed: () => onPromptSelected(prompt),
                  backgroundColor: const Color(0xFFF1F7F4),
                  side: const BorderSide(color: Color(0xFFE2F0E9)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final canSend = enabled && controller.text.trim().isNotEmpty;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFFFFFDF9),
        border: Border(top: BorderSide(color: Color(0xFFFCEEF2))),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: TextField(
                key: const Key('chatbot-message-input'),
                controller: controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 4,
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) {
                  if (canSend) onSend();
                },
                decoration: InputDecoration(
                  hintText: 'Nhập câu hỏi của bạn...',
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFFFFF5F7),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              key: const Key('chatbot-send-button'),
              onPressed: canSend ? onSend : null,
              tooltip: 'Gửi tin nhắn',
              style: IconButton.styleFrom(
                minimumSize: const Size.square(48),
                backgroundColor: const Color(0xFF132B1E),
                disabledBackgroundColor: const Color(0xFFE2F0E9),
              ),
              icon: enabled
                  ? const Icon(Icons.arrow_upward_rounded)
                  : const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0xFFF1F7F4),
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox.square(
                dimension: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('AI đang trả lời...'),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEFF1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.error_outline, color: Color(0xFFB5424A)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF7B2730), fontSize: 12),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            tooltip: 'Đóng thông báo lỗi',
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}
