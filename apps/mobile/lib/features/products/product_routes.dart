import 'package:flutter/material.dart';

import 'screens/product_detail_screen.dart';

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
    return MaterialPageRoute<void>(builder: (_) => page, settings: settings);
  }

  static Future<void> openDetail(BuildContext context, String productId) {
    return Navigator.of(context).pushNamed(detail, arguments: productId);
  }
}
