import 'package:flutter/material.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

/// Thanh mua hàng cố định ở đáy: "Thêm vào giỏ" và "Mua ngay". Cả hai đều mở
/// bảng chọn số lượng trước, giống Shopee.
class PurchaseBar extends StatelessWidget {
  const PurchaseBar({
    super.key,
    required this.inStock,
    required this.onAddToCart,
    required this.onBuyNow,
  });

  final bool inStock;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    return Container(
      key: const Key('detail-purchase-bar'),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F171C19),
            offset: Offset(0, -4),
            blurRadius: 20,
          ),
        ],
      ),
      child: SizedBox(
        height: 54,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('detail-add-to-cart'),
                onPressed: inStock ? onAddToCart : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: shape,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (inStock) ...[
                        const Icon(Icons.add_shopping_cart, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Text(inStock ? 'Thêm vào giỏ' : 'Hết hàng'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                key: const Key('detail-buy-now'),
                onPressed: inStock ? onBuyNow : null,
                style: FilledButton.styleFrom(
                  foregroundColor: AppColors.textLight,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: shape,
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Mua ngay'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
