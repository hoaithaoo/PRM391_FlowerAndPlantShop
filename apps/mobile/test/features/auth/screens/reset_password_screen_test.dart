import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/auth/auth.dart';

import '../support/auth_test_harness.dart';

Future<GlobalKey<NavigatorState>> openResetPassword(
  WidgetTester tester,
  FakeAuthRepository repo,
) async {
  final nav = await pumpAuthApp(
    tester,
    repo,
    home: const ResetPasswordScreen(),
  );
  return nav;
}

void main() {
  group('ResetPasswordScreen', () {
    authTestWidgets('hiển thị đầy đủ tiêu đề và các ô nhập mật khẩu mới', (
      tester,
      repo,
    ) async {
      await openResetPassword(tester, repo);

      expect(find.text('Tạo mật khẩu mới'), findsOneWidget);
      expect(find.text('Đặt lại mật khẩu'), findsOneWidget);
      expect(byKey('reset_password_new_password_field'), findsOneWidget);
      expect(byKey('reset_password_confirm_password_field'), findsOneWidget);
      expect(byKey('reset_password_submit_button'), findsOneWidget);
    });

    authTestWidgets('báo lỗi khi bấm cập nhật với dữ liệu không hợp lệ', (
      tester,
      repo,
    ) async {
      await openResetPassword(tester, repo);

      await enterIn(tester, 'reset_password_new_password_field', 'weak');
      await enterIn(tester, 'reset_password_confirm_password_field', 'not_match');
      await tapKey(tester, 'reset_password_submit_button');
      await settle(tester);

      expect(
        find.textContaining('Mật khẩu phải tối thiểu 8 ký tự'),
        findsOneWidget,
      );
      expect(
        find.text('Mật khẩu xác nhận không khớp với mật khẩu đã nhập.'),
        findsOneWidget,
      );
      expect(repo.calls, isEmpty);
    });

    authTestWidgets('toggle ẩn hiện mật khẩu', (tester, repo) async {
      await openResetPassword(tester, repo);

      await tapKey(tester, 'reset_password_toggle_new_password_button');
      await tester.pump();
      await tapKey(tester, 'reset_password_toggle_confirm_password_button');
      await tester.pump();
    });

    authTestWidgets('nhập mật khẩu hợp lệ: gọi updatePassword và thông báo thành công', (
      tester,
      repo,
    ) async {
      await openResetPassword(tester, repo);

      await enterIn(tester, 'reset_password_new_password_field', 'Hoa@12345');
      await enterIn(tester, 'reset_password_confirm_password_field', 'Hoa@12345');
      await tapKey(tester, 'reset_password_submit_button');
      await settle(tester);

      expect(repo.calls, ['updatePassword']);
      expect(repo.lastNewPassword, 'Hoa@12345');
      expect(
        find.text('Đổi mật khẩu thành công! Vui lòng đăng nhập bằng mật khẩu mới.'),
        findsOneWidget,
      );
    });

    authTestWidgets('bấm nút back gọi cancelPasswordRecovery', (tester, repo) async {
      await openResetPassword(tester, repo);

      await tapKey(tester, 'reset_password_back_button');
      await settle(tester);

      expect(repo.calls, ['cancelPasswordRecovery']);
    });
  });
}

