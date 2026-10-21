import 'dart:async';

import 'package:flutter/material.dart';

import '../auth_routes.dart';
import '../data/auth_scope.dart';
import '../state/email_verification_controller.dart';
import '../state/email_verification_state.dart';
import '../utils/auth_theme.dart';
import '../widgets/auth_common.dart';
import '../widgets/email_verification_widgets.dart';

/// Màn "Kiểm tra email" sau khi đăng ký: người dùng bấm link xác nhận trong
/// email, link mở lại app và phiên đăng nhập đến qua `signedInChanges`.
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key, required this.email});

  final String email;

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  late final EmailVerificationController _controller;
  late final StreamSubscription<bool> _signedInSubscription;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    final repository = AuthScope.of(context);
    _controller = EmailVerificationController(
      repository: repository,
      email: widget.email,
    );
    _signedInSubscription = repository.signedInChanges.listen((signedIn) {
      if (signedIn) _complete();
    });
  }

  @override
  void dispose() {
    _signedInSubscription.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _complete() {
    if (!mounted || _completed) return;
    _completed = true;
    ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
    AuthRoutes.completeAuth(context);
  }

  void _onBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }

  // Màn gốc là Đăng nhập khi chưa có phiên nên quay về màn đầu tiên
  void _onLogin() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _onResend() async {
    final result = await _controller.resend();
    if (!mounted) return;
    switch (result.status) {
      case ResendStatus.success:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Đã gửi lại email xác nhận.')),
          );
      case ResendStatus.failure:
        showAuthError(context, result.message!);
      case ResendStatus.ignored:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthPalette.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            EmailVerificationHeader(onBack: _onBack),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const EmailVerificationBanner(),
                    const SizedBox(height: 16),
                    _buildCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AuthPalette.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AuthPalette.softShadow,
      ),
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final state = _controller.state;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildIntro(),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: EmailVerificationChip(email: widget.email),
              ),
              const SizedBox(height: 16),
              Text(
                'Bấm vào link trong email để hoàn tất đăng ký. '
                'Link sẽ mở lại ứng dụng.',
                style: _bodyStyle,
              ),
              const SizedBox(height: 16),
              const EmailVerificationSpamNote(),
              const SizedBox(height: 24),
              AuthPrimaryButton(
                key: const Key('verify_email_resend_button'),
                label: 'Gửi lại email',
                leadingIcon: Icons.refresh,
                color: AuthPalette.forestButton,
                height: 54,
                radius: 16,
                shadows: AuthPalette.softShadow,
                isLoading: state.isResending,
                onPressed: state.canResend || state.isResending
                    ? _onResend
                    : null,
              ),
              if (state.remaining > Duration.zero) ...[
                const SizedBox(height: 8),
                _buildCooldown(state),
              ],
              const SizedBox(height: 16),
              _buildLinks(),
            ],
          );
        },
      ),
    );
  }

  TextStyle get _bodyStyle =>
      AuthFonts.sans(fontSize: 14, color: AuthPalette.muted, height: 22 / 14);

  Widget _buildIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kiểm tra email của bạn',
          key: const Key('verify_email_title'),
          style: AuthFonts.serif(
            fontSize: 22,
            height: 30 / 22,
            letterSpacing: -0.55,
          ),
        ),
        const SizedBox(height: 4),
        Text('Chúng tôi đã gửi link xác nhận tới', style: _bodyStyle),
      ],
    );
  }

  Widget _buildCooldown(EmailVerificationState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.schedule, size: 13, color: AuthPalette.muted),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'Gửi lại sau ${state.remainingSeconds}s',
            key: const Key('verify_email_cooldown'),
            textAlign: TextAlign.center,
            style: _bodyStyle,
          ),
        ),
      ],
    );
  }

  Widget _buildLinks() {
    final linkStyle = AuthFonts.sans(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AuthPalette.forest,
      height: 22 / 14,
    );
    final buttonStyle = TextButton.styleFrom(
      foregroundColor: AuthPalette.forest,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      minimumSize: const Size(0, 40),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    return Column(
      children: [
        TextButton(
          key: const Key('verify_email_change_email_link'),
          onPressed: _onBack,
          style: buttonStyle,
          child: Text('Dùng email khác', style: linkStyle),
        ),
        TextButton(
          key: const Key('verify_email_login_link'),
          onPressed: _onLogin,
          style: buttonStyle,
          child: Text.rich(
            TextSpan(
              style: _bodyStyle,
              children: [
                const TextSpan(text: 'Đã xác nhận? '),
                TextSpan(text: 'Đăng nhập', style: linkStyle),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
