import 'notification_failure.dart';

typedef NotificationAccessTokenProvider = Future<String?> Function();

abstract interface class NotificationApiTransport {
  Future<NotificationApiResponse> get({
    required String path,
    required Map<String, String> headers,
    Map<String, dynamic>? queryParameters,
  });

  Future<NotificationApiResponse> patch({
    required String path,
    required Map<String, String> headers,
    Map<String, dynamic>? body,
  });
}

class NotificationApiResponse {
  const NotificationApiResponse({required this.statusCode, required this.body});

  final int statusCode;
  final Map<String, dynamic> body;
}

class NotificationRemoteDataSource {
  const NotificationRemoteDataSource({
    required NotificationApiTransport transport,
    required NotificationAccessTokenProvider accessTokenProvider,
  }) : _transport = transport,
       _accessTokenProvider = accessTokenProvider;

  static const listEndpoint = '/api/v1/notifications';
  static const markAllEndpoint = '/api/v1/notifications/read-all';

  final NotificationApiTransport _transport;
  final NotificationAccessTokenProvider _accessTokenProvider;

  Future<Map<String, dynamic>> getNotifications({
    required int page,
    required bool unreadOnly,
  }) async {
    final headers = await _authenticatedHeaders();
    return _request(
      () => _transport.get(
        path: listEndpoint,
        headers: headers,
        queryParameters: <String, dynamic>{
          'page': page,
          'unreadOnly': unreadOnly,
        },
      ),
      preserveEnvelope: true,
    );
  }

  Future<Map<String, dynamic>> markAsRead(String notificationId) async {
    final headers = await _authenticatedHeaders();
    final encodedId = Uri.encodeComponent(notificationId);
    return _request(
      () => _transport.patch(
        path: '$listEndpoint/$encodedId/read',
        headers: headers,
      ),
    );
  }

  Future<Map<String, dynamic>> markAllAsRead() async {
    final headers = await _authenticatedHeaders();
    return _request(
      () => _transport.patch(path: markAllEndpoint, headers: headers),
    );
  }

  Future<Map<String, String>> _authenticatedHeaders() async {
    // TODO: Lấy access token từ Supabase Auth sau khi auth foundation được merge
    final accessToken = await _accessTokenProvider();
    if (accessToken == null || accessToken.trim().isEmpty) {
      throw const NotificationFailure(
        code: NotificationErrorCode.authTokenInvalid,
      );
    }

    return <String, String>{
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };
  }

  Future<Map<String, dynamic>> _request(
    Future<NotificationApiResponse> Function() send, {
    bool preserveEnvelope = false,
  }) async {
    try {
      final response = await send();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw NotificationFailure(
          code: _readErrorCode(response.body),
          statusCode: response.statusCode,
        );
      }

      if (preserveEnvelope) {
        return response.body;
      }

      final data = response.body['data'];
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return response.body;
    } on NotificationFailure {
      rethrow;
    } catch (_) {
      throw const NotificationFailure.network();
    }
  }

  String _readErrorCode(Map<String, dynamic> body) {
    final error = body['error'];
    if (error is Map) {
      final code = error['code'];
      if (code is String && code.isNotEmpty) {
        return code;
      }
    }
    return NotificationErrorCode.network;
  }
}
