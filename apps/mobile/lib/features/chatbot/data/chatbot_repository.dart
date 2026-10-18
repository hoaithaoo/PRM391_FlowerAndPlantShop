import '../models/chatbot_models.dart';

abstract interface class ChatbotRepository {
  Future<ChatbotReply> sendMessage({
    String? conversationId,
    required String message,
    ChatbotRequestContext? context,
  });

  Future<ChatbotHistory> getHistory(String conversationId, {int page = 1});

  Future<void> deleteConversation(String conversationId);
}
