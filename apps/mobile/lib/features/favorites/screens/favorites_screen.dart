import 'package:flutter/material.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

import '../../products/product_routes.dart';
import '../../products/widgets/catalog/catalog_product_card.dart';
import '../../products/widgets/common/brand_header.dart';
import '../state/favorite_controller.dart';
import '../state/favorite_scope.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key, this.onExploreProducts});

  /// Màn Tài khoản truyền vào để chuyển tab sau khi đóng màn yêu thích.
  final VoidCallback? onExploreProducts;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  FavoriteController? _controller;
  List<ProductSummary> _products = const [];
  bool _loading = true;
  bool _failed = false;
  int _requestId = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = FavoriteScope.of(context);
    if (identical(controller, _controller)) return;
    _controller = controller;
    // Scope nằm trên Navigator nên chỉ thông báo sau frame đang dựng.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    final requestId = ++_requestId;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final controller = _controller!;
      if (!await controller.load()) {
        throw StateError('Không tải được yêu thích');
      }
      final products = await controller.listProducts();
      if (!mounted || requestId != _requestId) return;
      setState(() => _products = products);
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() => _failed = true);
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _remove(String id) async {
    final ok = await _controller!.toggle(id);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa cập nhật được yêu thích. Vui lòng thử lại.'),
        ),
      );
    }
  }

  Future<void> _openProduct(String id) async {
    final result = await ProductRoutes.openDetail(context, id);
    if (!mounted) return;
    if (result == ProductDetailResult.openCart) {
      Navigator.of(context).pop(result);
    } else {
      await _load();
    }
  }

  void _explore() {
    Navigator.of(context).pop();
    widget.onExploreProducts?.call();
  }

  @override
  Widget build(BuildContext context) {
    final favorites = FavoriteScope.of(context);
    final products = _products
        .where((p) => favorites.isFavorite(p.id))
        .toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BrandHeader(
        title: 'Yêu thích',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_failed)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _message(
                  'Không tải được sản phẩm yêu thích',
                  'Thử lại',
                  _load,
                ),
              )
            else if (products.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _message(
                  'Chưa có sản phẩm yêu thích',
                  'Khám phá sản phẩm',
                  _explore,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList.builder(
                  itemCount: (products.length + 1) ~/ 2,
                  itemBuilder: (context, row) => Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: CatalogProductRow(
                      cards: [
                        for (final product in products.skip(row * 2).take(2))
                          CatalogProductCard(
                            product: product,
                            isFavorite: true,
                            onTap: () => _openProduct(product.id),
                            onToggleFavorite: () => _remove(product.id),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _message(String title, String action, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.favorite_border, size: 48, color: AppColors.textMuted),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyles.cardTitle,
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: onTap, child: Text(action)),
      ],
    ),
  );
}
