import 'package:flutter/material.dart';

/// Hiệu ứng ảnh sản phẩm bay vào icon giỏ hàng [target], kiểu Shopee.
///
/// Không tìm thấy icon (đã cuộn khỏi màn) thì bay tới góc trên bên phải.
void flyToCart(
  BuildContext context, {
  required GlobalKey target,
  required Widget child,
  double size = 84,
}) {
  final overlay = Overlay.of(context);
  final screen = MediaQuery.sizeOf(context);
  final start = Offset(screen.width / 2, screen.height * 0.72);

  final box = target.currentContext?.findRenderObject() as RenderBox?;
  final visible = box != null && box.attached;
  final end = visible
      ? box.localToGlobal(box.size.center(Offset.zero))
      : Offset(screen.width - 40, 48);

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOutCubic,
      onEnd: () => entry.remove(),
      builder: (_, t, _) {
        final position = Offset.lerp(start, end, t)!;
        final scale = 1 - 0.8 * t;
        return Positioned(
          left: position.dx - size / 2,
          top: position.dy - size / 2,
          child: IgnorePointer(
            child: Opacity(
              opacity: 1 - 0.3 * t,
              child: Transform.scale(
                scale: scale,
                child: SizedBox.square(dimension: size, child: child),
              ),
            ),
          ),
        );
      },
    ),
  );
  overlay.insert(entry);
}
