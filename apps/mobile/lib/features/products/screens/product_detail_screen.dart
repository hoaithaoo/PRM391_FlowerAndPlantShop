import 'package:flutter/material.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

import '../data/product_repository.dart';
import '../data/product_scope.dart';
import '../widgets/common/brand_header.dart';
import '../widgets/detail/detail_image_carousel.dart';
import '../widgets/detail/detail_info_section.dart';
import '../widgets/detail/detail_states.dart';
import '../widgets/detail/detail_sub_bar.dart';
import '../widgets/detail/purchase_bar.dart';
import '../widgets/detail/quantity_selector.dart';

/// Chi tiết sản phẩm (Penpot: "Chi tiết sản phẩm - Fleuré").
///
/// Được push bằng route riêng nên có Scaffold riêng, không có thanh điều
/// hướng dưới. Thanh mua hàng cố định ở đáy là `bottomNavigationBar`, nên
/// nội dung cuộn không bị che.
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  ProductDetail? _product;
  ProductFailure? _failure;
  bool _loading = true;
  int _quantity = 1;

  /// Tăng mỗi lần tải để bỏ qua kết quả của yêu cầu đã cũ.
  int _requestId = 0;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _load();
    }
  }

  @override
  void didUpdateWidget(ProductDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productId != widget.productId) _load();
  }

  Future<void> _load() async {
    final requestId = ++_requestId;
    final repository = ProductScope.of(context);
    setState(() {
      _loading = true;
      _failure = null;
      _product = null;
      _quantity = 1;
    });
    try {
      final product = await repository.getProduct(widget.productId);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _product = product;
        _loading = false;
      });
    } on ProductFailure catch (failure) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _failure = failure;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _failure = const ProductFailure(
          'Không tải được sản phẩm. Vui lòng thử lại.',
        );
        _loading = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _share() => _showMessage('Tính năng chia sẻ sẽ sớm ra mắt');

  void _openCart() => _showMessage('Giỏ hàng đang được phát triển');

  void _addToCart(ProductDetail product) {
    _showMessage('Đã thêm $_quantity × ${product.name} vào giỏ hàng');
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BrandHeader(
        key: const Key('detail-header'),
        onBack: () => Navigator.of(context).maybePop(),
        title: 'Chi Tiết Tác Phẩm',
        onShare: _share,
      ),
      body: _buildBody(product),
      bottomNavigationBar: product == null
          ? null
          : PurchaseBar(
              total: product.price * _quantity,
              inStock: product.inStock,
              onAddToCart: () => _addToCart(product),
            ),
    );
  }

  Widget _buildBody(ProductDetail? product) {
    if (_loading) return const DetailLoadingView();
    final failure = _failure;
    if (failure != null) {
      if (failure.notFound) {
        return DetailMessageView(
          icon: Icons.local_florist_outlined,
          message: 'Sản phẩm không tồn tại hoặc đã ngừng bán.',
          actionLabel: 'Quay lại',
          actionKey: const Key('detail-back'),
          onAction: () => Navigator.of(context).maybePop(),
        );
      }
      return DetailMessageView(
        icon: failure.offline ? Icons.wifi_off : Icons.error_outline,
        message: failure.offline
            ? 'Mất kết nối mạng. Vui lòng kiểm tra kết nối và thử lại.'
            : failure.message,
        actionLabel: 'Thử lại',
        actionKey: const Key('detail-retry'),
        onAction: _load,
      );
    }
    if (product == null) return const DetailLoadingView();
    return SingleChildScrollView(
      key: const Key('detail-scroll'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DetailSubBar(
            categoryName: product.category.name,
            onCartTap: _openCart,
          ),
          DetailImageCarousel(
            imageUrls: product.imageUrls,
            dimmed: !product.inStock,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DetailInfoSection(product: product),
                const SizedBox(height: 32),
                QuantitySelector(
                  quantity: _quantity,
                  stock: product.stock,
                  onChanged: (value) => setState(() => _quantity = value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
