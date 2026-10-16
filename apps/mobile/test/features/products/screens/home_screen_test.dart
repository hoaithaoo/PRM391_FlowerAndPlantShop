import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/app/main_shell.dart';
import 'package:plant_flower_mobile/features/products/data/mock_product_repository.dart';
import 'package:plant_flower_mobile/features/products/data/product_repository.dart';
import 'package:plant_flower_mobile/features/products/screens/home_screen.dart';
import 'package:plant_flower_mobile/features/products/widgets/home/home_product_grid.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';

import '../../../support/controlled_product_repository.dart';
import '../../../support/finders.dart';
import '../../../support/product_test_app.dart';

const _homeLimit = 4;

String _flowersId = MockProductRepository.freshFlowers.id;
Key _chip(String id) => Key('home-category-$id');

Finder _inHome(Finder finder) =>
    find.descendant(of: find.byType(HomeScreen), matching: finder);

Finder get _skeletons => find.byWidgetPredicate(
  (w) => w.runtimeType.toString() == '_ProductCardSkeleton',
);

/// Các lần gọi `listProducts` do trang chủ phát ra (màn danh mục nằm sẵn
/// trong IndexedStack cũng gọi, nhưng với limit khác).
List<PendingListCall> _homeCalls(ControlledProductRepository repo) =>
    repo.calls.where((c) => c.limit == _homeLimit).toList();

ProductDetail _detail(
  String id, {
  int stock = 5,
  int price = 100000,
  Category category = MockProductRepository.freshFlowers,
}) {
  return ProductDetail(
    id: id,
    sku: 'SKU-$id',
    name: 'Sản phẩm $id',
    price: price,
    stock: stock,
    taxRate: 8,
    category: category,
  );
}

Future<void> _tapVisible(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

void main() {
  group('hiển thị', () {
    testWidgets('render đủ các section', (tester) async {
      await pumpMainShell(tester);
      await tester.pumpAndSettle();

      expect(_inHome(find.text('Nhà Có Hoa')), findsOneWidget);
      expect(find.byKey(const Key('header-notifications')), findsWidgets);
      expect(find.byKey(const Key('home-search')), findsOneWidget);
      expect(find.byKey(const Key('home-filter')), findsOneWidget);
      expect(find.text('Tìm sản phẩm...'), findsOneWidget);
      expect(find.byKey(const Key('home-category-all')), findsOneWidget);
      expect(find.text('BOUTIQUE CURATIONS'), findsOneWidget);
      expect(
        find.text('Tạo không gian sống với thực vật & hoa tươi tự nhiên'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('home-hero-cta')), findsOneWidget);
      expect(find.text('Khám phá bộ sưu tập'), findsOneWidget);
      expect(find.byKey(const Key('home-note-details')), findsOneWidget);
      expect(find.text('TUYỂN CHỌN MÙA NÀY'), findsOneWidget);
      expect(find.text('Khám phá sản phẩm'), findsOneWidget);
      expect(find.byKey(const Key('home-see-more')), findsOneWidget);
      expect(find.text('Xem thêm'), findsOneWidget);

      await tester.ensureVisible(find.text('Mỗi nhánh hoa là một câu chuyện'));
      expect(find.text('Mỗi nhánh hoa là một câu chuyện'), findsOneWidget);
    });

    testWidgets('header trang chủ có logo 26 và avatar', (tester) async {
      await pumpMainShell(tester);
      await tester.pumpAndSettle();

      expect(
        _inHome(find.byWidgetPredicate((w) => w.runtimeType.toString() == '_Avatar')),
        findsOneWidget,
      );
      final logo = tester.widget<Text>(_inHome(find.text('Nhà Có Hoa')));
      expect(logo.style!.fontSize, 26);
    });

    testWidgets('chip danh mục: Tất cả + 3 category từ repository', (tester) async {
      await pumpMainShell(tester);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home-category-all')), findsOneWidget);
      for (final category in MockProductRepository.defaultCategories) {
        final chip = find.byKey(_chip(category.id));
        expect(chip, findsOneWidget, reason: category.name);
        expect(
          find.descendant(of: chip, matching: find.text(category.name)),
          findsOneWidget,
        );
      }
      // "Tất cả" luôn ở trạng thái đang chọn, chip khác thì không
      expect(isChipSelected(tester, const Key('home-category-all')), isTrue);
      expect(isChipSelected(tester, _chip(_flowersId)), isFalse);
    });

    testWidgets('4 sản phẩm mới nhất, có giá định dạng VND', (tester) async {
      await pumpMainShell(tester);
      await tester.pumpAndSettle();

      expect(find.byType(HomeProductCard), findsNWidgets(4));
      final products = MockProductRepository.defaultProducts.take(4).toList();
      for (final product in products) {
        final card = find.byKey(Key('home-product-${product.id}'));
        expect(card, findsOneWidget, reason: product.name);
        expect(
          find.descendant(of: card, matching: find.text(product.name)),
          findsOneWidget,
        );
        expect(
          find.descendant(of: card, matching: find.text(formatVnd(product.price))),
          findsOneWidget,
        );
        expect(
          find.descendant(of: card, matching: find.text(product.sku)),
          findsOneWidget,
        );
      }
      // Sản phẩm thứ 5 không hiện trên trang chủ
      final fifth = MockProductRepository.defaultProducts[4];
      expect(find.byKey(Key('home-product-${fifth.id}')), findsNothing);
      expect(find.text('490.000 ₫'), findsOneWidget);
    });

    testWidgets('chỉ gọi API lấy 4 sản phẩm và danh mục', (tester) async {
      final repo = ControlledProductRepository(
        categories: const [testCategory],
        heldLimit: _homeLimit,
      );
      await pumpMainShell(tester, repository: repo);
      await tester.pump();

      final calls = _homeCalls(repo);
      expect(calls, hasLength(1));
      expect(calls.single.page, 1);
      expect(calls.single.query, const ProductQuery());
    });

    testWidgets('sản phẩm hết hàng hiện "Hết hàng", còn hàng hiện "Còn hàng"', (tester) async {
      final repo = MockProductRepository(
        latency: Duration.zero,
        products: [
          _detail('a', stock: 5),
          _detail('b', stock: 0),
          _detail('c', stock: 1),
          _detail('d', stock: 0),
        ],
      );
      await pumpMainShell(tester, repository: repo);
      await tester.pumpAndSettle();

      Finder status(String id, String text) => find.descendant(
        of: find.byKey(Key('home-product-$id')),
        matching: find.text(text),
      );
      await tester.ensureVisible(find.byKey(const Key('home-product-d')));
      expect(status('a', 'Còn hàng'), findsOneWidget);
      expect(status('a', 'Hết hàng'), findsNothing);
      expect(status('b', 'Hết hàng'), findsOneWidget);
      expect(status('b', 'Còn hàng'), findsNothing);
      expect(status('c', 'Còn hàng'), findsOneWidget);
      expect(status('d', 'Hết hàng'), findsOneWidget);
    });

    testWidgets('chỉ có 1 sản phẩm vẫn dựng được lưới (hàng lẻ)', (tester) async {
      final repo = MockProductRepository(
        latency: Duration.zero,
        products: [_detail('only')],
      );
      await pumpMainShell(tester, repository: repo);
      await tester.pumpAndSettle();

      expect(find.byType(HomeProductCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('chưa có sản phẩm nào thì hiện thông báo rỗng', (tester) async {
      final repo = MockProductRepository(latency: Duration.zero, products: const []);
      await pumpMainShell(tester, repository: repo);
      await tester.pumpAndSettle();

      expect(find.text('Chưa có sản phẩm nào để hiển thị.'), findsOneWidget);
      expect(find.byType(HomeProductCard), findsNothing);
      expect(find.byKey(const Key('home-retry')), findsNothing);
    });
  });

  group('đang tải', () {
    testWidgets('hiện 4 skeleton cho đến khi có dữ liệu', (tester) async {
      final repo = ControlledProductRepository(
        categories: const [testCategory],
        heldLimit: _homeLimit,
      );
      await pumpMainShell(tester, repository: repo);
      await tester.pump();

      expect(_skeletons, findsNWidgets(4));
      expect(find.byType(HomeProductCard), findsNothing);
      expect(find.byKey(const Key('home-retry')), findsNothing);

      _homeCalls(repo).single.complete(
        pageOf([summary('a'), summary('b'), summary('c'), summary('d')]),
      );
      await tester.pumpAndSettle();

      expect(_skeletons, findsNothing);
      expect(find.byType(HomeProductCard), findsNWidgets(4));
    });

    testWidgets('"Tất cả" có ngay, chip category hiện sau khi tải xong', (tester) async {
      final repo = ControlledProductRepository(
        categories: const [testCategory],
        heldLimit: _homeLimit,
      );
      await pumpMainShell(tester, repository: repo);
      await tester.pump();

      expect(find.byKey(const Key('home-category-all')), findsOneWidget);

      _homeCalls(repo).single.complete(pageOf([summary('a')]));
      await tester.pumpAndSettle();

      expect(find.byKey(_chip(testCategory.id)), findsOneWidget);
    });

    testWidgets('độ trễ thật của repository: skeleton rồi lưới', (tester) async {
      final repo = MockProductRepository(latency: const Duration(milliseconds: 300));
      await pumpMainShell(tester, repository: repo);
      await tester.pump();
      expect(_skeletons, findsNWidgets(4));

      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(_skeletons, findsNothing);
      expect(find.byType(HomeProductCard), findsNWidgets(4));
    });
  });

  group('lỗi', () {
    testWidgets('lỗi tải sản phẩm: hiện thông báo + Thử lại, tải lại được', (tester) async {
      final repo = ControlledProductRepository(
        categories: const [testCategory],
        heldLimit: _homeLimit,
      );
      await pumpMainShell(tester, repository: repo);
      await tester.pump();

      _homeCalls(repo).single.fail(
        const ProductFailure('Không kết nối được máy chủ.', offline: true),
      );
      await tester.pumpAndSettle();

      expect(find.text('Không kết nối được máy chủ.'), findsOneWidget);
      expect(find.byKey(const Key('home-retry')), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
      expect(find.byType(HomeProductCard), findsNothing);
      expect(_skeletons, findsNothing);
      // Category vẫn tải được nên chip vẫn hiện
      expect(find.byKey(_chip(testCategory.id)), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('home-retry')));
      await tester.tap(find.byKey(const Key('home-retry')));
      await tester.pump();
      // Đang tải lại: quay về skeleton
      expect(_skeletons, findsNWidgets(4));
      expect(find.byKey(const Key('home-retry')), findsNothing);
      expect(_homeCalls(repo), hasLength(2));

      _homeCalls(repo)[1].complete(pageOf([summary('a'), summary('b')]));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home-retry')), findsNothing);
      expect(find.byType(HomeProductCard), findsNWidgets(2));
    });

    testWidgets('lỗi không phải ProductFailure hiện thông báo chung', (tester) async {
      final repo = ControlledProductRepository(heldLimit: _homeLimit);
      await pumpMainShell(tester, repository: repo);
      await tester.pump();

      _homeCalls(repo).single.fail(StateError('boom'));
      await tester.pumpAndSettle();

      expect(find.text('Không thể tải sản phẩm. Vui lòng thử lại.'), findsOneWidget);
      expect(find.byKey(const Key('home-retry')), findsOneWidget);
    });

    testWidgets('lỗi lần retry thứ hai vẫn hiện lại nút Thử lại', (tester) async {
      final repo = ControlledProductRepository(heldLimit: _homeLimit);
      await pumpMainShell(tester, repository: repo);
      await tester.pump();
      _homeCalls(repo)[0].fail(const ProductFailure('lỗi 1'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('home-retry')));
      await tester.tap(find.byKey(const Key('home-retry')));
      await tester.pump();
      _homeCalls(repo)[1].fail(const ProductFailure('lỗi 2'));
      await tester.pumpAndSettle();

      expect(find.text('lỗi 2'), findsOneWidget);
      expect(find.text('lỗi 1'), findsNothing);
      expect(find.byKey(const Key('home-retry')), findsOneWidget);
    });

    testWidgets('lỗi tải category không chặn sản phẩm: chỉ còn chip Tất cả', (tester) async {
      final repo = ControlledProductRepository(
        categoriesError: const ProductFailure('lỗi category'),
        heldLimit: _homeLimit,
      );
      await pumpMainShell(tester, repository: repo);
      await tester.pump();
      _homeCalls(repo).single.complete(pageOf([summary('a'), summary('b')]));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home-category-all')), findsOneWidget);
      expect(find.byType(HomeProductCard), findsNWidgets(2));
      expect(find.byKey(const Key('home-retry')), findsNothing);
    });
  });

  group('làm mới', () {
    testWidgets('kéo xuống để tải lại', (tester) async {
      final repo = ControlledProductRepository(
        categories: const [testCategory],
        heldLimit: _homeLimit,
      );
      await pumpMainShell(tester, repository: repo);
      await tester.pump();
      _homeCalls(repo)[0].complete(pageOf([summary('old-1'), summary('old-2')]));
      await tester.pumpAndSettle();

      await tester.drag(find.text('Khám phá sản phẩm'), const Offset(0, 350));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(_homeCalls(repo), hasLength(2));
      _homeCalls(repo)[1].complete(pageOf([summary('new-1')]));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home-product-new-1')), findsOneWidget);
      expect(find.byKey(const Key('home-product-old-1')), findsNothing);
    });

    testWidgets(
      'làm mới thất bại thì giữ thẻ và chip cũ, báo bằng SnackBar',
      (tester) async {
        final repo = ControlledProductRepository(
          categories: const [testCategory],
          heldLimit: _homeLimit,
        );
        await pumpMainShell(tester, repository: repo);
        await tester.pump();
        _homeCalls(repo)[0].complete(pageOf([summary('a'), summary('b')]));
        await tester.pumpAndSettle();

        await tester.drag(find.text('Khám phá sản phẩm'), const Offset(0, 350));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        _homeCalls(repo)[1].fail(const ProductFailure('Mất mạng', offline: true));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('home-product-a')), findsOneWidget);
        expect(find.byKey(const Key('home-product-b')), findsOneWidget);
        expect(find.byKey(_chip(testCategory.id)), findsOneWidget);
        expect(find.byKey(const Key('home-retry')), findsNothing);
        expect(
          find.text('Không thể làm mới. Vui lòng thử lại.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('làm mới mà chỉ category lỗi thì giữ chip cũ, vẫn cập nhật sản phẩm', (tester) async {
      final repo = ControlledProductRepository(
        categories: const [testCategory],
        heldLimit: _homeLimit,
      );
      await pumpMainShell(tester, repository: repo);
      await tester.pump();
      _homeCalls(repo)[0].complete(pageOf([summary('old')]));
      await tester.pumpAndSettle();
      expect(find.byKey(_chip(testCategory.id)), findsOneWidget);

      repo.categoriesError = const ProductFailure('lỗi category');
      await tester.drag(find.text('Khám phá sản phẩm'), const Offset(0, 350));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      _homeCalls(repo)[1].complete(pageOf([summary('new')]));
      await tester.pumpAndSettle();

      expect(find.byKey(_chip(testCategory.id)), findsOneWidget);
      expect(find.byKey(const Key('home-product-new')), findsOneWidget);
      expect(find.byKey(const Key('home-product-old')), findsNothing);
      expect(find.byKey(const Key('home-retry')), findsNothing);
    });

    testWidgets('response cũ về muộn sau lần tải mới thì bị bỏ', (tester) async {
      final repo = ControlledProductRepository(heldLimit: _homeLimit);
      await pumpMainShell(tester, repository: repo);
      await tester.pump();
      expect(_homeCalls(repo), hasLength(1));

      // Kéo làm mới khi lần tải đầu chưa xong
      await tester.drag(find.text('Khám phá sản phẩm'), const Offset(0, 350));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(_homeCalls(repo), hasLength(2));

      _homeCalls(repo)[1].complete(pageOf([summary('new')]));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home-product-new')), findsOneWidget);

      _homeCalls(repo)[0].complete(pageOf([summary('stale')]));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home-product-new')), findsOneWidget);
      expect(find.byKey(const Key('home-product-stale')), findsNothing);
    });
  });

  group('điều hướng', () {
    testWidgets('chạm chip category sang tab Sản phẩm với chip đó được chọn', (tester) async {
      await pumpMainShell(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(_chip(MockProductRepository.plants.id)));
      await tester.pumpAndSettle();

      expect(currentTab(tester), MainTab.products);
      final catalogChip = Key('catalog-category-${MockProductRepository.plants.id}');
      expect(isChipSelected(tester, catalogChip), isTrue);
      expect(isChipSelected(tester, const Key('catalog-category-all')), isFalse);
      expect(textOf(tester, find.byKey(const Key('catalog-count'))), 'Hiển thị 3 tác phẩm');
    });

    testWidgets('chạm chip "Tất cả" sang tab Sản phẩm, không lọc', (tester) async {
      await pumpMainShell(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('home-category-all')));
      await tester.pumpAndSettle();

      expect(currentTab(tester), MainTab.products);
      expect(isChipSelected(tester, const Key('catalog-category-all')), isTrue);
      expect(textOf(tester, find.byKey(const Key('catalog-count'))), 'Hiển thị 10 tác phẩm');
    });

    testWidgets('chạm hero CTA sang tab Sản phẩm', (tester) async {
      await pumpMainShell(tester);
      await tester.pumpAndSettle();

      await _tapVisible(tester, const Key('home-hero-cta'));

      expect(currentTab(tester), MainTab.products);
      expect(isChipSelected(tester, const Key('catalog-category-all')), isTrue);
    });

    testWidgets('chạm "Xem thêm" sang tab Sản phẩm', (tester) async {
      await pumpMainShell(tester);
      await tester.pumpAndSettle();

      await _tapVisible(tester, const Key('home-see-more'));

      expect(currentTab(tester), MainTab.products);
    });

    testWidgets('chạm ô tìm kiếm sang tab Sản phẩm', (tester) async {
      await pumpMainShell(tester);
      await tester.pumpAndSettle();

      await _tapVisible(tester, const Key('home-search'));

      expect(currentTab(tester), MainTab.products);
    });

    testWidgets('chạm nút lọc nhanh sang tab Sản phẩm', (tester) async {
      await pumpMainShell(tester);
      await tester.pumpAndSettle();

      await _tapVisible(tester, const Key('home-filter'));

      expect(currentTab(tester), MainTab.products);
    });

    testWidgets('chạm thẻ sản phẩm mở màn chi tiết đúng sản phẩm', (tester) async {
      await pumpMainShell(tester);
      await tester.pumpAndSettle();
      final target = MockProductRepository.defaultProducts[2];

      await _tapVisible(tester, Key('home-product-${target.id}'));

      expect(find.byKey(const Key('detail-header')), findsOneWidget);
      expect(textOf(tester, find.byKey(const Key('detail-name'))), target.name);
      expect(textOf(tester, find.byKey(const Key('detail-sku'))), 'SKU: ${target.sku}');
      expect(textOf(tester, find.byKey(const Key('detail-price'))), formatVnd(target.price));
    });

    testWidgets('từ chi tiết quay lại trang chủ vẫn giữ dữ liệu', (tester) async {
      final repo = createTestRepository();
      await pumpMainShell(tester, repository: repo);
      await tester.pumpAndSettle();
      final calls = repo.listProductsCalls;

      await _tapVisible(
        tester,
        Key('home-product-${MockProductRepository.defaultProducts[0].id}'),
      );
      await tester.tap(find.byKey(const Key('header-back')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('detail-header')), findsNothing);
      expect(currentTab(tester), MainTab.home);
      expect(find.byType(HomeProductCard), findsNWidgets(4));
      // Không tải lại khi quay về
      expect(repo.listProductsCalls, calls);
    });

    testWidgets('chạm "Chi tiết" ở thẻ ghi chú hiện SnackBar', (tester) async {
      await pumpMainShell(tester);
      await tester.pumpAndSettle();

      await _tapVisible(tester, const Key('home-note-details'));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.textContaining('Hoa được cắt mới mỗi sáng'),
        ),
        findsOneWidget,
      );
      expect(currentTab(tester), MainTab.home);
    });

    testWidgets('chạm "Chi tiết" hai lần chỉ còn một SnackBar', (tester) async {
      await pumpMainShell(tester);
      await tester.pumpAndSettle();

      await _tapVisible(tester, const Key('home-note-details'));
      await tester.tap(find.byKey(const Key('home-note-details')));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
