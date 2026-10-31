import 'package:flutter/material.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

/// Ô tìm kiếm + nút lọc nhanh (Penpot: "Section - Search Field").
///
/// Trang chủ không tự tìm kiếm: chạm ô hoặc nút lọc đều gọi [onTap]
/// để chuyển sang tab Sản phẩm.
class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppColors.softShadow,
        ),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                button: true,
                label: 'Tìm sản phẩm',
                child: InkWell(
                  key: const Key('home-search'),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12),
                  ),
                  onTap: onTap,
                  child: ExcludeSemantics(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search,
                            size: 20,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Tìm sản phẩm...',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.sans(color: AppColors.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: IconButton(
                key: const Key('home-filter'),
                onPressed: onTap,
                tooltip: 'Bộ lọc nhanh',
                style: IconButton.styleFrom(
                  fixedSize: const Size(36, 40),
                  minimumSize: const Size(36, 40),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(
                  Icons.tune,
                  size: 18,
                  color: AppColors.primaryActive,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
