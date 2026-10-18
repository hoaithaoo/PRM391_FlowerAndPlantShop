import 'package:plant_flower_shared/plant_flower_shared.dart';

import 'api_client.dart';

/// Các endpoint public của category/product (`docs/spec.md` mục 7.3–7.5).
class ProductsApi {
  const ProductsApi(this._client);

  final ApiClient _client;

  Future<List<Category>> listCategories() async {
    final response = await _client.get('api/v1/categories');
    return [
      for (final item in _items(response.data))
        Category.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<PagedResult<ProductSummary>> listProducts(
    ProductQuery query, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _client.get(
      'api/v1/products',
      query: query.toQueryParameters(page: page, limit: limit),
    );
    final items = [
      for (final item in _items(response.data))
        ProductSummary.fromJson(item as Map<String, dynamic>),
    ];
    // Spec ghi `meta.page`; backend hiện trả paging ở meta ngoài cùng.
    // Đọc cả `data.meta` để không gãy nếu backend đổi theo spec.
    final dataMeta = switch (response.data) {
      {'meta': final Map<String, dynamic> meta} => meta,
      _ => const <String, dynamic>{},
    };
    num? read(String key) =>
        (response.meta[key] ?? dataMeta[key]) as num?;
    final total = read('total')?.toInt() ?? items.length;
    return PagedResult(
      items: items,
      page: read('page')?.toInt() ?? page,
      total: total,
      totalPages: read('totalPages')?.toInt() ?? (total / limit).ceil(),
    );
  }

  Future<ProductDetail> getProduct(String id) async {
    final response = await _client.get(
      'api/v1/products/${Uri.encodeComponent(id)}',
    );
    return ProductDetail.fromJson(response.data as Map<String, dynamic>);
  }

  static List<dynamic> _items(Object? data) => switch (data) {
    {'items': final List<dynamic> items} => items,
    final List<dynamic> list => list,
    _ => const [],
  };
}
