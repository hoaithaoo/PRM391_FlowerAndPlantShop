import 'dart:async';

import 'package:flutter/material.dart';

import '../auth_routes.dart';
import '../data/auth_repository.dart';
import '../data/auth_scope.dart';
import '../state/login_gate_controller.dart';
import '../state/login_state.dart';
import '../utils/auth_theme.dart';
import '../widgets/auth_common.dart';
import '../widgets/login_widgets.dart';

/// Màn "Đăng nhập để tiếp tục": khách chạm vào tính năng cần tài khoản.
class LoginGateScreen extends StatefulWidget {
  const LoginGateScreen({super.key});

  @override
  State<LoginGateScreen> createState() => _LoginGateScreenState();
}

class _LoginGateScreenState extends State<LoginGateScreen> {
  late final AuthRepository _repository;
  late final LoginGateController _controller;
  StreamSubscription<bool>? _signedInSub;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _repository = AuthScope.of(context);
    _controller = LoginGateController(repository: _repository);
    // Google OAuth quay về app sẽ báo phiên đăng nhập qua stream này
    _signedInSub = _repository.signedInChanges.listen(_onSignedInChanged);
  }

  @override
  void dispose() {
    _signedInSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSignedInChanged(bool signedIn) {
    // Bỏ qua khi có màn khác (đăng nhập, OTP) đang nằm trên và tự xử lý
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

  Future<void> _onGoogle() async {
    final result = await _controller.signInWithGoogle();
    if (!mounted) return;
    if (result.status == LoginResultStatus.failure) {
      showAuthError(context, result.message!);
    }
  }

  void _dismiss() {
    // Không còn màn trước thì không làm gì
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthPalette.background,
      body: SafeArea(
        child: Column(
          children: [
            GateHeader(onBack: _dismiss),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GateTopRow(onClose: _dismiss),
                    const SizedBox(height: 24),
                    const GateHeroCard(),
                    const SizedBox(height: 24),
                    const _GateTitle(),
                    const SizedBox(height: 24),
                    _buildActions(),
                    const SizedBox(height: 24),
                    const GateSecurityNote(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthGoogleButton(
                key: const Key('gate_google_button'),
                label: 'Tiếp tục với Google',
                isLoading: _controller.isGoogleLoading,
                onPressed: _onGoogle,
              ),
              const SizedBox(height: 8),
              AuthPrimaryButton(
                key: const Key('gate_login_button'),
                label: 'Đăng nhập',
                leadingIcon: Icons.mark_email_read_outlined,
                onPressed: () =>
                    Navigator.of(context).pushNamed(AuthRoutes.login),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  key: const Key('gate_later_button'),
                  onPressed: _dismiss,
                  style: TextButton.styleFrom(
                    foregroundColor: AuthPalette.sage,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'Để sau, tôi muốn tiếp tục xem hoa',
                          style: AuthFonts.sans(
                            fontSize: 14,
                            color: AuthPalette.sage,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward,
                        size: 11,
                        color: AuthPalette.sage,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GateTitle extends StatelessWidget {
  const _GateTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Đăng nhập để tiếp tục',
          textAlign: TextAlign.center,
          style: AuthTextStyles.heading1,
        ),
        const SizedBox(height: 3),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Bạn cần đăng nhập để thêm sản phẩm vào giỏ, hoàn tất đơn hàng và '
            'trò chuyện cùng Trợ lý AI Botanical.',
            textAlign: TextAlign.center,
            style: AuthFonts.sans(
              fontSize: 14,
              color: AuthPalette.sage,
              height: 1.625,
            ),
          ),
        ),
      ],
    );
  }
}
