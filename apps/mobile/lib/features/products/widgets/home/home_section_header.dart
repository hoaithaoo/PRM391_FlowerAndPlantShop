import 'package:flutter/material.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

/// Header khu vực sản phẩm (Penpot: "Section - Featured Discovery Grid Header").
class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({super.key, required this.onSeeMore});

  final VoidCallback onSeeMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TUYỂN CHỌN MÙA NÀY',
                  style: AppTextStyles.overline.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text('Khám phá sản phẩm', style: AppTextStyles.headline2),
              ],
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            key: const Key('home-see-more'),
            onTap: onSeeMore,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Xem thêm',
                    style: AppFonts.sans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryActive,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right,
                    size: 14,
                    color: AppColors.primaryActive,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
