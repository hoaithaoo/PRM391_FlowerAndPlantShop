import 'package:plant_flower_api_client/plant_flower_api_client.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';

import 'product_repository.dart';

/// Gọi REST API thật (`GET /api/v1/categories`, `/products`, `/products/:id`).
class ApiProductRepository implements ProductRepository {
  ApiProductRepository(this._api);

  final ProductsApi _api;

  @override
  Future<List<Category>> listCategories() => _guard(_api.listCategories);

  @override
  Future<PagedResult<ProductSummary>> listProducts(
    ProductQuery query, {
    int page = 1,
    int limit = 20,
  }) {
    return _guard(() => _api.listProducts(query, page: page, limit: limit));
  }

  @override
  Future<ProductDetail> getProduct(String id) {
    return _guard(() => _api.getProduct(id));
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on ApiException catch (error) {
      throw ProductFailure(
        error.isNotFound && error.code == 'PRODUCT_NOT_FOUND'
            ? 'Sản phẩm không tồn tại hoặc đã ngừng bán.'
            : error.message,
        notFound: error.isNotFound,
        offline: error.isNetworkError,
      );
    }
  }
}
