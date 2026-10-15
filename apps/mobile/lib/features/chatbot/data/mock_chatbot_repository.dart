import '../models/chatbot_models.dart';
import 'chatbot_repository.dart';

class MockChatbotRepository implements ChatbotRepository {
  MockChatbotRepository({this.responseDelay = const Duration(milliseconds: 350)});

  final Duration responseDelay;
  final Map<String, List<ChatMessage>> _conversations =
      <String, List<ChatMessage>>{};
  var _conversationCounter = 0;
  var _messageCounter = 0;

  @override
  Future<ChatbotReply> sendMessage({
    String? conversationId,
    required String message,
    ChatbotRequestContext? context,
  }) async {
    await Future<void>.delayed(responseDelay);
    final id = conversationId ?? 'mock-conversation-${++_conversationCounter}';
    final now = DateTime.now();
    final product = SuggestedProduct(
      id: context?.productId ?? 'mock-product-1',
      name: 'Bó hoa Bình Minh',
      price: '350000',
    );
    final reply = ChatbotReply(
      conversationId: id,
      messageId: 'mock-message-${++_messageCounter}',
      reply: 'Mình gợi ý mẫu hoa này dựa trên nhu cầu của bạn.',
      products: <SuggestedProduct>[product],
      createdAt: now,
    );
    _conversations.putIfAbsent(id, () => <ChatMessage>[])
      ..add(ChatMessage.pendingUser(message, createdAt: now))
      ..add(reply.toMessage());
    return reply;
  }

  @override
  Future<ChatbotHistory> getHistory(
    String conversationId, {
    int page = 1,
  }) async {
    await Future<void>.delayed(responseDelay);
    return ChatbotHistory(
      conversationId: conversationId,
      title: 'Tư vấn hoa',
      messages: List<ChatMessage>.unmodifiable(
        _conversations[conversationId] ?? const <ChatMessage>[],
      ),
      page: page,
      totalPages: 1,
    );
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    await Future<void>.delayed(responseDelay);
    _conversations.remove(conversationId);
  }
}
