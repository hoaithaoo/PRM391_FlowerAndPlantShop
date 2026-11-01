import 'package:flutter/material.dart';

import 'screens/product_detail_screen.dart';

export 'screens/product_detail_screen.dart' show ProductDetailResult;

/// Tên route và điều hướng của luồng sản phẩm.
abstract final class ProductRoutes {
  /// Arguments: `String` productId.
  static const detail = '/products/detail';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final Widget? page = switch (settings.name) {
      detail => switch (settings.arguments) {
        final String productId => ProductDetailScreen(productId: productId),
        _ => null,
      },
      _ => null,
    };
    if (page == null) return null;
    return MaterialPageRoute<ProductDetailResult>(
      builder: (_) => page,
      settings: settings,
    );
  }

  static Future<ProductDetailResult?> openDetail(
    BuildContext context,
    String productId,
  ) {
    return Navigator.of(
      context,
    ).pushNamed<ProductDetailResult>(detail, arguments: productId);
  }
}
