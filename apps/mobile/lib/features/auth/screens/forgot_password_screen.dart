import 'dart:async';

import 'package:flutter/material.dart';

import '../auth_routes.dart';
import '../data/auth_scope.dart';
import '../state/forgot_password_controller.dart';
import '../state/forgot_password_state.dart';
import '../utils/auth_theme.dart';
import '../widgets/auth_common.dart';

/// Màn hình Quên mật khẩu: Nhập Gmail -> Nhận email chứa Link đặt lại mật khẩu.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final ForgotPasswordController _controller;
  StreamSubscription<bool>? _recoverySub;

  @override
  void initState() {
    super.initState();
    final repository = AuthScope.of(context);
    _controller = ForgotPasswordController(repository: repository);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _recoverySub?.cancel();
    final repository = AuthScope.of(context);
    _recoverySub = repository.passwordRecoveryChanges.listen((isRecovery) {
      if (isRecovery && mounted) {
        Navigator.of(context).pushReplacementNamed(AuthRoutes.resetPassword);
      }
    });
  }

  @override
  void dispose() {
    _recoverySub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onSendResetLink() async {
    FocusScope.of(context).unfocus();
    final result = await _controller.sendResetLink();
    if (!mounted) return;

    if (result.outcome == ForgotPasswordOutcome.failed) {
      showAuthError(context, result.message ?? 'Không thể gửi email khôi phục.');
    } else if (result.outcome == ForgotPasswordOutcome.linkSent) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Link đặt lại mật khẩu đã được gửi vào hòm thư của bạn.',
            ),
          ),
        );
    }
  }

  Future<void> _onResendResetLink() async {
    final result = await _controller.resendResetLink();
    if (!mounted) return;

    if (result.outcome == ForgotPasswordOutcome.failed) {
      showAuthError(
        context,
        result.message ?? 'Không thể gửi lại email khôi phục.',
      );
    } else if (result.outcome == ForgotPasswordOutcome.resendSuccess) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Đã gửi lại link đặt lại mật khẩu vào hòm thư của bạn.',
            ),
          ),
        );
    }
  }

  void _onBack() {
    Navigator.of(context).maybePop();
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
                    child: state.emailSent
                        ? _buildEmailSentView(state)
                        : _buildEnterEmailView(state),
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
            key: const Key('forgot_password_back_button'),
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            color: AuthPalette.ink,
            onPressed: _onBack,
          ),
          const SizedBox(width: 8),
          Text(
            'Quên mật khẩu',
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

  Widget _buildEnterEmailView(ForgotPasswordState state) {
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
            Icons.lock_reset,
            size: 32,
            color: AuthPalette.forest,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Khôi phục mật khẩu',
          textAlign: TextAlign.center,
          style: AuthTextStyles.heading1.copyWith(color: AuthPalette.ink),
        ),
        const SizedBox(height: 8),
        Text(
          'Nhập địa chỉ email tài khoản của bạn để nhận liên kết khôi phục và đặt lại mật khẩu mới.',
          textAlign: TextAlign.center,
          style: AuthTextStyles.body,
        ),
        const SizedBox(height: 32),
        Text(
          'Địa chỉ Email',
          style: AuthFonts.sans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AuthPalette.ink,
          ),
        ),
        const SizedBox(height: 6),
        AuthTextField(
          key: const Key('forgot_password_email_field'),
          controller: _controller.emailController,
          hintText: 'Nhập email đã đăng ký (ví dụ: name@gmail.com)',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          height: 54,
          radius: 14,
          status: state.showErrors && state.emailError != null
              ? AuthFieldStatus.error
              : AuthFieldStatus.normal,
          enabled: !state.isSubmitting,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _onSendResetLink(),
        ),
        if (state.showErrors && state.emailError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: AuthFieldError(
              key: const Key('forgot_password_email_error'),
              message: state.emailError!,
            ),
          ),
        if (state.generalError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: AuthFieldError(
              key: const Key('forgot_password_general_error'),
              message: state.generalError!,
            ),
          ),
        const SizedBox(height: 28),
        AuthPrimaryButton(
          key: const Key('forgot_password_send_link_button'),
          label: 'Gửi link khôi phục',
          isLoading: state.isSubmitting,
          onPressed: state.isSubmitting ? null : _onSendResetLink,
        ),
      ],
    );
  }

  Widget _buildEmailSentView(ForgotPasswordState state) {
    final isCountingDown = state.remainingCooldown > Duration.zero;

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
            Icons.mark_email_read_outlined,
            size: 32,
            color: AuthPalette.forest,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Kiểm tra hộp thư của bạn',
          textAlign: TextAlign.center,
          style: AuthTextStyles.heading1.copyWith(color: AuthPalette.ink),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AuthPalette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chúng tôi đã gửi link đặt lại mật khẩu đến:',
                style: AuthFonts.sans(
                  fontSize: 13,
                  color: AuthPalette.muted,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      state.email,
                      style: AuthFonts.sans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AuthPalette.forest,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    key: const Key('forgot_password_change_email_button'),
                    onPressed: state.isBusy ? null : _controller.changeEmail,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Đổi email',
                      style: AuthFonts.sans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AuthPalette.muted,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: AuthPalette.divider),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: AuthPalette.forest,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vui lòng nhấp vào liên kết trong email để mở lại ứng dụng Fleuré và nhập mật khẩu mới. Nếu không thấy thư, hãy kiểm tra mục Spam hoặc Thư rác.',
                      style: AuthFonts.sans(
                        fontSize: 13,
                        height: 1.45,
                        color: AuthPalette.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        _buildResendSection(state, isCountingDown),
        const SizedBox(height: 20),
        OutlinedButton(
          key: const Key('forgot_password_back_to_login_button'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: const BorderSide(color: AuthPalette.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: _onBack,
          child: Text(
            'Quay lại đăng nhập',
            style: AuthFonts.sans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AuthPalette.ink,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResendSection(ForgotPasswordState state, bool isCountingDown) {
    return Column(
      children: [
        if (state.generalError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AuthFieldError(
              key: const Key('forgot_password_resend_error'),
              message: state.generalError!,
            ),
          ),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: isCountingDown ? 0.45 : 1.0,
          child: TextButton.icon(
            key: const Key('forgot_password_resend_link_button'),
            onPressed: isCountingDown || state.isBusy ? null : _onResendResetLink,
            icon: state.isResending
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AuthPalette.forest,
                    ),
                  )
                : Icon(
                    Icons.refresh,
                    size: 16,
                    color: isCountingDown ? AuthPalette.muted : AuthPalette.forest,
                  ),
            label: Text(
              isCountingDown
                  ? 'Gửi lại sau ${state.remainingCooldown.inSeconds}s'
                  : 'Chưa nhận được email? Gửi lại link',
              style: AuthFonts.sans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isCountingDown ? AuthPalette.muted : AuthPalette.forest,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
