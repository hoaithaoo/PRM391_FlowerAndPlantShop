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
  });

  final String categoryName;
  final VoidCallback onCartTap;

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
          ],
        ),
      ),
    );
  }
}
