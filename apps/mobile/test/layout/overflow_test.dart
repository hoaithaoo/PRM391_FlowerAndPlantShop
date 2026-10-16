import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/app/main_shell.dart';
import 'package:plant_flower_mobile/features/products/data/mock_product_repository.dart';
import 'package:plant_flower_mobile/features/products/data/product_repository.dart';
import 'package:plant_flower_mobile/features/products/product_routes.dart';
import 'package:plant_flower_mobile/features/products/screens/home_screen.dart';
import 'package:plant_flower_mobile/features/products/screens/product_catalog_screen.dart';
import 'package:plant_flower_mobile/features/products/screens/product_detail_screen.dart';
import 'package:plant_flower_mobile/features/products/widgets/home/home_story_card.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';

import '../support/controlled_product_repository.dart';
import '../support/finders.dart';
import '../support/gated_detail_repository.dart';
import '../support/product_test_app.dart';

/// Tên sản phẩm, category, SKU rất dài để ép tràn dòng.
const _longName =
    'Bó Hoa Bạch Hồng Étoile Phối Greenery Khuynh Diệp Cao Cấp Nhập Khẩu '
    'Ecuador Phiên Bản Giới Hạn Mùa Xuân';
const _longCategory = 'Danh mục hoa tươi nhập khẩu cao cấp theo mùa';

ProductDetail _stress(
  String id, {
  int stock = 12,
  int price = 1234567890,
  List<String> imageUrls = const [],
  String? description,
}) {
  return ProductDetail(
    id: id,
    sku: 'VERY-LONG-SKU-CODE-$id-0000000000',
    name: _longName,
    description:
        description ??
        'Mô tả rất dài. ' * 60,
    price: price,
    stock: stock,
    taxRate: 8,
    category: const Category(id: 'long-cat', name: _longCategory),
    imageUrls: imageUrls,
  );
}

MockProductRepository _stressRepo({int stock = 12, int count = 30}) {
  return MockProductRepository(
    latency: Duration.zero,
    categories: const [
      Category(id: 'long-cat', name: _longCategory),
      MockProductRepository.freshFlowers,
      MockProductRepository.plants,
      MockProductRepository.accessories,
    ],
    products: [
      for (var i = 1; i <= count; i++)
        _stress('s$i', stock: i % 5 == 0 ? 0 : stock),
    ],
  );
}

void _expectNoOverflow(WidgetTester tester, String where) {
  expect(tester.takeException(), isNull, reason: 'Overflow/lỗi layout tại $where');
}

/// Cuộn hết màn qua [scrollable], kiểm tra không lỗi sau mỗi bước.
Future<void> _scrollThrough(
  WidgetTester tester,
  Finder scrollable, {
  required String label,
  bool settle = true,
}) async {
  Future<void> pump() => settle ? tester.pumpAndSettle() : pumpFrames(tester, 2);

  await pump();
  _expectNoOverflow(tester, '$label (đầu trang)');
  final isScrollable = scrollable.evaluate().first.widget is Scrollable;
  final inner = isScrollable
      ? scrollable
      : find.descendant(of: scrollable, matching: find.byType(Scrollable)).first;
  final position = tester.state<ScrollableState>(inner).position;
  for (var i = 0; i < 60 && position.extentAfter > 0.5; i++) {
    await tester.drag(scrollable, const Offset(0, -260));
    await pump();
    _expectNoOverflow(tester, '$label (bước cuộn $i)');
  }
  // Về đầu trang để chắc chắn phần đầu vẫn ổn sau khi dựng lại
  position.jumpTo(0);
  await pump();
  _expectNoOverflow(tester, '$label (về đầu trang)');
}

Finder get _homeScrollable => find
    .descendant(of: find.byType(HomeScreen), matching: find.byType(Scrollable))
    .first;

Finder get _catalogScrollable => find
    .descendant(
      of: find.byType(ProductCatalogScreen),
      matching: find.byType(Scrollable),
    )
    .first;

Future<void> _openDetailScreen(
  WidgetTester tester,
  ProductRepository repository,
  String id, {
  Size size = designSize,
}) async {
  await pumpProductApp(
    tester,
    Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          key: const Key('launcher'),
          onPressed: () => ProductRoutes.openDetail(context, id),
          child: const Text('mở'),
        ),
      ),
    ),
    repository: repository,
    size: size,
  );
  await tester.tap(find.byKey(const Key('launcher')));
  await tester.pumpAndSettle();
}

/// Tập kịch bản dùng chung cho mọi kích thước/độ phóng chữ.
void _defineScenarios(String suite, {required Size size, double textScale = 1}) {
  group(suite, () {
    setUp(() {});

    Future<void> configure(WidgetTester tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.view.reset);
    }

    testWidgets('Trang chủ: dữ liệu bình thường', (tester) async {
      await configure(tester);
      await pumpMainShell(tester, size: size);
      await _scrollThrough(tester, _homeScrollable, label: 'home');
    });

    testWidgets('Trang chủ: dữ liệu dài và có hàng hết', (tester) async {
      await configure(tester);
      await pumpMainShell(tester, size: size, repository: _stressRepo());
      // Tab Sản phẩm (ẩn) có > 1 trang nên spinner footer chạy mãi; không settle
      await pumpFrames(tester);
      await _scrollThrough(
        tester,
        _homeScrollable,
        label: 'home dài',
        settle: false,
      );
    });

    testWidgets('Trang chủ: skeleton', (tester) async {
      await configure(tester);
      final repo = ControlledProductRepository(
        categories: const [testCategory],
        heldLimit: 4,
      );
      await pumpMainShell(tester, size: size, repository: repo);
      await tester.pump();
      await _scrollThrough(
        tester,
        _homeScrollable,
        label: 'home skeleton',
        settle: false,
      );
    });

    testWidgets('Trang chủ: lỗi và thông báo dài', (tester) async {
      await configure(tester);
      final repo = ControlledProductRepository(heldLimit: 4);
      await pumpMainShell(tester, size: size, repository: repo);
      await tester.pump();
      repo.calls.single.fail(
        ProductFailure('Thông báo lỗi rất dài. ' * 12),
      );
      await tester.pumpAndSettle();
      await _scrollThrough(tester, _homeScrollable, label: 'home lỗi');
    });

    testWidgets('Trang chủ: trạng thái rỗng', (tester) async {
      await configure(tester);
      await pumpMainShell(
        tester,
        size: size,
        repository: MockProductRepository(
          latency: Duration.zero,
          products: const [],
        ),
      );
      await _scrollThrough(tester, _homeScrollable, label: 'home rỗng');
    });

    testWidgets('Danh mục: dữ liệu bình thường', (tester) async {
      await configure(tester);
      await pumpProductApp(tester, const ProductCatalogScreen(), size: size);
      await _scrollThrough(tester, _catalogScrollable, label: 'catalog');
    });

    testWidgets('Danh mục: dữ liệu dài, nhiều trang, có hàng hết', (tester) async {
      await configure(tester);
      await pumpProductApp(
        tester,
        const ProductCatalogScreen(),
        size: size,
        repository: _stressRepo(count: 45),
      );
      await pumpFrames(tester);
      await _scrollThrough(
        tester,
        _catalogScrollable,
        label: 'catalog dài',
        settle: false,
      );
    });

    testWidgets('Danh mục: đang tải', (tester) async {
      await configure(tester);
      final repo = ControlledProductRepository();
      await pumpProductApp(
        tester,
        const ProductCatalogScreen(),
        size: size,
        repository: repo,
      );
      await tester.pump();
      _expectNoOverflow(tester, 'catalog loading');
      await _scrollThrough(
        tester,
        _catalogScrollable,
        label: 'catalog loading',
        settle: false,
      );
    });

    testWidgets('Danh mục: lỗi', (tester) async {
      await configure(tester);
      final repo = ControlledProductRepository();
      await pumpProductApp(
        tester,
        const ProductCatalogScreen(),
        size: size,
        repository: repo,
      );
      await tester.pump();
      repo.calls.single.fail(ProductFailure('Lỗi máy chủ dài. ' * 15));
      await tester.pumpAndSettle();
      await _scrollThrough(tester, _catalogScrollable, label: 'catalog lỗi');
    });

    testWidgets('Danh mục: rỗng với từ khoá dài', (tester) async {
      await configure(tester);
      await pumpProductApp(tester, const ProductCatalogScreen(), size: size);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('catalog-search')),
        'từ khoá tìm kiếm rất dài không hề có kết quả nào khớp ' * 2,
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('catalog-empty')), findsOneWidget);
      await _scrollThrough(tester, _catalogScrollable, label: 'catalog rỗng');
    });

    testWidgets('Danh mục: lọc giá đang bật và menu sắp xếp', (tester) async {
      await configure(tester);
      await pumpProductApp(tester, const ProductCatalogScreen(), size: size);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('catalog-price-filter')));
      await tester.pumpAndSettle();
      _expectNoOverflow(tester, 'price sheet');
      await tester.enterText(
        find.byKey(const Key('catalog-price-min')),
        '1500000',
      );
      await tester.enterText(
        find.byKey(const Key('catalog-price-max')),
        '2500000',
      );
      await tester.tap(find.byKey(const Key('catalog-price-apply')));
      await tester.pumpAndSettle();
      _expectNoOverflow(tester, 'sau khi lọc giá');

      await tester.tap(find.byKey(const Key('catalog-sort')));
      await tester.pumpAndSettle();
      _expectNoOverflow(tester, 'menu sắp xếp');
    });

    testWidgets('Danh mục: lỗi nhập giá trong bottom sheet', (tester) async {
      await configure(tester);
      await pumpProductApp(tester, const ProductCatalogScreen(), size: size);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('catalog-price-filter')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('catalog-price-min')), '900');
      await tester.enterText(find.byKey(const Key('catalog-price-max')), '100');
      await tester.tap(find.byKey(const Key('catalog-price-apply')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('catalog-price-error')), findsOneWidget);
      _expectNoOverflow(tester, 'price sheet có lỗi');
    });

    testWidgets('Chi tiết: sản phẩm bình thường', (tester) async {
      await configure(tester);
      await _openDetailScreen(
        tester,
        createTestRepository(),
        MockProductRepository.defaultProducts.first.id,
        size: size,
      );
      await _scrollThrough(
        tester,
        find.byKey(const Key('detail-scroll')),
        label: 'detail',
      );
    });

    testWidgets('Chi tiết: tên, SKU, mô tả, giá rất dài + 3 ảnh', (tester) async {
      await configure(tester);
      await _openDetailScreen(
        tester,
        MockProductRepository(
          latency: Duration.zero,
          products: [
            _stress('s1', imageUrls: const ['a', 'b', 'c']),
          ],
        ),
        's1',
        size: size,
      );
      await _scrollThrough(
        tester,
        find.byKey(const Key('detail-scroll')),
        label: 'detail dài',
      );
      // Tăng số lượng tối đa để tổng tiền dài nhất
      await tester.ensureVisible(find.byKey(const Key('detail-qty-increase')));
      for (var i = 0; i < 9; i++) {
        await tester.tap(find.byKey(const Key('detail-qty-increase')));
        await tester.pump();
      }
      _expectNoOverflow(tester, 'detail tổng tiền dài');
      expect(find.byKey(const Key('detail-total')), findsOneWidget);
    });

    testWidgets('Chi tiết: hết hàng', (tester) async {
      await configure(tester);
      await _openDetailScreen(
        tester,
        MockProductRepository(
          latency: Duration.zero,
          products: [_stress('s1', stock: 0)],
        ),
        's1',
        size: size,
      );
      await _scrollThrough(
        tester,
        find.byKey(const Key('detail-scroll')),
        label: 'detail hết hàng',
      );
    });

    testWidgets('Chi tiết: đang tải, không tìm thấy, lỗi', (tester) async {
      await configure(tester);
      final gated = GatedDetailRepository();
      await pumpProductApp(
        tester,
        const ProductDetailScreen(productId: 'x'),
        repository: gated,
        size: size,
      );
      await tester.pump();
      _expectNoOverflow(tester, 'detail loading');

      gated.calls.single.fail(
        ProductFailure('Không tải được. ' * 20, offline: false),
      );
      await tester.pumpAndSettle();
      _expectNoOverflow(tester, 'detail lỗi');

      await tester.tap(find.byKey(const Key('detail-retry')));
      await tester.pump();
      gated.calls[1].fail(const ProductFailure('x', notFound: true));
      await tester.pumpAndSettle();
      _expectNoOverflow(tester, 'detail not found');
    });
  });
}

void main() {
  _defineScenarios('360x800', size: const Size(360, 800));
  _defineScenarios('430x800', size: const Size(430, 800));
  _defineScenarios(
    '390x844 chữ phóng to 1.3',
    size: designSize,
    textScale: 1.3,
  );

  group('vùng an toàn (tai thỏ, thanh điều hướng hệ thống)', () {
    Future<void> configure(WidgetTester tester) async {
      tester.view.physicalSize = designSize;
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
      tester.view.viewPadding = const FakeViewPadding(top: 47, bottom: 34);
      addTearDown(tester.view.reset);
    }

    testWidgets('Trang chủ không tràn và thẻ cuối không bị thanh điều hướng che', (tester) async {
      await configure(tester);
      await pumpMainShell(tester);
      await _scrollThrough(tester, _homeScrollable, label: 'home safe area');

      await tester.drag(_homeScrollable, const Offset(0, -100000));
      await tester.pumpAndSettle();
      final story = tester.getRect(
        find
            .descendant(
              of: find.byType(HomeStoryCard),
              matching: find.byType(Container),
            )
            .first,
      );
      final nav = tester.getRect(find.byType(AppBottomNav));
      expect(story.bottom, lessThanOrEqualTo(nav.top));
      // Header không bị tai thỏ che
      expect(
        tester.getTopLeft(find.byKey(const Key('header-notifications'))).dy,
        greaterThanOrEqualTo(47),
      );
    });

    testWidgets('Danh mục: footer không bị thanh điều hướng che', (tester) async {
      await configure(tester);
      await pumpMainShell(tester, initialTab: MainTab.products);
      await _scrollThrough(tester, _catalogScrollable, label: 'catalog safe area');

      await tester.drag(_catalogScrollable, const Offset(0, -100000));
      await tester.pumpAndSettle();
      final top = tester.getRect(find.byKey(const Key('catalog-scroll-top')));
      final nav = tester.getRect(find.byType(AppBottomNav));
      expect(top.bottom, lessThanOrEqualTo(nav.top));
    });

    testWidgets('Chi tiết: thanh mua hàng chừa vùng an toàn phía dưới', (tester) async {
      await configure(tester);
      await _openDetailScreen(
        tester,
        createTestRepository(),
        MockProductRepository.defaultProducts.first.id,
      );
      await _scrollThrough(
        tester,
        find.byKey(const Key('detail-scroll')),
        label: 'detail safe area',
      );

      final button = tester.getRect(find.byKey(const Key('detail-add-to-cart')));
      expect(button.bottom, lessThanOrEqualTo(designSize.height - 34));
      final header = tester.getRect(find.byKey(const Key('detail-header')));
      expect(header.height, 64 + 47);
    });
  });
}
