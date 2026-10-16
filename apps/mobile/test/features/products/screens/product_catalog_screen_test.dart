import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/products/data/mock_product_repository.dart';
import 'package:plant_flower_mobile/features/products/data/product_repository.dart';
import 'package:plant_flower_mobile/features/products/screens/product_catalog_screen.dart';
import 'package:plant_flower_mobile/features/products/widgets/catalog/catalog_product_card.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

import '../../../support/controlled_product_repository.dart';
import '../../../support/finders.dart';
import '../../../support/product_test_app.dart';

const _flowers = MockProductRepository.freshFlowers;
const _plants = MockProductRepository.plants;
const _accessories = MockProductRepository.accessories;

Key _chip(Category category) => Key('catalog-category-${category.id}');
Key _card(String id) => Key('catalog-product-$id');
Key _fav(String id) => Key('catalog-favorite-$id');
String _seedId(int n) =>
    '30000000-0000-4000-8000-${n.toString().padLeft(12, '0')}';

const _searchKey = Key('catalog-search');
const _countKey = Key('catalog-count');
const _priceFilterKey = Key('catalog-price-filter');

String _count(WidgetTester tester) => textOf(tester, find.byKey(_countKey));

List<String> _builtIds(WidgetTester tester) => tester
    .widgetList<CatalogProductCard>(find.byType(CatalogProductCard))
    .map((card) => card.product.id)
    .toList();

ProductDetail _detail(
  String id, {
  int stock = 5,
  int price = 100000,
  String? name,
  Category category = _flowers,
}) {
  return ProductDetail(
    id: id,
    sku: 'SKU-$id',
    name: name ?? 'Sản phẩm $id',
    price: price,
    stock: stock,
    taxRate: 8,
    category: category,
  );
}

MockProductRepository _bigRepo([int count = 45]) => MockProductRepository(
  latency: Duration.zero,
  categories: const [testCategory],
  products: generateProducts(count),
);

Future<void> _pumpCatalog(
  WidgetTester tester, {
  ProductRepository? repository,
  String? initialCategoryId,
  Size size = designSize,
  bool settle = true,
  bool withScaffold = false,
}) async {
  Widget screen = ProductCatalogScreen(initialCategoryId: initialCategoryId);
  // Trong app thật màn nằm dưới Scaffold của MainShell; cần cho SnackBar
  if (withScaffold) screen = Scaffold(body: screen);
  await pumpProductApp(tester, screen, repository: repository, size: size);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

ScrollPosition _position(WidgetTester tester) =>
    tester.state<ScrollableState>(find.byType(Scrollable).first).position;

/// Kéo danh sách xuống cho tới khi [done] đúng (tối đa 80 lần).
///
/// Không dùng pumpAndSettle vì footer đã được dựng sẵn (ngoài màn hình) và
/// spinner của nó chạy mãi khi còn trang tiếp theo.
Future<void> _scrollUntil(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 80 && !done(); i++) {
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await pumpFrames(tester, 2);
  }
  expect(done(), isTrue, reason: 'Cuộn hết mà điều kiện vẫn chưa đúng');
}

/// Cuộn tới tận cuối danh sách.
Future<void> _scrollToEnd(WidgetTester tester) async {
  await _scrollUntil(tester, () => _position(tester).extentAfter < 1);
  await pumpFrames(tester, 2);
}

Future<void> _openPriceSheet(WidgetTester tester) async {
  await tester.tap(find.byKey(_priceFilterKey));
  await tester.pumpAndSettle();
}

Future<void> _applyPrice(WidgetTester tester, {String? min, String? max}) async {
  await _openPriceSheet(tester);
  if (min != null) {
    await tester.enterText(find.byKey(const Key('catalog-price-min')), min);
  }
  if (max != null) {
    await tester.enterText(find.byKey(const Key('catalog-price-max')), max);
  }
  await tester.tap(find.byKey(const Key('catalog-price-apply')));
  await tester.pumpAndSettle();
}

Future<void> _selectSort(WidgetTester tester, ProductSort sort) async {
  await tester.tap(find.byKey(const Key('catalog-sort')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key('catalog-sort-${sort.apiValue}')));
  await tester.pumpAndSettle();
}

void main() {
  group('tải dữ liệu', () {
    testWidgets('loading rồi hiện lưới sản phẩm', (tester) async {
      final repo = ControlledProductRepository(categories: const [testCategory]);
      await _pumpCatalog(tester, repository: repo, settle: false);

      expect(find.byKey(const Key('catalog-loading')), findsOneWidget);
      expect(find.byType(CatalogProductCard), findsNothing);
      expect(find.byKey(_countKey), findsNothing);

      repo.calls.single.complete(
        pageOf([summary('a'), summary('b'), summary('c')], total: 3),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('catalog-loading')), findsNothing);
      expect(find.byType(CatalogProductCard), findsNWidgets(3));
      expect(_count(tester), 'Hiển thị 3 tác phẩm');
    });

    testWidgets('khung màn: header, ô tìm kiếm, chip, sắp xếp, lọc giá', (tester) async {
      await _pumpCatalog(tester);

      expect(find.text('Nhà Có Hoa'), findsWidgets);
      expect(find.text('BỘ SƯU TẬP'), findsOneWidget);
      expect(find.byKey(_searchKey), findsOneWidget);
      expect(find.text('Tìm sản phẩm...'), findsOneWidget);
      expect(find.byKey(const Key('catalog-category-all')), findsOneWidget);
      expect(find.byKey(const Key('catalog-sort')), findsOneWidget);
      expect(find.text('Mới nhất'), findsOneWidget);
      expect(find.text('Lọc giá (VNĐ)'), findsOneWidget);
      expect(find.text('Sẵn sàng vận chuyển'), findsOneWidget);
      // Không có nút xoá khi chưa nhập gì
      expect(find.byKey(const Key('catalog-search-clear')), findsNothing);
    });

    testWidgets('header danh mục có logo 26 và avatar', (tester) async {
      await _pumpCatalog(tester);

      expect(
        find.byWidgetPredicate((w) => w.runtimeType.toString() == '_Avatar'),
        findsOneWidget,
      );
      final logos = tester.widgetList<Text>(find.text('Nhà Có Hoa')).toList();
      expect(logos.map((t) => t.style!.fontSize), contains(26));
    });

    testWidgets('catalog-count hiện đúng total của API, không phải số item đã tải', (tester) async {
      final repo = ControlledProductRepository();
      await _pumpCatalog(tester, repository: repo, settle: false);
      repo.calls.single.complete(
        pageOf([summary('a'), summary('b')], total: 45, totalPages: 3),
      );
      await tester.pump();

      expect(_count(tester), 'Hiển thị 45 tác phẩm');
    });

    testWidgets('hiện chip cho từng category + Tất cả', (tester) async {
      await _pumpCatalog(tester);

      expect(find.byKey(const Key('catalog-category-all')), findsOneWidget);
      for (final category in MockProductRepository.defaultCategories) {
        final chip = find.byKey(_chip(category));
        // Chip cuộn ngang: category ngoài màn vẫn tồn tại trong cây
        await tester.ensureVisible(chip);
        expect(chip, findsOneWidget, reason: category.name);
      }
      expect(isChipSelected(tester, const Key('catalog-category-all')), isTrue);
    });

    testWidgets('mặc định hiện 10 sản phẩm seed theo thứ tự mới nhất', (tester) async {
      await _pumpCatalog(tester);

      expect(_count(tester), 'Hiển thị 10 tác phẩm');
      final ids = _builtIds(tester);
      expect(ids.take(4), [_seedId(1), _seedId(2), _seedId(3), _seedId(4)]);
    });

    testWidgets('thẻ sản phẩm có category, tên, giá và trạng thái kho', (tester) async {
      final repo = MockProductRepository(
        latency: Duration.zero,
        products: [
          _detail('in', price: 490000, name: 'Bó hoa A'),
          _detail('out', stock: 0, price: 280000, name: 'Bình B', category: _plants),
        ],
      );
      await _pumpCatalog(tester, repository: repo);

      Finder inCard(String id, Finder match) =>
          find.descendant(of: find.byKey(_card(id)), matching: match);
      expect(inCard('in', find.text('Bó hoa A')), findsOneWidget);
      expect(inCard('in', find.text('Hoa tươi')), findsOneWidget);
      expect(inCard('in', find.text('490.000 ₫')), findsOneWidget);
      expect(inCard('in', find.text('Còn hàng')), findsOneWidget);
      expect(inCard('out', find.text('Cây cảnh')), findsOneWidget);
      expect(inCard('out', find.text('280.000 ₫')), findsOneWidget);
      expect(inCard('out', find.text('Hết hàng')), findsOneWidget);
      expect(inCard('out', find.text('Còn hàng')), findsNothing);
    });

    testWidgets('initialCategoryId chọn sẵn chip và lọc ngay từ request đầu', (tester) async {
      final repo = ControlledProductRepository(
        categories: const [testCategory],
      );
      await _pumpCatalog(
        tester,
        repository: repo,
        initialCategoryId: testCategory.id,
        settle: false,
      );

      expect(repo.calls.single.query.categoryId, testCategory.id);
      repo.calls.single.complete(pageOf([summary('a')]));
      await tester.pumpAndSettle();
      expect(isChipSelected(tester, _chip(testCategory)), isTrue);
      expect(isChipSelected(tester, const Key('catalog-category-all')), isFalse);
    });

    testWidgets('initialCategoryId với Mock: chỉ hiện sản phẩm của category đó', (tester) async {
      await _pumpCatalog(tester, initialCategoryId: _accessories.id);

      expect(_count(tester), 'Hiển thị 3 tác phẩm');
      expect(isChipSelected(tester, _chip(_accessories)), isTrue);
    });
  });

  group('lọc theo category', () {
    testWidgets('chọn chip lọc kết quả, chọn Tất cả trả về đủ', (tester) async {
      await _pumpCatalog(tester);

      await tester.tap(find.byKey(_chip(_flowers)));
      await tester.pumpAndSettle();
      expect(_count(tester), 'Hiển thị 4 tác phẩm');
      expect(isChipSelected(tester, _chip(_flowers)), isTrue);
      expect(isChipSelected(tester, const Key('catalog-category-all')), isFalse);
      expect(
        tester
            .widgetList<CatalogProductCard>(find.byType(CatalogProductCard))
            .every((c) => c.product.category.id == _flowers.id),
        isTrue,
      );

      await tester.tap(find.byKey(const Key('catalog-category-all')));
      await tester.pumpAndSettle();
      expect(_count(tester), 'Hiển thị 10 tác phẩm');
      expect(isChipSelected(tester, const Key('catalog-category-all')), isTrue);
    });

    testWidgets('đổi chip gửi request với categoryId và hiện loading trong lúc chờ', (tester) async {
      final repo = ControlledProductRepository(categories: const [testCategory]);
      await _pumpCatalog(tester, repository: repo, settle: false);
      repo.calls[0].complete(pageOf([summary('a')]));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(_chip(testCategory)));
      await tester.pump();

      expect(repo.calls, hasLength(2));
      expect(repo.calls[1].query.categoryId, testCategory.id);
      expect(repo.calls[1].page, 1);
      expect(find.byKey(const Key('catalog-loading')), findsOneWidget);
      expect(find.byType(CatalogProductCard), findsNothing);

      repo.calls[1].complete(pageOf([summary('b')]));
      await tester.pumpAndSettle();
      expect(find.byKey(_card('b')), findsOneWidget);
    });
  });

  group('tìm kiếm', () {
    testWidgets('debounce: chỉ gọi API sau khi ngừng gõ 400ms', (tester) async {
      final repo = createTestRepository();
      await _pumpCatalog(tester, repository: repo);
      expect(repo.listProductsCalls, 1);

      await tester.enterText(find.byKey(_searchKey), 'tu');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(find.byKey(_searchKey), 'tulip');
      await tester.pump(const Duration(milliseconds: 399));
      expect(repo.listProductsCalls, 1);
      expect(_count(tester), 'Hiển thị 10 tác phẩm');

      await tester.pump(const Duration(milliseconds: 5));
      await tester.pumpAndSettle();

      expect(repo.listProductsCalls, 2);
      expect(_count(tester), 'Hiển thị 1 tác phẩm');
      expect(find.text('Bó Tulip Hà Lan Trắng'), findsOneWidget);
    });

    testWidgets('tìm theo SKU', (tester) async {
      await _pumpCatalog(tester);

      await tester.enterText(find.byKey(_searchKey), 'pl-104');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();

      expect(_builtIds(tester), [_seedId(2)]);
    });

    testWidgets('nhấn tìm kiếm trên bàn phím áp dụng ngay', (tester) async {
      final repo = createTestRepository();
      await _pumpCatalog(tester, repository: repo);

      await tester.enterText(find.byKey(_searchKey), 'tulip');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(repo.listProductsCalls, 2);
      expect(_count(tester), 'Hiển thị 1 tác phẩm');
    });

    testWidgets('nút xoá chỉ hiện khi có chữ, bấm xoá sẽ tải lại tất cả', (tester) async {
      final repo = createTestRepository();
      await _pumpCatalog(tester, repository: repo);

      await tester.enterText(find.byKey(_searchKey), 'tulip');
      await tester.pump();
      expect(find.byKey(const Key('catalog-search-clear')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      expect(_count(tester), 'Hiển thị 1 tác phẩm');

      await tester.tap(find.byKey(const Key('catalog-search-clear')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('catalog-search-clear')), findsNothing);
      expect(tester.widget<TextField>(find.byKey(_searchKey)).controller!.text, '');
      expect(_count(tester), 'Hiển thị 10 tác phẩm');
      expect(repo.listProductsCalls, 3);
    });

    testWidgets('xoá bằng nút khi debounce đang chờ không tạo request thừa', (tester) async {
      final repo = createTestRepository();
      await _pumpCatalog(tester, repository: repo);

      await tester.enterText(find.byKey(_searchKey), 'tulip');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const Key('catalog-search-clear')));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Từ khoá vẫn rỗng như ban đầu nên không có request mới nào
      expect(repo.listProductsCalls, 1);
      expect(_count(tester), 'Hiển thị 10 tác phẩm');
    });

    testWidgets('từ khoá được trim khi gửi lên', (tester) async {
      final repo = ControlledProductRepository();
      await _pumpCatalog(tester, repository: repo, settle: false);
      repo.calls[0].complete(pageOf([summary('a')]));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(_searchKey), '   hồng  ');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      expect(repo.calls[1].query.search, 'hồng');
      repo.calls[1].complete(pageOf([]));
      await tester.pumpAndSettle();
    });
  });

  group('sắp xếp', () {
    testWidgets('menu có 3 lựa chọn', (tester) async {
      await _pumpCatalog(tester);

      await tester.tap(find.byKey(const Key('catalog-sort')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('catalog-sort-newest')), findsOneWidget);
      expect(find.byKey(const Key('catalog-sort-price_asc')), findsOneWidget);
      expect(find.byKey(const Key('catalog-sort-price_desc')), findsOneWidget);
      expect(find.text('Giá tăng dần'), findsOneWidget);
      expect(find.text('Giá giảm dần'), findsOneWidget);
    });

    testWidgets('giá tăng dần: sản phẩm rẻ nhất lên đầu', (tester) async {
      await _pumpCatalog(tester);

      await _selectSort(tester, ProductSort.priceAsc);

      expect(find.text('Giá tăng dần'), findsOneWidget);
      final ids = _builtIds(tester);
      // AC-031 160k, AC-024 195k, AC-018 280k, PL-087 290k
      expect(ids.take(4), [_seedId(10), _seedId(8), _seedId(3), _seedId(5)]);
    });

    testWidgets('giá giảm dần: sản phẩm đắt nhất lên đầu', (tester) async {
      await _pumpCatalog(tester);

      await _selectSort(tester, ProductSort.priceDesc);

      expect(find.text('Giá giảm dần'), findsOneWidget);
      final ids = _builtIds(tester);
      // 620k, 550k, 490k, 420k
      expect(ids.take(4), [_seedId(4), _seedId(9), _seedId(1), _seedId(7)]);
    });

    testWidgets('quay lại Mới nhất khôi phục thứ tự ban đầu', (tester) async {
      await _pumpCatalog(tester);
      await _selectSort(tester, ProductSort.priceDesc);

      await _selectSort(tester, ProductSort.newest);

      expect(find.text('Mới nhất'), findsOneWidget);
      expect(_builtIds(tester).take(2), [_seedId(1), _seedId(2)]);
    });

    testWidgets('đổi sắp xếp gửi sort lên API và về trang 1', (tester) async {
      final repo = ControlledProductRepository();
      await _pumpCatalog(tester, repository: repo, settle: false);
      repo.calls[0].complete(pageOf([summary('a')]));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('catalog-sort')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('catalog-sort-price_asc')));
      await tester.pump();

      expect(repo.calls, hasLength(2));
      expect(repo.calls[1].query.sort, ProductSort.priceAsc);
      expect(repo.calls[1].page, 1);
      repo.calls[1].complete(pageOf([]));
      await tester.pumpAndSettle();
    });
  });

  group('lọc giá', () {
    testWidgets('mở bottom sheet với hai ô trống khi chưa lọc', (tester) async {
      await _pumpCatalog(tester);

      await _openPriceSheet(tester);

      expect(find.text('Lọc theo giá'), findsOneWidget);
      expect(find.byKey(const Key('catalog-price-min')), findsOneWidget);
      expect(find.byKey(const Key('catalog-price-max')), findsOneWidget);
      expect(find.byKey(const Key('catalog-price-apply')), findsOneWidget);
      expect(find.byKey(const Key('catalog-price-clear')), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('catalog-price-min')))
            .controller!
            .text,
        '',
      );
    });

    testWidgets('từ > đến hiện lỗi, sheet không đóng, sửa chữ thì lỗi biến mất', (tester) async {
      final repo = createTestRepository();
      await _pumpCatalog(tester, repository: repo);
      await _openPriceSheet(tester);

      await tester.enterText(find.byKey(const Key('catalog-price-min')), '500000');
      await tester.enterText(find.byKey(const Key('catalog-price-max')), '100000');
      await tester.tap(find.byKey(const Key('catalog-price-apply')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('catalog-price-error')), findsOneWidget);
      expect(find.text('Lọc theo giá'), findsOneWidget);
      expect(repo.listProductsCalls, 1);

      await tester.enterText(find.byKey(const Key('catalog-price-max')), '900000');
      await tester.pump();
      expect(find.byKey(const Key('catalog-price-error')), findsNothing);
    });

    testWidgets('chỉ nhận chữ số: ký tự khác bị chặn', (tester) async {
      await _pumpCatalog(tester);
      await _openPriceSheet(tester);

      await tester.enterText(find.byKey(const Key('catalog-price-min')), '1a2.b3-');

      expect(
        tester
            .widget<TextField>(find.byKey(const Key('catalog-price-min')))
            .controller!
            .text,
        '123',
      );
    });

    testWidgets('áp dụng khoảng giá: lọc kết quả, nút đổi nhãn và sáng lên', (tester) async {
      await _pumpCatalog(tester);
      expect(
        ancestorMaterialColor(tester, _priceFilterKey),
        AppColors.surface,
      );

      await _applyPrice(tester, min: '200000', max: '500000');

      expect(find.text('Lọc theo giá'), findsNothing);
      // 490, 350, 280, 290, 380, 420 nghìn
      expect(_count(tester), 'Hiển thị 6 tác phẩm');
      expect(find.text('200k - 500k'), findsOneWidget);
      expect(find.text('Lọc giá (VNĐ)'), findsNothing);
      expect(
        ancestorMaterialColor(tester, _priceFilterKey),
        AppColors.primaryLight,
      );
    });

    testWidgets('chỉ nhập "từ" hoặc chỉ "đến"', (tester) async {
      await _pumpCatalog(tester);

      await _applyPrice(tester, min: '500000');
      expect(find.text('Từ 500k'), findsOneWidget);
      expect(_count(tester), 'Hiển thị 2 tác phẩm');

      await _applyPrice(tester, min: '', max: '200000');
      expect(find.text('Đến 200k'), findsOneWidget);
      expect(_count(tester), 'Hiển thị 2 tác phẩm');
    });

    testWidgets('mở lại sheet thấy giá trị đang áp dụng', (tester) async {
      await _pumpCatalog(tester);
      await _applyPrice(tester, min: '200000', max: '500000');

      await _openPriceSheet(tester);

      String field(String key) =>
          tester.widget<TextField>(find.byKey(Key(key))).controller!.text;
      expect(field('catalog-price-min'), '200000');
      expect(field('catalog-price-max'), '500000');
    });

    testWidgets('"Xoá lọc" bỏ khoảng giá và trả nút về trạng thái tắt', (tester) async {
      await _pumpCatalog(tester);
      await _applyPrice(tester, min: '200000', max: '500000');

      await _openPriceSheet(tester);
      await tester.tap(find.byKey(const Key('catalog-price-clear')));
      await tester.pumpAndSettle();

      expect(find.text('Lọc giá (VNĐ)'), findsOneWidget);
      expect(_count(tester), 'Hiển thị 10 tác phẩm');
      expect(
        ancestorMaterialColor(tester, _priceFilterKey),
        AppColors.surface,
      );
    });

    testWidgets('áp dụng khi để trống cả hai ô cũng bỏ lọc', (tester) async {
      await _pumpCatalog(tester);
      await _applyPrice(tester, min: '200000', max: '500000');

      await _openPriceSheet(tester);
      await tester.enterText(find.byKey(const Key('catalog-price-min')), '');
      await tester.enterText(find.byKey(const Key('catalog-price-max')), '');
      await tester.tap(find.byKey(const Key('catalog-price-apply')));
      await tester.pumpAndSettle();

      expect(find.text('Lọc giá (VNĐ)'), findsOneWidget);
      expect(_count(tester), 'Hiển thị 10 tác phẩm');
    });

    testWidgets('đóng sheet bằng cách chạm ra ngoài không đổi bộ lọc', (tester) async {
      final repo = createTestRepository();
      await _pumpCatalog(tester, repository: repo);
      await _openPriceSheet(tester);
      await tester.enterText(find.byKey(const Key('catalog-price-min')), '999');

      await tester.tapAt(const Offset(195, 60));
      await tester.pumpAndSettle();

      expect(find.text('Lọc theo giá'), findsNothing);
      expect(find.text('Lọc giá (VNĐ)'), findsOneWidget);
      expect(repo.listProductsCalls, 1);
    });

    testWidgets('nhấn xong trên ô "đến" áp dụng luôn', (tester) async {
      await _pumpCatalog(tester);
      await _openPriceSheet(tester);

      await tester.enterText(find.byKey(const Key('catalog-price-max')), '200000');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Lọc theo giá'), findsNothing);
      expect(find.text('Đến 200k'), findsOneWidget);
    });

    testWidgets('sheet không tràn khi bàn phím che một phần màn hình', (tester) async {
      await _pumpCatalog(tester);
      await _openPriceSheet(tester);

      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('catalog-price-apply')), findsOneWidget);
    });

    testWidgets('giá đã lọc mà không có kết quả hiện trạng thái rỗng', (tester) async {
      await _pumpCatalog(tester);

      await _applyPrice(tester, min: '1', max: '2');

      expect(find.byKey(const Key('catalog-empty')), findsOneWidget);
      expect(find.text('Không tìm thấy tác phẩm phù hợp'), findsOneWidget);
    });
  });

  group('trạng thái rỗng', () {
    testWidgets('tìm không thấy: hiện từ khoá và nút xoá bộ lọc', (tester) async {
      await _pumpCatalog(tester);

      await tester.enterText(find.byKey(_searchKey), 'zzz');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('catalog-empty')), findsOneWidget);
      expect(find.text('Không tìm thấy tác phẩm phù hợp'), findsOneWidget);
      expect(find.textContaining('“zzz”'), findsOneWidget);
      expect(find.byKey(const Key('catalog-reset-filters')), findsOneWidget);
      expect(find.byKey(_countKey), findsNothing);
    });

    testWidgets('"Xóa tất cả bộ lọc" xoá mọi bộ lọc, ô tìm kiếm và sắp xếp', (tester) async {
      final repo = createTestRepository();
      await _pumpCatalog(tester, repository: repo);
      await _selectSort(tester, ProductSort.priceAsc);
      await tester.tap(find.byKey(_chip(_plants)));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(_searchKey), 'zzz');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('catalog-empty')), findsOneWidget);

      await tester.tap(find.byKey(const Key('catalog-reset-filters')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('catalog-empty')), findsNothing);
      expect(_count(tester), 'Hiển thị 10 tác phẩm');
      expect(tester.widget<TextField>(find.byKey(_searchKey)).controller!.text, '');
      expect(isChipSelected(tester, const Key('catalog-category-all')), isTrue);
      expect(find.text('Mới nhất'), findsOneWidget);
      expect(_builtIds(tester).first, _seedId(1));
    });

    testWidgets('rỗng do bộ lọc khác từ khoá dùng nội dung "bộ lọc hiện tại"', (tester) async {
      await _pumpCatalog(tester);

      await _applyPrice(tester, min: '1', max: '2');

      expect(find.textContaining('bộ lọc hiện tại'), findsOneWidget);
      await tester.tap(find.byKey(const Key('catalog-reset-filters')));
      await tester.pumpAndSettle();
      expect(_count(tester), 'Hiển thị 10 tác phẩm');
      expect(find.text('Lọc giá (VNĐ)'), findsOneWidget);
    });

    testWidgets('không có sản phẩm và không lọc: không có nút xoá bộ lọc', (tester) async {
      final repo = MockProductRepository(
        latency: Duration.zero,
        products: const [],
      );
      await _pumpCatalog(tester, repository: repo);

      expect(find.byKey(const Key('catalog-empty')), findsOneWidget);
      expect(find.text('Chưa có sản phẩm nào'), findsOneWidget);
      expect(find.byKey(const Key('catalog-reset-filters')), findsNothing);
    });
  });

  group('lỗi', () {
    testWidgets('lỗi hiện thông báo + Thử lại, thử lại thành công', (tester) async {
      final repo = ControlledProductRepository();
      await _pumpCatalog(tester, repository: repo, settle: false);

      repo.calls[0].fail(const ProductFailure('Máy chủ đang bận.'));
      await tester.pumpAndSettle();

      expect(find.text('Không tải được sản phẩm'), findsOneWidget);
      expect(find.text('Máy chủ đang bận.'), findsOneWidget);
      expect(find.byKey(const Key('catalog-retry')), findsOneWidget);
      expect(find.byType(CatalogProductCard), findsNothing);

      await tester.tap(find.byKey(const Key('catalog-retry')));
      await tester.pump();
      expect(find.byKey(const Key('catalog-loading')), findsOneWidget);
      repo.calls[1].complete(pageOf([summary('a')]));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('catalog-retry')), findsNothing);
      expect(find.byKey(_card('a')), findsOneWidget);
    });

    testWidgets('lỗi mạng hiện câu hướng dẫn kiểm tra kết nối', (tester) async {
      final repo = ControlledProductRepository();
      await _pumpCatalog(tester, repository: repo, settle: false);

      repo.calls[0].fail(const ProductFailure('raw', offline: true));
      await tester.pumpAndSettle();

      expect(
        find.text('Không có kết nối mạng. Vui lòng kiểm tra kết nối và thử lại.'),
        findsOneWidget,
      );
      expect(find.text('raw'), findsNothing);
    });

    testWidgets('lỗi lặp lại ở lần thử lại vẫn hiện nút Thử lại', (tester) async {
      final repo = ControlledProductRepository();
      await _pumpCatalog(tester, repository: repo, settle: false);
      repo.calls[0].fail(const ProductFailure('lỗi 1'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('catalog-retry')));
      await tester.pump();
      repo.calls[1].fail(const ProductFailure('lỗi 2'));
      await tester.pumpAndSettle();

      expect(find.text('lỗi 2'), findsOneWidget);
      expect(find.byKey(const Key('catalog-retry')), findsOneWidget);
    });

    testWidgets('lỗi khi đổi bộ lọc vẫn cho phép đổi bộ lọc khác', (tester) async {
      final repo = createTestRepository();
      await _pumpCatalog(tester, repository: repo);
      repo.nextFailure = const ProductFailure('lỗi tạm');

      await tester.tap(find.byKey(_chip(_flowers)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('catalog-retry')), findsOneWidget);

      // Ô tìm kiếm, chip vẫn dùng được khi đang ở trạng thái lỗi
      await tester.tap(find.byKey(_chip(_plants)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('catalog-retry')), findsNothing);
      expect(_count(tester), 'Hiển thị 3 tác phẩm');
    });
  });

  group('phân trang vô hạn', () {
    PagedResult<ProductSummary> page(int from, int to, {int p = 1}) => pageOf(
      [for (var i = from; i <= to; i++) summary('p$i')],
      page: p,
      total: 40,
      totalPages: 2,
    );

    testWidgets('trang đầu 20 sản phẩm, cuộn xuống tải thêm cho đến hết', (tester) async {
      final repo = _bigRepo();
      await _pumpCatalog(tester, repository: repo, settle: false);
      await pumpFrames(tester);

      expect(repo.listProductsCalls, 1);
      expect(_count(tester), 'Hiển thị 45 tác phẩm');

      await _scrollUntil(tester, () => repo.listProductsCalls == 3);
      await _scrollToEnd(tester);
      await tester.pumpAndSettle();

      expect(repo.listProductsCalls, 3);
      expect(find.text('Đang hiển thị tất cả sản phẩm hiện có'), findsOneWidget);
      expect(find.byKey(const Key('catalog-loading-more')), findsNothing);
      // Sản phẩm cuối cùng (45) đã được dựng và nằm trong màn hình
      expect(find.byKey(_card('p045')), findsOneWidget);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, 100000));
      await tester.pumpAndSettle();
      expect(_count(tester), 'Hiển thị 45 tác phẩm');
    });

    testWidgets('không tải thêm khi chưa cuộn gần cuối', (tester) async {
      final repo = _bigRepo();
      await _pumpCatalog(tester, repository: repo, settle: false);
      await pumpFrames(tester);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await pumpFrames(tester);

      expect(repo.listProductsCalls, 1);
    });

    testWidgets('chỉ 1 trang: không có spinner, hiện footer kết thúc', (tester) async {
      final repo = _bigRepo(7);
      await _pumpCatalog(tester, repository: repo);

      await _scrollToEnd(tester);
      await tester.pumpAndSettle();

      expect(repo.listProductsCalls, 1);
      expect(find.byKey(const Key('catalog-loading-more')), findsNothing);
      expect(find.text('Đang hiển thị tất cả sản phẩm hiện có'), findsOneWidget);
    });

    testWidgets('nút lên đầu trang cuộn về đầu danh sách', (tester) async {
      final repo = _bigRepo(30);
      await _pumpCatalog(tester, repository: repo, settle: false);
      await pumpFrames(tester);
      await _scrollUntil(tester, () => repo.listProductsCalls == 2);
      await _scrollToEnd(tester);
      await tester.pumpAndSettle();
      expect(_position(tester).pixels, greaterThan(500));

      await tester.tap(find.byKey(const Key('catalog-scroll-top')));
      await tester.pumpAndSettle();

      expect(_position(tester).pixels, 0);
      expect(find.byKey(_searchKey), findsOneWidget);
    });

    testWidgets('spinner tải thêm hiện khi chờ trang kế', (tester) async {
      final repo = ControlledProductRepository();
      await _pumpCatalog(tester, repository: repo, settle: false);
      repo.calls[0].complete(page(1, 20));
      await pumpFrames(tester);
      expect(repo.calls, hasLength(1));

      await _scrollUntil(tester, () => repo.calls.length == 2);
      expect(repo.calls[1].page, 2);
      await _scrollToEnd(tester);
      expect(find.byKey(const Key('catalog-loading-more')), findsOneWidget);

      repo.calls[1].complete(page(21, 40, p: 2));
      await pumpFrames(tester);
      await _scrollToEnd(tester);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('catalog-loading-more')), findsNothing);
      expect(find.text('Đang hiển thị tất cả sản phẩm hiện có'), findsOneWidget);
      expect(find.byKey(_card('p40')), findsOneWidget);
    });

    testWidgets(
      'footer nằm ngoài màn hình không giữ animation chạy liên tục',
      (tester) async {
        final repo = _bigRepo();
        await _pumpCatalog(tester, repository: repo, settle: false);
        await pumpFrames(tester);

        // Còn trang kế nhưng footer (spinner) chưa cuộn tới: không nên có
        // Ticker nào đang đặt lịch khung hình.
        expect(tester.binding.transientCallbackCount, 0);
      },
    );

    testWidgets('còn trang kế nhưng chưa tải: màn nghỉ được (pumpAndSettle), không có spinner', (tester) async {
      final repo = _bigRepo();
      await _pumpCatalog(tester, repository: repo);

      expect(repo.listProductsCalls, 1);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byKey(const Key('catalog-loading-more')), findsNothing);
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('danh sách ngắn hơn màn hình vẫn tự tải trang kế', (tester) async {
      final repo = ControlledProductRepository();
      await _pumpCatalog(tester, repository: repo, settle: false);

      repo.calls[0].complete(
        pageOf([summary('a'), summary('b')], total: 4, totalPages: 2),
      );
      await pumpFrames(tester);

      expect(repo.calls, hasLength(2));
      expect(repo.calls[1].page, 2);
      repo.calls[1].complete(
        pageOf([summary('c'), summary('d')], page: 2, total: 4, totalPages: 2),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CatalogProductCard), findsNWidgets(4));
    });

    testWidgets('lỗi tải thêm giữ danh sách, hiện Thử lại, thử lại tải tiếp', (tester) async {
      final repo = ControlledProductRepository();
      await _pumpCatalog(tester, repository: repo, settle: false);
      repo.calls[0].complete(page(1, 20));
      await pumpFrames(tester);
      await _scrollUntil(tester, () => repo.calls.length == 2);

      repo.calls[1].fail(const ProductFailure('Rớt mạng', offline: true));
      await pumpFrames(tester);
      await _scrollToEnd(tester);

      expect(
        find.text('Mất kết nối mạng, chưa tải thêm được sản phẩm.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('catalog-load-more-retry')), findsOneWidget);
      expect(find.byKey(_card('p20')), findsOneWidget);
      expect(find.byKey(const Key('catalog-loading-more')), findsNothing);
      // Không tự gọi lại khi đang lỗi, dù người dùng tiếp tục cuộn
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 100));
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await pumpFrames(tester);
      expect(repo.calls, hasLength(2));

      await tester.tap(find.byKey(const Key('catalog-load-more-retry')));
      await pumpFrames(tester, 2);
      expect(repo.calls, hasLength(3));
      expect(repo.calls[2].page, 2);
      expect(find.byKey(const Key('catalog-load-more-retry')), findsNothing);

      repo.calls[2].complete(page(21, 40, p: 2));
      await pumpFrames(tester);
      await _scrollToEnd(tester);
      await tester.pumpAndSettle();
      expect(find.text('Đang hiển thị tất cả sản phẩm hiện có'), findsOneWidget);
      expect(find.byKey(_card('p40')), findsOneWidget);
    });

    testWidgets('lỗi tải thêm không phải offline hiện message của server', (tester) async {
      final repo = ControlledProductRepository();
      await _pumpCatalog(tester, repository: repo, settle: false);
      repo.calls[0].complete(page(1, 20));
      await pumpFrames(tester);
      await _scrollUntil(tester, () => repo.calls.length == 2);

      repo.calls[1].fail(const ProductFailure('Server quá tải'));
      await pumpFrames(tester);
      await _scrollToEnd(tester);

      expect(find.text('Server quá tải'), findsOneWidget);
      expect(find.byKey(const Key('catalog-load-more-retry')), findsOneWidget);
    });

    testWidgets('đổi bộ lọc khi đang tải thêm: trang cũ về muộn không chen vào danh sách mới', (tester) async {
      final repo = ControlledProductRepository(categories: const [testCategory]);
      await _pumpCatalog(tester, repository: repo, settle: false);
      repo.calls[0].complete(page(1, 20));
      await pumpFrames(tester);
      await _scrollUntil(tester, () => repo.calls.length == 2);

      // Cuộn lên đầu để chạm chip rồi đổi bộ lọc
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 100000));
      await pumpFrames(tester);
      await tester.tap(find.byKey(_chip(testCategory)));
      await pumpFrames(tester, 2);
      expect(repo.calls, hasLength(3));

      repo.calls[1].complete(page(21, 40, p: 2));
      await pumpFrames(tester);
      repo.calls[2].complete(pageOf([summary('only')], total: 1));
      await pumpFrames(tester);

      expect(find.byType(CatalogProductCard), findsOneWidget);
      expect(find.byKey(_card('only')), findsOneWidget);
      expect(_count(tester), 'Hiển thị 1 tác phẩm');
    });
  });

  group('yêu thích', () {
    testWidgets('chạm tim đổi icon và tooltip, chạm lần nữa bỏ yêu thích', (tester) async {
      await _pumpCatalog(tester);
      final id = _seedId(1);
      Finder icon(IconData data) =>
          find.descendant(of: find.byKey(_fav(id)), matching: find.byIcon(data));

      expect(icon(Icons.favorite_border), findsOneWidget);
      expect(icon(Icons.favorite), findsNothing);
      expect(
        tester.widget<IconButton>(find.byKey(_fav(id))).tooltip,
        'Thêm vào yêu thích',
      );

      await tester.tap(find.byKey(_fav(id)));
      await tester.pump();
      expect(icon(Icons.favorite), findsOneWidget);
      expect(icon(Icons.favorite_border), findsNothing);
      expect(
        tester.widget<IconButton>(find.byKey(_fav(id))).tooltip,
        'Bỏ yêu thích',
      );

      await tester.tap(find.byKey(_fav(id)));
      await tester.pump();
      expect(icon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('chỉ sản phẩm được chạm đổi trạng thái, không mở chi tiết', (tester) async {
      await _pumpCatalog(tester);

      await tester.tap(find.byKey(_fav(_seedId(2))));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byKey(const Key('detail-header')), findsNothing);
    });

    testWidgets('trạng thái tim giữ nguyên sau khi đổi bộ lọc', (tester) async {
      await _pumpCatalog(tester);
      await tester.tap(find.byKey(_fav(_seedId(1))));
      await tester.pump();

      await _selectSort(tester, ProductSort.priceDesc);
      await _selectSort(tester, ProductSort.newest);

      expect(
        find.descendant(
          of: find.byKey(_fav(_seedId(1))),
          matching: find.byIcon(Icons.favorite),
        ),
        findsOneWidget,
      );
    });
  });

  group('điều hướng', () {
    testWidgets('chạm thẻ mở chi tiết đúng sản phẩm, back quay lại giữ bộ lọc', (tester) async {
      await _pumpCatalog(tester);
      await tester.enterText(find.byKey(_searchKey), 'tulip');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(_card(_seedId(4))));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('detail-header')), findsOneWidget);
      expect(textOf(tester, find.byKey(const Key('detail-name'))), 'Bó Tulip Hà Lan Trắng');
      expect(textOf(tester, find.byKey(const Key('detail-price'))), '620.000 ₫');

      await tester.tap(find.byKey(const Key('header-back')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('detail-header')), findsNothing);
      expect(tester.widget<TextField>(find.byKey(_searchKey)).controller!.text, 'tulip');
      expect(_count(tester), 'Hiển thị 1 tác phẩm');
    });

    testWidgets('chạm thẻ hết hàng vẫn mở được chi tiết', (tester) async {
      await _pumpCatalog(tester);
      await tester.tap(find.byKey(_chip(_flowers)));
      await tester.pumpAndSettle();
      final outOfStock = _seedId(9);
      await tester.ensureVisible(find.byKey(_card(outOfStock)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(_card(outOfStock)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('detail-header')), findsOneWidget);
      expect(find.text('Hết hàng'), findsWidgets);
    });

    testWidgets('khi được push (có thể quay lại) hiện nút back và pop khi chạm', (tester) async {
      await pumpProductApp(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const Key('launcher'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ProductCatalogScreen(),
                  ),
                ),
                child: const Text('Mở'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('launcher')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('catalog-back')), findsOneWidget);
      await tester.tap(find.byKey(const Key('catalog-back')));
      await tester.pumpAndSettle();

      expect(find.byType(ProductCatalogScreen), findsNothing);
      expect(find.byKey(const Key('launcher')), findsOneWidget);
    });
  });

  group('kéo để làm mới', () {
    testWidgets('kéo xuống tải lại, giữ nguyên bộ lọc', (tester) async {
      final repo = createTestRepository();
      await _pumpCatalog(tester, repository: repo);
      await tester.tap(find.byKey(_chip(_flowers)));
      await tester.pumpAndSettle();
      final before = repo.listProductsCalls;

      await tester.drag(find.byKey(_countKey), const Offset(0, 350));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(repo.listProductsCalls, before + 1);
      expect(_count(tester), 'Hiển thị 4 tác phẩm');
      expect(isChipSelected(tester, _chip(_flowers)), isTrue);
    });

    testWidgets('làm mới thất bại: giữ danh sách cũ và báo bằng SnackBar', (tester) async {
      final repo = createTestRepository();
      await _pumpCatalog(tester, repository: repo, withScaffold: true);
      repo.nextFailure = const ProductFailure('lỗi');

      await tester.drag(find.byKey(_countKey), const Offset(0, 350));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('Không thể làm mới. Vui lòng thử lại.'), findsOneWidget);
      expect(_count(tester), 'Hiển thị 10 tác phẩm');
      expect(find.byKey(const Key('catalog-retry')), findsNothing);
    });
  });
}
