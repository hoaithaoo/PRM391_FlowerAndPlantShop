import 'dart:async';

import 'package:flutter/material.dart';

import '../auth_routes.dart';
import '../data/auth_scope.dart';
import '../models/auth_models.dart';
import '../state/register_controller.dart';
import '../state/register_state.dart';
import '../utils/auth_theme.dart';
import '../widgets/auth_common.dart';
import '../widgets/register_widgets.dart';

/// Màn đăng ký: layout thường (Màn 3) và layout lỗi (Màn 4) dùng chung form.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late final RegisterController _controller;
  late final StreamSubscription<bool> _signedInSubscription;
  final ScrollController _scrollController = ScrollController();
  final Map<RegisterField, FocusNode> _focusNodes = {
    for (final field in RegisterField.values)
      field: FocusNode(debugLabel: 'register_${field.keyName}'),
  };

  bool _wasErrorLayout = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    final repository = AuthScope.of(context);
    _controller = RegisterController(repository: repository)
      ..addListener(_keepFocusAcrossLayouts);
    // Phiên đăng nhập Google quay về qua stream này
    _signedInSubscription = repository.signedInChanges.listen((signedIn) {
      if (signedIn) _complete();
    });
  }

  @override
  void dispose() {
    _signedInSubscription.cancel();
    _controller
      ..removeListener(_keepFocusAcrossLayouts)
      ..dispose();
    _scrollController.dispose();
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  // Đổi layout làm dựng lại ô nhập nên trả focus về ô đang gõ dở
  void _keepFocusAcrossLayouts() {
    final isErrorLayout = _controller.state.showErrorLayout;
    if (isErrorLayout == _wasErrorLayout) return;
    _wasErrorLayout = isErrorLayout;
    for (final node in _focusNodes.values) {
      if (!node.hasFocus) continue;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) node.requestFocus();
      });
      break;
    }
  }

  void _complete() {
    if (!mounted || _completed) return;
    _completed = true;
    AuthRoutes.completeAuth(context);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final result = await _controller.submit();
    if (!mounted) return;
    switch (result.outcome) {
      case RegisterOutcome.busy:
        break;
      case RegisterOutcome.invalid:
        _scrollToTop();
      case RegisterOutcome.needsEmailVerification:
        AuthRoutes.openOtp(
          context,
          OtpArgs(email: result.email!, purpose: OtpPurpose.signup),
        );
      case RegisterOutcome.signedIn:
        _complete();
      case RegisterOutcome.failed:
        showAuthError(context, result.message!);
    }
  }

  Future<void> _signInWithGoogle() async {
    final message = await _controller.signInWithGoogle();
    if (!mounted || message == null) return;
    showAuthError(context, message);
  }

  void _goBack() => Navigator.of(context).maybePop();

  // Route trước là màn đăng nhập thì quay lại, nếu không thì thay bằng màn đăng nhập
  void _goToLogin() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacementNamed(AuthRoutes.login);
    }
  }

  void _showSupport() {
    _showMessage('Hỗ trợ riêng cho thành viên Privé: 1800 6868 (8:00 - 21:00)');
  }

  void _showTermsPlaceholder() => _showMessage('Đang cập nhật');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AuthPalette.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final state = _controller.state;
            final isErrorLayout = state.showErrorLayout;
            return Column(
              children: [
                if (isErrorLayout)
                  RegisterErrorHeader(onBack: _goBack, onHelp: _showSupport),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: isErrorLayout
                        ? _buildErrorLayout(state)
                        : _buildNormalLayout(state),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNormalLayout(RegisterState state) {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RegisterHeader(onBack: _goBack),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: RegisterBanner(),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 9, 20, 12),
            child: RegisterGreeting(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final field in RegisterField.values) ...[
                  RegisterFormField(
                    field: field,
                    textController: _controller.textOf(field),
                    focusNode: _focusNodes[field]!,
                    obscureText: _obscureOf(state, field),
                    onToggleObscure: _toggleOf(field),
                    isLast: field == RegisterField.confirmPassword,
                  ),
                  const SizedBox(height: 12),
                ],
                RegisterAgreementRow(
                  checked: state.agreed,
                  onToggle: _controller.toggleAgreement,
                  onOpenLink: _showTermsPlaceholder,
                ),
                const SizedBox(height: 8),
                AuthPrimaryButton(
                  key: const Key('register_submit_button'),
                  label: 'Đăng ký tài khoản',
                  trailingIcon: Icons.arrow_forward,
                  isLoading: state.isSubmitting,
                  onPressed: _submit,
                ),
                const SizedBox(height: 32),
                RegisterSocialSection(
                  onGoogle: state.isBusy ? null : _signInWithGoogle,
                  isLoading: state.isGoogleLoading,
                ),
                const SizedBox(height: 14),
                RegisterLoginLink(onPressed: _goToLogin),
                const SizedBox(height: 14),
                const RegisterPerkCard(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorLayout(RegisterState state) {
    final errors = state.errors;
    return AutofillGroup(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const RegisterErrorIntro(),
            const SizedBox(height: 24),
            RegisterErrorSummary(count: errors.count),
            const SizedBox(height: 24),
            for (final field in RegisterField.values) ...[
              RegisterErrorField(
                field: field,
                textController: _controller.textOf(field),
                focusNode: _focusNodes[field]!,
                error: errors.of(field),
                password: state.password,
                obscureText: _obscureOf(state, field),
                onToggleObscure: _toggleOf(field),
                isLast: field == RegisterField.confirmPassword,
              ),
              const SizedBox(height: 24),
            ],
            RegisterAgreementRow(
              checked: state.agreed,
              onToggle: _controller.toggleAgreement,
              onOpenLink: _showTermsPlaceholder,
              errorLayout: true,
              errorMessage: errors.agreement,
            ),
            const SizedBox(height: 32),
            AuthPrimaryButton(
              key: const Key('register_submit_button'),
              label: 'Đăng ký tài khoản',
              trailingIcon: Icons.arrow_forward,
              radius: 16,
              isLoading: state.isSubmitting,
              onPressed: _submit,
            ),
            const SizedBox(height: 16),
            RegisterLoginLink(onPressed: _goToLogin),
            const SizedBox(height: 24),
            const RegisterSupportCard(),
          ],
        ),
      ),
    );
  }

  bool _obscureOf(RegisterState state, RegisterField field) {
    return switch (field) {
      RegisterField.password => state.obscurePassword,
      RegisterField.confirmPassword => state.obscureConfirmPassword,
      _ => false,
    };
  }

  VoidCallback? _toggleOf(RegisterField field) {
    return switch (field) {
      RegisterField.password => _controller.toggleObscurePassword,
      RegisterField.confirmPassword => _controller.toggleObscureConfirmPassword,
      _ => null,
    };
  }
}
