import 'package:flutter/material.dart';

import '../utils/auth_theme.dart';
import 'auth_common.dart';

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
              child: Text('Nhà Có Hoa', style: AuthTextStyles.brandLogo),
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

/// Nhãn phía trên ô nhập ("Mật khẩu", "Email").
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
