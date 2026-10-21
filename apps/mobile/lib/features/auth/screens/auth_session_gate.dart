import 'package:flutter/material.dart';

import '../data/auth_scope.dart';
import '../utils/auth_theme.dart';
import 'login_screen.dart';

/// Màn gốc của app: theo dõi phiên đăng nhập để chọn màn hiển thị.
///
/// - Chưa đăng nhập: [LoginScreen] (không còn màn "Đăng nhập để tiếp tục").
/// - Đã đăng nhập (đăng nhập thường, Google, hoặc bấm link xác nhận email
///   quay về app qua deep link): [signedInBuilder], mặc định là màn tạm.
class AuthSessionGate extends StatelessWidget {
  const AuthSessionGate({super.key, this.signedInBuilder});

  /// Màn chính khi đã đăng nhập. Khi app có màn chính thật, truyền vào đây.
  final WidgetBuilder? signedInBuilder;

  @override
  Widget build(BuildContext context) {
    final repository = AuthScope.of(context);
    return StreamBuilder<bool>(
      stream: repository.signedInChanges,
      initialData: repository.isSignedIn,
      builder: (context, snapshot) {
        if (snapshot.data ?? false) {
          return (signedInBuilder ?? (_) => const SignedInPlaceholder())(
            context,
          );
        }
        return const LoginScreen();
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
