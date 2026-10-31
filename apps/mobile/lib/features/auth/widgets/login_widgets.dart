import 'package:flutter/material.dart';

import '../utils/auth_theme.dart';
import 'auth_common.dart';

/// Biểu tượng vòng tròn nét + chấm vàng cạnh chữ "Fleuré" (32x32).
class FleureMark extends StatelessWidget {
  const FleureMark({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 32,
      child: Stack(
        children: [
          Positioned(
            left: 6,
            top: 10,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AuthPalette.forestButton, width: 2),
              ),
            ),
          ),
          Positioned(
            left: 19,
            top: 4,
            child: Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: AuthPalette.gold,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Thanh trên của màn đăng nhập: logo bên trái, pill "BOTANICAL" bên phải.
class LoginTopBar extends StatelessWidget {
  const LoginTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Hai khối đều co được (scaleDown) để không tràn khi chữ phóng to
          // hoặc font rộng; ở cỡ chữ thường chúng giữ nguyên kích thước.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FleureMark(),
                  const SizedBox(width: 8),
                  Text(
                    'Fleuré',
                    style: AuthFonts.serif(
                      fontSize: 22,
                      height: 1.2,
                      letterSpacing: -0.55,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: AuthPill(
                label: 'Botanical',
                icon: Icons.spa,
                textStyle: AuthFonts.sans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AuthPalette.forest,
                  height: 16 / 11,
                  letterSpacing: 0.275,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Nhãn phía trên ô nhập ("Mật khẩu", "Số điện thoại hoặc Email").
class LoginFieldLabel extends StatelessWidget {
  const LoginFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AuthFonts.sans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 22 / 14,
      ),
    );
  }
}

/// Link chữ nhỏ có vùng chạm đủ rộng (Quên mật khẩu?).
class LoginTextLink extends StatelessWidget {
  const LoginTextLink({
    super.key,
    required this.label,
    required this.onPressed,
    required this.style,
  });

  final String label;
  final VoidCallback? onPressed;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Text(label, style: style),
      ),
    );
  }
}
