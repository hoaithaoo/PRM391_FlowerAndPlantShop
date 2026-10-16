import 'package:plant_flower_shared/plant_flower_shared.dart';
import 'package:test/test.dart';

Map<String, dynamic> categoryJson([String id = 'c1']) => {
  'id': id,
  'name': 'Hoa tươi',
  'slug': 'hoa-tuoi',
};

void main() {
  group('ProductSort', () {
    test('apiValue khớp contract backend', () {
      expect(ProductSort.newest.apiValue, 'newest');
      expect(ProductSort.priceAsc.apiValue, 'price_asc');
      expect(ProductSort.priceDesc.apiValue, 'price_desc');
    });
  });

  group('Category', () {
    test('fromJson đọc đủ trường', () {
      final category = Category.fromJson(categoryJson());
      expect(category.id, 'c1');
      expect(category.name, 'Hoa tươi');
      expect(category.slug, 'hoa-tuoi');
    });

    test('slug thiếu thì null', () {
      final category = Category.fromJson({'id': 'c1', 'name': 'Hoa'});
      expect(category.slug, isNull);
    });

    test('so sánh bằng theo id và name', () {
      expect(
        const Category(id: 'a', name: 'X'),
        const Category(id: 'a', name: 'X', slug: 'khac'),
      );
      expect(
        const Category(id: 'a', name: 'X') ==
            const Category(id: 'b', name: 'X'),
        isFalse,
      );
    });
  });

  group('ProductSummary.fromJson', () {
    Map<String, dynamic> json({Object price = 490000, Object stock = 3}) => {
      'id': 'p1',
      'sku': 'FL-001',
      'name': 'Bó hoa',
      'price': price,
      'stock': stock,
      'imageUrl': 'https://example.com/a.png',
      'category': categoryJson(),
    };

    test('đọc đủ trường', () {
      final product = ProductSummary.fromJson(json());
      expect(product.id, 'p1');
      expect(product.sku, 'FL-001');
      expect(product.name, 'Bó hoa');
      expect(product.price, 490000);
      expect(product.stock, 3);
      expect(product.imageUrl, 'https://example.com/a.png');
      expect(product.category.id, 'c1');
      expect(product.inStock, isTrue);
    });

    test('price dạng số thực được làm tròn về int', () {
      expect(ProductSummary.fromJson(json(price: 490000.0)).price, 490000);
      expect(ProductSummary.fromJson(json(price: 490000.4)).price, 490000);
      expect(ProductSummary.fromJson(json(price: 490000.6)).price, 490001);
    });

    test('stock dạng số thực được đổi về int', () {
      expect(ProductSummary.fromJson(json(stock: 7.0)).stock, 7);
    });

    test('stock = 0 thì hết hàng', () {
      expect(ProductSummary.fromJson(json(stock: 0)).inStock, isFalse);
    });

    test('imageUrl thiếu thì null', () {
      final map = json()..remove('imageUrl');
      expect(ProductSummary.fromJson(map).imageUrl, isNull);
    });
  });

  group('ProductDetail.fromJson', () {
    Map<String, dynamic> json() => {
      'id': 'p1',
      'sku': 'FL-001',
      'name': 'Bó hoa',
      'description': 'Mô tả',
      'price': 350000.0,
      'stock': 5,
      'taxRate': 8,
      'imageUrls': ['a', 'b'],
      'category': categoryJson(),
      'isActive': false,
    };

    test('đọc đủ trường', () {
      final product = ProductDetail.fromJson(json());
      expect(product.description, 'Mô tả');
      expect(product.price, 350000);
      expect(product.taxRate, 8.0);
      expect(product.imageUrls, ['a', 'b']);
      expect(product.isActive, isFalse);
      expect(product.inStock, isTrue);
    });

    test('imageUrls thiếu hoặc null thì rỗng', () {
      final missing = json()..remove('imageUrls');
      expect(ProductDetail.fromJson(missing).imageUrls, isEmpty);
      final nullUrls = json()..['imageUrls'] = null;
      expect(ProductDetail.fromJson(nullUrls).imageUrls, isEmpty);
    });

    test('mặc định taxRate = 0, isActive = true, description null', () {
      final map = json()
        ..remove('taxRate')
        ..remove('isActive')
        ..remove('description');
      final product = ProductDetail.fromJson(map);
      expect(product.taxRate, 0);
      expect(product.isActive, isTrue);
      expect(product.description, isNull);
    });
  });

  group('PagedResult.hasMore', () {
    PagedResult<int> page(int page, int totalPages) => PagedResult(
      items: const [],
      page: page,
      total: 0,
      totalPages: totalPages,
    );

    test('còn trang kế', () => expect(page(1, 3).hasMore, isTrue));
    test('trang cuối', () => expect(page(3, 3).hasMore, isFalse));
    test('không có trang nào', () => expect(page(1, 0).hasMore, isFalse));
    test('trang vượt quá tổng', () => expect(page(4, 3).hasMore, isFalse));
  });

  group('ProductQuery', () {
    test('mặc định chỉ có page, limit, sort', () {
      expect(const ProductQuery().toQueryParameters(page: 1, limit: 20), {
        'page': '1',
        'limit': '20',
        'sort': 'newest',
      });
    });

    test('bỏ search rỗng hoặc toàn khoảng trắng', () {
      for (final search in ['', '   ', '\t\n']) {
        final params = ProductQuery(
          search: search,
        ).toQueryParameters(page: 1, limit: 20);
        expect(params.containsKey('search'), isFalse, reason: '"$search"');
      }
    });

    test('search được trim', () {
      final params = const ProductQuery(
        search: '  hoa hồng ',
      ).toQueryParameters(page: 1, limit: 20);
      expect(params['search'], 'hoa hồng');
    });

    test('bỏ categoryId rỗng, giữ categoryId có giá trị', () {
      expect(
        const ProductQuery(
          categoryId: '',
        ).toQueryParameters(page: 1, limit: 20).containsKey('categoryId'),
        isFalse,
      );
      expect(
        const ProductQuery(
          categoryId: 'abc',
        ).toQueryParameters(page: 1, limit: 20)['categoryId'],
        'abc',
      );
    });

    test('giữ min/max kể cả 0, và sort apiValue', () {
      final params = const ProductQuery(
        minPrice: 0,
        maxPrice: 500000,
        sort: ProductSort.priceDesc,
      ).toQueryParameters(page: 2, limit: 10);
      expect(params, {
        'page': '2',
        'limit': '10',
        'sort': 'price_desc',
        'minPrice': '0',
        'maxPrice': '500000',
      });
    });

    test('hasPriceFilter', () {
      expect(const ProductQuery().hasPriceFilter, isFalse);
      expect(const ProductQuery(minPrice: 1).hasPriceFilter, isTrue);
      expect(const ProductQuery(maxPrice: 1).hasPriceFilter, isTrue);
    });

    group('copyWith', () {
      const base = ProductQuery(
        search: 'a',
        categoryId: 'c',
        minPrice: 1,
        maxPrice: 2,
        sort: ProductSort.priceAsc,
      );

      test('không truyền gì thì giữ nguyên', () {
        expect(base.copyWith(), base);
      });

      test('đặt được từng trường về null', () {
        expect(base.copyWith(search: null).search, isNull);
        expect(base.copyWith(categoryId: null).categoryId, isNull);
        expect(base.copyWith(minPrice: null).minPrice, isNull);
        expect(base.copyWith(maxPrice: null).maxPrice, isNull);
      });

      test('đặt null một trường không ảnh hưởng trường khác', () {
        final next = base.copyWith(search: null);
        expect(next.categoryId, 'c');
        expect(next.minPrice, 1);
        expect(next.maxPrice, 2);
        expect(next.sort, ProductSort.priceAsc);
      });

      test('đổi giá trị và sort', () {
        final next = base.copyWith(search: 'b', sort: ProductSort.newest);
        expect(next.search, 'b');
        expect(next.sort, ProductSort.newest);
      });
    });

    test('== và hashCode theo giá trị', () {
      const a = ProductQuery(search: 'x', minPrice: 1);
      const b = ProductQuery(search: 'x', minPrice: 1);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == const ProductQuery(search: 'y', minPrice: 1), isFalse);
    });
  });
}
