import 'package:flutter/material.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

import '../../../app/main_shell.dart';
import '../data/product_repository.dart';
import '../data/product_scope.dart';
import '../product_routes.dart';
import '../widgets/common/brand_header.dart';
import '../widgets/home/home_category_chips.dart';
import '../widgets/home/home_hero_banner.dart';
import '../widgets/home/home_note_card.dart';
import '../widgets/home/home_product_grid.dart';
import '../widgets/home/home_search_bar.dart';
import '../widgets/home/home_section_header.dart';
import '../widgets/home/home_story_card.dart';

/// Trang chủ (Penpot: "Trang chủ - Fleuré").
///
/// Không tự tìm kiếm: các điểm chạm dẫn sang tab Sản phẩm qua
/// [MainShell.openCatalog]. Chỉ tải category cho chip và 4 sản phẩm mới nhất.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _featuredCount = 4;

  late final ProductRepository _repository;
  List<Category> _categories = const [];
  List<ProductSummary> _products = const [];
  bool _loading = true;
  String? _error;

  // Bỏ qua kết quả của lần tải cũ khi đã có lần tải mới
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _repository = ProductScope.of(context);
    _load();
  }

  /// Tải category + sản phẩm. [refresh] là kéo-để-làm-mới: nếu đã có dữ liệu
  /// mà tải lỗi thì giữ dữ liệu cũ và báo bằng SnackBar thay vì hiện khối lỗi.
  Future<void> _load({bool refresh = false}) async {
    final requestId = ++_requestId;
    // Đã có dữ liệu hiển thị từ lần tải trước (không phải đang loading/lỗi)
    final hasData = refresh && !_loading && _error == null;
    final categories = _repository.listCategories().then<List<Category>?>(
      (value) => value,
      // Lỗi category chỉ làm mất chip, trang vẫn dùng được
      onError: (_) => null,
    );
    List<ProductSummary> products = const [];
    String? error;
    try {
      final page = await _repository.listProducts(
        const ProductQuery(),
        limit: _featuredCount,
      );
      products = page.items;
    } on ProductFailure catch (failure) {
      error = failure.message;
    } catch (_) {
      error = 'Không thể tải sản phẩm. Vui lòng thử lại.';
    }
    final loadedCategories = await categories;
    if (!mounted || requestId != _requestId) return;
    if (error != null && hasData) {
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Không thể làm mới. Vui lòng thử lại.')),
        );
      return;
    }
    setState(() {
      _categories = loadedCategories ?? (hasData ? _categories : const []);
      _products = products;
      _error = error;
      _loading = false;
    });
  }

  Future<void> _retry() {
    setState(() {
      _loading = true;
      _error = null;
    });
    return _load();
  }

  void _openCatalog([String? categoryId]) {
    MainShell.openCatalog(context, categoryId: categoryId);
  }

  void _showNote() {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Hoa được cắt mới mỗi sáng tại vườn Đà Lạt hoặc nhập khẩu, '
            'giao đến bạn trong ngày.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: Column(
        children: [
          const BrandHeader(),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => _load(refresh: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(
                  bottom: AppBottomNav.reservedHeight,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HomeSearchBar(onTap: _openCatalog),
                    HomeCategoryChips(
                      categories: _categories,
                      onSelected: _openCatalog,
                    ),
                    HomeHeroBanner(onExplore: _openCatalog),
                    HomeNoteCard(onDetails: _showNote),
                    HomeSectionHeader(onSeeMore: _openCatalog),
                    HomeProductGrid(
                      loading: _loading,
                      products: _products,
                      errorMessage: _error,
                      onProductTap: (product) =>
                          ProductRoutes.openDetail(context, product.id),
                      onRetry: _retry,
                    ),
                    const HomeStoryCard(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
