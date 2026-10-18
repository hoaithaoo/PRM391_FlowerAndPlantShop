import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plant_flower_api_client/plant_flower_api_client.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';
import 'package:test/test.dart';

http.Response jsonResponse(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

ProductsApi apiFor(Future<http.Response> Function(http.Request) handler) {
  return ProductsApi(
    ApiClient(baseUrl: 'http://localhost:3000', httpClient: MockClient(handler)),
  );
}

const _category = {'id': 'c1', 'name': 'Hoa tươi', 'slug': 'hoa-tuoi'};

Map<String, dynamic> productJson(String id, {Object price = 100000}) => {
  'id': id,
  'sku': 'SKU-$id',
  'name': 'Sản phẩm $id',
  'price': price,
  'stock': 4,
  'imageUrl': null,
  'category': _category,
};

void main() {
  group('listCategories', () {
    test('đọc danh sách dạng mảng', () async {
      late http.Request captured;
      final api = apiFor((request) async {
        captured = request;
        return jsonResponse({
          'success': true,
          'data': [
            _category,
            {'id': 'c2', 'name': 'Cây cảnh'},
          ],
        });
      });

      final categories = await api.listCategories();

      expect(captured.url.path, '/api/v1/categories');
      expect(categories.map((c) => c.id), ['c1', 'c2']);
      expect(categories.last.slug, isNull);
    });

    test('đọc danh sách dạng data.items', () async {
      final api = apiFor(
        (_) async => jsonResponse({
          'success': true,
          'data': {
            'items': [_category],
          },
        }),
      );
      expect(await api.listCategories(), hasLength(1));
    });

    test('data null thì trả danh sách rỗng', () async {
      final api = apiFor(
        (_) async => jsonResponse({'success': true, 'data': null}),
      );
      expect(await api.listCategories(), isEmpty);
    });
  });

  group('listProducts', () {
    test('gửi đúng query string từ ProductQuery', () async {
      late http.Request captured;
      final api = apiFor((request) async {
        captured = request;
        return jsonResponse({'success': true, 'data': []});
      });

      await api.listProducts(
        const ProductQuery(
          search: '  hồng ',
          categoryId: 'c1',
          minPrice: 100000,
          maxPrice: 500000,
          sort: ProductSort.priceAsc,
        ),
        page: 3,
        limit: 8,
      );

      expect(captured.url.path, '/api/v1/products');
      expect(captured.url.queryParameters, {
        'page': '3',
        'limit': '8',
        'sort': 'price_asc',
        'search': 'hồng',
        'categoryId': 'c1',
        'minPrice': '100000',
        'maxPrice': '500000',
      });
    });

    test('query mặc định không gửi search/categoryId rỗng', () async {
      late http.Request captured;
      final api = apiFor((request) async {
        captured = request;
        return jsonResponse({'success': true, 'data': []});
      });

      await api.listProducts(const ProductQuery(search: '', categoryId: ''));

      expect(captured.url.queryParameters.keys.toSet(), {
        'page',
        'limit',
        'sort',
      });
      expect(captured.url.queryParameters['page'], '1');
      expect(captured.url.queryParameters['limit'], '20');
    });

    test('đọc paging ở meta ngoài cùng, data là mảng', () async {
      final api = apiFor(
        (_) async => jsonResponse({
          'success': true,
          'data': [productJson('1'), productJson('2')],
          'meta': {'page': 2, 'limit': 2, 'total': 7, 'totalPages': 4},
        }),
      );

      final result = await api.listProducts(const ProductQuery(), page: 2, limit: 2);

      expect(result.items.map((p) => p.id), ['1', '2']);
      expect(result.page, 2);
      expect(result.total, 7);
      expect(result.totalPages, 4);
      expect(result.hasMore, isTrue);
    });

    test('đọc paging ở data.meta khi data là object có items', () async {
      final api = apiFor(
        (_) async => jsonResponse({
          'success': true,
          'data': {
            'items': [productJson('1')],
            'meta': {'page': 3, 'total': 5, 'totalPages': 3},
          },
        }),
      );

      final result = await api.listProducts(const ProductQuery(), page: 3);

      expect(result.items, hasLength(1));
      expect(result.page, 3);
      expect(result.total, 5);
      expect(result.totalPages, 3);
      expect(result.hasMore, isFalse);
    });

    test('meta ngoài cùng được ưu tiên hơn data.meta', () async {
      final api = apiFor(
        (_) async => jsonResponse({
          'success': true,
          'data': {
            'items': [productJson('1')],
            'meta': {'total': 99, 'totalPages': 99},
          },
          'meta': {'total': 5, 'totalPages': 2},
        }),
      );

      final result = await api.listProducts(const ProductQuery());

      expect(result.total, 5);
      expect(result.totalPages, 2);
    });

    test('thiếu meta thì suy ra total từ số item và totalPages theo limit', () async {
      final api = apiFor(
        (_) async => jsonResponse({
          'success': true,
          'data': [productJson('1'), productJson('2'), productJson('3')],
        }),
      );

      final result = await api.listProducts(const ProductQuery(), limit: 2);

      expect(result.total, 3);
      expect(result.page, 1);
      expect(result.totalPages, 2);
    });

    test('price dạng số thực trong response được đổi về int', () async {
      final api = apiFor(
        (_) async => jsonResponse({
          'success': true,
          'data': [productJson('1', price: 490000.0)],
        }),
      );
      final result = await api.listProducts(const ProductQuery());
      expect(result.items.single.price, 490000);
    });

    test('lỗi backend được ném ra dưới dạng ApiException', () async {
      final api = apiFor(
        (_) async => jsonResponse({
          'success': false,
          'error': {'code': 'VALIDATION_ERROR', 'message': 'Sai tham số'},
        }, 400),
      );
      await expectLater(
        api.listProducts(const ProductQuery()),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('getProduct', () {
    Map<String, dynamic> detailJson() => {
      ...productJson('abc'),
      'description': 'Mô tả',
      'taxRate': 8,
      'imageUrls': ['u1', 'u2'],
      'isActive': true,
    };

    test('đọc chi tiết sản phẩm', () async {
      late http.Request captured;
      final api = apiFor((request) async {
        captured = request;
        return jsonResponse({'success': true, 'data': detailJson()});
      });

      final product = await api.getProduct('abc');

      expect(captured.url.path, '/api/v1/products/abc');
      expect(product.id, 'abc');
      expect(product.description, 'Mô tả');
      expect(product.imageUrls, ['u1', 'u2']);
    });

    test('encode id có ký tự đặc biệt', () async {
      late http.Request captured;
      final api = apiFor((request) async {
        captured = request;
        return jsonResponse({'success': true, 'data': detailJson()});
      });

      await api.getProduct('a b/c?d');

      // path vẫn giữ dạng đã encode: / trong id không tạo thêm segment
      expect(captured.url.path, '/api/v1/products/a%20b%2Fc%3Fd');
      expect(captured.url.query, isEmpty);
    });

    test('404 thành ApiException notFound', () async {
      final api = apiFor(
        (_) async => jsonResponse({
          'success': false,
          'error': {'code': 'PRODUCT_NOT_FOUND', 'message': 'Không có'},
        }, 404),
      );

      await expectLater(
        api.getProduct('x'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.isNotFound, 'isNotFound', isTrue)
              .having((e) => e.code, 'code', 'PRODUCT_NOT_FOUND'),
        ),
      );
    });
  });
}
