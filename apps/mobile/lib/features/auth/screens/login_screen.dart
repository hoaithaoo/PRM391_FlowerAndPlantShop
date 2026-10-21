import 'dart:async';

import 'package:flutter/material.dart';

import '../auth_routes.dart';
import '../data/auth_repository.dart';
import '../data/auth_scope.dart';
import '../state/login_controller.dart';
import '../state/login_state.dart';
import '../utils/auth_theme.dart';
import '../widgets/auth_common.dart';
import '../widgets/login_widgets.dart';

/// Màn đăng nhập (màn đầu của app) bằng email + mật khẩu hoặc Google.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthRepository _repository;
  late final LoginController _controller;
  final _passwordFocus = FocusNode();
  StreamSubscription<bool>? _signedInSub;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _repository = AuthScope.of(context);
    _controller = LoginController(repository: _repository);
    // Google OAuth quay về app sẽ báo phiên đăng nhập qua stream này
    _signedInSub = _repository.signedInChanges.listen(_onSignedInChanged);
  }

  @override
  void dispose() {
    _signedInSub?.cancel();
    _passwordFocus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onSignedInChanged(bool signedIn) {
    // Bỏ qua khi màn khác (vd Đăng ký) đang nằm trên; AuthSessionGate tự chuyển màn
    if (!signedIn || !mounted) return;
    if (ModalRoute.of(context)?.isCurrent == false) return;
    _complete();
  }

  void _complete() {
    if (_completed || !mounted) return;
    _completed = true;
    // Xóa thông báo cũ (vd lỗi sai mật khẩu) để lời chào hiện ngay
    ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
    AuthRoutes.completeAuth(context);
  }

  Future<void> _onSubmit() async {
    final result = await _controller.submit();
    if (!mounted) return;
    switch (result.status) {
      case LoginResultStatus.success:
        _complete();
      case LoginResultStatus.failure:
        showAuthError(context, result.message!);
      case LoginResultStatus.invalid:
      case LoginResultStatus.ignored:
        break;
    }
  }

  Future<void> _onGoogle() async {
    final result = await _controller.signInWithGoogle();
    if (!mounted) return;
    if (result.status == LoginResultStatus.failure) {
      showAuthError(context, result.message!);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Màn này là màn gốc nên không có route bên dưới để quay về; app chưa có
  /// trang chủ nên luôn báo đang phát triển (không pop để tránh thoát app).
  void _onExplore() => _showMessage('Trang chủ đang được phát triển.');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthPalette.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 1, 20, 12),
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => _buildContent(_controller.state),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(LoginState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const LoginTopBar(),
        Text(
          'Chào mừng bạn',
          style: AuthTextStyles.heading1.copyWith(color: AuthPalette.ink),
        ),
        const SizedBox(height: 8),
        Text(
          'Đăng nhập để tiếp tục mua sắm tại Fleuré.',
          style: AuthTextStyles.body,
        ),
        const SizedBox(height: 28),
        AutofillGroup(child: _buildForm(state)),
        const SizedBox(height: 24),
        AuthLabeledDivider(
          label: 'HOẶC',
          labelStyle: AuthFonts.sans(
            fontSize: 12,
            color: AuthPalette.muted,
            height: 1.5,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 24),
        AuthGoogleButton(
          key: const Key('login_google_button'),
          label: 'Đăng nhập với Google',
          height: 54,
          radius: 16,
          isLoading: state.isGoogleLoading,
          onPressed: state.isBusy ? null : _onGoogle,
        ),
        const SizedBox(height: 24),
        _buildExploreLink(),
        const SizedBox(height: 8),
        _buildRegisterRow(),
        const Padding(padding: EdgeInsets.only(top: 19), child: _LoginTerms()),
      ],
    );
  }

  Widget _buildForm(LoginState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const LoginFieldLabel('Số điện thoại hoặc Email'),
        const SizedBox(height: 6),
        AuthTextField(
          key: const Key('login_identifier_field'),
          controller: _controller.identifierController,
          hintText: 'Nhập số điện thoại hoặc email của bạn',
          prefixIcon: Icons.alternate_email,
          height: 54,
          radius: 14,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18),
          status: state.identifierError == null
              ? AuthFieldStatus.normal
              : AuthFieldStatus.error,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email, AutofillHints.username],
          enabled: !state.isSubmitting,
          onChanged: _controller.onIdentifierChanged,
          onSubmitted: (_) => _passwordFocus.requestFocus(),
        ),
        if (state.identifierError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: AuthFieldError(
              key: const Key('login_identifier_error'),
              message: state.identifierError!,
            ),
          ),
        const SizedBox(height: 16),
        const LoginFieldLabel('Mật khẩu'),
        const SizedBox(height: 6),
        AuthTextField(
          key: const Key('login_password_field'),
          controller: _controller.passwordController,
          focusNode: _passwordFocus,
          hintText: 'Nhập mật khẩu của bạn',
          prefixIcon: Icons.lock_outline,
          height: 54,
          radius: 14,
          contentPadding: const EdgeInsets.fromLTRB(18, 0, 12, 0),
          status: state.passwordError == null
              ? AuthFieldStatus.normal
              : AuthFieldStatus.error,
          obscureText: state.obscurePassword,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          enabled: !state.isSubmitting,
          onChanged: _controller.onPasswordChanged,
          onSubmitted: (_) => _onSubmit(),
          suffix: KeyedSubtree(
            key: const Key('login_password_toggle'),
            child: PasswordVisibilityButton(
              obscured: state.obscurePassword,
              onPressed: _controller.togglePasswordVisibility,
            ),
          ),
        ),
        if (state.passwordError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: AuthFieldError(
              key: const Key('login_password_error'),
              message: state.passwordError!,
            ),
          ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: LoginTextLink(
            key: const Key('login_forgot_password_link'),
            label: 'Quên mật khẩu?',
            style: AuthFonts.sans(fontSize: 12, color: AuthPalette.muted),
            onPressed: () =>
                _showMessage('Tính năng đặt lại mật khẩu sẽ sớm ra mắt.'),
          ),
        ),
        const SizedBox(height: 8),
        AuthPrimaryButton(
          key: const Key('login_submit_button'),
          label: 'Đăng nhập',
          trailingIcon: Icons.arrow_forward,
          color: AuthPalette.forestButton,
          height: 54,
          radius: 16,
          shadows: AuthPalette.softShadow,
          isLoading: state.isSubmitting,
          onPressed: state.isBusy ? null : _onSubmit,
        ),
      ],
    );
  }

  Widget _buildExploreLink() {
    return Center(
      child: InkWell(
        key: const Key('login_explore_link'),
        onTap: _onExplore,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  'Khám phá cửa hàng mà không cần đăng nhập',
                  textAlign: TextAlign.center,
                  style: AuthFonts.sans(
                    fontSize: 14,
                    color: AuthPalette.muted,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                size: 14,
                color: AuthPalette.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterRow() {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Chưa có tài khoản?',
            style: AuthFonts.sans(
              fontSize: 14,
              color: AuthPalette.muted,
              height: 1.5,
            ),
          ),
          InkWell(
            key: const Key('login_register_link'),
            onTap: () => Navigator.of(context).pushNamed(AuthRoutes.register),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Text(
                'Đăng ký ngay',
                style: AuthFonts.sans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AuthPalette.forest,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dòng điều khoản ở đáy màn.
class _LoginTerms extends StatelessWidget {
  const _LoginTerms();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Bằng việc tiếp tục, bạn đồng ý với các điều khoản dịch vụ và chính sách '
      'chăm sóc hoa của Fleuré.',
      textAlign: TextAlign.center,
      style: AuthFonts.sans(
        fontSize: 12,
        color: AuthPalette.muted.withValues(alpha: 0.7),
        height: 1.625,
      ),
    );
  }
}
