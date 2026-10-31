import '../models/chatbot_models.dart';

enum ChatbotStatus {
  ready,
  sending,
  loadingHistory,
  deleting,
  error,
  authenticationRequired,
}

class ChatbotState {
  const ChatbotState({
    this.conversationId,
    this.messages = const <ChatMessage>[],
    this.status = ChatbotStatus.ready,
    this.errorMessage,
  });

  final String? conversationId;
  final List<ChatMessage> messages;
  final ChatbotStatus status;
  final String? errorMessage;

  bool get isSending => status == ChatbotStatus.sending;

  bool get isBusy =>
      status == ChatbotStatus.sending ||
      status == ChatbotStatus.loadingHistory ||
      status == ChatbotStatus.deleting;

  ChatbotState copyWith({
    Object? conversationId = _unset,
    List<ChatMessage>? messages,
    ChatbotStatus? status,
    Object? errorMessage = _unset,
  }) {
    return ChatbotState(
      conversationId: identical(conversationId, _unset)
          ? this.conversationId
          : conversationId as String?,
      messages: messages ?? this.messages,
      status: status ?? this.status,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const _unset = Object();
