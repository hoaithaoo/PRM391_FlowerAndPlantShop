import 'package:flutter/material.dart';

import 'screens/complete_profile_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/reset_password_screen.dart';

/// Tên route và điều hướng dùng chung cho luồng auth.
///
/// Màn gốc của app là `AuthSessionGate`: chưa đăng nhập hiện [LoginScreen],
/// có phiên đăng nhập thì hiện màn chính. Các route dưới đây được đẩy lên trên.
abstract final class AuthRoutes {
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const forgotPassword = '/auth/forgot-password';
  static const completeProfile = '/auth/complete-profile';
  static const resetPassword = '/auth/reset-password';

  /// Arguments: `String` email vừa đăng ký.
  static const verifyEmail = '/auth/verify-email';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final Widget? page = switch (settings.name) {
      login => const LoginScreen(),
      register => const RegisterScreen(),
      forgotPassword => const ForgotPasswordScreen(),
      completeProfile => const CompleteProfileScreen(),
      resetPassword => const ResetPasswordScreen(),
      verifyEmail => switch (settings.arguments) {
        final String email => EmailVerificationScreen(email: email),
        _ => null,
      },
      _ => null,
    };
    if (page == null) return null;
    return MaterialPageRoute<void>(builder: (_) => page, settings: settings);
  }

  static Future<void> openVerifyEmail(BuildContext context, String email) {
    return Navigator.of(context).pushNamed(verifyEmail, arguments: email);
  }

  static Future<void> openForgotPassword(BuildContext context) {
    return Navigator.of(context).pushNamed(forgotPassword);
  }

  static Future<void> openResetPassword(BuildContext context) {
    return Navigator.of(context).pushNamed(resetPassword);
  }

  /// Gọi khi đã có phiên đăng nhập: đóng các màn auth đang đẩy lên trên để lộ
  /// màn gốc (`AuthSessionGate` tự chuyển sang màn chính) và báo thành công.
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
