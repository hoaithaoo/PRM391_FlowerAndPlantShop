import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_api_client/plant_flower_api_client.dart';
import 'package:plant_flower_mobile/features/cart/data/api_cart_repository.dart';
import 'package:plant_flower_mobile/features/cart/data/cart_failure.dart';

const _itemId = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
const _productId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';

Map<String, dynamic> _envelope() => {
  'success': true,
  'data': {
    'id': 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
    'items': [
      {
        'id': _itemId,
        'productId': _productId,
        'name': 'Bó Tulip',
        'price': 490000,
        'quantity': 2,
        'subtotal': 980000,
      },
    ],
    'subtotal': 980000,
    'totalQuantity': 2,
  },
  'meta': {'requestId': 'req_test'},
};

void main() {
  test('gọi đủ cart API với Bearer token và dùng snapshot từ server', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (request.method == 'DELETE') return http.Response('', 204);
      return http.Response(
        request.method == 'GET'
            ? jsonEncode(_envelope())
            // POST/PUT chỉ trả dòng vừa đổi, không phải cả giỏ.
            : jsonEncode({
                'success': true,
                'data': {'id': _itemId, 'quantity': 3, 'subtotal': 1470000},
              }),
        request.method == 'POST' ? 201 : 200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final repository = ApiCartRepository(
      ApiClient(baseUrl: 'https://api.example.com', httpClient: client),
      accessTokenProvider: () async => 'token-123',
    );

    final loaded = await repository.load();
    final added = await repository.add(productId: _productId, quantity: 2);
    await repository.update(itemId: _itemId, quantity: 3);
    await repository.remove(itemId: _itemId);
    await repository.clear();

    expect(added.items.single.id, _itemId);
    expect(loaded.id, 'dddddddd-dddd-4ddd-8ddd-dddddddddddd');
    expect(loaded.items.single.name, 'Bó Tulip');
    expect(loaded.items.single.unitPrice, 490000);
    expect(loaded.subtotal, 980000);
    expect(loaded.totalQuantity, 2);
    expect(requests.map((request) => '${request.method} ${request.url.path}'), [
      'GET /api/v1/cart',
      'POST /api/v1/cart/items',
      'GET /api/v1/cart',
      'PUT /api/v1/cart/items/$_itemId',
      'GET /api/v1/cart',
      'DELETE /api/v1/cart/items/$_itemId',
      'GET /api/v1/cart',
      'GET /api/v1/cart',
      'DELETE /api/v1/cart/items/$_itemId',
      'GET /api/v1/cart',
    ]);
    expect(
      requests.every(
        (request) => request.headers['authorization'] == 'Bearer token-123',
      ),
      isTrue,
    );
    expect(jsonDecode(requests[1].body), {
      'productId': _productId,
      'quantity': 2,
    });
    expect(jsonDecode(requests[3].body), {'quantity': 3});
  });

  test(
    'không có access token thì báo cần đăng nhập và không gọi HTTP',
    () async {
      var called = false;
      final repository = ApiCartRepository(
        ApiClient(
          baseUrl: 'https://api.example.com',
          httpClient: MockClient((_) async {
            called = true;
            return http.Response('{}', 200);
          }),
        ),
        accessTokenProvider: () async => null,
      );

      await expectLater(
        repository.load(),
        throwsA(
          isA<CartFailure>().having(
            (failure) => failure.code,
            'code',
            CartErrorCode.authenticationRequired,
          ),
        ),
      );
      expect(called, isFalse);
    },
  );

  test(
    'response thiếu cart data được báo malformed thay vì tạo giỏ giả',
    () async {
      final repository = ApiCartRepository(
        ApiClient(
          baseUrl: 'https://api.example.com',
          httpClient: MockClient(
            (_) async =>
                http.Response(jsonEncode({'success': true, 'data': null}), 200),
          ),
        ),
        accessTokenProvider: () async => 'token-123',
      );

      await expectLater(
        repository.load(),
        throwsA(
          isA<CartFailure>().having(
            (failure) => failure.code,
            'code',
            CartErrorCode.malformedResponse,
          ),
        ),
      );
    },
  );
  test('preserves stable backend error codes', () async {
    final repository = ApiCartRepository(
      ApiClient(
        baseUrl: 'https://api.example.com',
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'success': false,
              'error': {
                'code': 'PRODUCT_OUT_OF_STOCK',
                'message': 'Out of stock',
              },
            }),
            409,
          ),
        ),
      ),
      accessTokenProvider: () async => 'token-123',
    );

    await expectLater(
      repository.add(productId: _productId, quantity: 2),
      throwsA(
        isA<CartFailure>()
            .having(
              (failure) => failure.code,
              'code',
              CartErrorCode.productOutOfStock,
            )
            .having(
              (failure) => failure.backendCode,
              'backendCode',
              'PRODUCT_OUT_OF_STOCK',
            ),
      ),
    );
  });

  for (final testCase in [
    (401, 'AUTH_TOKEN_INVALID', CartErrorCode.authenticationRequired),
    (404, 'PRODUCT_NOT_FOUND', CartErrorCode.productNotFound),
    (422, 'VALIDATION_ERROR', CartErrorCode.validation),
    (500, 'INTERNAL_ERROR', CartErrorCode.server),
  ]) {
    test('maps ${testCase.$1} ${testCase.$2}', () async {
      final repository = ApiCartRepository(
        ApiClient(
          baseUrl: 'https://api.example.com',
          httpClient: MockClient(
            (_) async => http.Response(
              jsonEncode({
                'success': false,
                'error': {'code': testCase.$2, 'message': 'Request failed'},
              }),
              testCase.$1,
            ),
          ),
        ),
        accessTokenProvider: () async => 'token-123',
      );

      await expectLater(
        repository.load(),
        throwsA(
          isA<CartFailure>().having(
            (failure) => failure.code,
            'code',
            testCase.$3,
          ),
        ),
      );
    });
  }
}
