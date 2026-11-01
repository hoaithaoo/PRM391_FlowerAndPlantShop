import 'package:plant_flower_api_client/plant_flower_api_client.dart';

import 'chatbot_remote_data_source.dart';

class ApiClientChatbotTransport implements ChatbotApiTransport {
  const ApiClientChatbotTransport(this._client);

  final ApiClient _client;

  @override
  Future<ChatbotApiResponse> get({
    required String path,
    required Map<String, String> headers,
    Map<String, dynamic>? queryParameters,
  }) => _request(
    () => _client.get(
      path,
      headers: headers,
      query: queryParameters?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    ),
  );

  @override
  Future<ChatbotApiResponse> post({
    required String path,
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  }) => _request(() => _client.post(path, headers: headers, body: body));

  @override
  Future<ChatbotApiResponse> delete({
    required String path,
    required Map<String, String> headers,
  }) => _request(() => _client.delete(path, headers: headers));

  Future<ChatbotApiResponse> _request(
    Future<ApiResponse> Function() send,
  ) async {
    try {
      final response = await send();
      return ChatbotApiResponse(statusCode: 200, body: {'data': response.data});
    } on ApiException catch (error) {
      if (error.isNetworkError) rethrow;
      if (error.statusCode == 204) {
        return const ChatbotApiResponse(statusCode: 204, body: {});
      }
      return ChatbotApiResponse(
        statusCode: error.statusCode,
        body: {
          'error': {'code': error.code, 'message': error.message},
        },
      );
    }
  }
}
