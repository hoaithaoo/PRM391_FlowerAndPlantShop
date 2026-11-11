import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plant_flower_api_client/plant_flower_api_client.dart';
import 'package:plant_flower_mobile/features/favorites/data/api_favorite_repository.dart';
import 'package:plant_flower_mobile/features/favorites/data/favorite_repository.dart';

const _id = '11111111-1111-4111-8111-111111111111';

http.Response _success(Object data) => http.Response(
  jsonEncode({'success': true, 'data': data}),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  test('gọi đủ bốn endpoint với token và parse ProductSummary', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (request.method == 'DELETE') return http.Response('', 204);
      if (request.method == 'PUT') return _success({'productId': _id});
      if (request.url.path.endsWith('/ids')) {
        return _success({
          'productIds': [_id],
        });
      }
      return _success({
        'items': [
          {
            'id': _id,
            'sku': 'HOA-01',
            'name': 'Hoa hồng',
            'price': 250000,
            'stock': 2,
            'imageUrl': null,
            'category': {'id': 'flowers', 'name': 'Hoa tươi'},
            'favoritedAt': '2026-11-11T12:00:00Z',
          },
        ],
      });
    });
    addTearDown(client.close);
    final repository = ApiFavoriteRepository(
      ApiClient(baseUrl: 'https://api.example.com', httpClient: client),
      accessTokenProvider: () async => ' token ',
    );
    expect(await repository.listIds(), {_id});
    final products = await repository.list();
    expect(products.single.name, 'Hoa hồng');
    expect(products.single.price, 250000);
    expect(products.single.category.name, 'Hoa tươi');
    await repository.add(_id);
    await repository.remove(_id);
    expect(requests.map((r) => '${r.method} ${r.url.path}'), [
      'GET /api/v1/favorites/ids',
      'GET /api/v1/favorites',
      'PUT /api/v1/favorites/$_id',
      'DELETE /api/v1/favorites/$_id',
    ]);
    expect(
      requests.every((r) => r.headers['authorization'] == 'Bearer token'),
      isTrue,
    );
  });

  test('không có token thì không gửi HTTP', () async {
    var requests = 0;
    final client = MockClient((_) async {
      requests++;
      return _success({});
    });
    addTearDown(client.close);
    final repository = ApiFavoriteRepository(
      ApiClient(baseUrl: 'https://api.example.com', httpClient: client),
      accessTokenProvider: () async => null,
    );
    await expectLater(
      repository.listIds(),
      throwsA(
        isA<FavoriteFailure>().having((e) => e.statusCode, 'statusCode', 401),
      ),
    );
    expect(requests, 0);
  });

  test('chuyển ApiException thành FavoriteFailure giữ mã và thông báo', () async {
    // Response.bytes: body có chữ tiếng Việt, http.Response(String) chỉ nhận Latin-1.
    final client = MockClient(
      (_) async => http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'success': false,
            'error': {
              'code': 'PRODUCT_NOT_FOUND',
              'message': 'Không tìm thấy sản phẩm.',
            },
          }),
        ),
        404,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    );
    addTearDown(client.close);
    final repository = ApiFavoriteRepository(
      ApiClient(baseUrl: 'https://api.example.com', httpClient: client),
      accessTokenProvider: () async => 'token',
    );
    await expectLater(
      repository.add(_id),
      throwsA(
        isA<FavoriteFailure>()
            .having((e) => e.code, 'code', 'PRODUCT_NOT_FOUND')
            .having((e) => e.statusCode, 'statusCode', 404),
      ),
    );
  });

  test('dữ liệu sai định dạng được bọc thành lỗi repository', () async {
    final client = MockClient((_) async => _success({'items': 'invalid'}));
    addTearDown(client.close);
    final repository = ApiFavoriteRepository(
      ApiClient(baseUrl: 'https://api.example.com', httpClient: client),
      accessTokenProvider: () async => 'token',
    );
    await expectLater(repository.list(), throwsA(isA<FavoriteFailure>()));
    await expectLater(repository.listIds(), throwsA(isA<FavoriteFailure>()));
  });
}
