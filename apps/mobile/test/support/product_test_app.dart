import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/app/main_shell.dart';
import 'package:plant_flower_mobile/features/products/data/mock_product_repository.dart';
import 'package:plant_flower_mobile/features/products/data/product_repository.dart';
import 'package:plant_flower_mobile/features/products/data/product_scope.dart';
import 'package:plant_flower_mobile/features/products/product_routes.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

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
  Size size = designSize,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProductScope(
      repository: repository ?? createTestRepository(),
      child: MaterialApp(
        theme: AppTheme.data(),
        home: child,
        onGenerateRoute: ProductRoutes.onGenerateRoute,
      ),
    ),
  );
}

/// Dựng app đầy đủ (có thanh điều hướng) bắt đầu ở [initialTab].
Future<void> pumpMainShell(
  WidgetTester tester, {
  ProductRepository? repository,
  MainTab initialTab = MainTab.home,
  Size size = designSize,
}) {
  return pumpProductApp(
    tester,
    MainShell(initialTab: initialTab),
    repository: repository,
    size: size,
  );
}
