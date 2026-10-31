import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/products/data/mock_product_repository.dart';
import 'package:plant_flower_mobile/features/products/data/product_repository.dart';
import 'package:plant_flower_mobile/features/products/product_routes.dart';
import 'package:plant_flower_mobile/features/products/screens/product_detail_screen.dart';
import 'package:plant_flower_mobile/features/products/widgets/detail/quantity_selector.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';

import '../../../support/finders.dart';
import '../../../support/gated_detail_repository.dart';
import '../../../support/product_test_app.dart';

const _flowers = MockProductRepository.freshFlowers;

/// Chế độ chẩn đoán font Ahem (xem flutter_test_config.dart): chữ rộng 1em
/// nên không thể khẳng định "font thật không bị thu nhỏ".
final _usingAhem = Platform.environment['PFS_TEST_FONT']?.toLowerCase() == 'ahem';

ProductDetail _product(
  String id, {
  int stock = 5,
  int price = 490000,
  String? name,
  String? description = 'Mô tả sản phẩm.',
  List<String> imageUrls = const [],
  Category category = _flowers,
}) {
  return ProductDetail(
    id: id,
    sku: 'SKU-$id',
    name: name ?? 'Sản phẩm $id',
    description: description,
    price: price,
    stock: stock,
    taxRate: 8,
    category: category,
    imageUrls: imageUrls,
  );
}

MockProductRepository _repo(List<ProductDetail> products) =>
    MockProductRepository(latency: Duration.zero, products: products);

/// Mở màn chi tiết bằng cách push từ một màn "launcher", để back/pop hoạt động.
Future<void> _openDetail(
  WidgetTester tester,
  ProductRepository repository,
  String productId, {
  Size size = designSize,
  bool settle = true,
}) async {
  // Dựng lại từ đầu để không giữ Navigator của lần mở trước
  await tester.pumpWidget(const SizedBox());
  await pumpProductApp(
    tester,
    Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            key: const Key('launcher'),
            onPressed: () => ProductRoutes.openDetail(context, productId),
            child: const Text('Mở chi tiết'),
          ),
        ),
      ),
    ),
    repository: repository,
    size: size,
  );
  await tester.tap(find.byKey(const Key('launcher')));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }
}

String _text(WidgetTester tester, String key) =>
    textOf(tester, find.byKey(Key(key)));

bool _enabled(WidgetTester tester, String key) =>
    tester.widget<ButtonStyleButton>(find.byKey(Key(key))).onPressed != null;

bool _stepEnabled(WidgetTester tester, String key) {
  final button = find.descendant(
    of: find.byKey(Key(key)),
    matching: find.byType(IconButton),
  );
  return tester.widget<IconButton>(button).onPressed != null;
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.tap(find.byKey(Key(key)));
  await tester.pump();
}

void main() {
  group('tải dữ liệu', () {
    testWidgets('loading rồi hiện nội dung', (tester) async {
      final repo = GatedDetailRepository();
      await _openDetail(tester, repo, 'p1', settle: false);

      expect(find.byKey(const Key('detail-header')), findsOneWidget);
      expect(find.byKey(const Key('detail-loading')), findsOneWidget);
      expect(find.byKey(const Key('detail-scroll')), findsNothing);
      expect(find.byKey(const Key('detail-purchase-bar')), findsNothing);
      expect(repo.calls.single.id, 'p1');

      repo.calls.single.complete(_product('p1', name: 'Bó hoa thử'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('detail-loading')), findsNothing);
      expect(_text(tester, 'detail-name'), 'Bó hoa thử');
      expect(find.byKey(const Key('detail-purchase-bar')), findsOneWidget);
    });

    testWidgets('chỉ gọi getProduct một lần cho mỗi lần mở', (tester) async {
      final repo = GatedDetailRepository();
      await _openDetail(tester, repo, 'p1', settle: false);
      await tester.pump(const Duration(seconds: 1));

      expect(repo.calls, hasLength(1));
    });

    testWidgets('hiện đủ thông tin sản phẩm còn hàng', (tester) async {
      final product = _product(
        'p1',
        name: 'Bó Hoa Bạch Hồng',
        price: 490000,
        stock: 12,
        description: 'Bạch hồng Ecuador cao cấp.',
      );
      await _openDetail(tester, _repo([product]), 'p1');

      expect(find.text('Chi Tiết Tác Phẩm'), findsOneWidget);
      expect(find.byKey(const Key('header-back')), findsOneWidget);
      expect(find.byKey(const Key('header-share')), findsOneWidget);
      expect(find.byKey(const Key('header-notifications')), findsNothing);
      expect(find.byKey(const Key('detail-breadcrumb')), findsOneWidget);
      expect(find.text('Bộ sưu tập'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('detail-breadcrumb')),
          matching: find.text('Hoa tươi'),
        ),
        findsOneWidget,
      );
      expect(_text(tester, 'detail-category'), 'HOA TƯƠI');
      expect(_text(tester, 'detail-name'), 'Bó Hoa Bạch Hồng');
      expect(_text(tester, 'detail-price'), '490.000 ₫');
      expect(_text(tester, 'detail-sku'), 'SKU: SKU-p1');
      expect(
        find.descendant(
          of: find.byKey(const Key('detail-status')),
          matching: find.text('Còn hàng'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('detail-description')), findsOneWidget);
      expect(find.text('MÔ TẢ TÁC PHẨM'), findsOneWidget);
      expect(find.text('Bạch hồng Ecuador cao cấp.'), findsOneWidget);
      expect(find.byKey(const Key('detail-care-note')), findsOneWidget);
      expect(find.byKey(const Key('detail-carousel')), findsOneWidget);
      expect(find.byKey(const Key('detail-cart')), findsOneWidget);
    });

    testWidgets('mở đúng sản phẩm seed của Mock repository', (tester) async {
      final seed = MockProductRepository.defaultProducts[3];
      await _openDetail(tester, createTestRepository(), seed.id);

      expect(_text(tester, 'detail-name'), seed.name);
      expect(_text(tester, 'detail-price'), formatVnd(seed.price));
      expect(_text(tester, 'detail-sku'), 'SKU: ${seed.sku}');
      expect(_text(tester, 'detail-category'), seed.category.name.toUpperCase());
    });

    testWidgets('không có mô tả (null) thì ẩn thẻ mô tả nhưng vẫn có ghi chú', (tester) async {
      await _openDetail(
        tester,
        _repo([_product('p1', description: null)]),
        'p1',
      );

      expect(find.byKey(const Key('detail-description')), findsNothing);
      expect(find.text('MÔ TẢ TÁC PHẨM'), findsNothing);
      expect(find.byKey(const Key('detail-care-note')), findsOneWidget);
      expect(find.byKey(const Key('detail-name')), findsOneWidget);
    });

    testWidgets('mô tả rỗng hoặc toàn khoảng trắng cũng ẩn thẻ mô tả', (tester) async {
      for (final description in ['', '   \n ']) {
        await _openDetail(
          tester,
          _repo([_product('p1', description: description)]),
          'p1',
        );
        expect(
          find.byKey(const Key('detail-description')),
          findsNothing,
          reason: '"$description"',
        );
      }
    });

    testWidgets('mô tả được trim', (tester) async {
      await _openDetail(
        tester,
        _repo([_product('p1', description: '  Hoa đẹp  ')]),
        'p1',
      );
      expect(find.text('Hoa đẹp'), findsOneWidget);
    });

    testWidgets('giá và tổng tiền định dạng VND với số lớn', (tester) async {
      await _openDetail(
        tester,
        _repo([_product('p1', price: 1234567, stock: 10)]),
        'p1',
      );

      expect(_text(tester, 'detail-price'), '1.234.567 ₫');
      expect(_text(tester, 'detail-total'), '1.234.567 ₫');
    });
  });

  group('bộ chọn số lượng', () {
    testWidgets('stock 5: giới hạn 1..5, hint "Chỉ còn 5 sản phẩm"', (tester) async {
      await _openDetail(
        tester,
        _repo([_product('p1', stock: 5, price: 100000)]),
        'p1',
      );

      expect(_text(tester, 'detail-qty-hint'), 'Chỉ còn 5 sản phẩm');
      expect(_text(tester, 'detail-qty-value'), '1');
      expect(_stepEnabled(tester, 'detail-qty-decrease'), isFalse);
      expect(_stepEnabled(tester, 'detail-qty-increase'), isTrue);

      for (var expected = 2; expected <= 5; expected++) {
        await _tapKey(tester, 'detail-qty-increase');
        expect(_text(tester, 'detail-qty-value'), '$expected');
        expect(_text(tester, 'detail-total'), formatVnd(100000 * expected));
      }
      expect(_stepEnabled(tester, 'detail-qty-increase'), isFalse);
      expect(_stepEnabled(tester, 'detail-qty-decrease'), isTrue);

      // Chạm tiếp khi đã chạm biên không đổi gì
      await tester.tap(find.byKey(const Key('detail-qty-increase')));
      await tester.pump();
      expect(_text(tester, 'detail-qty-value'), '5');
    });

    testWidgets('stock 12: tối đa 10 mỗi đơn, hint "Tối đa 10 sản phẩm / đơn hàng"', (tester) async {
      await _openDetail(
        tester,
        _repo([_product('p1', stock: 12, price: 50000)]),
        'p1',
      );

      expect(_text(tester, 'detail-qty-hint'), 'Tối đa 10 sản phẩm / đơn hàng');
      for (var i = 0; i < 9; i++) {
        await _tapKey(tester, 'detail-qty-increase');
      }
      expect(_text(tester, 'detail-qty-value'), '10');
      expect(_text(tester, 'detail-total'), formatVnd(500000));
      expect(_stepEnabled(tester, 'detail-qty-increase'), isFalse);
    });

    testWidgets('stock đúng 10 hiện hint tối đa, 9 hiện "Chỉ còn 9"', (tester) async {
      await _openDetail(tester, _repo([_product('p1', stock: 10)]), 'p1');
      expect(_text(tester, 'detail-qty-hint'), 'Tối đa 10 sản phẩm / đơn hàng');

      await _openDetail(tester, _repo([_product('p2', stock: 9)]), 'p2');
      expect(_text(tester, 'detail-qty-hint'), 'Chỉ còn 9 sản phẩm');
    });

    testWidgets('stock 1: cả hai nút đều bị vô hiệu', (tester) async {
      await _openDetail(tester, _repo([_product('p1', stock: 1)]), 'p1');

      expect(_text(tester, 'detail-qty-hint'), 'Chỉ còn 1 sản phẩm');
      expect(_stepEnabled(tester, 'detail-qty-decrease'), isFalse);
      expect(_stepEnabled(tester, 'detail-qty-increase'), isFalse);
      expect(_enabled(tester, 'detail-add-to-cart'), isTrue);
    });

    testWidgets('giảm số lượng và tổng tiền theo, không xuống dưới 1', (tester) async {
      await _openDetail(
        tester,
        _repo([_product('p1', stock: 8, price: 200000)]),
        'p1',
      );
      await _tapKey(tester, 'detail-qty-increase');
      await _tapKey(tester, 'detail-qty-increase');
      expect(_text(tester, 'detail-total'), '600.000 ₫');

      await _tapKey(tester, 'detail-qty-decrease');
      expect(_text(tester, 'detail-qty-value'), '2');
      expect(_text(tester, 'detail-total'), '400.000 ₫');
      await _tapKey(tester, 'detail-qty-decrease');
      expect(_text(tester, 'detail-qty-value'), '1');
      expect(_stepEnabled(tester, 'detail-qty-decrease'), isFalse);
      expect(_text(tester, 'detail-total'), '200.000 ₫');
    });

    testWidgets('tổng tạm tính ban đầu bằng đúng giá', (tester) async {
      await _openDetail(
        tester,
        _repo([_product('p1', price: 350000)]),
        'p1',
      );
      expect(find.text('Tổng tạm tính'), findsOneWidget);
      expect(_text(tester, 'detail-total'), '350.000 ₫');
    });

    test('detailMaxQuantity: min(10, stock), không âm', () {
      expect(detailMaxPerOrder, 10);
      expect(detailMaxQuantity(0), 0);
      expect(detailMaxQuantity(-3), 0);
      expect(detailMaxQuantity(1), 1);
      expect(detailMaxQuantity(5), 5);
      expect(detailMaxQuantity(10), 10);
      expect(detailMaxQuantity(11), 10);
      expect(detailMaxQuantity(500), 10);
    });
  });

  group('hết hàng', () {
    testWidgets('nút "Hết hàng" bị vô hiệu, stepper bị vô hiệu', (tester) async {
      await _openDetail(
        tester,
        _repo([_product('p1', stock: 0, price: 280000)]),
        'p1',
      );

      expect(
        find.descendant(
          of: find.byKey(const Key('detail-status')),
          matching: find.text('Hết hàng'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('detail-add-to-cart')),
          matching: find.text('Hết hàng'),
        ),
        findsOneWidget,
      );
      expect(find.text('Thêm vào giỏ'), findsNothing);
      expect(_enabled(tester, 'detail-add-to-cart'), isFalse);
      expect(_stepEnabled(tester, 'detail-qty-decrease'), isFalse);
      expect(_stepEnabled(tester, 'detail-qty-increase'), isFalse);
      expect(_text(tester, 'detail-qty-hint'), 'Sản phẩm hiện đã hết hàng');
      expect(_text(tester, 'detail-total'), '280.000 ₫');
    });

    testWidgets('chạm nút "Hết hàng" không hiện SnackBar', (tester) async {
      await _openDetail(tester, _repo([_product('p1', stock: 0)]), 'p1');

      await tester.tap(find.byKey(const Key('detail-add-to-cart')));
      await tester.pump();

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('sản phẩm Mock hết hàng (FL-131) hiển thị đúng', (tester) async {
      final soldOut = MockProductRepository.defaultProducts[8];
      expect(soldOut.stock, 0);
      await _openDetail(tester, createTestRepository(), soldOut.id);

      expect(_enabled(tester, 'detail-add-to-cart'), isFalse);
      expect(_text(tester, 'detail-sku'), 'SKU: FL-131');
    });
  });

  group('thêm vào giỏ, chia sẻ, giỏ hàng', () {
    testWidgets('"Thêm vào giỏ" hiện SnackBar với số lượng và tên', (tester) async {
      await _openDetail(
        tester,
        _repo([_product('p1', name: 'Bó Tulip', stock: 5)]),
        'p1',
      );
      await _tapKey(tester, 'detail-qty-increase');
      await _tapKey(tester, 'detail-qty-increase');

      await _tapKey(tester, 'detail-add-to-cart');

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Đã thêm 3 × Bó Tulip vào giỏ hàng'), findsOneWidget);
      expect(find.text('Thêm vào giỏ'), findsOneWidget);
    });

    testWidgets('số lượng mặc định là 1', (tester) async {
      await _openDetail(
        tester,
        _repo([_product('p1', name: 'Bó Tulip')]),
        'p1',
      );

      await _tapKey(tester, 'detail-add-to-cart');

      expect(find.text('Đã thêm 1 × Bó Tulip vào giỏ hàng'), findsOneWidget);
    });

    testWidgets('thêm lần hai thay SnackBar cũ bằng số lượng mới', (tester) async {
      await _openDetail(
        tester,
        _repo([_product('p1', name: 'Bó Tulip')]),
        'p1',
      );
      await _tapKey(tester, 'detail-add-to-cart');
      await _tapKey(tester, 'detail-qty-increase');
      await _tapKey(tester, 'detail-add-to-cart');
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Đã thêm 2 × Bó Tulip vào giỏ hàng'), findsOneWidget);
      expect(find.text('Đã thêm 1 × Bó Tulip vào giỏ hàng'), findsNothing);
    });

    testWidgets('nút chia sẻ ở header hiện SnackBar', (tester) async {
      await _openDetail(tester, _repo([_product('p1')]), 'p1');

      await tester.tap(find.byKey(const Key('header-share')));
      await tester.pump();

      expect(find.text('Tính năng chia sẻ sẽ sớm ra mắt'), findsOneWidget);
    });

    testWidgets('nút giỏ hàng hiện SnackBar', (tester) async {
      await _openDetail(tester, _repo([_product('p1')]), 'p1');

      await tester.tap(find.byKey(const Key('detail-cart')));
      await tester.pump();

      expect(find.text('Giỏ hàng đang được phát triển'), findsOneWidget);
    });

    testWidgets('các SnackBar nối tiếp nhau chỉ hiện một cái', (tester) async {
      await _openDetail(tester, _repo([_product('p1')]), 'p1');

      await tester.tap(find.byKey(const Key('header-share')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('detail-cart')));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Giỏ hàng đang được phát triển'), findsOneWidget);
    });
  });

  group('lỗi', () {
    testWidgets('không tìm thấy: thông báo + nút Quay lại, pop về màn trước', (tester) async {
      await _openDetail(tester, createTestRepository(), 'id-la');

      expect(
        _text(tester, 'detail-message'),
        'Sản phẩm không tồn tại hoặc đã ngừng bán.',
      );
      expect(find.byKey(const Key('detail-retry')), findsNothing);
      expect(find.byKey(const Key('detail-purchase-bar')), findsNothing);
      expect(find.byKey(const Key('detail-scroll')), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const Key('detail-back')),
          matching: find.text('Quay lại'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('detail-back')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('detail-header')), findsNothing);
      expect(find.byKey(const Key('launcher')), findsOneWidget);
    });

    testWidgets('sản phẩm ngừng bán (isActive = false) cũng là không tìm thấy', (tester) async {
      final inactive = ProductDetail(
        id: 'old',
        sku: 'X',
        name: 'Cũ',
        price: 1,
        stock: 1,
        taxRate: 0,
        category: _flowers,
        isActive: false,
      );
      await _openDetail(tester, _repo([inactive]), 'old');

      expect(find.byKey(const Key('detail-back')), findsOneWidget);
    });

    testWidgets('lỗi offline: câu hướng dẫn mạng + Thử lại', (tester) async {
      final repo = GatedDetailRepository();
      await _openDetail(tester, repo, 'p1', settle: false);

      repo.calls[0].fail(const ProductFailure('raw', offline: true));
      await tester.pumpAndSettle();

      expect(
        _text(tester, 'detail-message'),
        'Mất kết nối mạng. Vui lòng kiểm tra kết nối và thử lại.',
      );
      expect(find.byKey(const Key('detail-retry')), findsOneWidget);
      expect(find.byKey(const Key('detail-back')), findsNothing);
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    });

    testWidgets('lỗi khác: hiện message của lỗi + Thử lại', (tester) async {
      final repo = GatedDetailRepository();
      await _openDetail(tester, repo, 'p1', settle: false);

      repo.calls[0].fail(const ProductFailure('Máy chủ đang bảo trì.'));
      await tester.pumpAndSettle();

      expect(_text(tester, 'detail-message'), 'Máy chủ đang bảo trì.');
      expect(find.byKey(const Key('detail-retry')), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('lỗi không phải ProductFailure hiện thông báo chung', (tester) async {
      final repo = GatedDetailRepository();
      await _openDetail(tester, repo, 'p1', settle: false);

      repo.calls[0].fail(StateError('boom'));
      await tester.pumpAndSettle();

      expect(
        _text(tester, 'detail-message'),
        'Không tải được sản phẩm. Vui lòng thử lại.',
      );
      expect(find.byKey(const Key('detail-retry')), findsOneWidget);
    });

    testWidgets('Thử lại: loading rồi hiện nội dung', (tester) async {
      final repo = GatedDetailRepository();
      await _openDetail(tester, repo, 'p1', settle: false);
      repo.calls[0].fail(const ProductFailure('lỗi', offline: true));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('detail-retry')));
      await tester.pump();

      expect(find.byKey(const Key('detail-loading')), findsOneWidget);
      expect(find.byKey(const Key('detail-retry')), findsNothing);
      expect(repo.calls, hasLength(2));
      expect(repo.calls[1].id, 'p1');

      repo.calls[1].complete(_product('p1', name: 'Đã tải được'));
      await tester.pumpAndSettle();
      expect(_text(tester, 'detail-name'), 'Đã tải được');
    });

    testWidgets('Thử lại lần hai vẫn lỗi thì hiện lại nút Thử lại', (tester) async {
      final repo = GatedDetailRepository();
      await _openDetail(tester, repo, 'p1', settle: false);
      repo.calls[0].fail(const ProductFailure('lỗi 1'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('detail-retry')));
      await tester.pump();
      repo.calls[1].fail(const ProductFailure('lỗi 2'));
      await tester.pumpAndSettle();

      expect(_text(tester, 'detail-message'), 'lỗi 2');
      expect(find.byKey(const Key('detail-retry')), findsOneWidget);
    });

    testWidgets('header (back + chia sẻ) vẫn dùng được khi đang lỗi', (tester) async {
      final repo = GatedDetailRepository();
      await _openDetail(tester, repo, 'p1', settle: false);
      repo.calls[0].fail(const ProductFailure('lỗi'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('header-back')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('launcher')), findsOneWidget);
    });
  });

  group('header', () {
    testWidgets('nút back ở header quay về màn trước', (tester) async {
      await _openDetail(tester, _repo([_product('p1')]), 'p1');

      await tester.tap(find.byKey(const Key('header-back')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('detail-header')), findsNothing);
      expect(find.byKey(const Key('launcher')), findsOneWidget);
    });

    testWidgets('mở lại sản phẩm khác sau khi quay lại thì tải lại từ đầu', (tester) async {
      final repo = GatedDetailRepository();
      await _openDetail(tester, repo, 'p1', settle: false);
      repo.calls[0].complete(_product('p1'));
      await tester.pumpAndSettle();
      await _tapKey(tester, 'detail-qty-increase');
      expect(_text(tester, 'detail-qty-value'), '2');
      await tester.tap(find.byKey(const Key('header-back')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('launcher')));
      await tester.pump();
      repo.calls[1].complete(_product('p1'));
      await tester.pumpAndSettle();

      expect(_text(tester, 'detail-qty-value'), '1');
    });
  });

  group('carousel ảnh', () {
    testWidgets('không có ảnh: placeholder, chip "1 / 1", không có chấm', (tester) async {
      await _openDetail(
        tester,
        _repo([_product('p1', imageUrls: const [])]),
        'p1',
      );

      expect(
        find.descendant(
          of: find.byKey(const Key('detail-carousel')),
          matching: find.byIcon(Icons.local_florist_outlined),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('detail-image-counter')),
          matching: find.text('1 / 1'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('detail-page-indicator')), findsNothing);
    });

    testWidgets('1 ảnh: chip "1 / 1" và không có chấm', (tester) async {
      await _openDetail(
        tester,
        _repo([_product('p1', imageUrls: const ['https://example.com/1.jpg'])]),
        'p1',
      );

      expect(find.text('1 / 1'), findsOneWidget);
      expect(find.byKey(const Key('detail-page-indicator')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('3 ảnh: chip "1 / 3", có 3 chấm, vuốt đổi trang', (tester) async {
      await _openDetail(
        tester,
        _repo([
          _product(
            'p1',
            imageUrls: const [
              'https://example.com/1.jpg',
              'https://example.com/2.jpg',
              'https://example.com/3.jpg',
            ],
          ),
        ]),
        'p1',
      );

      expect(find.text('1 / 3'), findsOneWidget);
      expect(find.byKey(const Key('detail-page-indicator')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('detail-page-indicator')),
          matching: find.byType(AnimatedContainer),
        ),
        findsNWidgets(3),
      );

      final carousel = find.byKey(const Key('detail-carousel'));
      await tester.drag(carousel, const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(find.text('2 / 3'), findsOneWidget);

      await tester.drag(carousel, const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(find.text('3 / 3'), findsOneWidget);

      // Vuốt tiếp ở trang cuối không đổi
      await tester.drag(carousel, const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(find.text('3 / 3'), findsOneWidget);

      await tester.drag(carousel, const Offset(300, 0));
      await tester.pumpAndSettle();
      expect(find.text('2 / 3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('chấm đang chọn to hơn và đổi theo trang', (tester) async {
      await _openDetail(
        tester,
        _repo([
          _product('p1', imageUrls: const ['a', 'b', 'c']),
        ]),
        'p1',
      );
      List<double> widths() => tester
          .widgetList<AnimatedContainer>(
            find.descendant(
              of: find.byKey(const Key('detail-page-indicator')),
              matching: find.byType(AnimatedContainer),
            ),
          )
          .map((c) => c.constraints!.maxWidth)
          .toList();

      expect(widths(), [8, 6, 6]);
      await tester.drag(
        find.byKey(const Key('detail-carousel')),
        const Offset(-300, 0),
      );
      await tester.pumpAndSettle();
      expect(widths(), [6, 8, 6]);
    });

    testWidgets('lỗi tải ảnh mạng vẫn hiện placeholder, không ném lỗi', (tester) async {
      await _openDetail(
        tester,
        _repo([
          _product('p1', imageUrls: const ['https://example.invalid/x.png']),
        ]),
        'p1',
      );
      await tester.pump(const Duration(seconds: 1));

      expect(
        find.descendant(
          of: find.byKey(const Key('detail-carousel')),
          matching: find.byIcon(Icons.local_florist_outlined),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('đổi productId', () {
    Future<ValueNotifier<String>> pumpHost(
      WidgetTester tester,
      ProductRepository repository,
      String initial,
    ) async {
      final id = ValueNotifier(initial);
      addTearDown(id.dispose);
      await pumpProductApp(
        tester,
        ValueListenableBuilder<String>(
          valueListenable: id,
          builder: (_, value, _) => ProductDetailScreen(productId: value),
        ),
        repository: repository,
      );
      return id;
    }

    testWidgets('đổi productId tải lại, về loading và reset số lượng', (tester) async {
      final repo = GatedDetailRepository();
      final id = await pumpHost(tester, repo, 'a');
      repo.calls[0].complete(_product('a', name: 'Sản phẩm A', stock: 8));
      await tester.pumpAndSettle();
      await _tapKey(tester, 'detail-qty-increase');
      expect(_text(tester, 'detail-qty-value'), '2');

      id.value = 'b';
      await tester.pump();

      expect(repo.calls, hasLength(2));
      expect(repo.calls[1].id, 'b');
      expect(find.byKey(const Key('detail-loading')), findsOneWidget);
      expect(find.byKey(const Key('detail-purchase-bar')), findsNothing);

      repo.calls[1].complete(_product('b', name: 'Sản phẩm B', stock: 8));
      await tester.pumpAndSettle();

      expect(_text(tester, 'detail-name'), 'Sản phẩm B');
      expect(_text(tester, 'detail-qty-value'), '1');
    });

    testWidgets('response của sản phẩm cũ về muộn bị bỏ', (tester) async {
      final repo = GatedDetailRepository();
      final id = await pumpHost(tester, repo, 'a');

      id.value = 'b';
      await tester.pump();
      repo.calls[1].complete(_product('b', name: 'Sản phẩm B'));
      await tester.pumpAndSettle();
      expect(_text(tester, 'detail-name'), 'Sản phẩm B');

      repo.calls[0].complete(_product('a', name: 'Sản phẩm A'));
      await tester.pumpAndSettle();

      expect(_text(tester, 'detail-name'), 'Sản phẩm B');
    });

    testWidgets('lỗi của sản phẩm cũ về muộn không ghi đè nội dung mới', (tester) async {
      final repo = GatedDetailRepository();
      final id = await pumpHost(tester, repo, 'a');

      id.value = 'b';
      await tester.pump();
      repo.calls[1].complete(_product('b', name: 'Sản phẩm B'));
      await tester.pumpAndSettle();

      repo.calls[0].fail(const ProductFailure('lỗi cũ'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('detail-message')), findsNothing);
      expect(_text(tester, 'detail-name'), 'Sản phẩm B');
    });

    testWidgets('rebuild với cùng productId không tải lại', (tester) async {
      final repo = GatedDetailRepository();
      final id = await pumpHost(tester, repo, 'a');
      repo.calls[0].complete(_product('a'));
      await tester.pumpAndSettle();

      id.value = 'a';
      await tester.pump();
      // ValueNotifier không notify khi giá trị không đổi nên ép rebuild bằng tay
      tester.element(find.byType(ProductDetailScreen)).markNeedsBuild();
      await tester.pump();

      expect(repo.calls, hasLength(1));
    });

    testWidgets('đổi productId từ lỗi sang sản phẩm hợp lệ', (tester) async {
      final repo = GatedDetailRepository();
      final id = await pumpHost(tester, repo, 'a');
      repo.calls[0].fail(const ProductFailure('lỗi', notFound: true));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('detail-back')), findsOneWidget);

      id.value = 'b';
      await tester.pump();
      repo.calls[1].complete(_product('b', name: 'Sản phẩm B'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('detail-back')), findsNothing);
      expect(_text(tester, 'detail-name'), 'Sản phẩm B');
    });
  });

  group('header và hàng giá', () {
    Finder avatar() => find.byWidgetPredicate(
      (w) => w.runtimeType.toString() == '_Avatar',
    );

    double logoSize(WidgetTester tester) {
      final logo = find.descendant(
        of: find.byKey(const Key('detail-header')),
        matching: find.text('Nhà Có Hoa'),
      );
      return tester.widget<Text>(logo).style!.fontSize!;
    }

    testWidgets('header chi tiết: logo 20, không có avatar', (tester) async {
      await _openDetail(tester, _repo([_product('p1')]), 'p1');

      expect(avatar(), findsNothing);
      expect(logoSize(tester), 20);
      expect(find.byKey(const Key('header-back')), findsOneWidget);
      expect(find.byKey(const Key('header-share')), findsOneWidget);
    });

    for (final width in [360.0, 390.0, 430.0]) {
      testWidgets('font thật x1.0 ở $width: logo 20 và tiêu đề 16 không bị FittedBox thu nhỏ', (tester) async {
        await _openDetail(
          tester,
          _repo([_product('p1')]),
          'p1',
          size: Size(width, 800),
        );

        expect(
          fittedBoxScale(tester, find.byKey(const Key('detail-header'))),
          1.0,
        );
        final title = tester.widget<Text>(find.text('Chi Tiết Tác Phẩm')).style!;
        expect(title.fontSize, 16);
        expect(logoSize(tester), 20);
      }, skip: _usingAhem);
    }

    for (final (width, scale) in [
      (360.0, 1.0),
      (390.0, 1.0),
      (430.0, 1.0),
      (390.0, 1.3),
      (360.0, 1.3),
    ]) {
      testWidgets('tiêu đề "Chi Tiết Tác Phẩm" 1 dòng, không overflow ($width, x$scale)', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await _openDetail(
          tester,
          _repo([_product('p1')]),
          'p1',
          size: Size(width, 800),
        );

        final title = find.text('Chi Tiết Tác Phẩm');
        expect(title, findsOneWidget);
        final style = tester.widget<Text>(title).style!;
        final lineHeight = style.fontSize! * (style.height ?? 1.5) * scale;
        expect(tester.getSize(title).height, lessThanOrEqualTo(lineHeight * 1.2));
        // Tiêu đề nằm gọn trong header, không vượt qua nút chia sẻ
        final header = tester.getRect(find.byKey(const Key('detail-header')));
        expect(tester.getRect(title).right, lessThanOrEqualTo(header.right));
        expect(
          tester.getRect(title).right,
          lessThanOrEqualTo(tester.getRect(find.byKey(const Key('header-share'))).left + 0.5),
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('SKU nằm bên phải giá, căn phải, tối đa 2 dòng', (tester) async {
      await _openDetail(tester, _repo([_product('p1')]), 'p1');

      final price = tester.getRect(find.byKey(const Key('detail-price')));
      final sku = tester.getRect(find.byKey(const Key('detail-sku')));
      expect(tester.getTopLeft(find.byKey(const Key('detail-sku'))).dx,
          greaterThan(tester.getTopLeft(find.byKey(const Key('detail-price'))).dx));
      expect(sku.left, greaterThanOrEqualTo(price.right));
      final skuText = tester.widget<Text>(find.byKey(const Key('detail-sku')));
      expect(skuText.textAlign, TextAlign.end);
      expect(skuText.maxLines, 2);
      expect(skuText.overflow, TextOverflow.ellipsis);
    });

    testWidgets('SKU sát lề phải của nội dung', (tester) async {
      await _openDetail(tester, _repo([_product('p1')]), 'p1');

      final sku = tester.getRect(find.byKey(const Key('detail-sku')));
      expect(sku.right, closeTo(designSize.width - 20, 0.5));
    });

    testWidgets('giá 12.000.000 ₫ ở 360 với chữ x1.3 không overflow', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final product = _product('p1', price: 12000000, stock: 10);
      await _openDetail(tester, _repo([product]), 'p1', size: const Size(360, 800));

      expect(_text(tester, 'detail-price'), '12.000.000 ₫');
      expect(tester.takeException(), isNull);
      final price = tester.getRect(find.byKey(const Key('detail-price')));
      final sku = tester.getRect(find.byKey(const Key('detail-sku')));
      expect(price.right, lessThanOrEqualTo(sku.left));
      expect(sku.right, closeTo(360 - 20, 0.5));
      // Tổng tạm tính với số lượng tối đa vẫn không tràn
      for (var i = 0; i < 9; i++) {
        await _tapKey(tester, 'detail-qty-increase');
      }
      expect(_text(tester, 'detail-total'), '120.000.000 ₫');
      expect(tester.takeException(), isNull);
    });

    testWidgets('SKU rất dài tối đa 2 dòng, không đẩy giá', (tester) async {
      final product = ProductDetail(
        id: 'p1',
        sku: 'VERY-LONG-SKU-CODE-' * 6,
        name: 'Tên',
        price: 1234567,
        stock: 5,
        taxRate: 8,
        category: _flowers,
      );
      await _openDetail(tester, _repo([product]), 'p1', size: const Size(360, 800));

      final sku = find.byKey(const Key('detail-sku'));
      final style = tester.widget<Text>(sku).style!;
      expect(
        tester.getSize(sku).height,
        lessThanOrEqualTo(style.fontSize! * (style.height ?? 1.6) * 2 + 2),
      );
      expect(
        tester.getRect(find.byKey(const Key('detail-price'))).right,
        lessThanOrEqualTo(tester.getRect(sku).left),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('giá và tổng tiền dùng font sans, không phải Cormorant Garamond', (tester) async {
      await _openDetail(tester, _repo([_product('p1')]), 'p1');

      final price = tester.widget<Text>(find.byKey(const Key('detail-price'))).style!;
      final total = tester.widget<Text>(find.byKey(const Key('detail-total'))).style!;
      for (final style in [price, total]) {
        expect(style.fontFamily, 'Plus Jakarta Sans');
        expect(style.fontFamily, isNot('Cormorant Garamond'));
        expect(style.fontWeight, FontWeight.w700);
      }
      expect(price.fontSize, 20);
      expect(total.fontSize, 18);
    });
  });

  group('cuộn', () {
    testWidgets('nội dung cuộn được và bộ chọn số lượng nằm ở cuối', (tester) async {
      await _openDetail(
        tester,
        _repo([_product('p1', description: 'Mô tả dài. ' * 40)]),
        'p1',
      );
      final scroll = find.byKey(const Key('detail-scroll'));

      await tester.drag(scroll, const Offset(0, -2000));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('detail-quantity')), findsOneWidget);
      final quantityRect = tester.getRect(find.byKey(const Key('detail-quantity')));
      final barRect = tester.getRect(find.byKey(const Key('detail-purchase-bar')));
      // Thanh mua hàng không che bộ chọn số lượng
      expect(quantityRect.bottom, lessThanOrEqualTo(barRect.top));
    });

    testWidgets('thanh mua hàng luôn cố định ở đáy khi cuộn', (tester) async {
      await _openDetail(tester, _repo([_product('p1')]), 'p1');
      final before = tester.getRect(find.byKey(const Key('detail-purchase-bar')));

      await tester.drag(find.byKey(const Key('detail-scroll')), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(tester.getRect(find.byKey(const Key('detail-purchase-bar'))), before);
      expect(before.bottom, closeTo(designSize.height, 0.5));
    });
  });
}
