import 'package:flutter/material.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

import '../common/product_image.dart';

/// Thẻ sản phẩm trong lưới 2 cột (Penpot: "Product N").
///
/// Ảnh tỉ lệ 169:211 bo 12, nút tim góc trên phải, badge tồn kho góc dưới trái;
/// dưới ảnh là tên category, tên sản phẩm (tối đa 2 dòng) và giá.
class CatalogProductCard extends StatelessWidget {
  const CatalogProductCard({
    super.key,
    required this.product,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
  });

  final ProductSummary product;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final inStock = product.inStock;
    final textColor = inStock ? AppColors.textHeading : AppColors.textMuted;
    return InkWell(
      key: Key('catalog-product-${product.id}'),
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 169 / 211.3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.surfacePastel,
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ProductImage(url: product.imageUrl, dimmed: !inStock),
                  ),
                ),
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: _StockBadge(inStock: inStock),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    key: Key('catalog-favorite-${product.id}'),
                    tooltip: isFavorite ? 'Bỏ yêu thích' : 'Thêm vào yêu thích',
                    onPressed: onToggleFavorite,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 32,
                      height: 32,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surface.withValues(alpha: 0.85),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 16,
                      color: isFavorite ? AppColors.accent : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            product.category.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 2),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.cardTitle.copyWith(color: textColor),
          ),
          const SizedBox(height: 4),
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

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.inStock});

  final bool inStock;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: inStock ? AppColors.primaryLight : AppColors.borderInactive,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        child: Text(
          inStock ? 'Còn hàng' : 'Hết hàng',
          maxLines: 1,
          style: AppTextStyles.badge.copyWith(
            color: inStock ? AppColors.primaryActive : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

/// Lưới 2 cột dạng danh sách hàng, mỗi hàng có hai thẻ (khoảng cách ngang 12,
/// dọc 24 theo Penpot). Chiều cao hàng theo thẻ cao nhất nên không tràn khi
/// chữ phóng to.
class CatalogProductRow extends StatelessWidget {
  const CatalogProductRow({super.key, required this.cards});

  /// Một hoặc hai thẻ; hàng lẻ để trống ô bên phải.
  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: cards.first),
        const SizedBox(width: 12),
        Expanded(child: cards.length > 1 ? cards[1] : const SizedBox.shrink()),
      ],
    );
  }
}
