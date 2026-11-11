import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/favorites/data/mock_favorite_repository.dart';
import 'package:plant_flower_mobile/features/favorites/screens/favorites_screen.dart';
import 'package:plant_flower_mobile/features/favorites/state/favorite_controller.dart';
import 'package:plant_flower_mobile/features/products/screens/product_detail_screen.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';

import '../../support/product_test_app.dart';

const _product = ProductSummary(
  id: 'one',
  sku: 'HOA-01',
  name: 'Hoa yêu thích',
  price: 250000,
  stock: 5,
  category: Category(id: 'flowers', name: 'Hoa tươi'),
);

Future<FavoriteController> _pump(
  WidgetTester tester,
  MockFavoriteRepository repo,
) async {
  final controller = FavoriteController(repository: repo);
  addTearDown(controller.dispose);
  await pumpProductApp(
    tester,
    const FavoritesScreen(),
    favoriteController: controller,
  );
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  testWidgets('rỗng có tiêu đề và nút khám phá', (tester) async {
    await _pump(tester, MockFavoriteRepository());
    expect(find.text('Yêu thích'), findsOneWidget);
    expect(find.text('Chưa có sản phẩm yêu thích'), findsOneWidget);
    expect(find.text('Khám phá sản phẩm'), findsOneWidget);
  });

  testWidgets('có dữ liệu và bấm tim bỏ sản phẩm khỏi lưới', (tester) async {
    final repo = MockFavoriteRepository(
      products: [_product],
      initialIds: ['one'],
    );
    final controller = await _pump(tester, repo);
    expect(find.text('Hoa yêu thích'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    await tester.tap(find.byKey(const Key('catalog-favorite-one')));
    await tester.pumpAndSettle();
    expect(find.text('Hoa yêu thích'), findsNothing);
    expect(find.text('Chưa có sản phẩm yêu thích'), findsOneWidget);
    expect(controller.ids, isEmpty);
    expect(await repo.listIds(), isEmpty);
  });

  testWidgets('bỏ tim lỗi khôi phục thẻ và hiện thông báo', (tester) async {
    final controller = await _pump(tester, _RemoveFailureRepository());
    await tester.tap(find.byKey(const Key('catalog-favorite-one')));
    await tester.pumpAndSettle();
    expect(find.text('Hoa yêu thích'), findsOneWidget);
    expect(controller.ids, {'one'});
    expect(
      find.text('Chưa cập nhật được yêu thích. Vui lòng thử lại.'),
      findsOneWidget,
    );
  });

  testWidgets('lỗi tải có nút thử lại, thử lại lấy được dữ liệu', (
    tester,
  ) async {
    final repo = _ListFailureRepository();
    await _pump(tester, repo);
    expect(find.text('Thử lại'), findsOneWidget);
    repo.fail = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Hoa yêu thích'), findsOneWidget);
    expect(find.text('Thử lại'), findsNothing);
  });

  testWidgets('đang tải và kéo để làm mới', (tester) async {
    final repo = _GatedListRepository();
    final controller = FavoriteController(repository: repo);
    addTearDown(controller.dispose);
    await pumpProductApp(
      tester,
      const FavoritesScreen(),
      favoriteController: controller,
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repo.result.complete([_product]);
    await tester.pumpAndSettle();
    expect(repo.calls, 1);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 450));
    await tester.pumpAndSettle();
    expect(repo.calls, 2);
  });

  testWidgets('nút tim chi tiết đổi trạng thái, có action Xem và bỏ tim', (
    tester,
  ) async {
    final repo = createTestRepository();
    final products = await repo.listProducts(const ProductQuery());
    final id = products.items.first.id;
    final controller = FavoriteController(repository: MockFavoriteRepository());
    addTearDown(controller.dispose);
    await pumpProductApp(
      tester,
      ProductDetailScreen(productId: id),
      repository: repo,
      favoriteController: controller,
    );
    await tester.pumpAndSettle();
    final heart = find.byKey(const Key('detail-favorite'));
    expect(tester.widget<IconButton>(heart).tooltip, 'Thêm vào yêu thích');
    expect(tester.getSize(heart), const Size(40, 40));
    await tester.tap(heart);
    await tester.pumpAndSettle();
    expect(controller.isFavorite(id), isTrue);
    expect(tester.widget<IconButton>(heart).tooltip, 'Bỏ yêu thích');
    expect(find.text('Đã thêm vào Yêu thích'), findsOneWidget);
    expect(find.text('Xem'), findsOneWidget);
    await tester.tap(find.text('Xem'));
    await tester.pumpAndSettle();
    expect(find.byType(FavoritesScreen), findsOneWidget);
    await tester.tap(find.byKey(const Key('header-back')));
    await tester.pumpAndSettle();
    await tester.tap(heart);
    await tester.pumpAndSettle();
    expect(controller.isFavorite(id), isFalse);
    expect(find.text('Đã bỏ khỏi Yêu thích'), findsOneWidget);
  });
}

class _RemoveFailureRepository extends MockFavoriteRepository {
  _RemoveFailureRepository() : super(products: [_product], initialIds: ['one']);
  @override
  Future<void> remove(String productId) async => throw Exception('Mất mạng');
}

class _ListFailureRepository extends MockFavoriteRepository {
  _ListFailureRepository() : super(products: [_product], initialIds: ['one']);
  bool fail = true;
  @override
  Future<List<ProductSummary>> list() async {
    if (fail) throw Exception('Mất mạng');
    return super.list();
  }
}

class _GatedListRepository extends MockFavoriteRepository {
  _GatedListRepository() : super(initialIds: ['one']);
  final result = Completer<List<ProductSummary>>();
  int calls = 0;
  @override
  Future<List<ProductSummary>> list() {
    calls++;
    return result.future;
  }
}
