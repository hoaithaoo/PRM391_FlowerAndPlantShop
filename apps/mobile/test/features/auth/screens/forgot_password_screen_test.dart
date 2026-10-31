import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/auth/auth.dart';

import '../support/auth_test_harness.dart';

Future<GlobalKey<NavigatorState>> openForgotPassword(
  WidgetTester tester,
  FakeAuthRepository repo,
) async {
  final nav = await pumpAuthApp(
    tester,
    repo,
    home: const ForgotPasswordScreen(),
  );
  return nav;
}

void main() {
  group('ForgotPasswordScreen - Nhập Email và gửi Link', () {
    authTestWidgets('hiển thị đầy đủ tiêu đề và ô nhập email', (tester, repo) async {
      await openForgotPassword(tester, repo);

      expect(find.text('Quên mật khẩu'), findsOneWidget);
      expect(find.text('Khôi phục mật khẩu'), findsOneWidget);
      expect(byKey('forgot_password_email_field'), findsOneWidget);
      expect(byKey('forgot_password_send_link_button'), findsOneWidget);
    });

    authTestWidgets('báo lỗi khi bấm gửi mà để trống email', (tester, repo) async {
      await openForgotPassword(tester, repo);

      await tapKey(tester, 'forgot_password_send_link_button');
      await settle(tester);

      expect(find.text('Vui lòng nhập địa chỉ email.'), findsOneWidget);
      expect(repo.calls, isEmpty);
    });

    authTestWidgets('nhập email hợp lệ và gửi: gọi sendPasswordResetEmail, hiện thông báo thành công và countdown', (
      tester,
      repo,
    ) async {
      await openForgotPassword(tester, repo);

      await enterIn(tester, 'forgot_password_email_field', 'user@gmail.com');
      await tapKey(tester, 'forgot_password_send_link_button');
      await settle(tester);

      expect(repo.calls, ['sendPasswordResetEmail']);
      expect(repo.lastEmail, 'user@gmail.com');

      // Chuyển sang màn hình thông báo email đã gửi
      expect(find.text('Kiểm tra hộp thư của bạn'), findsOneWidget);
      expect(find.text('user@gmail.com'), findsOneWidget);
      expect(byKey('forgot_password_change_email_button'), findsOneWidget);
      expect(byKey('forgot_password_resend_link_button'), findsOneWidget);
      expect(find.textContaining('Gửi lại sau'), findsOneWidget);
    });

    authTestWidgets('nút Đổi email quay lại form nhập email', (tester, repo) async {
      await openForgotPassword(tester, repo);

      await enterIn(tester, 'forgot_password_email_field', 'user@gmail.com');
      await tapKey(tester, 'forgot_password_send_link_button');
      await settle(tester);

      await tapKey(tester, 'forgot_password_change_email_button');
      await settle(tester);

      expect(find.text('Khôi phục mật khẩu'), findsOneWidget);
      expect(byKey('forgot_password_email_field'), findsOneWidget);
    });

    authTestWidgets('nút Quay lại đăng nhập hoạt động', (tester, repo) async {
      await openForgotPassword(tester, repo);

      await enterIn(tester, 'forgot_password_email_field', 'user@gmail.com');
      await tapKey(tester, 'forgot_password_send_link_button');
      await settle(tester);

      expect(byKey('forgot_password_back_to_login_button'), findsOneWidget);
      await tapKey(tester, 'forgot_password_back_to_login_button');
      await settle(tester);
    });

    authTestWidgets('tự động chuyển sang ResetPasswordScreen khi nhận tín hiệu passwordRecovery', (
      tester,
      repo,
    ) async {
      await openForgotPassword(tester, repo);

      // Người dùng đang ở màn hình "Kiểm tra hộp thư của bạn"
      await enterIn(tester, 'forgot_password_email_field', 'user@gmail.com');
      await tapKey(tester, 'forgot_password_send_link_button');
      await settle(tester);

      expect(find.text('Kiểm tra hộp thư của bạn'), findsOneWidget);

      // Giả lập người dùng bấm vào link trong email
      repo.simulatePasswordRecovery();
      await settle(tester);

      // Đã tự động điều hướng sang màn hình Tạo mật khẩu mới
      expect(find.text('Tạo mật khẩu mới'), findsOneWidget);
      expect(byKey('reset_password_new_password_field'), findsOneWidget);
    });
  });
}
