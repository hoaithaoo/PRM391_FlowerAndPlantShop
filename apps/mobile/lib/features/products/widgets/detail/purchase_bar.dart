import 'package:flutter/material.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

/// Thanh mua hàng cố định ở đáy (Penpot: "Aside - Sticky Purchase Bottom Bar").
///
/// Bố cục 1 hàng ngang với 2 nút song song: "Thêm vào giỏ" và "Mua ngay" (kèm giá tiền).
class PurchaseBar extends StatelessWidget {
  const PurchaseBar({
    super.key,
    required this.total,
    required this.inStock,
    required this.onAddToCart,
    required this.onBuyNow,
  });

  final int total;
  final bool inStock;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;

  @override
  Widget build(BuildContext context) {
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
      child: Row(
        children: [
          // Nút 1: Thêm vào giỏ
          Expanded(
            child: SizedBox(
              height: 54,
              child: OutlinedButton(
                key: const Key('detail-add-to-cart'),
                onPressed: inStock ? onAddToCart : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  disabledForegroundColor: AppColors.textMuted,
                  backgroundColor:
                      inStock ? AppColors.primarySoft : AppColors.surface,
                  side: BorderSide(
                    color: inStock
                        ? AppColors.primary
                        : AppColors.borderInactive,
                    width: 1.2,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (inStock) ...[
                        const Icon(Icons.add_shopping_cart, size: 18),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        inStock ? 'Thêm vào giỏ' : 'Hết hàng',
                        style: AppTextStyles.button.copyWith(
                          color: inStock
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Nút 2: Mua ngay (kèm tổng giá)
          Expanded(
            child: SizedBox(
              height: 54,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: inStock ? AppColors.buttonShadow : null,
                ),
                child: FilledButton(
                  key: const Key('detail-buy-now'),
                  onPressed: inStock ? onBuyNow : null,
                  style: FilledButton.styleFrom(
                    foregroundColor: AppColors.textLight,
                    disabledForegroundColor: AppColors.textMuted,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ).copyWith(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.disabled)) {
                        return AppColors.borderInactive;
                      }
                      if (states.contains(WidgetState.pressed)) {
                        return AppColors.primaryPressed;
                      }
                      return AppColors.primary;
                    }),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (inStock) ...[
                              const Icon(
                                Icons.bolt,
                                size: 16,
                                color: AppColors.textLight,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              inStock ? 'Mua ngay' : 'Hết hàng',
                              style: AppTextStyles.button.copyWith(
                                color: inStock
                                    ? AppColors.textLight
                                    : AppColors.textMuted,
                                fontSize: 14,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatVnd(total),
                          key: const Key('detail-total'),
                          style: AppFonts.sans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: inStock
                                ? AppColors.textLight.withValues(alpha: 0.95)
                                : AppColors.textMuted,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
