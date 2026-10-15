import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../utils/auth_theme.dart';

/// Logo chữ G nhiều màu của Google (20x20 trong thiết kế).
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 20});

  final double size;

  static const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
<path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
<path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
<path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
<path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
</svg>''';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(_svg, width: size, height: size);
  }
}

/// Nút chính nền xanh đậm, chữ trắng 16px, có icon tùy chọn.
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.leadingIcon,
    this.trailingIcon,
    this.color = AuthPalette.forest,
    this.height = 56,
    this.radius = 12,
    this.shadows = AuthPalette.buttonShadow,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final Color color;
  final double height;
  final double radius;
  final List<BoxShadow> shadows;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Opacity(
        opacity: onPressed == null ? 0.6 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: shadows,
          ),
          child: Material(
            color: color,
            borderRadius: BorderRadius.circular(radius),
            child: InkWell(
              onTap: enabled ? onPressed : null,
              borderRadius: BorderRadius.circular(radius),
              child: SizedBox(
                height: height,
                width: double.infinity,
                child: Center(
                  child: isLoading
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (leadingIcon != null) ...[
                              Icon(leadingIcon, size: 18, color: Colors.white),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Text(
                                label,
                                style: AuthTextStyles.button,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (trailingIcon != null) ...[
                              const SizedBox(width: 8),
                              Icon(trailingIcon, size: 16, color: Colors.white),
                            ],
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Nút trắng kem có logo Google.
class AuthGoogleButton extends StatelessWidget {
  const AuthGoogleButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.height = 56,
    this.radius = 12,
    this.width = double.infinity,
    this.labelStyle,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final double radius;
  final double width;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null && !isLoading,
      label: label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: AuthPalette.softShadow,
        ),
        child: Material(
          color: AuthPalette.surface,
          borderRadius: BorderRadius.circular(radius),
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(radius),
            child: SizedBox(
              height: height,
              width: width,
              child: Center(
                child: isLoading
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: AuthPalette.forest,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const GoogleLogo(),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  labelStyle ??
                                  AuthFonts.sans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    height: 1.5,
                                  ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Đường kẻ ngang có chữ ở giữa ("HOẶC", "Hoặc đăng ký nhanh bằng").
class AuthLabeledDivider extends StatelessWidget {
  const AuthLabeledDivider({
    super.key,
    required this.label,
    this.lineColor = AuthPalette.divider,
    this.labelStyle,
    this.gap = 12,
  });

  final String label;
  final Color lineColor;
  final TextStyle? labelStyle;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: lineColor)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: gap),
          child: Text(
            label,
            style:
                labelStyle ??
                AuthFonts.sans(
                  fontSize: 12,
                  color: AuthPalette.muted,
                  height: 1.5,
                ),
          ),
        ),
        Expanded(child: Container(height: 1, color: lineColor)),
      ],
    );
  }
}

/// Nhãn bo tròn (pill) có chấm hoặc icon phía trước.
class AuthPill extends StatelessWidget {
  const AuthPill({
    super.key,
    required this.label,
    this.icon,
    this.showDot = false,
    this.background = AuthPalette.sageSoft,
    this.foreground = AuthPalette.forest,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    this.gap = 6,
    this.textStyle,
    this.shadows = const [],
  });

  final String label;
  final IconData? icon;
  final bool showDot;
  final Color background;
  final Color foreground;
  final EdgeInsets padding;
  final double gap;
  final TextStyle? textStyle;
  final List<BoxShadow> shadows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(9999),
        boxShadow: shadows,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot)
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: foreground,
                shape: BoxShape.circle,
              ),
            ),
          if (icon != null) Icon(icon, size: 12, color: foreground),
          if (showDot || icon != null) SizedBox(width: gap),
          Text(
            label.toUpperCase(),
            style:
                textStyle ??
                AuthFonts.sans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                  height: 16 / 11,
                  letterSpacing: 0.55,
                ),
          ),
        ],
      ),
    );
  }
}

/// Trạng thái hiển thị của ô nhập.
enum AuthFieldStatus { normal, error, valid }

/// Ô nhập nền kem bo góc có bóng nhẹ, icon trái và nút phải tùy chọn.
///
/// Nhãn phía trên và dòng báo lỗi phía dưới do từng màn tự vẽ vì kiểu chữ
/// khác nhau giữa màn đăng nhập và đăng ký.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.prefixIcon,
    this.suffix,
    this.status = AuthFieldStatus.normal,
    this.height = 56,
    this.radius = 12,
    this.obscureText = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.contentPadding,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData? prefixIcon;

  /// Thường là nút ẩn/hiện mật khẩu hoặc icon trạng thái lỗi/hợp lệ.
  final Widget? suffix;
  final AuthFieldStatus status;
  final double height;
  final double radius;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final EdgeInsets? contentPadding;

  @override
  Widget build(BuildContext context) {
    final border = switch (status) {
      AuthFieldStatus.error => Border.all(color: AuthPalette.error, width: 2),
      AuthFieldStatus.valid => Border.all(color: AuthPalette.sage),
      AuthFieldStatus.normal => null,
    };
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AuthPalette.surface,
        borderRadius: BorderRadius.circular(radius),
        border: border,
        boxShadow: AuthPalette.softShadow,
      ),
      padding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (prefixIcon != null) ...[
            Icon(prefixIcon, size: 18, color: AuthPalette.muted),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              obscureText: obscureText,
              keyboardType: keyboardType,
              textCapitalization: textCapitalization,
              textInputAction: textInputAction,
              autofillHints: autofillHints,
              inputFormatters: inputFormatters,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              style: AuthTextStyles.input,
              cursorColor: AuthPalette.forest,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: AuthTextStyles.placeholder,
              ),
            ),
          ),
          if (suffix != null) ...[const SizedBox(width: 8), suffix!],
        ],
      ),
    );
  }
}

/// Nút con mắt ẩn/hiện mật khẩu.
class PasswordVisibilityButton extends StatelessWidget {
  const PasswordVisibilityButton({
    super.key,
    required this.obscured,
    required this.onPressed,
  });

  final bool obscured;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: obscured ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      icon: Icon(
        obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        size: 20,
        color: AuthPalette.muted,
      ),
    );
  }
}

/// Dòng báo lỗi "! nội dung" màu đỏ dưới ô nhập (màn đăng ký lỗi).
class AuthFieldError extends StatelessWidget {
  const AuthFieldError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '!',
            style: AuthFonts.sans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AuthPalette.error,
              height: 1.5,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(child: Text(message, style: AuthTextStyles.fieldError)),
        ],
      ),
    );
  }
}

/// Hiện lỗi từ Supabase (sai mật khẩu, mất mạng...) bằng SnackBar đỏ.
void showAuthError(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AuthPalette.errorDeep),
    );
}
