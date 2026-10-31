import 'dart:async';

import 'package:plant_flower_mobile/features/products/data/product_repository.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';

/// Một lần gọi `getProduct` đang chờ test quyết định kết quả.
class PendingDetailCall {
  PendingDetailCall(this.id);

  final String id;
  final Completer<ProductDetail> _completer = Completer();

  void complete(ProductDetail product) => _completer.complete(product);

  void fail(Object error) => _completer.completeError(error);
}

/// Repository chỉ phục vụ màn chi tiết: mỗi `getProduct` chờ test điều khiển.
class GatedDetailRepository implements ProductRepository {
  final List<PendingDetailCall> calls = [];

  @override
  Future<ProductDetail> getProduct(String id) {
    final call = PendingDetailCall(id);
    calls.add(call);
    return call._completer.future;
  }

  @override
  Future<List<Category>> listCategories() async => const [];

  @override
  Future<PagedResult<ProductSummary>> listProducts(
    ProductQuery query, {
    int page = 1,
    int limit = 20,
  }) async {
    return const PagedResult(items: [], page: 1, total: 0, totalPages: 0);
  }
}
