import 'package:plant_flower_shared/plant_flower_shared.dart';

/// Nguồn dữ liệu category/product cho các màn sản phẩm.
///
/// Lỗi được ném ra dưới dạng [ProductFailure] với câu tiếng Việt để hiển thị.
abstract interface class ProductRepository {
  /// Danh mục để làm chip lọc.
  Future<List<Category>> listCategories();

  /// Một trang sản phẩm theo offset paging (`page` bắt đầu từ 1).
  Future<PagedResult<ProductSummary>> listProducts(
    ProductQuery query, {
    int page = 1,
    int limit = 20,
  });

  /// Chi tiết sản phẩm; ném [ProductFailure] với [ProductFailure.notFound]
  /// khi sản phẩm không tồn tại hoặc đã ngừng bán.
  Future<ProductDetail> getProduct(String id);
}

/// Lỗi khi tải dữ liệu sản phẩm.
class ProductFailure implements Exception {
  const ProductFailure(this.message, {this.notFound = false, this.offline = false});

  /// Câu tiếng Việt có thể hiển thị cho người dùng.
  final String message;

  /// Sản phẩm không tồn tại hoặc không còn bán (404).
  final bool notFound;

  /// Không kết nối được máy chủ.
  final bool offline;

  @override
  String toString() => 'ProductFailure($message)';
}
