import 'package:flutter/widgets.dart';

import 'product_repository.dart';

/// Cung cấp [ProductRepository] cho các màn sản phẩm qua cây widget.
class ProductScope extends InheritedWidget {
  const ProductScope({
    super.key,
    required this.repository,
    required super.child,
  });

  final ProductRepository repository;

  static ProductRepository of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<ProductScope>();
    assert(scope != null, 'Không tìm thấy ProductScope phía trên widget này.');
    return scope!.repository;
  }

  @override
  bool updateShouldNotify(ProductScope oldWidget) {
    return repository != oldWidget.repository;
  }
}
