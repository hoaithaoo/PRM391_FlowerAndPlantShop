import 'package:flutter/foundation.dart';

import '../data/chatbot_failure.dart';
import '../data/chatbot_repository.dart';
import '../models/chatbot_models.dart';
import 'chatbot_state.dart';

typedef ChatbotContextProvider = ChatbotRequestContext? Function();

class ChatbotController extends ChangeNotifier {
  ChatbotController({
    required ChatbotRepository repository,
    ChatbotContextProvider? contextProvider,
  }) : _repository = repository,
       _contextProvider = contextProvider;

  final ChatbotRepository _repository;
  final ChatbotContextProvider? _contextProvider;
  ChatbotState _state = const ChatbotState();
  var _isDisposed = false;

  ChatbotState get state => _state;

  Future<void> send(String rawMessage) async {
    final message = rawMessage.trim();
    if (message.isEmpty || _state.isBusy) return;

    final userMessage = ChatMessage.pendingUser(message);
    _setState(
      _state.copyWith(
        messages: <ChatMessage>[..._state.messages, userMessage],
        status: ChatbotStatus.sending,
        errorMessage: null,
      ),
    );

    try {
      final reply = await _repository.sendMessage(
        conversationId: _state.conversationId,
        message: message,
        context: _contextProvider?.call(),
      );
      _setState(
        _state.copyWith(
          conversationId: reply.conversationId,
          messages: <ChatMessage>[..._state.messages, reply.toMessage()],
          status: ChatbotStatus.ready,
          errorMessage: null,
        ),
      );
    } on ChatbotFailure catch (failure) {
      _setFailure(failure);
    } catch (_) {
      _setFailure(const ChatbotFailure.network());
    }
  }

  Future<void> resume(String conversationId) async {
    if (_state.isBusy || conversationId.trim().isEmpty) return;
    _setState(
      _state.copyWith(
        status: ChatbotStatus.loadingHistory,
        errorMessage: null,
      ),
    );
    try {
      final history = await _repository.getHistory(conversationId);
      _setState(
        ChatbotState(
          conversationId: history.conversationId,
          messages: history.messages,
        ),
      );
    } on ChatbotFailure catch (failure) {
      _setFailure(failure);
    } catch (_) {
      _setFailure(const ChatbotFailure.network());
    }
  }

  void startNewConversation() {
    if (_state.isBusy) return;
    _setState(const ChatbotState());
  }

  Future<void> deleteCurrentConversation() async {
    if (_state.isBusy) return;
    final conversationId = _state.conversationId;
    if (conversationId == null) {
      startNewConversation();
      return;
    }
    _setState(
      _state.copyWith(
        status: ChatbotStatus.deleting,
        errorMessage: null,
      ),
    );
    try {
      await _repository.deleteConversation(conversationId);
      _setState(const ChatbotState());
    } on ChatbotFailure catch (failure) {
      _setFailure(failure);
    } catch (_) {
      _setFailure(const ChatbotFailure.network());
    }
  }

  void dismissError() {
    if (_state.status != ChatbotStatus.error &&
        _state.status != ChatbotStatus.authenticationRequired) {
      return;
    }
    _setState(
      _state.copyWith(status: ChatbotStatus.ready, errorMessage: null),
    );
  }

  void _setFailure(ChatbotFailure failure) {
    final requiresAuthentication =
        failure.code == ChatbotErrorCode.authTokenMissing ||
        failure.code == ChatbotErrorCode.authTokenInvalid;
    _setState(
      _state.copyWith(
        status: requiresAuthentication
            ? ChatbotStatus.authenticationRequired
            : ChatbotStatus.error,
        errorMessage: _messageForFailure(failure),
      ),
    );
  }

  String _messageForFailure(ChatbotFailure failure) {
    return switch (failure.code) {
      ChatbotErrorCode.authTokenMissing || ChatbotErrorCode.authTokenInvalid =>
        'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
      ChatbotErrorCode.rateLimited =>
        'Bạn đang gửi tin nhắn quá nhanh. Vui lòng chờ một chút.',
      ChatbotErrorCode.providerTimeout =>
        'Trợ lý chưa kịp phản hồi. Vui lòng thử lại.',
      ChatbotErrorCode.providerError =>
        'Trợ lý đang tạm gián đoạn. Vui lòng thử lại sau.',
      ChatbotErrorCode.productNotFound =>
        'Sản phẩm bạn đang xem không còn khả dụng.',
      ChatbotErrorCode.validationError =>
        'Tin nhắn chưa hợp lệ. Vui lòng kiểm tra lại.',
      ChatbotErrorCode.conversationNotFound =>
        'Không tìm thấy phiên tư vấn này.',
      _ => 'Không thể kết nối với trợ lý. Vui lòng thử lại.',
    };
  }

  void _setState(ChatbotState nextState) {
    if (_isDisposed) return;
    _state = nextState;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
