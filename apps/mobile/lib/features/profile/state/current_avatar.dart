import 'package:flutter/material.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

/// Ảnh đại diện của người đang đăng nhập, dùng chung cho mọi header.
///
/// Màn Tài khoản cập nhật giá trị mỗi khi tải hồ sơ hoặc đổi ảnh, nên header
/// ở Trang chủ, Sản phẩm, Thông báo luôn khớp với ảnh trong hồ sơ.
class CurrentAvatar extends InheritedNotifier<ValueNotifier<String?>> {
  const CurrentAvatar({
    super.key,
    required ValueNotifier<String?> super.notifier,
    required super.child,
  });

  /// URL ảnh hiện tại (đăng ký lắng nghe thay đổi). Null là chưa có ảnh.
  static String? urlOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<CurrentAvatar>()
      ?.notifier
      ?.value;

  /// Ghi URL mới; không có [CurrentAvatar] phía trên thì bỏ qua.
  static void update(BuildContext context, String? url) {
    final notifier = context
        .getInheritedWidgetOfExactType<CurrentAvatar>()
        ?.notifier;
    if (notifier != null) notifier.value = url;
  }
}

/// Avatar tròn 32px trên header: ảnh thật của tài khoản, chưa có ảnh hoặc
/// tải lỗi thì hiện icon người.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, this.radius = 16});

  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = CurrentAvatar.urlOf(context);
    final hasImage = url != null && url.isNotEmpty;
    return Container(
      key: const Key('user-avatar'),
      padding: const EdgeInsets.all(1),
      decoration: const BoxDecoration(
        color: AppColors.accentBorder,
        shape: BoxShape.circle,
      ),
      child: CircleAvatar(
        radius: radius - 1,
        backgroundColor: AppColors.accentLight,
        foregroundImage: hasImage ? NetworkImage(url) : null,
        onForegroundImageError: hasImage ? (_, _) {} : null,
        child: Icon(
          Icons.person_outline,
          size: radius + 2,
          color: AppColors.accent,
        ),
      ),
    );
  }
}
