import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plant_flower_api_client/plant_flower_api_client.dart';
import 'package:plant_flower_mobile/features/products/data/api_product_repository.dart';
import 'package:plant_flower_mobile/features/products/data/product_repository.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

ApiProductRepository _repo(Future<http.Response> Function(http.Request) h) {
  return ApiProductRepository(
    ProductsApi(
      ApiClient(baseUrl: 'http://localhost:3000', httpClient: MockClient(h)),
    ),
  );
}

Map<String, dynamic> _errorBody(String code, String message) => {
  'success': false,
  'error': {'code': code, 'message': message},
};

Matcher _failure({bool? notFound, bool? offline, String? message}) {
  var matcher = isA<ProductFailure>();
  if (notFound != null) {
    matcher = matcher.having((f) => f.notFound, 'notFound', notFound);
  }
  if (offline != null) {
    matcher = matcher.having((f) => f.offline, 'offline', offline);
  }
  if (message != null) {
    matcher = matcher.having((f) => f.message, 'message', message);
  }
  return matcher;
}

void main() {
  const category = {'id': 'c1', 'name': 'Hoa tươi'};
  final productJson = {
    'id': 'p1',
    'sku': 'FL-1',
    'name': 'Bó hoa',
    'price': 490000,
    'stock': 3,
    'category': category,
  };

  group('thành công', () {
    test('listCategories', () async {
      final repo = _repo(
        (_) async => _json({
          'success': true,
          'data': [category],
        }),
      );
      final categories = await repo.listCategories();
      expect(categories.single.name, 'Hoa tươi');
    });

    test('listProducts chuyển query và paging', () async {
      late http.Request captured;
      final repo = _repo((request) async {
        captured = request;
        return _json({
          'success': true,
          'data': [productJson],
          'meta': {'page': 1, 'total': 1, 'totalPages': 1},
        });
      });

      final result = await repo.listProducts(
        const ProductQuery(search: 'hoa'),
        limit: 4,
      );

      expect(captured.url.queryParameters['search'], 'hoa');
      expect(captured.url.queryParameters['limit'], '4');
      expect(result.items.single.id, 'p1');
      expect(result.total, 1);
    });

    test('getProduct', () async {
      final repo = _repo(
        (_) async => _json({'success': true, 'data': productJson}),
      );
      expect((await repo.getProduct('p1')).sku, 'FL-1');
    });
  });

  group('map ApiException sang ProductFailure', () {
    test('404 PRODUCT_NOT_FOUND thành notFound với câu tiếng Việt chuẩn', () {
      final repo = _repo(
        (_) async => _json(_errorBody('PRODUCT_NOT_FOUND', 'Not found'), 404),
      );
      expect(
        repo.getProduct('x'),
        throwsA(
          _failure(
            notFound: true,
            offline: false,
            message: 'Sản phẩm không tồn tại hoặc đã ngừng bán.',
          ),
        ),
      );
    });

    test('404 mã khác vẫn là notFound nhưng giữ message của server', () {
      final repo = _repo(
        (_) async => _json(_errorBody('ROUTE_NOT_FOUND', 'Không có route'), 404),
      );
      expect(
        repo.getProduct('x'),
        throwsA(_failure(notFound: true, message: 'Không có route')),
      );
    });

    test('lỗi mạng thành offline', () {
      final repo = _repo((_) async => throw http.ClientException('down'));
      expect(
        repo.listProducts(const ProductQuery()),
        throwsA(_failure(offline: true, notFound: false)),
      );
    });

    test('lỗi mạng ở listCategories và getProduct cũng thành offline', () async {
      final repo = _repo((_) async => throw http.ClientException('down'));
      await expectLater(repo.listCategories(), throwsA(_failure(offline: true)));
      await expectLater(repo.getProduct('x'), throwsA(_failure(offline: true)));
    });

    test('500 giữ message server, không notFound không offline', () {
      final repo = _repo(
        (_) async => _json(_errorBody('INTERNAL_ERROR', 'Lỗi máy chủ'), 500),
      );
      expect(
        repo.listProducts(const ProductQuery()),
        throwsA(
          _failure(notFound: false, offline: false, message: 'Lỗi máy chủ'),
        ),
      );
    });

    test('body không phải JSON thành lỗi chung, không offline', () {
      final repo = _repo((_) async => http.Response('oops', 502));
      expect(
        repo.listCategories(),
        throwsA(_failure(notFound: false, offline: false)),
      );
    });
  });
}
