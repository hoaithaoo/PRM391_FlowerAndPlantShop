import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plant_flower_api_client/plant_flower_api_client.dart';
import 'package:plant_flower_mobile/features/chatbot/data/api_client_chatbot_transport.dart';

void main() {
  test('chatbot transport forwards requests through ApiClient', () async {
    final requests = <http.Request>[];
    final client = ApiClient(
      baseUrl: 'https://api.example.com',
      httpClient: MockClient((request) async {
        requests.add(request);
        if (request.method == 'DELETE') return http.Response('', 204);
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'conversationId': 'conversation-1'},
          }),
          200,
        );
      }),
    );
    final transport = ApiClientChatbotTransport(client);

    final post = await transport.post(
      path: '/api/v1/chatbot/messages',
      headers: {'Authorization': 'Bearer token'},
      body: {'message': 'Xin chào'},
    );
    final get = await transport.get(
      path: '/api/v1/chatbot/conversations/conversation-1/messages',
      headers: {'Authorization': 'Bearer token'},
      queryParameters: {'page': 2},
    );
    final delete = await transport.delete(
      path: '/api/v1/chatbot/conversations/conversation-1',
      headers: {'Authorization': 'Bearer token'},
    );

    expect(post.statusCode, 200);
    expect(post.body['data'], {'conversationId': 'conversation-1'});
    expect(get.statusCode, 200);
    expect(delete.statusCode, 204);
    expect(requests.map((request) => request.method), [
      'POST',
      'GET',
      'DELETE',
    ]);
    expect(requests[1].url.queryParameters, {'page': '2'});
    expect(
      requests.every(
        (request) => request.headers['authorization'] == 'Bearer token',
      ),
      isTrue,
    );
  });

  test('chatbot transport preserves backend errors', () async {
    final transport = ApiClientChatbotTransport(
      ApiClient(
        baseUrl: 'https://api.example.com',
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'success': false,
              'error': {
                'code': 'AUTH_TOKEN_INVALID',
                'message': 'Token không hợp lệ',
              },
            }),
            401,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      ),
    );

    final response = await transport.post(
      path: '/api/v1/chatbot/messages',
      headers: {'Authorization': 'Bearer token'},
      body: {'message': 'Xin chào'},
    );

    expect(response.statusCode, 401);
    expect(response.body['error'], {
      'code': 'AUTH_TOKEN_INVALID',
      'message': 'Token không hợp lệ',
    });
  });
}
