import '../models/chatbot_models.dart';
import 'chatbot_failure.dart';

typedef ChatbotAccessTokenProvider = Future<String?> Function();

abstract interface class ChatbotApiTransport {
  Future<ChatbotApiResponse> get({
    required String path,
    required Map<String, String> headers,
    Map<String, dynamic>? queryParameters,
  });

  Future<ChatbotApiResponse> post({
    required String path,
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  });

  Future<ChatbotApiResponse> delete({
    required String path,
    required Map<String, String> headers,
  });
}

class ChatbotApiResponse {
  const ChatbotApiResponse({required this.statusCode, required this.body});

  final int statusCode;
  final Map<String, dynamic> body;
}

class ChatbotRemoteDataSource {
  const ChatbotRemoteDataSource({
    required ChatbotApiTransport transport,
    required ChatbotAccessTokenProvider accessTokenProvider,
  }) : _transport = transport,
       _accessTokenProvider = accessTokenProvider;

  static const messagesEndpoint = '/api/v1/chatbot/messages';
  static const conversationsEndpoint = '/api/v1/chatbot/conversations';

  final ChatbotApiTransport _transport;
  final ChatbotAccessTokenProvider _accessTokenProvider;

  Future<Map<String, dynamic>> sendMessage({
    String? conversationId,
    required String message,
    ChatbotRequestContext? context,
  }) async {
    final headers = await _authenticatedHeaders();
    final body = <String, dynamic>{
      'conversationId': conversationId,
      'message': message,
      ...?context?.toRequestFields(),
    };
    return _request(
      () => _transport.post(
        path: messagesEndpoint,
        headers: headers,
        body: body,
      ),
    );
  }

  Future<Map<String, dynamic>> getHistory(
    String conversationId, {
    int page = 1,
  }) async {
    final headers = await _authenticatedHeaders();
    final encodedId = Uri.encodeComponent(conversationId);
    return _request(
      () => _transport.get(
        path: '$conversationsEndpoint/$encodedId/messages',
        headers: headers,
        queryParameters: <String, dynamic>{'page': page},
      ),
    );
  }

  Future<void> deleteConversation(String conversationId) async {
    final headers = await _authenticatedHeaders();
    final encodedId = Uri.encodeComponent(conversationId);
    await _request(
      () => _transport.delete(
        path: '$conversationsEndpoint/$encodedId',
        headers: headers,
      ),
      allowEmpty: true,
    );
  }

  Future<Map<String, String>> _authenticatedHeaders() async {
    final token = await _accessTokenProvider();
    if (token == null || token.trim().isEmpty) {
      throw const ChatbotFailure(
        code: ChatbotErrorCode.authTokenInvalid,
        statusCode: 401,
      );
    }
    return <String, String>{
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<Map<String, dynamic>> _request(
    Future<ChatbotApiResponse> Function() send, {
    bool allowEmpty = false,
  }) async {
    try {
      final response = await send();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error = response.body['error'];
        final errorJson = error is Map
            ? Map<String, dynamic>.from(error)
            : const <String, dynamic>{};
        throw ChatbotFailure(
          code: chatbotErrorCodeFromApi(errorJson['code']),
          statusCode: response.statusCode,
          message: errorJson['message'] is String
              ? errorJson['message'] as String
              : null,
        );
      }
      if (allowEmpty && response.statusCode == 204) {
        return const <String, dynamic>{};
      }
      final data = response.body['data'];
      if (data is Map) return Map<String, dynamic>.from(data);
      throw const ChatbotFailure(code: ChatbotErrorCode.malformedResponse);
    } on ChatbotFailure {
      rethrow;
    } catch (_) {
      throw const ChatbotFailure.network();
    }
  }
}
