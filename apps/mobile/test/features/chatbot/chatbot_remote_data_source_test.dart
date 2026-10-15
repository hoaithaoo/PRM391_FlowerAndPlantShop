import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/chatbot/data/chatbot_failure.dart';
import 'package:plant_flower_mobile/features/chatbot/data/chatbot_remote_data_source.dart';
import 'package:plant_flower_mobile/features/chatbot/models/chatbot_models.dart';

void main() {
  test('sendMessage sends bearer auth and screen context to the API', () async {
    final transport = RecordingChatbotTransport(
      nextResponse: ChatbotApiResponse(
        statusCode: 200,
        body: _successEnvelope,
      ),
    );
    final source = ChatbotRemoteDataSource(
      transport: transport,
      accessTokenProvider: () async => 'access-token',
    );

    final data = await source.sendMessage(
      conversationId: 'conversation-1',
      message: 'Tư vấn hoa sinh nhật',
      context: const ChatbotRequestContext(
        productId: 'product-1',
        orderId: 'order-1',
        source: 'product-detail',
      ),
    );

    expect(data['conversationId'], 'conversation-1');
    expect(transport.lastMethod, 'POST');
    expect(transport.lastPath, '/api/v1/chatbot/messages');
    expect(transport.lastHeaders?['Authorization'], 'Bearer access-token');
    expect(transport.lastBody, <String, dynamic>{
      'conversationId': 'conversation-1',
      'message': 'Tư vấn hoa sinh nhật',
      'productId': 'product-1',
      'context': <String, dynamic>{
        'orderId': 'order-1',
        'source': 'product-detail',
      },
    });
  });

  test('getHistory encodes conversation id and sends the requested page', () async {
    final transport = RecordingChatbotTransport(
      nextResponse: const ChatbotApiResponse(
        statusCode: 200,
        body: <String, dynamic>{
          'success': true,
          'data': <String, dynamic>{},
        },
      ),
    );
    final source = ChatbotRemoteDataSource(
      transport: transport,
      accessTokenProvider: () async => 'access-token',
    );

    await source.getHistory('conversation/with slash', page: 2);

    expect(transport.lastMethod, 'GET');
    expect(
      transport.lastPath,
      '/api/v1/chatbot/conversations/conversation%2Fwith%20slash/messages',
    );
    expect(transport.lastQuery, <String, dynamic>{'page': 2});
  });

  test('deleteConversation accepts a 204 response', () async {
    final transport = RecordingChatbotTransport(
      nextResponse: const ChatbotApiResponse(
        statusCode: 204,
        body: <String, dynamic>{},
      ),
    );
    final source = ChatbotRemoteDataSource(
      transport: transport,
      accessTokenProvider: () async => 'access-token',
    );

    await source.deleteConversation('conversation-1');

    expect(transport.lastMethod, 'DELETE');
    expect(
      transport.lastPath,
      '/api/v1/chatbot/conversations/conversation-1',
    );
  });

  test('missing access token is mapped to auth failure', () async {
    final source = ChatbotRemoteDataSource(
      transport: RecordingChatbotTransport(
        nextResponse: ChatbotApiResponse(
          statusCode: 200,
          body: _successEnvelope,
        ),
      ),
      accessTokenProvider: () async => null,
    );

    expect(
      () => source.sendMessage(message: 'Xin chào'),
      throwsA(
        isA<ChatbotFailure>().having(
          (failure) => failure.code,
          'code',
          ChatbotErrorCode.authTokenInvalid,
        ),
      ),
    );
  });

  test('backend error code is preserved for rate limit handling', () async {
    final source = ChatbotRemoteDataSource(
      transport: RecordingChatbotTransport(
        nextResponse: const ChatbotApiResponse(
          statusCode: 429,
          body: <String, dynamic>{
            'success': false,
            'error': <String, dynamic>{
              'code': 'CHATBOT_RATE_LIMITED',
              'message': 'Gửi quá nhanh.',
            },
          },
        ),
      ),
      accessTokenProvider: () async => 'access-token',
    );

    expect(
      () => source.sendMessage(message: 'Xin chào'),
      throwsA(
        isA<ChatbotFailure>()
            .having(
              (failure) => failure.code,
              'code',
              ChatbotErrorCode.rateLimited,
            )
            .having((failure) => failure.statusCode, 'statusCode', 429),
      ),
    );
  });
}

const _successEnvelope = <String, dynamic>{
  'success': true,
  'data': <String, dynamic>{
    'conversationId': 'conversation-1',
    'messageId': 'message-1',
    'reply': 'Xin chào.',
    'suggestedProducts': <Object>[],
    'action': null,
    'createdAt': '2026-10-15T08:00:00.000Z',
  },
};

class RecordingChatbotTransport implements ChatbotApiTransport {
  RecordingChatbotTransport({required this.nextResponse});

  final ChatbotApiResponse nextResponse;
  String? lastMethod;
  String? lastPath;
  Map<String, String>? lastHeaders;
  Map<String, dynamic>? lastBody;
  Map<String, dynamic>? lastQuery;

  @override
  Future<ChatbotApiResponse> delete({
    required String path,
    required Map<String, String> headers,
  }) async {
    lastMethod = 'DELETE';
    lastPath = path;
    lastHeaders = headers;
    return nextResponse;
  }

  @override
  Future<ChatbotApiResponse> get({
    required String path,
    required Map<String, String> headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    lastMethod = 'GET';
    lastPath = path;
    lastHeaders = headers;
    lastQuery = queryParameters;
    return nextResponse;
  }

  @override
  Future<ChatbotApiResponse> post({
    required String path,
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  }) async {
    lastMethod = 'POST';
    lastPath = path;
    lastHeaders = headers;
    lastBody = body;
    return nextResponse;
  }
}
