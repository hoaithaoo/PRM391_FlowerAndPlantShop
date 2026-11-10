import 'package:plant_flower_api_client/plant_flower_api_client.dart';

import 'notification_remote_data_source.dart';

/// Adapter mỏng để Notifications dùng chung ApiClient của ứng dụng.
class ApiClientNotificationTransport implements NotificationApiTransport {
  const ApiClientNotificationTransport(this._client);

  final ApiClient _client;

  @override
  Future<NotificationApiResponse> get({
    required String path,
    required Map<String, String> headers,
    Map<String, dynamic>? queryParameters,
  }) => _request(
    () => _client.get(
      _relativePath(path),
      headers: headers,
      query: queryParameters?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    ),
  );

  @override
  Future<NotificationApiResponse> patch({
    required String path,
    required Map<String, String> headers,
    Map<String, dynamic>? body,
  }) => _request(
    () => _client.patch(_relativePath(path), headers: headers, body: body),
  );

  Future<NotificationApiResponse> _request(
    Future<ApiResponse> Function() send,
  ) async {
    try {
      final response = await send();
      return NotificationApiResponse(
        statusCode: response.statusCode,
        body: <String, dynamic>{
          'data': response.data,
          if (response.meta.isNotEmpty) 'meta': response.meta,
        },
      );
    } on ApiException catch (error) {
      if (error.isNetworkError) rethrow;
      return NotificationApiResponse(
        statusCode: error.statusCode,
        body: <String, dynamic>{
          'error': <String, dynamic>{
            'code': error.code,
            'message': error.message,
          },
        },
      );
    }
  }

  String _relativePath(String path) =>
      path.startsWith('/') ? path.substring(1) : path;
}
