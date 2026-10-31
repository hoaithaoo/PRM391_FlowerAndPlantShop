import 'package:flutter/material.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

/// Thẻ "Mỗi nhánh hoa là một câu chuyện" cuối trang
/// (Penpot: "Section - Editorial Philosophy Card").
class HomeStoryCard extends StatelessWidget {
  const HomeStoryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_florist_outlined,
                size: 20,
                color: AppColors.primaryActive,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Mỗi nhánh hoa là một câu chuyện',
              textAlign: TextAlign.center,
              style: AppTextStyles.cardTitle.copyWith(height: 1.4),
            ),
            const SizedBox(height: 4),
            Text(
              'Nhà Có Hoa trân trọng tính tự nhiên, tối giản và thuần khiết '
              'trong từng thiết kế cành lá mang đến ngôi nhà bạn.',
              textAlign: TextAlign.center,
              style: AppFonts.sans(
                fontSize: 12,
                height: 1.625,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
