import 'package:flutter/material.dart';

import '../auth_routes.dart';
import '../data/auth_scope.dart';
import '../models/auth_models.dart';
import '../state/otp_controller.dart';
import '../state/otp_state.dart';
import '../utils/auth_theme.dart';
import '../utils/auth_validators.dart';
import '../widgets/auth_common.dart';
import '../widgets/otp_widgets.dart';

/// Màn nhập mã OTP 6 số gửi về email (đăng nhập OTP hoặc xác thực đăng ký).
class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.purpose,
  });

  final String email;
  final OtpPurpose purpose;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  late final OtpController _controller;
  final _inputController = TextEditingController();
  final _focusNode = FocusNode();
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _controller = OtpController(
      repository: AuthScope.of(context),
      email: widget.email,
      purpose: widget.purpose,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }

  Future<void> _onConfirm() async {
    if (!_controller.state.canSubmit) return;
    final result = await _controller.verify();
    if (!mounted) return;
    switch (result.status) {
      case OtpResultStatus.success:
        if (_completed) return;
        _completed = true;
        ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
        AuthRoutes.completeAuth(context);
      case OtpResultStatus.failure:
        // Sai mã: xóa các ô và đưa con trỏ về ô đầu
        _inputController.clear();
        _focusNode.requestFocus();
        showAuthError(context, result.message!);
      case OtpResultStatus.invalid:
        showAuthError(context, result.message!);
      case OtpResultStatus.ignored:
        break;
    }
  }

  Future<void> _onResend() async {
    final result = await _controller.resend();
    if (!mounted) return;
    switch (result.status) {
      case OtpResultStatus.success:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Đã gửi lại mã xác thực.')),
          );
      case OtpResultStatus.failure:
        showAuthError(context, result.message!);
      case OtpResultStatus.invalid:
      case OtpResultStatus.ignored:
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
            OtpHeader(onBack: _onBack),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const OtpBanner(),
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
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: OtpEmailChip(
                  maskedEmail: AuthValidators.maskEmail(widget.email),
                  onEdit: _onBack,
                ),
              ),
              const SizedBox(height: 24),
              _buildCodeInput(state),
              const SizedBox(height: 24),
              _buildResend(state),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: AuthPrimaryButton(
                  key: const Key('otp_confirm_button'),
                  label: 'Xác nhận',
                  trailingIcon: Icons.arrow_forward,
                  color: AuthPalette.forestButton,
                  height: 54,
                  radius: 16,
                  shadows: AuthPalette.softShadow,
                  isLoading: state.isVerifying,
                  onPressed: state.isComplete ? _onConfirm : null,
                ),
              ),
              const SizedBox(height: 24),
              const OtpSecurityNote(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Xác thực Email',
          style: AuthFonts.serif(
            fontSize: 22,
            height: 30 / 22,
            letterSpacing: -0.55,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Chúng tôi đã gửi mã xác thực gồm 6 chữ số đến email của bạn.',
          style: AuthFonts.sans(
            fontSize: 14,
            color: AuthPalette.muted,
            height: 22 / 14,
          ),
        ),
      ],
    );
  }

  Widget _buildCodeInput(OtpState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MÃ OTP (6 CHỮ SỐ)',
          style: AuthFonts.sans(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AuthPalette.muted,
            height: 16 / 11,
            letterSpacing: 0.55,
          ),
        ),
        const SizedBox(height: 8),
        OtpDigitInput(
          code: state.code,
          textController: _inputController,
          focusNode: _focusNode,
          hasError: state.hasError,
          onChanged: _controller.setCode,
          onSubmitted: _onConfirm,
        ),
      ],
    );
  }

  Widget _buildResend(OtpState state) {
    final mutedStyle = AuthFonts.sans(
      fontSize: 14,
      color: AuthPalette.muted,
      height: 22 / 14,
    );
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          Text('Bạn chưa nhận được mã?', style: mutedStyle),
          const SizedBox(height: 4),
          if (state.canResend || state.isResending)
            TextButton(
              key: const Key('otp_resend_button'),
              onPressed: state.isResending ? null : _onResend,
              style: TextButton.styleFrom(
                foregroundColor: AuthPalette.forest,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: state.isResending
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AuthPalette.forest,
                      ),
                    )
                  : Text(
                      'Gửi lại mã',
                      style: AuthFonts.sans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AuthPalette.forest,
                        height: 22 / 14,
                      ),
                    ),
            )
          else
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                const Icon(Icons.schedule, size: 13, color: AuthPalette.muted),
                Text('Gửi lại mã sau', style: mutedStyle),
                Text(
                  state.countdownLabel,
                  key: const Key('otp_countdown'),
                  style: mutedStyle.copyWith(color: AuthPalette.forest),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
