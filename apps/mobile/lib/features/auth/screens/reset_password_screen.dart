import 'package:flutter/material.dart';

import '../data/auth_scope.dart';
import '../state/reset_password_controller.dart';
import '../state/reset_password_state.dart';
import '../utils/auth_theme.dart';
import '../widgets/auth_common.dart';

/// Màn hình Đổi mật khẩu mới: Mở ra sau khi người dùng bấm vào Link khôi phục trong email.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  late final ResetPasswordController _controller;

  @override
  void initState() {
    super.initState();
    final repository = AuthScope.of(context);
    _controller = ResetPasswordController(repository: repository);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    FocusScope.of(context).unfocus();
    final result = await _controller.submit();
    if (!mounted) return;

    if (result.outcome == ResetPasswordOutcome.success) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Đổi mật khẩu thành công! Vui lòng đăng nhập bằng mật khẩu mới.',
            ),
          ),
        );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } else if (result.outcome == ResetPasswordOutcome.failed) {
      showAuthError(context, result.message ?? 'Không thể cập nhật mật khẩu.');
    }
  }

  Future<void> _onCancel() async {
    await _controller.cancel();
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthPalette.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final state = _controller.state;
            return Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: _buildForm(state),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            key: const Key('reset_password_back_button'),
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            color: AuthPalette.ink,
            onPressed: _onCancel,
          ),
          const SizedBox(width: 8),
          Text(
            'Tạo mật khẩu mới',
            style: AuthFonts.sans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AuthPalette.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(ResetPasswordState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AuthPalette.sageSoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.lock_outline,
            size: 32,
            color: AuthPalette.forest,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Đặt lại mật khẩu',
          textAlign: TextAlign.center,
          style: AuthTextStyles.heading1.copyWith(color: AuthPalette.ink),
        ),
        const SizedBox(height: 8),
        Text(
          'Tài khoản của bạn đã được xác thực an toàn qua email. Hãy thiết lập mật khẩu mới ngay dưới đây.',
          textAlign: TextAlign.center,
          style: AuthTextStyles.body,
        ),
        const SizedBox(height: 28),
        Text(
          'Mật khẩu mới',
          style: AuthFonts.sans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AuthPalette.ink,
          ),
        ),
        const SizedBox(height: 6),
        AuthTextField(
          key: const Key('reset_password_new_password_field'),
          controller: _controller.newPasswordController,
          hintText: 'Nhập mật khẩu mới',
          prefixIcon: Icons.lock_outline,
          obscureText: state.obscureNewPassword,
          height: 54,
          radius: 14,
          status: state.showErrors && state.newPasswordError != null
              ? AuthFieldStatus.error
              : AuthFieldStatus.normal,
          suffix: PasswordVisibilityButton(
            key: const Key('reset_password_toggle_new_password_button'),
            obscured: state.obscureNewPassword,
            onPressed: _controller.toggleObscureNewPassword,
          ),
          enabled: !state.isSubmitting,
          textInputAction: TextInputAction.next,
        ),
        if (state.showErrors && state.newPasswordError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: AuthFieldError(
              key: const Key('reset_password_new_password_error'),
              message: state.newPasswordError!,
            ),
          ),
        const SizedBox(height: 16),
        Text(
          'Xác nhận mật khẩu mới',
          style: AuthFonts.sans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AuthPalette.ink,
          ),
        ),
        const SizedBox(height: 6),
        AuthTextField(
          key: const Key('reset_password_confirm_password_field'),
          controller: _controller.confirmPasswordController,
          hintText: 'Nhập lại mật khẩu mới',
          prefixIcon: Icons.lock_outline,
          obscureText: state.obscureConfirmPassword,
          height: 54,
          radius: 14,
          status: state.showErrors && state.confirmPasswordError != null
              ? AuthFieldStatus.error
              : AuthFieldStatus.normal,
          suffix: PasswordVisibilityButton(
            key: const Key('reset_password_toggle_confirm_password_button'),
            obscured: state.obscureConfirmPassword,
            onPressed: _controller.toggleObscureConfirmPassword,
          ),
          enabled: !state.isSubmitting,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _onSubmit(),
        ),
        if (state.showErrors && state.confirmPasswordError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: AuthFieldError(
              key: const Key('reset_password_confirm_password_error'),
              message: state.confirmPasswordError!,
            ),
          ),
        const SizedBox(height: 12),
        Text(
          '• Mật khẩu cần tối thiểu 8 ký tự, bao gồm ít nhất 1 chữ hoa, 1 chữ thường và 1 số.',
          style: AuthFonts.sans(
            fontSize: 12,
            height: 1.4,
            color: AuthPalette.muted,
          ),
        ),
        if (state.generalError != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: AuthFieldError(
              key: const Key('reset_password_general_error'),
              message: state.generalError!,
            ),
          ),
        const SizedBox(height: 28),
        AuthPrimaryButton(
          key: const Key('reset_password_submit_button'),
          label: 'Cập nhật mật khẩu',
          isLoading: state.isSubmitting,
          onPressed: state.isSubmitting ? null : _onSubmit,
        ),
      ],
    );
  }
}
