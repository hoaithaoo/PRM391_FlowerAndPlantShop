import 'package:flutter/material.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

/// Khối thông tin sản phẩm (Penpot: "Section - Product Meta & Primary Details"
/// không gồm thẻ số lượng): tag, tên, giá + SKU, mô tả, ghi chú chăm sóc.
class DetailInfoSection extends StatelessWidget {
  const DetailInfoSection({super.key, required this.product});

  final ProductDetail product;

  @override
  Widget build(BuildContext context) {
    final description = product.description?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TagRow(categoryName: product.category.name, inStock: product.inStock),
        const SizedBox(height: 4),
        Text(
          product.name,
          key: const Key('detail-name'),
          style: AppTextStyles.headline1,
        ),
        const SizedBox(height: 8),
        _PriceRow(price: product.price, sku: product.sku),
        if (description != null && description.isNotEmpty) ...[
          const SizedBox(height: 24),
          _DescriptionCard(description: description),
        ],
        const SizedBox(height: 12),
        const _CareNote(),
      ],
    );
  }
}

/// Nền thẻ trắng bo 12 có viền nhẹ và bóng mảnh.
BoxDecoration _cardDecoration() => BoxDecoration(
  color: AppColors.surface,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: AppColors.border),
  boxShadow: AppColors.softShadow,
);

class _TagRow extends StatelessWidget {
  const _TagRow({required this.categoryName, required this.inStock});

  final String categoryName;
  final bool inStock;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            categoryName.toUpperCase(),
            key: const Key('detail-category'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.overline.copyWith(color: AppColors.textMuted),
          ),
        ),
        const SizedBox(width: 12),
        _StatusPill(inStock: inStock),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.inStock});

  final bool inStock;

  @override
  Widget build(BuildContext context) {
    final color = inStock ? AppColors.primaryActive : AppColors.textMuted;
    return Container(
      key: const Key('detail-status'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: inStock ? AppColors.primaryLight : AppColors.borderInactive,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (inStock) ...[
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            inStock ? 'Còn hàng' : 'Hết hàng',
            style: AppTextStyles.badge.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.price, required this.sku});

  final int price;
  final String sku;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Giá không flex: chiếm đúng kích thước nội dung, SKU lấy phần còn lại.
        Text(
          formatVnd(price),
          key: const Key('detail-price'),
          style: AppFonts.sans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            height: 1.3,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'SKU: $sku',
            key: const Key('detail-sku'),
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w400),
          ),
        ),
      ],
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('detail-description'),
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_florist_outlined,
                size: 14,
                color: AppColors.primaryActive,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text('MÔ TẢ TÁC PHẨM', style: AppTextStyles.overline),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(description, style: AppTextStyles.body.copyWith(height: 1.625)),
        ],
      ),
    );
  }
}

class _CareNote extends StatelessWidget {
  const _CareNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('detail-care-note'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.eco_outlined,
              size: 14,
              color: AppColors.primaryActive,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tươi mới mỗi sớm mai',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Mỗi cành hoa được tuyển lựa và cắm tay trực tiếp tại xưởng '
                  'Nhà Có Hoa trước giờ gửi trao.',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
