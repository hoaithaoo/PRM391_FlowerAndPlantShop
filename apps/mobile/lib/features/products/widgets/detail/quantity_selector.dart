import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

/// Số lượng tối đa mỗi đơn hàng.
const detailMaxPerOrder = 10;

/// Số lượng tối đa chọn được: `min(10, stock)`, 0 khi hết hàng.
int detailMaxQuantity(int stock) =>
    math.max(0, math.min(detailMaxPerOrder, stock));

/// Thẻ số lượng (Penpot: "Quantity Selector Section").
///
/// Trái: "Số lượng" + dòng phụ. Phải: stepper tròn (−, số, +). Nút bị vô hiệu
/// khi chạm biên 1 hoặc [detailMaxQuantity].
class QuantitySelector extends StatelessWidget {
  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.stock,
    required this.onChanged,
  });

  final int quantity;
  final int stock;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final max = detailMaxQuantity(stock);
    final enabled = max > 0;
    final hint = !enabled
        ? 'Sản phẩm hiện đã hết hàng'
        : stock < detailMaxPerOrder
        ? 'Chỉ còn $stock sản phẩm'
        : 'Tối đa $detailMaxPerOrder sản phẩm / đơn hàng';
    return Container(
      key: const Key('detail-quantity'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Số lượng',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textHeading,
                  ),
                ),
                Text(
                  hint,
                  key: const Key('detail-qty-hint'),
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfacePastel,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StepButton(
                  key: const Key('detail-qty-decrease'),
                  icon: Icons.remove,
                  tooltip: 'Giảm số lượng',
                  onPressed: enabled && quantity > 1
                      ? () => onChanged(quantity - 1)
                      : null,
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 40),
                  child: Text(
                    '$quantity',
                    key: const Key('detail-qty-value'),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontSize: 16,
                      color: enabled
                          ? AppColors.textHeading
                          : AppColors.textMuted,
                    ),
                  ),
                ),
                _StepButton(
                  key: const Key('detail-qty-increase'),
                  icon: Icons.add,
                  tooltip: 'Tăng số lượng',
                  onPressed: enabled && quantity < max
                      ? () => onChanged(quantity + 1)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      iconSize: 16,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.surface,
        disabledBackgroundColor: AppColors.surface.withValues(alpha: 0.5),
        foregroundColor: AppColors.primary,
        disabledForegroundColor: AppColors.iconInactive,
        fixedSize: const Size(32, 32),
        minimumSize: const Size(32, 32),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(icon),
    );
  }
}
