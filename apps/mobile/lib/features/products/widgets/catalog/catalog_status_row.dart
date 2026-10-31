import 'package:flutter/material.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

/// Dòng trạng thái: "Hiển thị N tác phẩm" (trái) và "Sẵn sàng vận chuyển" (phải).
class CatalogStatusRow extends StatelessWidget {
  const CatalogStatusRow({super.key, required this.total});

  /// Tổng số sản phẩm khớp bộ lọc theo API.
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text.rich(
            key: const Key('catalog-count'),
            TextSpan(
              text: 'Hiển thị ',
              children: [
                TextSpan(
                  text: '$total',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textHeading,
                  ),
                ),
                const TextSpan(text: ' tác phẩm'),
              ],
            ),
            style: AppTextStyles.caption,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: SizedBox.square(
                  dimension: 6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.primaryActive,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Sẵn sàng vận chuyển',
                  textAlign: TextAlign.end,
                  style: AppTextStyles.caption,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
