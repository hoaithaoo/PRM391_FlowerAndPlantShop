import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/auth_assets.dart';
import '../utils/auth_theme.dart';
import '../utils/auth_validators.dart';

/// Header màn OTP: nút back + logo Fleuré + tiêu đề "Xác thực Email" (cao 64).
class OtpHeader extends StatelessWidget {
  const OtpHeader({super.key, required this.onBack});

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
            key: const Key('otp_back_button'),
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
              'Xác thực Email',
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

/// Banner "Bảo mật cao cấp - Kiểm tra hộp thư đến của bạn" (cao 96).
class OtpBanner extends StatelessWidget {
  const OtpBanner({super.key});

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
            child: Image.asset(AuthAssets.otpThumbnail, fit: BoxFit.cover),
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
                      Text(
                        'Bảo mật cao cấp',
                        style: AuthFonts.sans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AuthPalette.gold,
                          height: 16 / 11,
                          letterSpacing: 0.44,
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

/// Chip hiển thị email đã che kèm nút sửa email.
class OtpEmailChip extends StatelessWidget {
  const OtpEmailChip({
    super.key,
    required this.maskedEmail,
    required this.onEdit,
  });

  final String maskedEmail;
  final VoidCallback onEdit;

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
              maskedEmail,
              key: const Key('otp_email_text'),
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
          const SizedBox(width: 8),
          InkWell(
            key: const Key('otp_edit_email_button'),
            onTap: onEdit,
            customBorder: const CircleBorder(),
            child: const SizedBox.square(
              dimension: 20,
              child: Icon(
                Icons.edit_outlined,
                size: 11.3,
                color: AuthPalette.forest,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hàng 6 ô OTP: một TextField trong suốt phủ lên 6 ô vẽ tay.
///
/// Dùng một TextField duy nhất nên tự nhảy ô, Backspace lùi ô, dán 6 số và
/// autofill `oneTimeCode` đều hoạt động như một ô nhập bình thường.
class OtpDigitInput extends StatefulWidget {
  const OtpDigitInput({
    super.key,
    required this.code,
    required this.textController,
    required this.focusNode,
    required this.onChanged,
    this.hasError = false,
    this.enabled = true,
    this.onSubmitted,
  });

  final String code;
  final TextEditingController textController;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final bool hasError;
  final bool enabled;
  final VoidCallback? onSubmitted;

  @override
  State<OtpDigitInput> createState() => _OtpDigitInputState();
}

class _OtpDigitInputState extends State<OtpDigitInput> {
  @override
  void initState() {
    super.initState();
    widget.textController.addListener(_keepCaretAtEnd);
  }

  @override
  void didUpdateWidget(OtpDigitInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.textController != widget.textController) {
      oldWidget.textController.removeListener(_keepCaretAtEnd);
      widget.textController.addListener(_keepCaretAtEnd);
    }
  }

  @override
  void dispose() {
    widget.textController.removeListener(_keepCaretAtEnd);
    super.dispose();
  }

  /// Chạm giữa dãy số vẫn phải gõ tiếp ở cuối để mỗi ô đúng một chữ số.
  void _keepCaretAtEnd() {
    final value = widget.textController.value;
    final end = value.text.length;
    if (value.selection.isCollapsed && value.selection.baseOffset != end) {
      widget.textController.selection = TextSelection.collapsed(offset: end);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.focusNode,
      builder: (context, _) {
        final focused = widget.focusNode.hasFocus;
        final activeIndex = widget.code.length.clamp(
          0,
          AuthValidators.otpLength - 1,
        );
        return Stack(
          children: [
            Row(
              children: [
                for (var i = 0; i < AuthValidators.otpLength; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: OtpDigitBox(
                      key: Key('otp_digit_$i'),
                      digit: i < widget.code.length ? widget.code[i] : null,
                      isFocused: focused && i == activeIndex,
                      hasError: widget.hasError,
                    ),
                  ),
                ],
              ],
            ),
            // Lớp nhập liệu trong suốt phủ đúng vùng 6 ô
            Positioned.fill(
              child: TextField(
                key: const Key('otp_input'),
                controller: widget.textController,
                focusNode: widget.focusNode,
                enabled: widget.enabled,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.oneTimeCode],
                autocorrect: false,
                enableSuggestions: false,
                showCursor: false,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(AuthValidators.otpLength),
                ],
                onChanged: widget.onChanged,
                onSubmitted: (_) => widget.onSubmitted?.call(),
                style: const TextStyle(color: Colors.transparent),
                cursorColor: Colors.transparent,
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Một ô OTP vuông: trống, đã nhập, đang focus hoặc báo lỗi.
class OtpDigitBox extends StatelessWidget {
  const OtpDigitBox({
    super.key,
    required this.digit,
    required this.isFocused,
    required this.hasError,
  });

  final String? digit;
  final bool isFocused;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final filled = digit != null;
    final shadows = isFocused
        ? AuthPalette.softShadow
        : filled
        ? const [
            BoxShadow(
              color: Color(0x1A000000),
              offset: Offset(0, 2),
              blurRadius: 4,
            ),
          ]
        : const <BoxShadow>[];
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: isFocused ? Colors.white : AuthPalette.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
          border: hasError
              ? Border.all(color: AuthPalette.error, width: 1.5)
              : null,
          boxShadow: shadows,
        ),
        foregroundDecoration: isFocused
            ? BoxDecoration(
                color: AuthPalette.forest.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        alignment: Alignment.center,
        child: digit == null
            ? null
            : Text(digit!, style: AuthFonts.serif(fontSize: 22, height: 1.2)),
      ),
    );
  }
}

/// Ghi chú "Mã OTP có hiệu lực trong 5 phút..." ở cuối thẻ.
class OtpSecurityNote extends StatelessWidget {
  const OtpSecurityNote({super.key});

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
              Icons.verified_user_outlined,
              size: 15,
              color: AuthPalette.sage,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mã OTP có hiệu lực trong 5 phút. Vui lòng bảo mật mã này để '
              'bảo vệ tài khoản tác phẩm của bạn.',
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
