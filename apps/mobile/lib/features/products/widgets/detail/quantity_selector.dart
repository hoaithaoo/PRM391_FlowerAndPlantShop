import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

import '../../../cart/widgets/quantity_input.dart';

/// Số lượng tối đa mỗi đơn hàng.
const detailMaxPerOrder = 10;

/// Số lượng tối đa chọn được: `min(10, stock)`, 0 khi hết hàng.
int detailMaxQuantity(int stock) =>
    math.max(0, math.min(detailMaxPerOrder, stock));

/// Hàng số lượng trong bảng mua hàng.
///
/// Trái: "Số lượng" + dòng phụ. Phải: stepper (−, ô nhập, +). Nút bị vô hiệu
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
    return Padding(
      key: const Key('detail-quantity'),
      padding: const EdgeInsets.symmetric(vertical: 12),
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
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
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
                QuantityInput(
                  key: const Key('detail-qty-value'),
                  value: quantity,
                  max: max,
                  enabled: enabled,
                  live: true,
                  width: 44,
                  onChanged: onChanged,
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
