import 'package:flutter/material.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

/// Trạng thái đang tải của màn chi tiết.
class DetailLoadingView extends StatelessWidget {
  const DetailLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: Key('detail-loading'),
      child: CircularProgressIndicator(),
    );
  }
}

/// Trạng thái lỗi / không tìm thấy của màn chi tiết: icon, thông báo và một
/// nút hành động ("Thử lại" hoặc "Quay lại").
class DetailMessageView extends StatelessWidget {
  const DetailMessageView({
    super.key,
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.actionKey,
    required this.onAction,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final Key actionKey;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.accentSoft),
            const SizedBox(height: 16),
            Text(
              message,
              key: const Key('detail-message'),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge,
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: actionKey,
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textLight,
                minimumSize: const Size(140, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(actionLabel, style: AppTextStyles.button),
            ),
          ],
        ),
      ),
    );
  }
}
