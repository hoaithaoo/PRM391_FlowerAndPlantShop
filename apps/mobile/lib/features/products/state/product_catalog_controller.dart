import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';

import '../data/product_repository.dart';
import 'product_catalog_state.dart';

/// Điều phối tải danh sách sản phẩm: bộ lọc, tìm kiếm có debounce, phân trang.
///
/// Logic thuần, không phụ thuộc `BuildContext`. Mỗi lần tải trang 1 tăng một
/// "token"; kết quả của request cũ (token lệch) bị bỏ qua nên không ghi đè
/// bộ lọc mới.
class ProductCatalogController extends ChangeNotifier {
  ProductCatalogController({
    required this.repository,
    String? initialCategoryId,
    this.pageSize = 20,
    this.searchDebounce = const Duration(milliseconds: 400),
  }) : _state = ProductCatalogState(
         query: ProductQuery(categoryId: initialCategoryId),
       );

  final ProductRepository repository;
  final int pageSize;
  final Duration searchDebounce;

  ProductCatalogState _state;
  Timer? _debounce;

  // Từ khoá đang chờ debounce (hợp lệ khi _debounce còn active).
  String? _pendingSearch;
  int _token = 0;
  bool _disposed = false;

  ProductCatalogState get state => _state;

  /// Tải category và trang đầu song song. Không bao giờ ném lỗi.
  ///
  /// Trạng thái ban đầu đã là "đang tải" nên không notify đồng bộ, an toàn khi
  /// gọi trong lúc dựng widget.
  Future<void> initialize() {
    return Future.wait([_loadCategories(), _loadFirstPage(announce: false)]);
  }

  // --- Bộ lọc -------------------------------------------------------------

  /// Gõ chữ tìm kiếm: áp dụng sau [searchDebounce] kể từ lần gõ cuối.
  void setSearchText(String text) {
    _debounce?.cancel();
    final search = _normalizeSearch(text);
    if (search == _state.query.search) return;
    _pendingSearch = search;
    _debounce = Timer(searchDebounce, () {
      _applyQuery(_state.query.copyWith(search: search));
    });
  }

  /// Nhấn tìm kiếm trên bàn phím: áp dụng ngay.
  void submitSearch(String text) {
    _debounce?.cancel();
    _applyQuery(_state.query.copyWith(search: _normalizeSearch(text)));
  }

  /// Chọn danh mục; null là "Tất cả".
  void selectCategory(String? categoryId) {
    _applyQuery(_state.query.copyWith(categoryId: categoryId));
  }

  void setSort(ProductSort sort) {
    _applyQuery(_state.query.copyWith(sort: sort));
  }

  /// Áp dụng khoảng giá; giá trị null là không giới hạn đầu đó.
  ///
  /// Bỏ qua khi [min] lớn hơn [max] (UI đã báo lỗi trước khi gọi).
  void applyPriceFilter({int? min, int? max}) {
    if (min != null && max != null && min > max) return;
    _applyQuery(_state.query.copyWith(minPrice: min, maxPrice: max));
  }

  void clearPriceFilter() => applyPriceFilter();

  /// Đưa mọi bộ lọc về mặc định: tất cả danh mục, không tìm kiếm/giá, mới nhất.
  void resetFilters() {
    _debounce?.cancel();
    _applyQuery(const ProductQuery());
  }

  // --- Tải dữ liệu -------------------------------------------------------

  /// Tải lại trang 1 sau lỗi toàn màn; nếu category trước đó chưa tải được
  /// thì tải lại song song (category lỗi tiếp vẫn không chặn danh sách).
  Future<void> retry() {
    return Future.wait([
      if (_state.categories.isEmpty) _loadCategories(),
      _loadFirstPage(),
    ]);
  }

  /// Kéo để làm mới: giữ danh sách cũ cho tới khi có kết quả mới.
  ///
  /// Trả về false khi thất bại (danh sách cũ, nếu có, được giữ nguyên).
  ///
  /// Từ khoá đang chờ debounce được áp dụng ngay để query khớp ô tìm kiếm.
  Future<bool> refresh() async {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
      _set(
        _state.copyWith(query: _state.query.copyWith(search: _pendingSearch)),
      );
    }
    if (_state.categories.isEmpty) unawaited(_loadCategories());
    final token = ++_token;
    final query = _state.query;
    _set(_state.copyWith(loadingMore: false, loadMoreError: null));
    try {
      final result = await repository.listProducts(query, page: 1, limit: pageSize);
      if (_isStale(token)) return true;
      _set(_readyState(result));
      return true;
    } catch (error) {
      if (_isStale(token)) return false;
      if (_state.items.isEmpty) {
        _set(
          _state.copyWith(
            status: CatalogStatus.error,
            error: _asFailure(error),
          ),
        );
      }
      return false;
    }
  }

  /// Tự tải trang kế khi cuộn gần cuối; bỏ qua nếu không đủ điều kiện hoặc
  /// lần tải thêm trước đó đang lỗi (dùng [retryLoadMore] để thử lại).
  Future<void> loadMore() async {
    if (!_state.canLoadMore) return;
    await _fetchNextPage();
  }

  /// Thử lại trang kế sau khi tải thêm bị lỗi.
  Future<void> retryLoadMore() async {
    if (_state.status != CatalogStatus.ready ||
        !_state.hasMore ||
        _state.loadingMore) {
      return;
    }
    await _fetchNextPage();
  }

  // --- Nội bộ ------------------------------------------------------------

  static String? _normalizeSearch(String text) {
    final trimmed = text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _applyQuery(ProductQuery query) {
    if (query == _state.query) return;
    _set(_state.copyWith(query: query));
    unawaited(_loadFirstPage());
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await repository.listCategories();
      _set(_state.copyWith(categories: categories));
    } catch (_) {
      // Lỗi category không chặn danh sách: chỉ còn chip "Tất cả".
    }
  }

  Future<void> _loadFirstPage({bool announce = true}) async {
    final token = ++_token;
    final query = _state.query;
    final loading = _state.copyWith(
      status: CatalogStatus.loading,
      items: const [],
      total: 0,
      page: 0,
      hasMore: false,
      loadingMore: false,
      error: null,
      loadMoreError: null,
    );
    if (announce) {
      _set(loading);
    } else {
      _state = loading;
    }
    try {
      final result = await repository.listProducts(query, page: 1, limit: pageSize);
      if (_isStale(token)) return;
      _set(_readyState(result));
    } catch (error) {
      if (_isStale(token)) return;
      _set(
        _state.copyWith(status: CatalogStatus.error, error: _asFailure(error)),
      );
    }
  }

  Future<void> _fetchNextPage() async {
    final token = _token;
    final query = _state.query;
    final nextPage = _state.page + 1;
    _set(_state.copyWith(loadingMore: true, loadMoreError: null));
    try {
      final result = await repository.listProducts(
        query,
        page: nextPage,
        limit: pageSize,
      );
      if (_isStale(token)) return;
      final known = {for (final item in _state.items) item.id};
      _set(
        _state.copyWith(
          items: [
            ..._state.items,
            for (final item in result.items)
              if (!known.contains(item.id)) item,
          ],
          total: result.total,
          page: result.page,
          hasMore: result.hasMore,
          loadingMore: false,
        ),
      );
    } catch (error) {
      if (_isStale(token)) return;
      _set(_state.copyWith(loadingMore: false, loadMoreError: _asFailure(error)));
    }
  }

  ProductCatalogState _readyState(PagedResult<ProductSummary> result) {
    return _state.copyWith(
      status: CatalogStatus.ready,
      items: result.items,
      total: result.total,
      page: result.page,
      hasMore: result.hasMore,
      loadingMore: false,
      error: null,
      loadMoreError: null,
    );
  }

  bool _isStale(int token) => _disposed || token != _token;

  static ProductFailure _asFailure(Object error) {
    if (error is ProductFailure) return error;
    return const ProductFailure(
      'Không tải được danh sách sản phẩm. Vui lòng thử lại.',
    );
  }

  void _set(ProductCatalogState next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    super.dispose();
  }
}
