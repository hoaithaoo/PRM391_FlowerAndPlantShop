import 'package:flutter/material.dart';

import '../utils/auth_assets.dart';
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
          Row(
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
          AuthPill(
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

/// Link chữ nhỏ có vùng chạm đủ rộng (Đăng nhập OTP, Quên mật khẩu?).
class LoginTextLink extends StatelessWidget {
  const LoginTextLink({
    super.key,
    required this.label,
    required this.onPressed,
    required this.style,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final TextStyle style;

  /// Hiện vòng xoay nhỏ và vô hiệu hóa khi đang xử lý.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading) ...[
              const SizedBox.square(
                dimension: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.6,
                  color: AuthPalette.sage,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(label, style: style),
          ],
        ),
      ),
    );
  }
}

/// Header màn "Đăng nhập để tiếp tục": nút back tròn + tiêu đề (cao 64).
class GateHeader extends StatelessWidget {
  const GateHeader({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AuthPalette.surface.withValues(alpha: 0.9),
        boxShadow: AuthPalette.softShadow,
      ),
      child: Row(
        children: [
          IconButton(
            key: const Key('gate_back_button'),
            onPressed: onBack,
            tooltip: 'Quay lại',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            icon: const Icon(
              Icons.arrow_back,
              size: 16,
              color: AuthPalette.ink,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Đăng Nhập Để Tiếp Tục',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AuthTextStyles.headerTitle,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dòng "● FLEURÉ STUDIO" bên trái và nút đóng tròn bên phải.
class GateTopRow extends StatelessWidget {
  const GateTopRow({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AuthPalette.forest,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'FLEURÉ STUDIO',
                style: AuthFonts.serif(
                  fontSize: 12,
                  height: 16 / 12,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          Material(
            color: AuthPalette.chipGrey,
            shape: const CircleBorder(),
            child: InkWell(
              key: const Key('gate_close_button'),
              onTap: onClose,
              customBorder: const CircleBorder(),
              child: const SizedBox.square(
                dimension: 36,
                child: Icon(Icons.close, size: 11, color: AuthPalette.muted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Khung ảnh hero 176px có gradient xanh và pill "ĐẶC QUYỀN HỘI VIÊN".
class GateHeroCard extends StatelessWidget {
  const GateHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 176,
      decoration: BoxDecoration(
        color: AuthPalette.surfaceStone,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AuthPalette.softShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(AuthAssets.loginGateHero, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  AuthPalette.forest.withValues(alpha: 0.7),
                  AuthPalette.forest.withValues(alpha: 0.2),
                  AuthPalette.forest.withValues(alpha: 0),
                ],
                stops: const [0, 0.5, 1],
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 16,
            child: AuthPill(
              label: 'Đặc quyền hội viên Fleuré',
              icon: Icons.workspace_premium_outlined,
              foreground: AuthPalette.gold,
              background: AuthPalette.surface.withValues(alpha: 0.9),
              shadows: AuthPalette.softShadow,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dòng "Bảo mật với Supabase Auth..." ở cuối màn gate.
class GateSecurityNote extends StatelessWidget {
  const GateSecurityNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.verified_user_outlined,
          size: 13,
          color: AuthPalette.gold,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'Bảo mật với Supabase Auth. Không cần ghi nhớ mật khẩu.',
            textAlign: TextAlign.center,
            style: AuthFonts.sans(
              fontSize: 12,
              color: AuthPalette.muted,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}
