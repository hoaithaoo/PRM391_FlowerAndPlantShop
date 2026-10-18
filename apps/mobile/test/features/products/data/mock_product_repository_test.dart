import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/products/data/mock_product_repository.dart';
import 'package:plant_flower_mobile/features/products/data/product_repository.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';

const _flowers = MockProductRepository.freshFlowers;
const _plants = MockProductRepository.plants;

ProductDetail _product(
  String id, {
  String? sku,
  String? name,
  int price = 100000,
  int stock = 5,
  Category category = _flowers,
  bool isActive = true,
}) {
  return ProductDetail(
    id: id,
    sku: sku ?? 'SKU-$id',
    name: name ?? 'Sản phẩm $id',
    price: price,
    stock: stock,
    taxRate: 8,
    category: category,
    isActive: isActive,
  );
}

MockProductRepository _repo(List<ProductDetail> products) =>
    MockProductRepository(latency: Duration.zero, products: products);

void main() {
  final repository = MockProductRepository(latency: Duration.zero);

  group('listCategories', () {
    test('trả về 3 danh mục mặc định, không sửa được', () async {
      final categories = await repository.listCategories();
      expect(categories.map((c) => c.name), ['Hoa tươi', 'Cây cảnh', 'Phụ kiện']);
      expect(() => categories.add(_flowers), throwsUnsupportedError);
    });
  });

  group('listProducts - lọc', () {
    test('lọc theo category, giá và sắp xếp giá tăng dần', () async {
      final result = await repository.listProducts(
        const ProductQuery(
          categoryId: '20000000-0000-4000-8000-000000000001',
          maxPrice: 500000,
          sort: ProductSort.priceAsc,
        ),
      );

      expect(result.items.map((p) => p.price), [380000, 490000]);
      expect(result.total, 2);
    });

    test('mặc định trả cả 10 sản phẩm seed theo thứ tự mới nhất', () async {
      final result = await repository.listProducts(const ProductQuery());
      expect(result.total, 10);
      expect(result.items.first.sku, 'FL-092');
      expect(result.items.last.sku, 'AC-031');
    });

    test('lọc theo category chỉ trả đúng category đó', () async {
      final result = await repository.listProducts(
        ProductQuery(categoryId: _plants.id),
      );
      expect(result.items, isNotEmpty);
      expect(result.items.every((p) => p.category.id == _plants.id), isTrue);
    });

    test('tìm theo tên không phân biệt hoa thường', () async {
      final result = await repository.listProducts(
        const ProductQuery(search: 'TULIP'),
      );
      expect(result.items.map((p) => p.sku), ['FL-115']);
    });

    test('tìm theo SKU không phân biệt hoa thường', () async {
      final result = await repository.listProducts(
        const ProductQuery(search: 'pl-087'),
      );
      expect(result.items.map((p) => p.name), ['Cây Lưỡi Hổ Viền Vàng']);
    });

    test('search được trim và search toàn khoảng trắng bị bỏ qua', () async {
      final trimmed = await repository.listProducts(
        const ProductQuery(search: '  tulip  '),
      );
      expect(trimmed.total, 1);
      final blank = await repository.listProducts(
        const ProductQuery(search: '   '),
      );
      expect(blank.total, 10);
    });

    test('không có kết quả thì rỗng và totalPages = 0', () async {
      final result = await repository.listProducts(
        const ProductQuery(search: 'không-có-sản-phẩm-này'),
      );
      expect(result.items, isEmpty);
      expect(result.total, 0);
      expect(result.totalPages, 0);
      expect(result.hasMore, isFalse);
    });

    test('khoảng giá gồm cả hai biên', () async {
      final result = await repository.listProducts(
        const ProductQuery(minPrice: 280000, maxPrice: 350000),
      );
      expect(result.items.map((p) => p.price).toSet(), {280000, 290000, 350000});
    });

    test('chỉ có minPrice hoặc chỉ có maxPrice', () async {
      final min = await repository.listProducts(
        const ProductQuery(minPrice: 550000),
      );
      expect(min.items.map((p) => p.price).toSet(), {550000, 620000});
      final max = await repository.listProducts(
        const ProductQuery(maxPrice: 195000),
      );
      expect(max.items.map((p) => p.price).toSet(), {160000, 195000});
    });

    test('kết hợp category + search + giá', () async {
      final result = await repository.listProducts(
        ProductQuery(
          categoryId: _flowers.id,
          search: 'bó',
          minPrice: 400000,
        ),
      );
      expect(result.items.map((p) => p.sku).toSet(), {
        'FL-092',
        'FL-115',
        'FL-131',
      });
    });

    test('bỏ qua sản phẩm không còn bán (isActive = false)', () async {
      final repo = _repo([
        _product('1'),
        _product('2', isActive: false),
        _product('3'),
      ]);
      final result = await repo.listProducts(const ProductQuery());
      expect(result.items.map((p) => p.id), ['1', '3']);
      expect(result.total, 2);
    });

    test('summary giữ nguyên giá, tồn kho, category và ảnh đầu tiên', () async {
      final repo = _repo([
        ProductDetail(
          id: '1',
          sku: 'A',
          name: 'A',
          price: 123000,
          stock: 0,
          taxRate: 8,
          category: _plants,
          imageUrls: const ['u1', 'u2'],
        ),
      ]);
      final summary = (await repo.listProducts(const ProductQuery())).items.single;
      expect(summary.price, 123000);
      expect(summary.stock, 0);
      expect(summary.inStock, isFalse);
      expect(summary.category, _plants);
      expect(summary.imageUrl, 'u1');
    });
  });

  group('listProducts - sắp xếp', () {
    test('giá tăng dần', () async {
      final result = await repository.listProducts(
        const ProductQuery(sort: ProductSort.priceAsc),
      );
      final prices = result.items.map((p) => p.price).toList();
      expect(prices, [...prices]..sort());
      expect(prices.first, 160000);
    });

    test('giá giảm dần', () async {
      final result = await repository.listProducts(
        const ProductQuery(sort: ProductSort.priceDesc),
      );
      final prices = result.items.map((p) => p.price).toList();
      expect(prices, ([...prices]..sort()).reversed.toList());
      expect(prices.first, 620000);
    });

    test('cùng giá thì tie-break theo id tăng dần ở cả hai chiều', () async {
      final repo = _repo([
        _product('c', price: 100000),
        _product('a', price: 100000),
        _product('b', price: 100000),
        _product('z', price: 50000),
      ]);
      final asc = await repo.listProducts(
        const ProductQuery(sort: ProductSort.priceAsc),
      );
      expect(asc.items.map((p) => p.id), ['z', 'a', 'b', 'c']);
      final desc = await repo.listProducts(
        const ProductQuery(sort: ProductSort.priceDesc),
      );
      expect(desc.items.map((p) => p.id), ['a', 'b', 'c', 'z']);
    });

    test('mới nhất giữ thứ tự khai báo (không sắp theo id)', () async {
      final repo = _repo([_product('c'), _product('a'), _product('b')]);
      final result = await repo.listProducts(const ProductQuery());
      expect(result.items.map((p) => p.id), ['c', 'a', 'b']);
    });
  });

  group('listProducts - phân trang', () {
    test('phân trang trả đúng totalPages và hasMore', () async {
      final first = await repository.listProducts(const ProductQuery(), limit: 4);
      final last = await repository.listProducts(
        const ProductQuery(),
        page: 3,
        limit: 4,
      );

      expect(first.totalPages, 3);
      expect(first.hasMore, isTrue);
      expect(last.items, hasLength(2));
      expect(last.hasMore, isFalse);
    });

    test('các trang liên tiếp không trùng và ghép lại đủ tổng', () async {
      final ids = <String>[];
      for (var page = 1; page <= 4; page++) {
        final result = await repository.listProducts(
          const ProductQuery(),
          page: page,
          limit: 3,
        );
        expect(result.page, page);
        ids.addAll(result.items.map((p) => p.id));
      }
      expect(ids, hasLength(10));
      expect(ids.toSet(), hasLength(10));
    });

    test('trang vượt quá tổng trả danh sách rỗng, hasMore = false', () async {
      final result = await repository.listProducts(
        const ProductQuery(),
        page: 9,
        limit: 4,
      );
      expect(result.items, isEmpty);
      expect(result.total, 10);
      expect(result.hasMore, isFalse);
    });

    test('limit lớn hơn tổng chỉ có 1 trang', () async {
      final result = await repository.listProducts(const ProductQuery());
      expect(result.totalPages, 1);
      expect(result.hasMore, isFalse);
    });
  });

  group('getProduct', () {
    test('trả về đúng sản phẩm', () async {
      final product = await repository.getProduct(
        '30000000-0000-4000-8000-000000000004',
      );
      expect(product.sku, 'FL-115');
    });

    test('ném notFound với id không tồn tại', () {
      expect(
        repository.getProduct('khong-ton-tai'),
        throwsA(
          isA<ProductFailure>().having((f) => f.notFound, 'notFound', true),
        ),
      );
    });

    test('ném notFound với sản phẩm không còn bán', () {
      final repo = _repo([_product('1', isActive: false)]);
      expect(
        repo.getProduct('1'),
        throwsA(
          isA<ProductFailure>().having((f) => f.notFound, 'notFound', true),
        ),
      );
    });
  });

  group('nextFailure và bộ đếm', () {
    test('nextFailure làm lần gọi kế tiếp thất bại rồi tự xoá', () async {
      final repo = MockProductRepository(latency: Duration.zero);
      repo.nextFailure = const ProductFailure('Hỏng', offline: true);

      await expectLater(
        repo.listProducts(const ProductQuery()),
        throwsA(
          isA<ProductFailure>()
              .having((f) => f.message, 'message', 'Hỏng')
              .having((f) => f.offline, 'offline', isTrue),
        ),
      );
      expect(repo.nextFailure, isNull);
      expect((await repo.listProducts(const ProductQuery())).total, 10);
    });

    test('nextFailure áp dụng cho cả listCategories và getProduct', () async {
      final repo = MockProductRepository(latency: Duration.zero);
      repo.nextFailure = const ProductFailure('A');
      await expectLater(repo.listCategories(), throwsA(isA<ProductFailure>()));
      repo.nextFailure = const ProductFailure('B');
      await expectLater(
        repo.getProduct('30000000-0000-4000-8000-000000000001'),
        throwsA(isA<ProductFailure>()),
      );
    });

    test('listProductsCalls đếm cả lần gọi thất bại', () async {
      final repo = MockProductRepository(latency: Duration.zero);
      expect(repo.listProductsCalls, 0);
      await repo.listProducts(const ProductQuery());
      expect(repo.listProductsCalls, 1);
      repo.nextFailure = const ProductFailure('x');
      await expectLater(
        repo.listProducts(const ProductQuery()),
        throwsA(isA<ProductFailure>()),
      );
      expect(repo.listProductsCalls, 2);
    });
  });
}
