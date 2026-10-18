import 'package:flutter/material.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

/// Thẻ ghi chú nhỏ dưới banner (Penpot: "Section - Editorial Micro Banner Note").
class HomeNoteCard extends StatelessWidget {
  const HomeNoteCard({super.key, required this.onDetails});

  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppColors.softShadow,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.eco_outlined,
              size: 16,
              color: AppColors.primaryActive,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Hoa cắt mới mỗi sáng tại vườn Đà Lạt & nhập khẩu',
                style: AppFonts.sans(
                  fontSize: 12,
                  height: 1.5,
                  color: AppColors.textBody,
                ),
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              key: const Key('home-note-details'),
              onTap: onDetails,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Chi tiết',
                  style: AppFonts.sans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryActive,
                    letterSpacing: 0.4,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
