import 'package:flutter/material.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

/// Thanh phụ dưới header (Penpot: "Minimal In-Page Sub-Bar with Cart Access").
///
/// Trái: breadcrumb "Bộ sưu tập › {category}". Phải: nút giỏ hàng tròn 40px.
class DetailSubBar extends StatelessWidget {
  const DetailSubBar({
    super.key,
    required this.categoryName,
    required this.onCartTap,
    this.cartKey,
    this.isFavorite = false,
    this.onFavoriteTap,
    this.cartCount = 0,
  });

  final bool isFavorite;
  final VoidCallback? onFavoriteTap;
  final String categoryName;
  final VoidCallback onCartTap;

  /// Đích của hiệu ứng bay vào giỏ.
  final GlobalKey? cartKey;
  final int cartCount;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Row(
                key: const Key('detail-breadcrumb'),
                children: [
                  Text(
                    'Bộ sưu tập',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppColors.iconInactive,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      categoryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (onFavoriteTap != null) ...[
              IconButton(
                key: const Key('detail-favorite'),
                onPressed: onFavoriteTap,
                tooltip: isFavorite ? 'Bỏ yêu thích' : 'Thêm vào yêu thích',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primarySoft,
                  fixedSize: const Size(40, 40),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  size: 20,
                  color: isFavorite ? AppColors.accent : AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Stack(
              key: cartKey,
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  key: const Key('detail-cart'),
                  onPressed: onCartTap,
                  tooltip: 'Giỏ hàng',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primarySoft,
                    fixedSize: const Size(40, 40),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(
                    Icons.shopping_bag_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                if (cartCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      key: const Key('detail-cart-count'),
                      constraints: const BoxConstraints(minWidth: 18),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        cartCount > 99 ? '99+' : '$cartCount',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.badge.copyWith(
                          color: AppColors.textLight,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
