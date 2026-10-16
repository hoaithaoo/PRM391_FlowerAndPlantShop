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
        left: onBack == null ? 20 : 8,
        right: 20,
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
              onPressed: onBack,
              tooltip: 'Quay lại',
              icon: const Icon(Icons.arrow_back, color: AppColors.textHeading),
            ),
          // Có tiêu đề: logo nhỏ lại, ẩn avatar để tiêu đề vừa 1 dòng ở 360-430px.
          Text(
            'Nhà Có Hoa',
            style: AppTextStyles.brandLogo.copyWith(
              fontSize: title == null ? 26 : 22,
            ),
          ),
          if (title != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  maxLines: 1,
                  softWrap: false,
                  style: AppTextStyles.headerTitle.copyWith(fontSize: 18),
                ),
              ),
            ),
          ] else
            const Spacer(),
          if (onShare != null)
            IconButton(
              key: const Key('header-share'),
              onPressed: onShare,
              tooltip: 'Chia sẻ',
              icon: const Icon(Icons.share_outlined, color: AppColors.primaryActive),
            )
          else
            _NotificationButton(showDot: showNotificationDot),
          if (title == null) ...[
            const SizedBox(width: 4),
            const _Avatar(),
          ],
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
      child: const Icon(Icons.person_outline, size: 18, color: AppColors.accent),
    );
  }
}
