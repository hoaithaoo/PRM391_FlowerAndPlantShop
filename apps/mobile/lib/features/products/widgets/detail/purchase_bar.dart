import 'package:flutter/material.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

/// Thanh mua hàng cố định ở đáy (Penpot: "Aside - Sticky Purchase Bottom Bar").
///
/// Trái: "Tổng tạm tính" + tổng tiền. Phải: nút "Thêm vào giỏ" (bo 16, cao 54).
class PurchaseBar extends StatelessWidget {
  const PurchaseBar({
    super.key,
    required this.total,
    required this.inStock,
    required this.onAddToCart,
  });

  final int total;
  final bool inStock;
  final VoidCallback onAddToCart;

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final buttonWidth = (constraints.maxWidth * 0.6).clamp(0.0, 220.0);
          return Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Tổng tạm tính',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        formatVnd(total),
                        key: const Key('detail-total'),
                        style: AppFonts.sans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: buttonWidth,
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: inStock ? AppColors.buttonShadow : null,
                  ),
                  child: FilledButton(
                    key: const Key('detail-add-to-cart'),
                    onPressed: inStock ? onAddToCart : null,
                    style:
                        FilledButton.styleFrom(
                          foregroundColor: AppColors.textLight,
                          disabledForegroundColor: AppColors.textMuted,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ).copyWith(
                          backgroundColor: WidgetStateProperty.resolveWith((
                            states,
                          ) {
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (inStock) ...[
                            const Icon(Icons.add_shopping_cart, size: 18),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            inStock ? 'Thêm vào giỏ' : 'Hết hàng',
                            style: AppTextStyles.button.copyWith(
                              color: inStock
                                  ? AppColors.textLight
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
