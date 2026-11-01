import 'package:flutter/material.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

import 'quantity_selector.dart';

/// Bảng chọn số lượng trượt từ dưới lên. Trả về số lượng đã xác nhận, `null`
/// khi khách đóng bảng.
Future<int?> showProductPurchaseSheet(
  BuildContext context, {
  required ProductDetail product,
  required String confirmLabel,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) =>
        _PurchaseSheet(product: product, confirmLabel: confirmLabel),
  );
}

class _PurchaseSheet extends StatefulWidget {
  const _PurchaseSheet({required this.product, required this.confirmLabel});

  final ProductDetail product;
  final String confirmLabel;

  @override
  State<_PurchaseSheet> createState() => _PurchaseSheetState();
}

class _PurchaseSheetState extends State<_PurchaseSheet> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final imageUrl = product.imageUrls.isEmpty ? null : product.imageUrls.first;
    return Padding(
      // Bàn phím số không che nút xác nhận.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Column(
          key: const Key('detail-purchase-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ProductThumbnail(imageUrl: imageUrl, size: 120),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatVnd(product.price * _quantity),
                          key: const Key('detail-total'),
                          style: AppFonts.sans(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kho: ${product.stock}',
                          key: const Key('detail-sheet-stock'),
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('detail-sheet-close'),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Đóng',
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: QuantitySelector(
                quantity: _quantity,
                stock: product.stock,
                onChanged: (value) => setState(() => _quantity = value),
              ),
            ),
            const Divider(height: 6, thickness: 6),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: SizedBox(
                height: 52,
                child: FilledButton(
                  key: const Key('detail-sheet-confirm'),
                  onPressed: () => Navigator.of(context).pop(_quantity),
                  child: Text(widget.confirmLabel),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ảnh sản phẩm vuông bo góc, dùng ở bảng chọn số lượng và hiệu ứng bay vào giỏ.
class ProductThumbnail extends StatelessWidget {
  const ProductThumbnail({super.key, this.imageUrl, required this.size});

  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: AppColors.surfacePastel,
      child: Icon(
        Icons.local_florist_outlined,
        size: size / 2,
        color: AppColors.primary,
      ),
    );
    final url = imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox.square(
        dimension: size,
        child: url == null
            ? placeholder
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => placeholder,
              ),
      ),
    );
  }
}
