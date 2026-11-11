import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/app/main_shell.dart';
import 'package:plant_flower_mobile/features/favorites/data/mock_favorite_repository.dart';
import 'package:plant_flower_mobile/features/favorites/state/favorite_controller.dart';
import 'package:plant_flower_mobile/features/favorites/state/favorite_scope.dart';
import 'package:plant_flower_mobile/features/cart/state/cart_controller.dart';
import 'package:plant_flower_mobile/features/cart/state/cart_scope.dart';
import 'package:plant_flower_mobile/features/products/data/buy_now_scope.dart';
import 'package:plant_flower_mobile/features/products/data/mock_product_repository.dart';
import 'package:plant_flower_mobile/features/products/data/product_repository.dart';
import 'package:plant_flower_mobile/features/products/data/product_scope.dart';
import 'package:plant_flower_mobile/features/products/product_routes.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

import 'cart_test_repository.dart';

/// Kích thước màn hình thiết kế Penpot (390 x 844).
const designSize = Size(390, 844);

/// Repository giả không có độ trễ cho test.
MockProductRepository createTestRepository() =>
    MockProductRepository(latency: Duration.zero);

/// Dựng [child] trong MaterialApp có theme, [ProductScope] và route sản phẩm.
///
/// Đặt kích thước màn hình bằng [size] (mặc định [designSize]).
Future<void> pumpProductApp(
  WidgetTester tester,
  Widget child, {
  ProductRepository? repository,
  CartController? cartController,
  FavoriteController? favoriteController,
  BuyNowCallback? onBuyNow,
  Size size = designSize,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final cart =
      cartController ?? CartController(repository: TestCartRepository());
  if (cartController == null) addTearDown(cart.dispose);
  if (cart.status == CartStatus.initial) await cart.initialize();
  final favorites =
      favoriteController ??
      FavoriteController(repository: MockFavoriteRepository());
  if (favoriteController == null) addTearDown(favorites.dispose);
  await favorites.load();
  final app = CartScope(
    controller: cart,
    child: ProductScope(
      repository: repository ?? createTestRepository(),
      child: BuyNowScope(
        onBuyNow: onBuyNow ?? (_, _) {},
        child: MaterialApp(
          theme: AppTheme.data(),
          home: child,
          onGenerateRoute: ProductRoutes.onGenerateRoute,
        ),
      ),
    ),
  );
  await tester.pumpWidget(FavoriteScope(controller: favorites, child: app));
}

/// Dựng app đầy đủ (có thanh điều hướng) bắt đầu ở [initialTab].
Future<void> pumpMainShell(
  WidgetTester tester, {
  ProductRepository? repository,
  CartController? cartController,
  MainTab initialTab = MainTab.home,
  Size size = designSize,
}) {
  return pumpProductApp(
    tester,
    MainShell(initialTab: initialTab),
    repository: repository,
    cartController: cartController,
    size: size,
  );
}
