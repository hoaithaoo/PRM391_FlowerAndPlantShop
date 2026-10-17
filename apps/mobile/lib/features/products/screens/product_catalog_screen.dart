import 'package:flutter/material.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

import '../../../app/main_shell.dart';
import '../data/product_scope.dart';
import '../product_routes.dart';
import '../state/product_catalog_controller.dart';
import '../state/product_catalog_state.dart';
import '../widgets/catalog/catalog_category_chips.dart';
import '../widgets/catalog/catalog_footer.dart';
import '../widgets/catalog/catalog_header.dart';
import '../widgets/catalog/catalog_product_card.dart';
import '../widgets/catalog/catalog_search_field.dart';
import '../widgets/catalog/catalog_sort_bar.dart';
import '../widgets/catalog/catalog_status_row.dart';
import '../widgets/catalog/price_filter_sheet.dart';
import '../widgets/common/brand_header.dart';

/// Danh mục sản phẩm (Penpot: "Danh mục sản phẩm - Fleuré").
///
/// Tìm kiếm, lọc danh mục/giá, sắp xếp và phân trang vô hạn; logic nằm ở
/// [ProductCatalogController].
class ProductCatalogScreen extends StatefulWidget {
  const ProductCatalogScreen({super.key, this.initialCategoryId});

  /// Category được chọn sẵn khi mở từ trang chủ; null là "Tất cả".
  final String? initialCategoryId;

  @override
  State<ProductCatalogScreen> createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
  /// Khoảng còn lại phía dưới (px) để bắt đầu tải trang kế.
  static const _loadMoreThreshold = 600.0;

  final _scroll = ScrollController();
  final _searchText = TextEditingController();

  // Yêu thích chỉ lưu trong phiên, chưa có API.
  final _favorites = <String>{};

  ProductCatalogController? _controller;
  bool _loadMoreCheckScheduled = false;

  ProductCatalogController get _ctrl => _controller!;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_checkLoadMore);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    _controller = ProductCatalogController(
      repository: ProductScope.of(context),
      initialCategoryId: widget.initialCategoryId,
    )..addListener(_scheduleLoadMoreCheck);
    _ctrl.initialize();
  }

  @override
  void dispose() {
    _controller?.removeListener(_scheduleLoadMoreCheck);
    _controller?.dispose();
    _scroll.dispose();
    _searchText.dispose();
    super.dispose();
  }

  /// Danh sách chưa đủ dài để cuộn (hoặc vừa nối thêm trang) thì vẫn phải
  /// kiểm tra xem có cần tải tiếp không.
  void _scheduleLoadMoreCheck() {
    if (_loadMoreCheckScheduled) return;
    _loadMoreCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMoreCheckScheduled = false;
      if (mounted) _checkLoadMore();
    });
  }

  void _checkLoadMore() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.extentAfter < _loadMoreThreshold) _ctrl.loadMore();
  }

  void _scrollToTop() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _refresh() async {
    final ok = await _ctrl.refresh();
    if (!ok && mounted && _ctrl.state.items.isNotEmpty) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Không thể làm mới. Vui lòng thử lại.')),
      );
    }
  }

  void _clearSearch() {
    _searchText.clear();
    _ctrl.submitSearch('');
  }

  void _resetFilters() {
    _searchText.clear();
    _ctrl.resetFilters();
  }

  Future<void> _openPriceFilter() async {
    final query = _ctrl.state.query;
    final range = await showPriceFilterSheet(
      context,
      min: query.minPrice,
      max: query.maxPrice,
    );
    if (range == null || !mounted) return;
    _ctrl.applyPriceFilter(min: range.min, max: range.max);
  }

  void _toggleFavorite(String productId) {
    setState(() {
      if (!_favorites.remove(productId)) _favorites.add(productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: Column(
        children: [
          const BrandHeader(),
          Expanded(
            child: ListenableBuilder(
              listenable: _ctrl,
              builder: (context, _) => RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.surface,
                onRefresh: _refresh,
                child: CustomScrollView(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: _buildSlivers(context, _ctrl.state),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSlivers(BuildContext context, ProductCatalogState state) {
    final query = state.query;
    return [
      const SliverPadding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
        sliver: SliverToBoxAdapter(child: CatalogSubHeader()),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        sliver: SliverToBoxAdapter(
          child: CatalogSearchField(
            controller: _searchText,
            onChanged: _ctrl.setSearchText,
            onSubmitted: _ctrl.submitSearch,
            onClear: _clearSearch,
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.only(top: 12),
        sliver: SliverToBoxAdapter(
          child: CatalogCategoryChips(
            categories: state.categories,
            selectedId: query.categoryId,
            onSelected: _ctrl.selectCategory,
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        sliver: SliverToBoxAdapter(
          child: CatalogSortBar(
            sort: query.sort,
            minPrice: query.minPrice,
            maxPrice: query.maxPrice,
            onSortChanged: _ctrl.setSort,
            onPriceFilterTap: _openPriceFilter,
          ),
        ),
      ),
      ..._buildBody(context, state),
      const SliverToBoxAdapter(
        child: SizedBox(height: AppBottomNav.reservedHeight),
      ),
    ];
  }

  List<Widget> _buildBody(BuildContext context, ProductCatalogState state) {
    switch (state.status) {
      case CatalogStatus.loading:
        return const [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 72),
              child: Center(
                child: CircularProgressIndicator(key: Key('catalog-loading')),
              ),
            ),
          ),
        ];
      case CatalogStatus.error:
        final error = state.error;
        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: CatalogMessage(
                title: 'Không tải được sản phẩm',
                body: error != null && error.offline
                    ? 'Không có kết nối mạng. Vui lòng kiểm tra kết nối và thử lại.'
                    : error?.message ?? 'Đã có lỗi xảy ra. Vui lòng thử lại.',
                illustration: const Icon(
                  Icons.cloud_off_outlined,
                  size: 48,
                  color: AppColors.iconInactive,
                ),
                actionKey: const Key('catalog-retry'),
                actionLabel: 'Thử lại',
                onAction: _ctrl.retry,
              ),
            ),
          ),
        ];
      case CatalogStatus.ready:
        if (state.items.isEmpty) return [_buildEmpty(state)];
        return _buildProducts(state);
    }
  }

  Widget _buildEmpty(ProductCatalogState state) {
    final search = state.query.search;
    final hasFilters = state.hasActiveFilters;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 32),
        child: CatalogMessage(
          key: const Key('catalog-empty'),
          title: hasFilters
              ? 'Không tìm thấy tác phẩm phù hợp'
              : 'Chưa có sản phẩm nào',
          body: !hasFilters
              ? 'Xưởng hoa đang chuẩn bị thêm tác phẩm mới. Bạn quay lại sau nhé.'
              : search != null
              ? 'Rất tiếc, xưởng hoa hiện chưa có tác phẩm hoặc chậu cây khớp với từ khóa “$search”. Bạn hãy thử điều chỉnh từ khóa hoặc làm mới bộ lọc nhé.'
              : 'Rất tiếc, xưởng hoa hiện chưa có tác phẩm hoặc chậu cây khớp với bộ lọc hiện tại. Bạn hãy thử điều chỉnh hoặc xóa bộ lọc nhé.',
          illustration: const CatalogEmptyIllustration(),
          actionKey: hasFilters ? const Key('catalog-reset-filters') : null,
          actionLabel: hasFilters ? 'Xóa tất cả bộ lọc' : null,
          onAction: hasFilters ? _resetFilters : null,
        ),
      ),
    );
  }

  List<Widget> _buildProducts(ProductCatalogState state) {
    final items = state.items;
    final rowCount = (items.length + 1) ~/ 2;

    Widget card(ProductSummary product) => CatalogProductCard(
      product: product,
      isFavorite: _favorites.contains(product.id),
      onTap: () => ProductRoutes.openDetail(context, product.id),
      onToggleFavorite: () => _toggleFavorite(product.id),
    );

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        sliver: SliverToBoxAdapter(child: CatalogStatusRow(total: state.total)),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        sliver: SliverList.builder(
          itemCount: rowCount,
          itemBuilder: (context, row) {
            final first = row * 2;
            return Padding(
              padding: EdgeInsets.only(bottom: row == rowCount - 1 ? 0 : 24),
              child: CatalogProductRow(
                cards: [
                  card(items[first]),
                  if (first + 1 < items.length) card(items[first + 1]),
                ],
              ),
            );
          },
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
        sliver: SliverToBoxAdapter(
          child: CatalogListFooter(
            loadingMore: state.loadingMore,
            hasMore: state.hasMore,
            loadMoreError: state.loadMoreError,
            onRetry: _ctrl.retryLoadMore,
            onScrollToTop: _scrollToTop,
          ),
        ),
      ),
    ];
  }
}
