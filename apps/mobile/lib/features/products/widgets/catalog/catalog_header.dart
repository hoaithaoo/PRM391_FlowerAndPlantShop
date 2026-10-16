import 'package:flutter/material.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

/// Sub-header: nút quay lại (khi có thể), chữ thương hiệu + chấm hồng,
/// nhãn "BỘ SƯU TẬP" bên phải (Penpot: "Sub-header with Back Icon...").
class CatalogSubHeader extends StatelessWidget {
  const CatalogSubHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40),
      child: Row(
        children: [
          if (canPop) ...[
            Material(
              color: AppColors.primarySoft,
              shape: const CircleBorder(),
              child: InkWell(
                key: const Key('catalog-back'),
                customBorder: const CircleBorder(),
                onTap: () => Navigator.maybePop(context),
                child: const SizedBox.square(
                  dimension: 40,
                  child: Icon(
                    Icons.arrow_back,
                    size: 20,
                    color: AppColors.textHeading,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              'Nhà Có Hoa',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.headerTitle,
            ),
          ),
          const SizedBox(width: 6),
          const SizedBox.square(
            dimension: 6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'BỘ SƯU TẬP',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: AppFonts.sans(
                fontSize: 12,
                letterSpacing: 1.2,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
