import 'dart:async';
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

ApiClient clientFor(
  Future<http.Response> Function(http.Request request) handler, {
  String baseUrl = 'http://localhost:3000',
  Duration timeout = const Duration(seconds: 15),
}) {
  return ApiClient(
    baseUrl: baseUrl,
    httpClient: MockClient(handler),
    timeout: timeout,
  );
}

void main() {
  group('ApiClient.get - thành công', () {
    test('bóc envelope: data và meta', () async {
      final client = clientFor(
        (_) async => jsonResponse({
          'success': true,
          'data': {'hello': 'world'},
          'meta': {'page': 2, 'total': 9},
        }),
      );

      final response = await client.get('api/v1/ping');

      expect(response.data, {'hello': 'world'});
      expect(response.meta, {'page': 2, 'total': 9});
    });

    test('thiếu meta thì meta rỗng', () async {
      final client = clientFor(
        (_) async => jsonResponse({'success': true, 'data': []}),
      );
      final response = await client.get('api/v1/ping');
      expect(response.data, isEmpty);
      expect(response.meta, isEmpty);
    });

    test('envelope không có trường success vẫn được chấp nhận', () async {
      final client = clientFor((_) async => jsonResponse({'data': 1}));
      expect((await client.get('x')).data, 1);
    });

    test('giải mã UTF-8 tiếng Việt kể cả khi không có charset', () async {
      final client = clientFor(
        (_) async => http.Response.bytes(
          utf8.encode(jsonEncode({'success': true, 'data': 'Hoa tươi'})),
          200,
        ),
      );
      expect((await client.get('x')).data, 'Hoa tươi');
    });

    test('gửi GET tới đúng URL, query string và header Accept', () async {
      late http.Request captured;
      final client = clientFor((request) async {
        captured = request;
        return jsonResponse({'success': true, 'data': null});
      });

      await client.get('api/v1/products', query: {'page': '1', 'search': 'a b'});

      expect(captured.method, 'GET');
      expect(captured.url.path, '/api/v1/products');
      expect(captured.url.queryParameters, {'page': '1', 'search': 'a b'});
      expect(captured.headers['Accept'], 'application/json');
    });

    test('baseUrl có hoặc không có dấu / cuối đều ra cùng URL', () async {
      final urls = <String>[];
      for (final base in [
        'http://localhost:3000',
        'http://localhost:3000/',
      ]) {
        final client = clientFor((request) async {
          urls.add(request.url.toString());
          return jsonResponse({'success': true, 'data': null});
        }, baseUrl: base);
        await client.get('api/v1/categories');
      }
      expect(urls, [
        'http://localhost:3000/api/v1/categories',
        'http://localhost:3000/api/v1/categories',
      ]);
    });

    test('baseUrl có path prefix được giữ lại', () async {
      late Uri captured;
      final client = clientFor((request) async {
        captured = request.url;
        return jsonResponse({'success': true, 'data': null});
      }, baseUrl: 'https://example.com/shop');

      await client.get('api/v1/categories');

      expect(captured.toString(), 'https://example.com/shop/api/v1/categories');
    });
  });

  group('ApiClient.get - lỗi từ backend', () {
    test('error envelope thành ApiException đúng status, code, message', () async {
      final client = clientFor(
        (_) async => jsonResponse({
          'success': false,
          'error': {
            'code': 'PRODUCT_NOT_FOUND',
            'message': 'Không tìm thấy sản phẩm',
          },
        }, 404),
      );

      await expectLater(
        client.get('api/v1/products/x'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 404)
              .having((e) => e.code, 'code', 'PRODUCT_NOT_FOUND')
              .having((e) => e.message, 'message', 'Không tìm thấy sản phẩm')
              .having((e) => e.isNotFound, 'isNotFound', isTrue)
              .having((e) => e.isNetworkError, 'isNetworkError', isFalse),
        ),
      );
    });

    test('lỗi 400 validation giữ nguyên code', () async {
      final client = clientFor(
        (_) async => jsonResponse({
          'success': false,
          'error': {'code': 'VALIDATION_ERROR', 'message': 'Sai tham số'},
        }, 400),
      );

      await expectLater(
        client.get('x'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.code, 'code', 'VALIDATION_ERROR')
              .having((e) => e.isNotFound, 'isNotFound', isFalse),
        ),
      );
    });

    test('error thiếu code/message thì dùng giá trị mặc định', () async {
      final client = clientFor(
        (_) async => jsonResponse({'success': false, 'error': {}}, 500),
      );

      await expectLater(
        client.get('x'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.code, 'code', 'UNKNOWN_ERROR')
              .having((e) => e.message, 'message', isNotEmpty),
        ),
      );
    });

    test('body không phải JSON thành UNKNOWN_ERROR giữ statusCode', () async {
      final client = clientFor(
        (_) async => http.Response('<html>Bad Gateway</html>', 502),
      );

      await expectLater(
        client.get('x'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 502)
              .having((e) => e.code, 'code', 'UNKNOWN_ERROR')
              .having((e) => e.isNetworkError, 'isNetworkError', isFalse),
        ),
      );
    });

    test('status 2xx nhưng body không phải JSON cũng là UNKNOWN_ERROR', () async {
      final client = clientFor((_) async => http.Response('OK', 200));

      await expectLater(
        client.get('x'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 200)
              .having((e) => e.code, 'code', 'UNKNOWN_ERROR'),
        ),
      );
    });

    test('body rỗng với status lỗi thành UNKNOWN_ERROR', () async {
      final client = clientFor((_) async => http.Response('', 500));

      await expectLater(
        client.get('x'),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', 'UNKNOWN_ERROR'),
        ),
      );
    });

    test('body JSON nhưng không phải object thành UNKNOWN_ERROR', () async {
      final client = clientFor((_) async => jsonResponse([1, 2, 3]));

      await expectLater(
        client.get('x'),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', 'UNKNOWN_ERROR'),
        ),
      );
    });

    test('success=false dù status 200 vẫn là lỗi', () async {
      final client = clientFor(
        (_) async => jsonResponse({
          'success': false,
          'error': {'code': 'SOMETHING', 'message': 'Hỏng'},
        }),
      );

      await expectLater(
        client.get('x'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'SOMETHING')
              .having((e) => e.message, 'message', 'Hỏng'),
        ),
      );
    });
  });

  group('ApiClient.get - lỗi mạng', () {
    test('ClientException thành lỗi mạng', () async {
      final client = clientFor(
        (_) async => throw http.ClientException('Connection refused'),
      );

      await expectLater(
        client.get('x'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.isNetworkError, 'isNetworkError', isTrue)
              .having((e) => e.code, 'code', ApiException.networkErrorCode)
              .having((e) => e.statusCode, 'statusCode', 0)
              .having((e) => e.isNotFound, 'isNotFound', isFalse),
        ),
      );
    });

    test('quá thời gian chờ thành lỗi mạng', () async {
      final never = Completer<http.Response>();
      final client = clientFor(
        (_) => never.future,
        timeout: const Duration(milliseconds: 20),
      );

      await expectLater(
        client.get('x'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.isNetworkError, 'isNetworkError', isTrue)
              .having((e) => e.message, 'message', isNotEmpty),
        ),
      );
    });
  });

  group('ApiException', () {
    test('toString chứa status và code', () {
      const error = ApiException(statusCode: 404, code: 'X', message: 'm');
      expect(error.toString(), contains('404'));
      expect(error.toString(), contains('X'));
    });

    test('network() có message mặc định và có thể tuỳ biến', () {
      expect(const ApiException.network().message, isNotEmpty);
      expect(const ApiException.network('abc').message, 'abc');
    });
  });
}
