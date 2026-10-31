import 'package:flutter/material.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

import '../../data/product_repository.dart';

/// Chân danh sách: spinner khi tải thêm, lỗi tải thêm + thử lại, hoặc
/// "Đang hiển thị tất cả sản phẩm hiện có" + nút cuộn lên đầu.
class CatalogListFooter extends StatelessWidget {
  const CatalogListFooter({
    super.key,
    required this.loadingMore,
    required this.hasMore,
    required this.loadMoreError,
    required this.onRetry,
    required this.onScrollToTop,
  });

  final bool loadingMore;
  final bool hasMore;
  final ProductFailure? loadMoreError;
  final VoidCallback onRetry;
  final VoidCallback onScrollToTop;

  @override
  Widget build(BuildContext context) {
    final error = loadMoreError;
    if (error != null) {
      return Column(
        children: [
          Text(
            error.offline
                ? 'Mất kết nối mạng, chưa tải thêm được sản phẩm.'
                : error.message,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            key: const Key('catalog-load-more-retry'),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Thử lại'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accent,
              textStyle: AppTextStyles.button,
            ),
          ),
        ],
      );
    }
    if (loadingMore) {
      return const Center(
        child: SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(
            key: Key('catalog-loading-more'),
            strokeWidth: 2.5,
          ),
        ),
      );
    }
    // Còn trang nhưng chưa tải: chừa chỗ tĩnh, không chạy animation.
    if (hasMore) return const SizedBox(key: Key('catalog-more-pending'), height: 24);
    return Column(
      children: [
        Text(
          'Đang hiển thị tất cả sản phẩm hiện có',
          textAlign: TextAlign.center,
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: 8),
        Material(
          color: AppColors.primarySoft,
          shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
          child: InkWell(
            key: const Key('catalog-scroll-top'),
            customBorder: const CircleBorder(),
            onTap: onScrollToTop,
            child: const SizedBox.square(
              dimension: 32,
              child: Icon(
                Icons.keyboard_arrow_up,
                size: 20,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Màn trạng thái toàn trang (lỗi, rỗng, đang tải) nằm trong danh sách cuộn.
class CatalogMessage extends StatelessWidget {
  const CatalogMessage({
    super.key,
    required this.title,
    this.body,
    this.illustration,
    this.actionKey,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  final String title;
  final String? body;
  final Widget? illustration;
  final Key? actionKey;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final body = this.body;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          ?illustration,
          if (illustration != null) const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.headline2,
          ),
          if (body != null) ...[
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
            ),
          ],
          if (actionLabel != null) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: actionKey,
                onPressed: onAction,
                icon: Icon(actionIcon ?? Icons.refresh, size: 18),
                label: Text(actionLabel!),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: AppTextStyles.button.copyWith(fontSize: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Minh hoạ cho trạng thái rỗng: vòng tròn xanh nhạt với bình hoa.
class CatalogEmptyIllustration extends StatelessWidget {
  const CatalogEmptyIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 112,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: SizedBox.expand(),
          ),
          const Icon(
            Icons.local_florist_outlined,
            size: 44,
            color: AppColors.primaryActive,
          ),
          Positioned(
            top: 8,
            right: 14,
            child: _dot(6, AppColors.accentSoft),
          ),
          Positioned(
            bottom: 20,
            left: 12,
            child: _dot(8, AppColors.primaryLight),
          ),
        ],
      ),
    );
  }

  static Widget _dot(double size, Color color) => SizedBox.square(
    dimension: size,
    child: DecoratedBox(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ),
  );
}
