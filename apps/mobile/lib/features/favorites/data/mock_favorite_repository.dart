import 'package:plant_flower_shared/plant_flower_shared.dart';

import 'favorite_repository.dart';

/// Kho trong bộ nhớ, có thể truyền sản phẩm mẫu cho test hoặc bản demo.
class MockFavoriteRepository implements FavoriteRepository {
  MockFavoriteRepository({
    Iterable<ProductSummary> products = const [],
    Iterable<String> initialIds = const [],
  }) : _products = {for (final product in products) product.id: product},
       _ids = {...initialIds};

  final Map<String, ProductSummary> _products;
  final Set<String> _ids;

  @override
  Future<Set<String>> listIds() async => {..._ids};

  @override
  Future<List<ProductSummary>> list() async => [
    for (final id in _ids.toList().reversed) ?_products[id],
  ];

  @override
  Future<void> add(String productId) async {
    _ids.add(productId);
  }

  @override
  Future<void> remove(String productId) async {
    _ids.remove(productId);
  }
}
