import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plant_flower_api_client/plant_flower_api_client.dart';
import 'package:plant_flower_mobile/features/notifications/data/api_client_notification_transport.dart';
import 'package:plant_flower_mobile/features/notifications/data/notification_failure.dart';
import 'package:plant_flower_mobile/features/notifications/data/notification_remote_data_source.dart';

void main() {
  test('ApiClient adapter giữ meta và mã hóa query theo contract', () async {
    late http.Request capturedRequest;
    final client = ApiClient(
      baseUrl: 'https://api.example.com',
      httpClient: MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'items': <Object>[]},
            'meta': {'page': 3, 'total': 0, 'totalPages': 0, 'unreadCount': 0},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.close);

    final response = await ApiClientNotificationTransport(client).get(
      path: '/api/v1/notifications',
      headers: {'Authorization': 'Bearer token'},
      queryParameters: {'page': 3, 'unreadOnly': true},
    );

    expect(capturedRequest.url.path, '/api/v1/notifications');
    expect(capturedRequest.url.queryParameters, {
      'page': '3',
      'unreadOnly': 'true',
    });
    expect(capturedRequest.headers['Authorization'], 'Bearer token');
    expect((response.body['meta'] as Map)['page'], 3);
  });

  group('NotificationRemoteDataSource', () {
    late _RecordingTransport transport;
    late NotificationRemoteDataSource dataSource;

    setUp(() {
      transport = _RecordingTransport();
      dataSource = NotificationRemoteDataSource(
        transport: transport,
        accessTokenProvider: () async => 'access-token',
      );
    });

    test('GET gửi đúng page, unreadOnly và Bearer token', () async {
      transport.nextResponse = const NotificationApiResponse(
        statusCode: 200,
        body: {
          'data': {'items': <Object>[]},
          'meta': {'page': 2, 'total': 0, 'totalPages': 0, 'unreadCount': 0},
        },
      );

      final response = await dataSource.getNotifications(
        page: 2,
        unreadOnly: true,
      );

      expect(transport.method, 'GET');
      expect(transport.path, '/api/v1/notifications');
      expect(transport.query, {'page': 2, 'unreadOnly': true});
      expect(transport.headers?['Authorization'], 'Bearer access-token');
      expect(response['meta'], isA<Map>());
    });

    test('PATCH đọc một và đọc tất cả không gửi body', () async {
      transport.nextResponse = const NotificationApiResponse(
        statusCode: 200,
        body: {
          'data': {
            'id': 'id-1',
            'isRead': true,
            'readAt': '2026-11-02T00:00:00.000Z',
          },
        },
      );
      await dataSource.markAsRead('id-1');
      expect(transport.path, '/api/v1/notifications/id-1/read');
      expect(transport.body, isNull);

      transport.nextResponse = const NotificationApiResponse(
        statusCode: 200,
        body: {
          'data': {'updatedCount': 3},
        },
      );
      await dataSource.markAllAsRead();
      expect(transport.path, '/api/v1/notifications/read-all');
      expect(transport.body, isNull);
    });

    test('không có session token thì chặn request', () async {
      dataSource = NotificationRemoteDataSource(
        transport: transport,
        accessTokenProvider: () async => null,
      );

      await expectLater(
        dataSource.getNotifications(page: 1, unreadOnly: false),
        throwsA(
          isA<NotificationFailure>().having(
            (failure) => failure.code,
            'code',
            NotificationErrorCode.authTokenInvalid,
          ),
        ),
      );
      expect(transport.method, isNull);
    });

    test('giữ status và error code từ backend', () async {
      transport.nextResponse = const NotificationApiResponse(
        statusCode: 403,
        body: {
          'error': {'code': 'ACCOUNT_INACTIVE'},
        },
      );

      await expectLater(
        dataSource.getNotifications(page: 1, unreadOnly: false),
        throwsA(
          isA<NotificationFailure>()
              .having((failure) => failure.statusCode, 'statusCode', 403)
              .having((failure) => failure.code, 'code', 'ACCOUNT_INACTIVE'),
        ),
      );
    });

    test('lỗi kết nối được chuẩn hóa thành NETWORK_ERROR', () async {
      dataSource = NotificationRemoteDataSource(
        transport: const _ThrowingTransport(),
        accessTokenProvider: () async => 'token',
      );

      await expectLater(
        dataSource.getNotifications(page: 1, unreadOnly: false),
        throwsA(
          isA<NotificationFailure>().having(
            (failure) => failure.code,
            'code',
            NotificationErrorCode.network,
          ),
        ),
      );
    });
  });
}

class _ThrowingTransport implements NotificationApiTransport {
  const _ThrowingTransport();

  @override
  Future<NotificationApiResponse> get({
    required String path,
    required Map<String, String> headers,
    Map<String, dynamic>? queryParameters,
  }) => Future<NotificationApiResponse>.error(Exception('offline'));

  @override
  Future<NotificationApiResponse> patch({
    required String path,
    required Map<String, String> headers,
    Map<String, dynamic>? body,
  }) => Future<NotificationApiResponse>.error(Exception('offline'));
}

class _RecordingTransport implements NotificationApiTransport {
  NotificationApiResponse nextResponse = const NotificationApiResponse(
    statusCode: 200,
    body: <String, dynamic>{},
  );
  String? method;
  String? path;
  Map<String, String>? headers;
  Map<String, dynamic>? query;
  Map<String, dynamic>? body;

  @override
  Future<NotificationApiResponse> get({
    required String path,
    required Map<String, String> headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    method = 'GET';
    this.path = path;
    this.headers = headers;
    query = queryParameters;
    return nextResponse;
  }

  @override
  Future<NotificationApiResponse> patch({
    required String path,
    required Map<String, String> headers,
    Map<String, dynamic>? body,
  }) async {
    method = 'PATCH';
    this.path = path;
    this.headers = headers;
    this.body = body;
    return nextResponse;
  }
}
