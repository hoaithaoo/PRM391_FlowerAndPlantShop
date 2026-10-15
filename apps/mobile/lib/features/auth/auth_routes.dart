import 'package:flutter/material.dart';

import 'models/auth_models.dart';
import 'screens/login_gate_screen.dart';
import 'screens/login_screen.dart';
import 'screens/otp_verification_screen.dart';
import 'screens/register_screen.dart';

/// Tên route và điều hướng dùng chung cho luồng auth.
abstract final class AuthRoutes {
  static const gate = '/auth';
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const otp = '/auth/otp';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final Widget? page = switch (settings.name) {
      gate => const LoginGateScreen(),
      login => const LoginScreen(),
      register => const RegisterScreen(),
      otp => switch (settings.arguments) {
        final OtpArgs args => OtpVerificationScreen(
          email: args.email,
          purpose: args.purpose,
        ),
        _ => null,
      },
      _ => null,
    };
    if (page == null) return null;
    return MaterialPageRoute<void>(builder: (_) => page, settings: settings);
  }

  static Future<void> openOtp(BuildContext context, OtpArgs args) {
    return Navigator.of(context).pushNamed(otp, arguments: args);
  }

  /// Gọi khi đã có phiên đăng nhập: đóng toàn bộ luồng auth và báo thành công.
  ///
  /// Khi app có màn chính, thay `popUntil` bằng điều hướng sang trang chủ.
  static void completeAuth(BuildContext context) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    Navigator.of(context).popUntil((route) => route.isFirst);
    messenger?.showSnackBar(
      const SnackBar(
        content: Text('Đăng nhập thành công. Chào mừng bạn đến Fleuré!'),
      ),
    );
  }
}
