import 'dart:async';

import 'package:flutter/material.dart';

import '../data/auth_scope.dart';
import '../utils/auth_theme.dart';
import 'complete_profile_screen.dart';
import 'login_screen.dart';
import 'reset_password_screen.dart';

/// Màn gốc của app: theo dõi phiên đăng nhập để chọn màn hiển thị.
///
/// - Đang khôi phục mật khẩu (từ email link): [ResetPasswordScreen].
/// - Chưa đăng nhập: [LoginScreen] (không còn màn "Đăng nhập để tiếp tục").
/// - Đã đăng nhập nhưng chưa hoàn thiện thông tin (Google): [CompleteProfileScreen].
/// - Đã đăng nhập và đủ thông tin: [signedInBuilder], mặc định là màn tạm.
class AuthSessionGate extends StatefulWidget {
  const AuthSessionGate({super.key, this.signedInBuilder});

  /// Màn chính khi đã đăng nhập. Khi app có màn chính thật, truyền vào đây.
  final WidgetBuilder? signedInBuilder;

  @override
  State<AuthSessionGate> createState() => _AuthSessionGateState();
}

class _AuthSessionGateState extends State<AuthSessionGate> {
  StreamSubscription<bool>? _recoverySub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _recoverySub?.cancel();
    final repository = AuthScope.of(context);
    _recoverySub = repository.passwordRecoveryChanges.listen((isRecovery) {
      if (isRecovery && mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  @override
  void dispose() {
    _recoverySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = AuthScope.of(context);
    return StreamBuilder<bool>(
      stream: repository.passwordRecoveryChanges,
      initialData: repository.isInPasswordRecovery,
      builder: (context, recoverySnapshot) {
        final isRecovery = recoverySnapshot.data ?? false;
        if (isRecovery) {
          return const ResetPasswordScreen();
        }

        return StreamBuilder<bool>(
          stream: repository.signedInChanges,
          initialData: repository.isSignedIn,
          builder: (context, snapshot) {
            if (snapshot.data ?? false) {
              if (!repository.isProfileComplete) {
                return const CompleteProfileScreen();
              }
              return (widget.signedInBuilder ?? (_) => const SignedInPlaceholder())(
                context,
              );
            }
            return const LoginScreen();
          },
        );
      },
    );
  }
}

/// Màn tạm sau khi đăng nhập cho tới khi tích hợp màn chính.
class SignedInPlaceholder extends StatelessWidget {
  const SignedInPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = AuthScope.of(context);
    return Scaffold(
      backgroundColor: AuthPalette.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Bạn đã đăng nhập', style: AuthTextStyles.heading1),
                const SizedBox(height: 8),
                Text(
                  'Trang chủ đang được phát triển.',
                  style: AuthTextStyles.body,
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  key: const Key('signed_in_sign_out'),
                  onPressed: repository.signOut,
                  child: const Text('Đăng xuất'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
