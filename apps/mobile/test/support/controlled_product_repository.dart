import 'dart:async';

import 'package:plant_flower_mobile/features/products/data/product_repository.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';

/// Một lần gọi `listProducts` đang chờ test quyết định kết quả.
class PendingListCall {
  PendingListCall(this.query, this.page, this.limit);

  final ProductQuery query;
  final int page;
  final int limit;
  final Completer<PagedResult<ProductSummary>> _completer = Completer();

  bool get isCompleted => _completer.isCompleted;

  void complete(PagedResult<ProductSummary> result) =>
      _completer.complete(result);

  void fail(Object error) => _completer.completeError(error);
}

/// Repository mà test tự điều khiển thời điểm và kết quả của từng request.
///
/// Dùng để dựng race (response cũ về muộn) mà không phụ thuộc thời gian thật.
class ControlledProductRepository implements ProductRepository {
  ControlledProductRepository({
    this.categories = const [],
    this.categoriesError,
    this.detail,
    this.heldLimit,
  });

  /// Khác null thì chỉ giữ lại (chờ test quyết định) các lần gọi `listProducts`
  /// có `limit` này; lần gọi khác trả ngay trang rỗng. Dùng khi nhiều màn
  /// cùng gọi (ví dụ trang chủ limit 4 và danh mục limit 20 trong MainShell).
  final int? heldLimit;

  List<Category> categories;

  /// Khác null thì `listCategories` ném lỗi này (một lần rồi tự xoá).
  Object? categoriesError;

  /// Nếu đặt, [getProduct] trả về bản ghi này khi id khớp.
  ProductDetail? detail;

  final List<PendingListCall> calls = [];
  int listCategoriesCalls = 0;

  @override
  Future<List<Category>> listCategories() async {
    listCategoriesCalls++;
    final error = categoriesError;
    if (error != null) {
      categoriesError = null;
      throw error;
    }
    return categories;
  }

  @override
  Future<PagedResult<ProductSummary>> listProducts(
    ProductQuery query, {
    int page = 1,
    int limit = 20,
  }) {
    if (heldLimit != null && limit != heldLimit) {
      return Future.value(pageOf(const [], totalPages: 0));
    }
    final call = PendingListCall(query, page, limit);
    calls.add(call);
    return call._completer.future;
  }

  @override
  Future<ProductDetail> getProduct(String id) async {
    final value = detail;
    if (value != null && value.id == id) return value;
    throw const ProductFailure('Không tìm thấy', notFound: true);
  }
}

const testCategory = Category(id: 'cat-1', name: 'Hoa tươi');

ProductSummary summary(
  String id, {
  int price = 100000,
  int stock = 5,
  Category category = testCategory,
  String? name,
}) {
  return ProductSummary(
    id: id,
    sku: 'SKU-$id',
    name: name ?? 'Sản phẩm $id',
    price: price,
    stock: stock,
    category: category,
  );
}

PagedResult<ProductSummary> pageOf(
  List<ProductSummary> items, {
  int page = 1,
  int? total,
  int totalPages = 1,
}) {
  return PagedResult(
    items: items,
    page: page,
    total: total ?? items.length,
    totalPages: totalPages,
  );
}

/// Sinh [count] sản phẩm với id `p001`, `p002`... giá tăng dần.
List<ProductDetail> generateProducts(
  int count, {
  Category category = testCategory,
}) {
  return [
    for (var i = 1; i <= count; i++)
      ProductDetail(
        id: 'p${i.toString().padLeft(3, '0')}',
        sku: 'GEN-${i.toString().padLeft(3, '0')}',
        name: 'Sản phẩm số ${i.toString().padLeft(3, '0')}',
        price: 10000 * i,
        stock: 5,
        taxRate: 8,
        category: category,
      ),
  ];
}
