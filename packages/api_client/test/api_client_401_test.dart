import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plant_flower_api_client/plant_flower_api_client.dart';
import 'package:test/test.dart';

http.Response jsonResponse(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  final unauthorized = {
    'success': false,
    'error': {'code': 'AUTH_TOKEN_INVALID', 'message': 'Hết hạn'},
  };
  final ok = {'success': true, 'data': 1, 'meta': <String, dynamic>{}};
  const auth = {'Authorization': 'Bearer old'};

  ApiClient client(
    Future<http.Response> Function(http.Request request) handler, {
    required Future<String?> Function() refresh,
    void Function()? expired,
  }) => ApiClient(
    baseUrl: 'http://localhost:3000',
    httpClient: MockClient(handler),
    refreshAccessToken: refresh,
    onSessionExpired: expired,
  );

  test('refresh rồi gửi lại với token mới', () async {
    final tokens = <String?>[];
    final api = client((request) async {
      tokens.add(request.headers['Authorization']);
      return tokens.length == 1
          ? jsonResponse(unauthorized, 401)
          : jsonResponse(ok);
    }, refresh: () async => 'new');

    expect((await api.get('x', headers: auth)).data, 1);
    expect(tokens, ['Bearer old', 'Bearer new']);
  });

  test('token mới vẫn 401 thì báo hết phiên', () async {
    var expired = 0;
    final api = client(
      (_) async => jsonResponse(unauthorized, 401),
      refresh: () async => 'new',
      expired: () => expired++,
    );

    await expectLater(
      api.get('x', headers: auth),
      throwsA(isA<ApiException>()),
    );
    expect(expired, 1);
  });

  test('refresh trả null thì báo hết phiên, không gửi lại', () async {
    var calls = 0;
    var expired = 0;
    final api = client(
      (_) async {
        calls++;
        return jsonResponse(unauthorized, 401);
      },
      refresh: () async => null,
      expired: () => expired++,
    );

    await expectLater(
      api.get('x', headers: auth),
      throwsA(isA<ApiException>()),
    );
    expect(calls, 1);
    expect(expired, 1);
  });

  test('refresh lỗi mạng thì không đăng xuất', () async {
    var expired = 0;
    final api = client(
      (_) async => jsonResponse(unauthorized, 401),
      refresh: () async => throw Exception('mất mạng'),
      expired: () => expired++,
    );

    await expectLater(
      api.get('x', headers: auth),
      throwsA(isA<ApiException>()),
    );
    expect(expired, 0);
  });

  test('request không có token thì không refresh', () async {
    var refreshed = 0;
    final api = client(
      (_) async => jsonResponse(unauthorized, 401),
      refresh: () async {
        refreshed++;
        return 'new';
      },
    );

    await expectLater(api.get('x'), throwsA(isA<ApiException>()));
    expect(refreshed, 0);
  });

  test('nhiều 401 cùng lúc chỉ refresh một lần', () async {
    var refreshed = 0;
    final api = client(
      (request) async => request.headers['Authorization'] == 'Bearer new'
          ? jsonResponse(ok)
          : jsonResponse(unauthorized, 401),
      refresh: () async {
        refreshed++;
        await Future<void>.delayed(const Duration(milliseconds: 5));
        return 'new';
      },
    );

    await Future.wait([
      api.get('a', headers: auth),
      api.get('b', headers: auth),
    ]);
    expect(refreshed, 1);
  });
}
