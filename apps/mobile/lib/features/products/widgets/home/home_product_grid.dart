import 'package:flutter/material.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

import '../common/product_image.dart';

/// Lưới 2 cột sản phẩm mới nhất (Penpot: "Section - 2-Column Product Discovery Grid").
///
/// Tự xử lý bốn trạng thái: đang tải (skeleton), lỗi, rỗng và có dữ liệu.
class HomeProductGrid extends StatelessWidget {
  const HomeProductGrid({
    super.key,
    required this.loading,
    required this.products,
    required this.onProductTap,
    required this.onRetry,
    this.errorMessage,
  });

  final bool loading;
  final List<ProductSummary> products;

  /// Khác null nghĩa là tải sản phẩm thất bại.
  final String? errorMessage;
  final ValueChanged<ProductSummary> onProductTap;
  final VoidCallback onRetry;

  static const _columnGap = 12.0;
  static const _rowGap = 24.0;

  @override
  Widget build(BuildContext context) {
    final Widget content;
    final message = errorMessage;
    if (loading) {
      content = _twoColumns(
        List.generate(4, (_) => const _ProductCardSkeleton()),
      );
    } else if (message != null) {
      content = _GridMessage(
        message: message,
        action: FilledButton(
          key: const Key('home-retry'),
          onPressed: onRetry,
          child: const Text('Thử lại'),
        ),
      );
    } else if (products.isEmpty) {
      content = const _GridMessage(
        message: 'Chưa có sản phẩm nào để hiển thị.',
      );
    } else {
      content = _twoColumns([
        for (final product in products)
          HomeProductCard(
            key: Key('home-product-${product.id}'),
            product: product,
            onTap: () => onProductTap(product),
          ),
      ]);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: content,
    );
  }

  Widget _twoColumns(List<Widget> cards) {
    final rows = <Widget>[];
    for (var i = 0; i < cards.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: _rowGap));
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cards[i]),
            const SizedBox(width: _columnGap),
            Expanded(
              child: i + 1 < cards.length ? cards[i + 1] : const SizedBox(),
            ),
          ],
        ),
      );
    }
    return Column(children: rows);
  }
}

/// Thẻ sản phẩm: ảnh 169:211 + badge SKU, tên, trạng thái kho, giá.
class HomeProductCard extends StatelessWidget {
  const HomeProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  final ProductSummary product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final inStock = product.inStock;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 169 / 211,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppColors.cardShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ProductImage(url: product.imageUrl, dimmed: !inStock),
                    Positioned(
                      left: 10,
                      top: 13,
                      right: 10,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _SkuBadge(sku: product.sku),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.cardTitle.copyWith(
              fontSize: 17,
              color: inStock ? AppColors.textHeading : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              SizedBox.square(
                dimension: 6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: inStock
                        ? AppColors.primaryActive
                        : AppColors.iconInactive,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  inStock ? 'Còn hàng' : 'Hết hàng',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatVnd(product.price),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.price.copyWith(
              color: inStock ? AppColors.primary : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkuBadge extends StatelessWidget {
  const _SkuBadge({required this.sku});

  final String sku;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        sku,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.badge.copyWith(
          color: AppColors.textMuted,
          letterSpacing: 0.44,
        ),
      ),
    );
  }
}

/// Skeleton cùng kích thước thẻ sản phẩm khi đang tải.
class _ProductCardSkeleton extends StatelessWidget {
  const _ProductCardSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(4),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 169 / 211,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 10),
        bar(120, 16),
        const SizedBox(height: 8),
        bar(60, 11),
        const SizedBox(height: 10),
        bar(80, 14),
      ],
    );
  }
}

class _GridMessage extends StatelessWidget {
  const _GridMessage({required this.message, this.action});

  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.local_florist_outlined,
            size: 32,
            color: AppColors.accentSoft,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: AppTextStyles.body),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}
