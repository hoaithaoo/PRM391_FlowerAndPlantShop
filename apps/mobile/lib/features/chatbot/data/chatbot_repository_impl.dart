import '../models/chatbot_models.dart';
import 'chatbot_failure.dart';
import 'chatbot_remote_data_source.dart';
import 'chatbot_repository.dart';

class ChatbotRepositoryImpl implements ChatbotRepository {
  const ChatbotRepositoryImpl(this._remoteDataSource);

  final ChatbotRemoteDataSource _remoteDataSource;

  @override
  Future<ChatbotReply> sendMessage({
    String? conversationId,
    required String message,
    ChatbotRequestContext? context,
  }) async {
    final data = await _remoteDataSource.sendMessage(
      conversationId: conversationId,
      message: message,
      context: context,
    );
    try {
      return ChatbotReply.fromJson(data);
    } on FormatException {
      throw const ChatbotFailure(code: ChatbotErrorCode.malformedResponse);
    }
  }

  @override
  Future<ChatbotHistory> getHistory(
    String conversationId, {
    int page = 1,
  }) async {
    final data = await _remoteDataSource.getHistory(conversationId, page: page);
    try {
      return ChatbotHistory.fromJson(data);
    } on FormatException {
      throw const ChatbotFailure(code: ChatbotErrorCode.malformedResponse);
    }
  }

  @override
  Future<void> deleteConversation(String conversationId) {
    return _remoteDataSource.deleteConversation(conversationId);
  }
}
