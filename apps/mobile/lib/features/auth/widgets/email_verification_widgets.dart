import 'package:flutter/material.dart';

import '../utils/auth_assets.dart';
import '../utils/auth_theme.dart';

// Ảnh minh hoạ xuất từ Penpot (AuthAssets không còn khai báo ảnh này).
const _thumbnailAsset = 'assets/auth/otp_thumbnail.png';

/// Header màn "Kiểm tra email": nút back + logo Fleuré + tiêu đề (cao 64).
class EmailVerificationHeader extends StatelessWidget {
  const EmailVerificationHeader({super.key, required this.onBack});

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
            key: const Key('verify_email_back_button'),
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
          const SizedBox(width: 4),
          Image.asset(AuthAssets.fleureLogo, height: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Kiểm tra email',
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

/// Banner "Bảo mật cao cấp - Kiểm tra hộp thư đến của bạn" (cao tối thiểu 96).
class EmailVerificationBanner extends StatelessWidget {
  const EmailVerificationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Cao tối thiểu 96 như thiết kế, chữ phóng to thì banner giãn theo
      constraints: const BoxConstraints(minHeight: 96),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AuthPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AuthPalette.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AuthPalette.surfaceStone,
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(_thumbnailAsset, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AuthPalette.goldSoft,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock, size: 9, color: AuthPalette.gold),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Bảo mật cao cấp',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AuthFonts.sans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AuthPalette.gold,
                            height: 16 / 11,
                            letterSpacing: 0.44,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kiểm tra hộp thư đến của bạn',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AuthFonts.sans(
                    fontSize: 14,
                    color: AuthPalette.muted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip hiển thị email đã đăng ký.
class EmailVerificationChip extends StatelessWidget {
  const EmailVerificationChip({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AuthPalette.sageSoft,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mail_outline, size: 13, color: AuthPalette.forest),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              email,
              key: const Key('verify_email_address'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AuthFonts.sans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AuthPalette.forest,
                height: 22 / 14,
                letterSpacing: 0.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ghi chú nhắc kiểm tra thư mục spam ở cuối thẻ.
class EmailVerificationSpamNote extends StatelessWidget {
  const EmailVerificationSpamNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AuthPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Icon(
              Icons.mark_email_unread_outlined,
              size: 15,
              color: AuthPalette.sage,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Chưa thấy email? Hãy kiểm tra cả thư mục spam hoặc thư rác.',
              style: AuthFonts.sans(
                fontSize: 12,
                color: AuthPalette.muted,
                height: 1.625,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
