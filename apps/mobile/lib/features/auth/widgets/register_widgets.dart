import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../state/register_state.dart';
import '../utils/auth_assets.dart';
import '../utils/auth_theme.dart';
import '../utils/auth_validators.dart';
import 'auth_common.dart';

/// Cấu hình từng ô trên form đăng ký (nhãn, placeholder, bàn phím...).
class RegisterFieldConfig {
  const RegisterFieldConfig({
    required this.label,
    required this.errorLabel,
    required this.hint,
    required this.icon,
    required this.keyboardType,
    required this.autofillHints,
  });

  /// Nhãn ở layout thường (Màn 3).
  final String label;

  /// Nhãn ở layout lỗi (Màn 4).
  final String errorLabel;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final List<String> autofillHints;

  static RegisterFieldConfig of(RegisterField field) {
    return switch (field) {
      RegisterField.fullName => const RegisterFieldConfig(
        label: 'HỌ VÀ TÊN ĐẦY ĐỦ',
        errorLabel: 'HỌ VÀ TÊN',
        hint: 'Ví dụ: Nguyễn Phương Hà',
        icon: Icons.person_outline,
        keyboardType: TextInputType.name,
        autofillHints: [AutofillHints.name],
      ),
      RegisterField.phone => const RegisterFieldConfig(
        label: 'SỐ ĐIỆN THOẠI',
        errorLabel: 'SỐ ĐIỆN THOẠI',
        hint: '(+84) 912 345 678',
        icon: Icons.phone_outlined,
        keyboardType: TextInputType.phone,
        autofillHints: [AutofillHints.telephoneNumber],
      ),
      RegisterField.email => const RegisterFieldConfig(
        label: 'EMAIL',
        errorLabel: 'ĐỊA CHỈ EMAIL',
        hint: 'email@domain.vn',
        icon: Icons.alternate_email,
        keyboardType: TextInputType.emailAddress,
        autofillHints: [AutofillHints.email],
      ),
      RegisterField.address => const RegisterFieldConfig(
        label: 'ĐỊA CHỈ',
        errorLabel: 'ĐỊA CHỈ NHẬN HÀNG MẶC ĐỊNH',
        hint: 'Nhập địa chỉ nhận hàng',
        icon: Icons.location_on_outlined,
        keyboardType: TextInputType.streetAddress,
        autofillHints: [AutofillHints.fullStreetAddress],
      ),
      RegisterField.password => const RegisterFieldConfig(
        label: 'MẬT KHẨU',
        errorLabel: 'MẬT KHẨU',
        hint: 'Tối thiểu 8 ký tự an toàn',
        icon: Icons.lock_outline,
        keyboardType: TextInputType.text,
        autofillHints: [AutofillHints.newPassword],
      ),
      RegisterField.confirmPassword => const RegisterFieldConfig(
        label: 'XÁC NHẬN MẬT KHẨU',
        errorLabel: 'XÁC NHẬN MẬT KHẨU',
        hint: 'Nhập lại mật khẩu vừa tạo',
        icon: Icons.verified_user_outlined,
        keyboardType: TextInputType.text,
        autofillHints: [AutofillHints.newPassword],
      ),
    };
  }
}

bool _isPasswordField(RegisterField field) {
  return field == RegisterField.password ||
      field == RegisterField.confirmPassword;
}

/// Nút eye ẩn/hiện mật khẩu, bỏ khỏi thứ tự focus để "next" nhảy đúng ô.
class _PasswordToggle extends StatelessWidget {
  const _PasswordToggle({
    required this.field,
    required this.obscured,
    required this.onPressed,
  });

  final RegisterField field;
  final bool obscured;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ExcludeFocus(
      child: PasswordVisibilityButton(
        key: Key('register_${field.keyName}_visibility_button'),
        obscured: obscured,
        onPressed: onPressed,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Layout thường (Màn 3)
// ---------------------------------------------------------------------------

/// Nút tròn 40 nền kem có bóng nhẹ.
class _RoundBackButton extends StatelessWidget {
  const _RoundBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Quay lại',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AuthPalette.surface,
          shape: BoxShape.circle,
          boxShadow: AuthPalette.softShadow,
        ),
        child: InkWell(
          key: const Key('register_back_button'),
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: const SizedBox.square(
            dimension: 40,
            child: Icon(Icons.arrow_back, size: 18, color: AuthPalette.forest),
          ),
        ),
      ),
    );
  }
}

/// Header của layout thường: back | FLEURÉ • | icon trang trí.
class RegisterHeader extends StatelessWidget {
  const RegisterHeader({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          _RoundBackButton(onPressed: onBack),
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'FLEURÉ',
                    style: AuthFonts.serif(
                      fontSize: 18,
                      height: 26 / 18,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AuthPalette.rose,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox.square(
            dimension: 40,
            child: Icon(Icons.spa_outlined, size: 16, color: AuthPalette.sage),
          ),
        ],
      ),
    );
  }
}


/// Pill + tiêu đề + mô tả của layout thường.
class RegisterGreeting extends StatelessWidget {
  const RegisterGreeting({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AuthPill(label: 'Gia nhập Fleuré Privé', showDot: true),
        const SizedBox(height: 3),
        Text(
          'Tạo tài khoản mới',
          style: AuthTextStyles.heading1.copyWith(color: AuthPalette.ink),
        ),
        const SizedBox(height: 3),
        Text(
          'Trở thành thành viên để lưu giữ những bó hoa yêu thích, tích lũy '
          'đặc quyền và nhận tư vấn cắm hoa riêng biệt từ nghệ nhân.',
          style: AuthTextStyles.body,
        ),
      ],
    );
  }
}

/// Ô nhập ở layout thường: nhãn caps + ô cao 56 có icon trái.
class RegisterFormField extends StatelessWidget {
  const RegisterFormField({
    super.key,
    required this.field,
    required this.textController,
    required this.focusNode,
    this.obscureText = false,
    this.onToggleObscure,
    this.isLast = false,
  });

  final RegisterField field;
  final TextEditingController textController;
  final FocusNode focusNode;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final config = RegisterFieldConfig.of(field);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(config.label, style: AuthTextStyles.capsLabel),
        const SizedBox(height: 4),
        AuthTextField(
          key: Key('register_${field.keyName}_field'),
          controller: textController,
          focusNode: focusNode,
          hintText: config.hint,
          prefixIcon: config.icon,
          obscureText: obscureText,
          keyboardType: config.keyboardType,
          textCapitalization: field == RegisterField.fullName
              ? TextCapitalization.words
              : TextCapitalization.none,
          textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
          autofillHints: config.autofillHints,
          suffix: _isPasswordField(field)
              ? _PasswordToggle(
                  field: field,
                  obscured: obscureText,
                  onPressed: onToggleObscure ?? () {},
                )
              : null,
        ),
      ],
    );
  }
}

/// Nút Google nhỏ + đường kẻ "Hoặc đăng ký nhanh bằng".
class RegisterSocialSection extends StatelessWidget {
  const RegisterSocialSection({
    super.key,
    required this.onGoogle,
    required this.isLoading,
  });

  final VoidCallback? onGoogle;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AuthLabeledDivider(
          label: 'Hoặc đăng ký nhanh bằng',
          lineColor: AuthPalette.chipGrey,
          gap: 16,
        ),
        const SizedBox(height: 16),
        AuthGoogleButton(
          key: const Key('register_google_button'),
          label: 'Google',
          onPressed: onGoogle,
          isLoading: isLoading,
          height: 46,
          width: 170,
          labelStyle: AuthFonts.sans(fontSize: 14, height: 1.5),
        ),
      ],
    );
  }
}


// ---------------------------------------------------------------------------
// Layout lỗi (Màn 4)
// ---------------------------------------------------------------------------

/// Header cố định cao 56 có viền dưới: back | FLEURÉ | help.
class RegisterErrorHeader extends StatelessWidget {
  const RegisterErrorHeader({
    super.key,
    required this.onBack,
    required this.onHelp,
  });

  final VoidCallback onBack;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AuthPalette.background.withValues(alpha: 0.9),
        border: const Border(bottom: BorderSide(color: AuthPalette.border)),
      ),
      child: Row(
        children: [
          IconButton(
            key: const Key('register_back_button'),
            onPressed: onBack,
            tooltip: 'Quay lại',
            icon: const Icon(
              Icons.arrow_back,
              size: 20,
              color: AuthPalette.forest,
            ),
          ),
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_florist,
                    size: 16,
                    color: AuthPalette.rose,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'FLEURÉ',
                    style: AuthFonts.serif(
                      fontSize: 18,
                      height: 26 / 18,
                      letterSpacing: 1.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            key: const Key('register_help_button'),
            onPressed: onHelp,
            tooltip: 'Hỗ trợ',
            icon: const Icon(
              Icons.help_outline,
              size: 18,
              color: AuthPalette.muted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill "KIỂM TRA THÔNG TIN" + tiêu đề + mô tả của layout lỗi.
class RegisterErrorIntro extends StatelessWidget {
  const RegisterErrorIntro({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthPill(
          label: 'Kiểm tra thông tin',
          icon: Icons.error,
          background: AuthPalette.errorSurface,
          foreground: AuthPalette.error,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          gap: 4,
        ),
        const SizedBox(height: 4),
        Text(
          'Đăng ký tài khoản',
          style: AuthFonts.serif(fontSize: 28, height: 36 / 28),
        ),
        const SizedBox(height: 4),
        Text(
          'Vui lòng kiểm tra và sửa lại các thông tin chưa chính xác bên dưới '
          'để hoàn tất đăng ký Fleuré Privé.',
          style: AuthFonts.sans(
            fontSize: 14,
            color: AuthPalette.muted,
            height: 22 / 14,
          ),
        ),
      ],
    );
  }
}

/// Hộp "Có N mục cần điều chỉnh".
class RegisterErrorSummary extends StatelessWidget {
  const RegisterErrorSummary({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('register_error_summary'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AuthPalette.errorSurface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AuthPalette.error.withValues(alpha: 0.4)),
        boxShadow: AuthPalette.softShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error, size: 18, color: AuthPalette.error),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Có $count mục cần điều chỉnh',
                  key: const Key('register_error_count'),
                  style: AuthFonts.sans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AuthPalette.errorDeep,
                    height: 22 / 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Những trường bị lỗi đã được làm nổi bật với thông báo cụ '
                  'thể bên dưới.',
                  style: AuthFonts.sans(
                    fontSize: 12,
                    color: AuthPalette.errorDeep.withValues(alpha: 0.9),
                    height: 1.5,
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

/// Ô nhập ở layout lỗi: nhãn + "*"/"HỢP LỆ", ô cao 38, icon trạng thái bên phải.
class RegisterErrorField extends StatelessWidget {
  const RegisterErrorField({
    super.key,
    required this.field,
    required this.textController,
    required this.focusNode,
    required this.error,
    required this.password,
    this.obscureText = false,
    this.onToggleObscure,
    this.isLast = false,
  });

  final RegisterField field;
  final TextEditingController textController;
  final FocusNode focusNode;

  /// Câu báo lỗi, null nếu ô hợp lệ.
  final String? error;

  /// Mật khẩu hiện tại, dùng cho checklist dưới ô mật khẩu.
  final String password;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final config = RegisterFieldConfig.of(field);
    final hasError = error != null;
    final statusIcon = Icon(
      hasError ? Icons.cancel : Icons.check_circle,
      key: Key('register_status_icon_${field.keyName}'),
      size: 16,
      color: hasError ? AuthPalette.error : AuthPalette.sage,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                config.errorLabel,
                style: AuthFonts.sans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 16 / 11,
                  letterSpacing: 0.275,
                ),
              ),
            ),
            if (hasError)
              Text(
                '*',
                key: Key('register_error_mark_${field.keyName}'),
                style: AuthFonts.sans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AuthPalette.error,
                  height: 16 / 11,
                ),
              )
            else
              Text(
                'HỢP LỆ',
                key: Key('register_valid_badge_${field.keyName}'),
                style: AuthFonts.sans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AuthPalette.sage,
                  height: 16 / 11,
                  letterSpacing: 0.44,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        AuthTextField(
          key: Key('register_${field.keyName}_field'),
          controller: textController,
          focusNode: focusNode,
          hintText: config.hint,
          height: 38,
          status: hasError ? AuthFieldStatus.error : AuthFieldStatus.valid,
          obscureText: obscureText,
          keyboardType: config.keyboardType,
          textCapitalization: field == RegisterField.fullName
              ? TextCapitalization.words
              : TextCapitalization.none,
          textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
          autofillHints: config.autofillHints,
          suffix: _isPasswordField(field)
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PasswordToggle(
                      field: field,
                      obscured: obscureText,
                      onPressed: onToggleObscure ?? () {},
                    ),
                    const SizedBox(width: 4),
                    statusIcon,
                  ],
                )
              : statusIcon,
        ),
        if (hasError)
          AuthFieldError(
            key: Key('register_error_${field.keyName}'),
            message: error!,
          ),
        if (hasError && field == RegisterField.password) ...[
          const SizedBox(height: 8),
          RegisterPasswordRules(password: password),
        ],
      ],
    );
  }
}

/// Checklist 4 điều kiện mật khẩu dưới ô mật khẩu ở layout lỗi.
class RegisterPasswordRules extends StatelessWidget {
  const RegisterPasswordRules({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final rules = PasswordRules.of(password);
    return Container(
      key: const Key('register_password_rules'),
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AuthPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AuthPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RuleRow(
            ruleKey: 'min_length',
            label: 'Tối thiểu 8 ký tự',
            passed: rules.hasMinLength,
          ),
          const SizedBox(height: 4),
          _RuleRow(
            ruleKey: 'uppercase',
            label: 'Ít nhất 1 chữ cái in hoa',
            passed: rules.hasUppercase,
          ),
          const SizedBox(height: 4),
          _RuleRow(
            ruleKey: 'digit',
            label: 'Ít nhất 1 chữ số',
            passed: rules.hasDigit,
          ),
          const SizedBox(height: 4),
          _RuleRow(
            ruleKey: 'special',
            label: 'Ít nhất 1 ký tự đặc biệt',
            passed: rules.hasSpecial,
          ),
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({
    required this.ruleKey,
    required this.label,
    required this.passed,
  });

  final String ruleKey;
  final String label;
  final bool passed;

  @override
  Widget build(BuildContext context) {
    final color = passed ? AuthPalette.sage : AuthPalette.error;
    return Row(
      key: Key('register_password_rule_$ruleKey'),
      children: [
        Icon(
          passed ? Icons.check_circle : Icons.cancel,
          size: 12,
          color: color,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            passed ? '$label (Đạt)' : '$label (Chưa có)',
            style: AuthFonts.sans(
              fontSize: 12,
              fontWeight: passed ? FontWeight.w400 : FontWeight.w500,
              color: color,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

/// Thẻ "Cần hỗ trợ đăng ký?" cuối layout lỗi.
class RegisterSupportCard extends StatelessWidget {
  const RegisterSupportCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('register_support_card'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AuthPalette.sageSoft.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AuthPalette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AuthPalette.surface,
              shape: BoxShape.circle,
              boxShadow: AuthPalette.softShadow,
            ),
            child: const Icon(
              Icons.support_agent,
              size: 22,
              color: AuthPalette.forest,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cần hỗ trợ đăng ký?',
                  style: AuthFonts.sans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AuthPalette.forest,
                    height: 22 / 14,
                  ),
                ),
                Text(
                  'Hỗ trợ riêng cho thành viên Privé: 1800 6868 (8:00 - 21:00)',
                  style: AuthFonts.sans(
                    fontSize: 12,
                    color: AuthPalette.muted,
                    height: 1.5,
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

// ---------------------------------------------------------------------------
// Dùng chung cho hai layout
// ---------------------------------------------------------------------------

/// Checkbox đồng ý điều khoản; bấm cả dòng để chọn, link chỉ báo "Đang cập nhật".
class RegisterAgreementRow extends StatefulWidget {
  const RegisterAgreementRow({
    super.key,
    required this.checked,
    required this.onToggle,
    required this.onOpenLink,
    this.errorLayout = false,
    this.errorMessage,
  });

  final bool checked;
  final VoidCallback onToggle;
  final VoidCallback onOpenLink;

  /// Layout lỗi dùng chữ "và", link màu forest và "Fleuré Privé".
  final bool errorLayout;

  /// Câu báo lỗi hiện dưới checkbox (layout lỗi, khi chưa chọn).
  final String? errorMessage;

  @override
  State<RegisterAgreementRow> createState() => _RegisterAgreementRowState();
}

class _RegisterAgreementRowState extends State<RegisterAgreementRow> {
  late final TapGestureRecognizer _termsTap;
  late final TapGestureRecognizer _privacyTap;

  @override
  void initState() {
    super.initState();
    _termsTap = TapGestureRecognizer()..onTap = _openLink;
    _privacyTap = TapGestureRecognizer()..onTap = _openLink;
  }

  void _openLink() => widget.onOpenLink();

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final errorLayout = widget.errorLayout;
    final baseStyle = AuthFonts.sans(
      fontSize: 12,
      color: AuthPalette.muted,
      height: errorLayout ? 1.625 : 1.25,
    );
    final linkStyle = AuthFonts.sans(
      fontSize: 12,
      fontWeight: errorLayout ? FontWeight.w400 : FontWeight.w500,
      color: errorLayout ? AuthPalette.forest : AuthPalette.ink,
      height: errorLayout ? 1.625 : 1.25,
      decoration: TextDecoration.underline,
    );
    final showError = widget.errorMessage != null;
    return Semantics(
      checked: widget.checked,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onToggle,
        child: Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    key: const Key('register_agreement_checkbox'),
                    onTap: widget.onToggle,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: widget.checked
                            ? AuthPalette.forest
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: widget.checked
                            ? null
                            : Border.all(
                                color: showError
                                    ? AuthPalette.error
                                    : AuthPalette.muted,
                                width: 1.5,
                              ),
                      ),
                      child: widget.checked
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                  SizedBox(width: errorLayout ? 8 : 12),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: baseStyle,
                        children: [
                          const TextSpan(text: 'Tôi đồng ý với '),
                          TextSpan(
                            text: 'Điều khoản dịch vụ',
                            style: linkStyle,
                            recognizer: _termsTap,
                          ),
                          TextSpan(text: errorLayout ? ' và ' : ' & '),
                          TextSpan(
                            text: 'Chính sách bảo mật',
                            style: linkStyle,
                            recognizer: _privacyTap,
                          ),
                          TextSpan(
                            text: errorLayout
                                ? ' của Fleuré Privé.'
                                : ' của Fleuré.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (showError)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: AuthFieldError(
                    key: const Key('register_error_agreement'),
                    message: widget.errorMessage!,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Đã có tài khoản Fleuré? Đăng nhập ngay".
class RegisterLoginLink extends StatelessWidget {
  const RegisterLoginLink({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Đã có tài khoản Fleuré? ',
          style: AuthFonts.sans(fontSize: 14, color: AuthPalette.muted),
        ),
        GestureDetector(
          key: const Key('register_login_link'),
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'Đăng nhập ngay',
              style: AuthFonts.sans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AuthPalette.forest,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
