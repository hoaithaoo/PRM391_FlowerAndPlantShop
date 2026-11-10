import 'package:flutter/material.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

import '../common/product_image.dart';
import 'quantity_selector.dart';

/// Mở bottom sheet pop-up cho phép người dùng chọn lại số lượng và bấm "Thanh toán".
///
/// Trả về số lượng đã chọn khi bấm nút Thanh toán, hoặc `null` khi đóng sheet.
Future<int?> showBuyNowSheet(
  BuildContext context, {
  required ProductDetail product,
  int initialQuantity = 1,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => BuyNowSheet(
      product: product,
      initialQuantity: initialQuantity,
    ),
  );
}

/// Pop-up chọn số lượng và xác nhận mua ngay.
class BuyNowSheet extends StatefulWidget {
  const BuyNowSheet({
    super.key,
    required this.product,
    this.initialQuantity = 1,
  });

  final ProductDetail product;
  final int initialQuantity;

  @override
  State<BuyNowSheet> createState() => _BuyNowSheetState();
}

class _BuyNowSheetState extends State<BuyNowSheet> {
  late int _quantity;

  int get _maxQuantity => detailMaxQuantity(widget.product.stock);

  @override
  void initState() {
    super.initState();
    final max = _maxQuantity;
    _quantity = max <= 0
        ? 0
        : widget.initialQuantity.clamp(1, max);
  }

  void _increase() {
    if (_quantity < _maxQuantity) {
      setState(() => _quantity++);
    }
  }

  void _decrease() {
    if (_quantity > 1) {
      setState(() => _quantity--);
    }
  }

  void _onCheckout() {
    Navigator.of(context).pop(_quantity);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final total = product.price * _quantity;
    final max = _maxQuantity;
    final canCheckout = product.inStock && _quantity > 0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Ảnh, Tên, Đơn giá, Tồn kho
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ảnh thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: ProductImage(
                    url: product.imageUrls.isNotEmpty
                        ? product.imageUrls.first
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Thông tin sản phẩm
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: AppFonts.sans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHeading,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatVnd(product.price),
                      style: AppFonts.sans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.inStock
                          ? 'Kho: ${product.stock}'
                          : 'Sản phẩm hiện đã hết hàng',
                      style: AppTextStyles.caption.copyWith(
                        color: product.inStock
                            ? AppColors.textMuted
                            : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 16),

          // Bộ chọn số lượng
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Số lượng mua',
                    style: AppFonts.sans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textHeading,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    !product.inStock
                        ? 'Hết hàng'
                        : product.stock < detailMaxPerOrder
                            ? 'Chỉ còn ${product.stock} sản phẩm'
                            : 'Tối đa $detailMaxPerOrder sản phẩm / đơn',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
              // Stepper: -, số, +
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfacePastel,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      key: const Key('buy-now-qty-decrease'),
                      icon: const Icon(Icons.remove, size: 18),
                      color: AppColors.textHeading,
                      disabledColor: AppColors.iconInactive,
                      onPressed: canCheckout && _quantity > 1 ? _decrease : null,
                      visualDensity: VisualDensity.compact,
                    ),
                    Container(
                      constraints: const BoxConstraints(minWidth: 32),
                      alignment: Alignment.center,
                      child: Text(
                        '$_quantity',
                        key: const Key('buy-now-qty-value'),
                        style: AppFonts.sans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textHeading,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const Key('buy-now-qty-increase'),
                      icon: const Icon(Icons.add, size: 18),
                      color: AppColors.textHeading,
                      disabledColor: AppColors.iconInactive,
                      onPressed: canCheckout && _quantity < max ? _increase : null,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Tổng thanh toán
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfacePastel,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tổng thanh toán:',
                  style: AppFonts.sans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textBody,
                  ),
                ),
                Text(
                  formatVnd(total),
                  key: const Key('buy-now-total'),
                  style: AppFonts.sans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Nút Thanh toán
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              key: const Key('buy-now-checkout-button'),
              onPressed: canCheckout ? _onCheckout : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.borderInactive,
                foregroundColor: AppColors.textLight,
                disabledForegroundColor: AppColors.textMuted,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.payment, size: 20),
              label: const Text(
                'Thanh toán ngay',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

