import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/auth/auth.dart';

import '../support/auth_test_harness.dart';
import '../support/register_test_helpers.dart';

TextField textFieldOf(WidgetTester tester, String key) =>
    tester.widget<TextField>(
      find.descendant(of: byKey(key), matching: find.byType(TextField)),
    );

void main() {
  group('hiển thị (layout thường)', () {
    authTestWidgets('có đủ nội dung theo thiết kế', (tester, repo) async {
      await openRegister(tester, repo);

      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(find.text('FLEURÉ'), findsOneWidget);
      expect(find.text('FLEURÉ ATELIER'), findsOneWidget);
      expect(find.text('Nghệ thuật hoa tươi thủ công'), findsOneWidget);
      expect(find.text('GIA NHẬP FLEURÉ PRIVÉ'), findsOneWidget);
      expect(find.text('Tạo tài khoản mới'), findsOneWidget);
      for (final label in [
        'HỌ VÀ TÊN ĐẦY ĐỦ',
        'SỐ ĐIỆN THOẠI',
        'EMAIL',
        'ĐỊA CHỈ',
        'MẬT KHẨU',
        'XÁC NHẬN MẬT KHẨU',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      for (final hint in [
        'Ví dụ: Nguyễn Phương Hà',
        '(+84) 912 345 678',
        'email@domain.vn',
        'Nhập địa chỉ nhận hàng',
        'Tối thiểu 8 ký tự an toàn',
        'Nhập lại mật khẩu vừa tạo',
      ]) {
        expect(find.text(hint), findsOneWidget, reason: hint);
      }
      expect(find.text('Đăng ký tài khoản'), findsOneWidget);
      expect(find.text('Hoặc đăng ký nhanh bằng'), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
      expect(find.text('Đăng nhập ngay'), findsOneWidget);
      expect(find.text('Đặc quyền chào đón thành viên'), findsOneWidget);
      expect(
        find.textContaining('giảm 10%', findRichText: true),
        findsOneWidget,
      );
    });

    authTestWidgets(
      'mặc định: chưa tick đồng ý, mật khẩu bị che, chưa có lỗi',
      (tester, repo) async {
        await openRegister(tester, repo);

        expect(isChecked(tester), isFalse);
        expect(
          textFieldOf(tester, 'register_password_field').obscureText,
          isTrue,
        );
        expect(
          textFieldOf(tester, 'register_confirm_password_field').obscureText,
          isTrue,
        );
        expect(byKey('register_error_summary'), findsNothing);
        for (final f in registerFields) {
          expect(byKey('register_error_$f'), findsNothing);
        }
      },
    );

    authTestWidgets('thuộc tính bàn phím từng ô', (tester, repo) async {
      await openRegister(tester, repo);

      final name = textFieldOf(tester, 'register_full_name_field');
      expect(name.textCapitalization, TextCapitalization.words);
      expect(name.textInputAction, TextInputAction.next);
      expect(
        textFieldOf(tester, 'register_phone_field').keyboardType,
        TextInputType.phone,
      );
      expect(
        textFieldOf(tester, 'register_email_field').keyboardType,
        TextInputType.emailAddress,
      );
      expect(
        textFieldOf(tester, 'register_address_field').keyboardType,
        TextInputType.streetAddress,
      );
      expect(
        textFieldOf(tester, 'register_confirm_password_field').textInputAction,
        TextInputAction.done,
      );
    });

    for (final size in [kSmallPhone, kPhone]) {
      final label = '${size.width.toInt()}x${size.height.toInt()}';

      authTestWidgets('không overflow ở $label (cuộn hết trang)', (
        tester,
        repo,
      ) async {
        await openRegister(tester, repo, size: size);
        expect(tester.takeException(), isNull);
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -5000),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('Đặc quyền chào đón thành viên'), findsOneWidget);
      });

      authTestWidgets('không overflow ở $label khi bàn phím mở', (
        tester,
        repo,
      ) async {
        showKeyboard(tester, 300);
        await openRegister(tester, repo, size: size);
        await tapKey(tester, 'register_full_name_field');
        expect(tester.takeException(), isNull);
      });
    }

    authTestWidgets('không overflow khi chữ phóng to 1.3x', (
      tester,
      repo,
    ) async {
      await openRegister(tester, repo, textScale: 1.3);
      expect(tester.takeException(), isNull);
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -5000),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('nhập liệu', () {
    authTestWidgets('nút mắt đổi che/hiện độc lập cho hai ô mật khẩu', (
      tester,
      repo,
    ) async {
      await openRegister(tester, repo);
      await enterIn(tester, 'register_password_field', 'Hoa@12345');

      await tapKey(tester, 'register_password_visibility_button');
      expect(
        textFieldOf(tester, 'register_password_field').obscureText,
        isFalse,
      );
      expect(
        textFieldOf(tester, 'register_confirm_password_field').obscureText,
        isTrue,
      );
      expect(textOf(tester, 'register_password_field'), 'Hoa@12345');

      await tapKey(tester, 'register_confirm_password_visibility_button');
      expect(
        textFieldOf(tester, 'register_confirm_password_field').obscureText,
        isFalse,
      );
      await tapKey(tester, 'register_password_visibility_button');
      expect(
        textFieldOf(tester, 'register_password_field').obscureText,
        isTrue,
      );
    });

    authTestWidgets('nhập liệu ở layout thường chưa hiện lỗi', (
      tester,
      repo,
    ) async {
      await openRegister(tester, repo);
      await fillDesignErrorData(tester);

      expect(byKey('register_error_summary'), findsNothing);
      expect(find.text('FLEURÉ ATELIER'), findsOneWidget);
    });

    authTestWidgets('ô "next" nhảy sang ô kế tiếp', (tester, repo) async {
      await openRegister(tester, repo);
      await tester.tap(byKey('register_full_name_field'));
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();

      final phone = tester.widget<EditableText>(
        find.descendant(
          of: byKey('register_phone_field'),
          matching: find.byType(EditableText),
        ),
      );
      expect(phone.focusNode.hasFocus, isTrue);
    });
  });

  group('điều khoản', () {
    authTestWidgets('bấm ô vuông bật/tắt đồng ý', (tester, repo) async {
      await openRegister(tester, repo);
      await tapAgreement(tester);
      expect(isChecked(tester), isTrue);
      await tapAgreement(tester);
      expect(isChecked(tester), isFalse);
    });

    authTestWidgets('bấm vào chữ của dòng cũng bật/tắt (không phải link)', (
      tester,
      repo,
    ) async {
      await openRegister(tester, repo);
      await tester.ensureVisible(byKey('register_agreement_checkbox'));
      await tester.pump();
      await tester.tapOnText(find.textRange.ofSubstring('Tôi đồng ý với'));
      await tester.pump();
      expect(isChecked(tester), isTrue);
    });

    authTestWidgets(
      'bấm link Điều khoản/Chính sách: SnackBar "Đang cập nhật"',
      (tester, repo) async {
        await openRegister(tester, repo);
        await tester.ensureVisible(byKey('register_agreement_checkbox'));
        await tester.pump();

        await tester.tapOnText(
          find.textRange.ofSubstring('Điều khoản dịch vụ'),
        );
        await tester.pump();
        expect(snackText('Đang cập nhật'), findsOneWidget);
        expect(isChecked(tester), isFalse);

        await tester.tapOnText(
          find.textRange.ofSubstring('Chính sách bảo mật'),
        );
        await tester.pump();
        expect(snackText('Đang cập nhật'), findsOneWidget);
        expect(isChecked(tester), isFalse);
      },
    );
  });

  group('đăng ký thành công', () {
    authTestWidgets('gọi signUp với dữ liệu đã trim rồi mở màn OTP (signup)', (
      tester,
      repo,
    ) async {
      await openRegister(tester, repo);
      await fillRegister(
        tester,
        name: '  Nguyễn Phương Hà ',
        phone: ' 0912345678 ',
        email: ' phuongha@gmail.com ',
        address: ' $validAddress ',
      );
      await tapAgreement(tester);
      await tapKey(tester, 'register_submit_button');
      await settle(tester);

      expect(repo.calls, ['signUp']);
      final request = repo.lastSignUp!;
      expect(request.fullName, 'Nguyễn Phương Hà');
      expect(request.phone, '0912345678');
      expect(request.email, 'phuongha@gmail.com');
      expect(request.address, validAddress);
      expect(request.password, 'Hoa@12345');

      final otp = tester.widget<OtpVerificationScreen>(
        find.byType(OtpVerificationScreen),
      );
      expect(otp.email, 'phuongha@gmail.com');
      expect(otp.purpose, OtpPurpose.signup);
      expect(find.text('ph***@gmail.com'), findsOneWidget);
    });

    authTestWidgets('xác thực OTP xong đóng cả luồng, chỉ một SnackBar chào', (
      tester,
      repo,
    ) async {
      await openRegister(tester, repo);
      await fillRegister(tester);
      await tapAgreement(tester);
      await tapKey(tester, 'register_submit_button');
      await settle(tester);

      await tester.enterText(byKey('otp_input'), '123456');
      await tester.pump();
      await tester.tap(byKey('otp_confirm_button'));
      await settle(tester);

      expect(repo.lastPurpose, OtpPurpose.signup);
      expect(find.byType(RegisterScreen), findsNothing);
      expect(find.byType(OtpVerificationScreen), findsNothing);
      expect(find.text(kHomeText), findsOneWidget);
      expect(find.text(kLoginSuccessText), findsOneWidget);
    });

    authTestWidgets('signUp trả signedIn thì hoàn tất đăng nhập luôn', (
      tester,
      repo,
    ) async {
      repo.forcedSignUpResult = SignUpResult.signedIn;
      await openRegister(tester, repo);
      await fillRegister(tester);
      await tapAgreement(tester);
      await tapKey(tester, 'register_submit_button');
      await settle(tester);

      expect(find.byType(OtpVerificationScreen), findsNothing);
      expect(find.byType(RegisterScreen), findsNothing);
      expect(find.text(kHomeText), findsOneWidget);
      expect(find.text(kLoginSuccessText), findsOneWidget);
    });

    authTestWidgets('email đã tồn tại: SnackBar lỗi, ở lại form, giữ dữ liệu', (
      tester,
      repo,
    ) async {
      await openRegister(tester, repo);
      await fillRegister(tester, email: MockAuthRepository.existingEmail);
      await tapAgreement(tester);
      await tapKey(tester, 'register_submit_button');
      await settle(tester);

      expect(
        snackText('Email này đã được đăng ký. Vui lòng đăng nhập.'),
        findsOneWidget,
      );
      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(find.byType(OtpVerificationScreen), findsNothing);
      expect(byKey('register_error_summary'), findsNothing);
      expect(textOf(tester, 'register_email_field'), 'existing@fleure.vn');
      expect(textOf(tester, 'register_full_name_field'), 'Nguyễn Phương Hà');
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    authTestWidgets('đang gửi: spinner, chặn bấm đôi, khoá nút Google', (
      tester,
      repo,
    ) async {
      final blocker = repo.block('signUp');
      await openRegister(tester, repo);
      await fillRegister(tester);
      await tapAgreement(tester);
      await tapKey(tester, 'register_submit_button');

      expect(
        find.descendant(
          of: byKey('register_submit_button'),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      await tester.tap(byKey('register_submit_button'));
      await tester.pump();
      await tester.ensureVisible(byKey('register_google_button'));
      await tester.pump();
      await tester.tap(byKey('register_google_button'));
      await tester.pump();
      expect(repo.calls, ['signUp']);

      blocker.complete();
      await settle(tester);
      expect(repo.calls, ['signUp']);
      expect(find.byType(OtpVerificationScreen), findsOneWidget);
    });

    authTestWidgets('mất mạng khi đăng ký: câu lỗi mạng', (tester, repo) async {
      repo.failWith('signUp', AuthFailure.network);
      await openRegister(tester, repo);
      await fillRegister(tester);
      await tapAgreement(tester);
      await tapKey(tester, 'register_submit_button');
      await settle(tester);

      expect(snackText(AuthFailure.network.message), findsOneWidget);
    });

    // Repository ném lỗi không phải AuthFailure (vd. StateError) vẫn phải hiện
    // câu thông báo chung thay vì bỏ lỗi async ra ngoài.
    authTestWidgets('lỗi không phải AuthFailure vẫn hiện câu chung', (
      tester,
      repo,
    ) async {
      repo.failWith('signUp', StateError('boom'));
      await openRegister(tester, repo);
      await fillRegister(tester);
      await tapAgreement(tester);
      await tapKey(tester, 'register_submit_button');
      await settle(tester);

      expect(
        snackText('Đã có lỗi xảy ra. Vui lòng thử lại sau.'),
        findsOneWidget,
      );
    });

    authTestWidgets('rời màn khi đang gửi rồi hoàn tất: không crash', (
      tester,
      repo,
    ) async {
      final blocker = repo.block('signUp');
      await openRegister(tester, repo);
      await fillRegister(tester);
      await tapAgreement(tester);
      await tapKey(tester, 'register_submit_button');

      await unmountApp(tester);
      blocker.complete();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });
  });

  group('Google', () {
    authTestWidgets('thành công: hoàn tất đăng nhập', (tester, repo) async {
      await openRegister(tester, repo);
      await tapKey(tester, 'register_google_button');
      await settle(tester);

      expect(repo.count('signInWithGoogle'), 1);
      expect(find.byType(RegisterScreen), findsNothing);
      expect(find.text(kLoginSuccessText), findsOneWidget);
    });

    authTestWidgets('đang mở trình duyệt: spinner và chặn bấm đôi', (
      tester,
      repo,
    ) async {
      final blocker = repo.block('signInWithGoogle');
      await openRegister(tester, repo);
      await tapKey(tester, 'register_google_button');
      expect(
        find.descendant(
          of: byKey('register_google_button'),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      await tester.tap(byKey('register_google_button'));
      await tester.tap(byKey('register_submit_button'), warnIfMissed: false);
      await tester.pump();
      expect(repo.calls, ['signInWithGoogle']);
      blocker.complete();
      await settle(tester);
    });

    authTestWidgets('lỗi: SnackBar; huỷ: im lặng', (tester, repo) async {
      repo.failWith(
        'signInWithGoogle',
        const AuthFailure(AuthFailureCode.network, 'Mất mạng.'),
      );
      await openRegister(tester, repo);
      await tapKey(tester, 'register_google_button');
      await settle(tester);
      expect(snackText('Mất mạng.'), findsOneWidget);

      ScaffoldMessenger.of(
        tester.element(find.byType(RegisterScreen)),
      ).clearSnackBars();
      await tester.pump();
      repo.failWith(
        'signInWithGoogle',
        const AuthFailure(AuthFailureCode.cancelled, 'Đã huỷ.'),
      );
      await tapKey(tester, 'register_google_button');
      await settle(tester);
      expect(find.byType(SnackBar), findsNothing);
    });

    authTestWidgets('OAuth quay về (signedInChanges=true) hoàn tất đăng nhập', (
      tester,
      repo,
    ) async {
      await openRegister(tester, repo);
      repo.emitSignedIn(true);
      await settle(tester);

      expect(find.byType(RegisterScreen), findsNothing);
      expect(find.text(kLoginSuccessText), findsOneWidget);
    });
  });

  group('điều hướng', () {
    authTestWidgets('nút back pop về màn trước', (tester, repo) async {
      await openRegister(tester, repo);
      await tapKey(tester, 'register_back_button');
      await tester.pumpAndSettle();

      expect(find.byType(RegisterScreen), findsNothing);
      expect(find.text(kHomeText), findsOneWidget);
    });

    authTestWidgets('"Đăng nhập ngay": quay về màn đăng nhập nếu đến từ đó', (
      tester,
      repo,
    ) async {
      final nav = await pumpAuthApp(tester, repo);
      await pushRoute(tester, nav, AuthRoutes.login);
      await tapKey(tester, 'login_register_link');
      await tester.pumpAndSettle();
      expect(find.byType(RegisterScreen), findsOneWidget);

      await tapKey(tester, 'register_login_link');
      await tester.pumpAndSettle();

      expect(find.byType(RegisterScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
      // Chỉ có đúng một màn đăng nhập trong stack
      nav.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.text(kHomeText), findsOneWidget);
    });

    authTestWidgets(
      '"Đăng nhập ngay": thay bằng màn đăng nhập nếu là route đầu',
      (tester, repo) async {
        await pumpAuthApp(tester, repo, home: const RegisterScreen());
        await tapKey(tester, 'register_login_link');
        await tester.pumpAndSettle();

        expect(find.byType(RegisterScreen), findsNothing);
        expect(find.byType(LoginScreen), findsOneWidget);
      },
    );

    authTestWidgets('nút back khi là route đầu không crash', (
      tester,
      repo,
    ) async {
      await pumpAuthApp(tester, repo, home: const RegisterScreen());
      await tapKey(tester, 'register_back_button');
      await tester.pumpAndSettle();

      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
