import 'package:flutter/material.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

/// Thanh header 64px dùng chung (Penpot board "Header").
///
/// Trái: nút quay lại (tuỳ chọn) + logo "Nhà Có Hoa" + tiêu đề (tuỳ chọn).
/// Phải: nút thông báo hoặc chia sẻ + avatar tài khoản.
class BrandHeader extends StatelessWidget implements PreferredSizeWidget {
  const BrandHeader({
    super.key,
    this.onBack,
    this.title,
    this.onShare,
    this.showNotificationDot = true,
  });

  /// Có giá trị thì hiện nút quay lại.
  final VoidCallback? onBack;

  /// Tiêu đề trang cạnh logo, ví dụ "Chi Tiết Tác Phẩm".
  final String? title;

  /// Có giá trị thì hiện nút chia sẻ thay cho nút thông báo.
  final VoidCallback? onShare;
  final bool showNotificationDot;

  static const height = 64.0;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    return Container(
      height: height + MediaQuery.paddingOf(context).top,
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top,
        left: onBack == null ? 20 : (title == null ? 8 : 4),
        right: title == null ? 20 : 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A171C19),
            offset: Offset(0, 1),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              key: const Key('header-back'),
              visualDensity: title == null ? null : VisualDensity.compact,
              onPressed: onBack,
              tooltip: 'Quay lại',
              icon: const Icon(Icons.arrow_back, color: AppColors.textHeading),
            ),
          // Logo (và tiêu đề nếu có) nằm trong vùng co giãn: tự thu nhỏ thay vì
          // tràn khi font rộng hoặc chữ lớn. Các nút giữ kích thước cố định.
          // Có tiêu đề: logo nhỏ lại, ẩn avatar để tiêu đề vừa 1 dòng.
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Nhà Có Hoa',
                    maxLines: 1,
                    softWrap: false,
                    style: AppTextStyles.brandLogo.copyWith(
                      fontSize: title == null ? 26 : 20,
                    ),
                  ),
                  if (title != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      title,
                      maxLines: 1,
                      softWrap: false,
                      style: AppTextStyles.headerTitle.copyWith(fontSize: 16),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (onShare != null)
            IconButton(
              key: const Key('header-share'),
              visualDensity: title == null ? null : VisualDensity.compact,
              onPressed: onShare,
              tooltip: 'Chia sẻ',
              icon: const Icon(
                Icons.share_outlined,
                color: AppColors.primaryActive,
              ),
            )
          else
            _NotificationButton(showDot: showNotificationDot),
          if (title == null) ...[const SizedBox(width: 4), const _Avatar()],
        ],
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.showDot});

  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('header-notifications'),
      onPressed: () {},
      tooltip: 'Thông báo',
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_none, color: AppColors.primaryActive),
          if (showDot)
            Positioned(
              right: 1,
              top: 1,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.accentBorder),
      ),
      child: const Icon(
        Icons.person_outline,
        size: 18,
        color: AppColors.accent,
      ),
    );
  }
}
