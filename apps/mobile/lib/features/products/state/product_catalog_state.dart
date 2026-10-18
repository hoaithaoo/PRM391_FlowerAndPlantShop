import 'package:plant_flower_shared/plant_flower_shared.dart';

import '../data/product_repository.dart';

/// Giai đoạn tải danh sách ở trang 1.
enum CatalogStatus {
  /// Đang tải trang đầu (lần đầu hoặc sau khi đổi bộ lọc).
  loading,

  /// Có kết quả (có thể rỗng).
  ready,

  /// Tải trang đầu thất bại.
  error,
}

/// Trạng thái bất biến của màn danh mục sản phẩm.
class ProductCatalogState {
  const ProductCatalogState({
    this.query = const ProductQuery(),
    this.categories = const [],
    this.status = CatalogStatus.loading,
    this.items = const [],
    this.total = 0,
    this.page = 0,
    this.hasMore = false,
    this.loadingMore = false,
    this.error,
    this.loadMoreError,
  });

  /// Bộ lọc đang áp dụng (`search` đã trim, rỗng thì null).
  final ProductQuery query;

  /// Category để làm chip; rỗng khi chưa tải xong hoặc tải lỗi.
  final List<Category> categories;
  final CatalogStatus status;

  /// Các sản phẩm đã tải, theo thứ tự trang.
  final List<ProductSummary> items;

  /// Tổng số sản phẩm khớp bộ lọc theo API.
  final int total;

  /// Trang cuối đã tải (0 khi chưa có).
  final int page;
  final bool hasMore;
  final bool loadingMore;

  /// Lỗi khi tải trang đầu (khi [status] là [CatalogStatus.error]).
  final ProductFailure? error;

  /// Lỗi khi tải thêm trang kế; danh sách đã có vẫn giữ nguyên.
  final ProductFailure? loadMoreError;

  bool get isLoading => status == CatalogStatus.loading;
  bool get isEmpty => status == CatalogStatus.ready && items.isEmpty;

  /// Đang có bộ lọc khác mặc định (tìm kiếm, danh mục, giá, sắp xếp).
  bool get hasActiveFilters =>
      (query.search?.isNotEmpty ?? false) ||
      query.categoryId != null ||
      query.hasPriceFilter ||
      query.sort != ProductSort.newest;

  /// Có thể tự động tải trang kế.
  bool get canLoadMore =>
      status == CatalogStatus.ready &&
      hasMore &&
      !loadingMore &&
      loadMoreError == null;

  ProductCatalogState copyWith({
    ProductQuery? query,
    List<Category>? categories,
    CatalogStatus? status,
    List<ProductSummary>? items,
    int? total,
    int? page,
    bool? hasMore,
    bool? loadingMore,
    Object? error = _unset,
    Object? loadMoreError = _unset,
  }) {
    return ProductCatalogState(
      query: query ?? this.query,
      categories: categories ?? this.categories,
      status: status ?? this.status,
      items: items ?? this.items,
      total: total ?? this.total,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      error: identical(error, _unset) ? this.error : error as ProductFailure?,
      loadMoreError: identical(loadMoreError, _unset)
          ? this.loadMoreError
          : loadMoreError as ProductFailure?,
    );
  }
}

const Object _unset = Object();
