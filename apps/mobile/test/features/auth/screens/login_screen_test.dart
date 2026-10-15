import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/auth/auth.dart';
import 'package:plant_flower_mobile/features/auth/widgets/auth_common.dart';

import '../support/auth_test_harness.dart';

const _idField = 'login_identifier_field';
const _pwField = 'login_password_field';
const _idError = 'login_identifier_error';
const _pwError = 'login_password_error';

const _emptyId = 'Vui lòng nhập số điện thoại hoặc email.';
const _emptyPw = 'Vui lòng nhập mật khẩu.';
const _phoneUnsupported =
    'Đăng nhập bằng số điện thoại chưa được hỗ trợ, vui lòng dùng email.';
const _badEmail =
    'Email không đúng định dạng tiêu chuẩn (ví dụ hợp lệ: name@example.com).';

Future<GlobalKey<NavigatorState>> openLogin(
  WidgetTester tester,
  FakeAuthRepository repo, {
  Size size = kSmallPhone,
  double textScale = 1,
}) async {
  final nav = await pumpAuthApp(tester, repo, size: size, textScale: textScale);
  await pushRoute(tester, nav, AuthRoutes.login);
  return nav;
}

AuthFieldStatus statusOf(WidgetTester tester, String key) =>
    tester.widget<AuthTextField>(byKey(key)).status;

void main() {
  group('hiển thị', () {
    authTestWidgets('có đủ nội dung theo thiết kế', (tester, repo) async {
      await openLogin(tester, repo);

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Fleuré'), findsOneWidget);
      expect(find.text('BOTANICAL'), findsOneWidget);
      expect(find.text('Chào mừng bạn'), findsOneWidget);
      expect(
        find.text('Đăng nhập để tiếp tục mua sắm tại Fleuré.'),
        findsOneWidget,
      );
      expect(find.text('Số điện thoại hoặc Email'), findsOneWidget);
      expect(find.text('Đăng nhập OTP'), findsOneWidget);
      expect(find.text('Mật khẩu'), findsOneWidget);
      expect(
        find.text('Nhập số điện thoại hoặc email của bạn'),
        findsOneWidget,
      );
      expect(find.text('Nhập mật khẩu của bạn'), findsOneWidget);
      expect(find.text('Quên mật khẩu?'), findsOneWidget);
      expect(find.text('Đăng nhập'), findsOneWidget);
      expect(find.text('HOẶC'), findsOneWidget);
      expect(find.text('Đăng nhập với Google'), findsOneWidget);
      expect(
        find.text('Khám phá cửa hàng mà không cần đăng nhập'),
        findsOneWidget,
      );
      expect(find.text('Chưa có tài khoản?'), findsOneWidget);
      expect(find.text('Đăng ký ngay'), findsOneWidget);
      expect(
        find.textContaining('Bằng việc tiếp tục, bạn đồng ý với'),
        findsOneWidget,
      );
    });

    authTestWidgets('ban đầu không có lỗi và mật khẩu bị che', (
      tester,
      repo,
    ) async {
      await openLogin(tester, repo);

      expect(byKey(_idError), findsNothing);
      expect(byKey(_pwError), findsNothing);
      expect(statusOf(tester, _idField), AuthFieldStatus.normal);
      expect(statusOf(tester, _pwField), AuthFieldStatus.normal);
      expect(tester.widget<AuthTextField>(byKey(_pwField)).obscureText, isTrue);
    });

    for (final size in [kSmallPhone, kPhone]) {
      final label = '${size.width.toInt()}x${size.height.toInt()}';

      authTestWidgets('không overflow ở $label (kể cả khi có lỗi)', (
        tester,
        repo,
      ) async {
        await openLogin(tester, repo, size: size);
        expect(tester.takeException(), isNull);

        await tapKey(tester, 'login_submit_button');
        await tester.pump();
        expect(byKey(_idError), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -3000),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      });

      authTestWidgets('không overflow ở $label khi bàn phím mở', (
        tester,
        repo,
      ) async {
        showKeyboard(tester, 300);
        await openLogin(tester, repo, size: size);
        await tester.tap(byKey(_idField));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }

    authTestWidgets('không overflow khi chữ phóng to 1.3x', (
      tester,
      repo,
    ) async {
      await openLogin(tester, repo, textScale: 1.3);
      expect(tester.takeException(), isNull);
    });
  });

  group('kiểm tra dữ liệu', () {
    authTestWidgets(
      'bấm Đăng nhập khi để trống: hiện cả hai lỗi, không gọi repo',
      (tester, repo) async {
        await openLogin(tester, repo);
        await tapKey(tester, 'login_submit_button');

        expect(find.text(_emptyId), findsOneWidget);
        expect(find.text(_emptyPw), findsOneWidget);
        expect(statusOf(tester, _idField), AuthFieldStatus.error);
        expect(statusOf(tester, _pwField), AuthFieldStatus.error);
        expect(repo.calls, isEmpty);
      },
    );

    authTestWidgets('gõ trước lần submit đầu thì chưa hiện lỗi', (
      tester,
      repo,
    ) async {
      await openLogin(tester, repo);
      await enterIn(tester, _idField, 'abc');
      await enterIn(tester, _idField, '');
      await enterIn(tester, _pwField, 'x');
      await enterIn(tester, _pwField, '');

      expect(byKey(_idError), findsNothing);
      expect(byKey(_pwError), findsNothing);
    });

    authTestWidgets('sau submit đầu lỗi cập nhật theo thời gian thực', (
      tester,
      repo,
    ) async {
      await openLogin(tester, repo);
      await tapKey(tester, 'login_submit_button');
      expect(find.text(_emptyId), findsOneWidget);

      await enterIn(tester, _idField, 'abc');
      expect(find.text(_badEmail), findsOneWidget);
      expect(find.text(_emptyId), findsNothing);

      await enterIn(tester, _idField, 'name@example.com');
      expect(byKey(_idError), findsNothing);
      expect(statusOf(tester, _idField), AuthFieldStatus.normal);
      // Ô mật khẩu vẫn còn lỗi
      expect(find.text(_emptyPw), findsOneWidget);

      await enterIn(tester, _pwField, 'a');
      expect(byKey(_pwError), findsNothing);
      expect(statusOf(tester, _pwField), AuthFieldStatus.normal);
    });

    authTestWidgets('số điện thoại bị từ chối với câu "chưa được hỗ trợ"', (
      tester,
      repo,
    ) async {
      await openLogin(tester, repo);
      await enterIn(tester, _idField, '0912345678');
      await enterIn(tester, _pwField, 'Hoa@12345');
      await tapKey(tester, 'login_submit_button');

      expect(find.text(_phoneUnsupported), findsOneWidget);
      expect(repo.calls, isEmpty);
    });

    authTestWidgets('email sai định dạng', (tester, repo) async {
      await openLogin(tester, repo);
      await enterIn(tester, _idField, 'name@domain');
      await enterIn(tester, _pwField, 'x');
      await tapKey(tester, 'login_submit_button');

      expect(find.text(_badEmail), findsOneWidget);
      expect(byKey(_pwError), findsNothing);
      expect(repo.calls, isEmpty);
    });

    authTestWidgets('mật khẩu đăng nhập không bị áp quy tắc độ mạnh', (
      tester,
      repo,
    ) async {
      await openLogin(tester, repo);
      await enterIn(tester, _idField, 'name@example.com');
      await enterIn(tester, _pwField, 'a');
      await tapKey(tester, 'login_submit_button');
      await settle(tester);

      expect(repo.count('signInWithPassword'), 1);
    });
  });

  group('đăng nhập bằng mật khẩu', () {
    authTestWidgets('thành công: gọi repo với email đã trim và hoàn tất', (
      tester,
      repo,
    ) async {
      await openLogin(tester, repo);
      await enterIn(tester, _idField, '  name@example.com ');
      await enterIn(tester, _pwField, 'Hoa@12345');
      await tapKey(tester, 'login_submit_button');
      await settle(tester);

      expect(repo.count('signInWithPassword'), 1);
      expect(repo.lastEmail, 'name@example.com');
      expect(repo.lastPassword, 'Hoa@12345');
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.text(kHomeText), findsOneWidget);
      expect(find.text(kLoginSuccessText), findsOneWidget);
    });

    authTestWidgets('sai mật khẩu: SnackBar lỗi, ở lại màn, không đăng nhập', (
      tester,
      repo,
    ) async {
      await openLogin(tester, repo);
      await enterIn(tester, _idField, 'name@example.com');
      await enterIn(tester, _pwField, MockAuthRepository.wrongPassword);
      await tapKey(tester, 'login_submit_button');
      await settle(tester);

      expect(snackText('Email hoặc mật khẩu không đúng.'), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text(kLoginSuccessText), findsNothing);
      expect(repo.isSignedIn, isFalse);
      // Dữ liệu đã nhập được giữ nguyên để sửa lại
      expect(textOf(tester, _idField), 'name@example.com');
      expect(textOf(tester, _pwField), MockAuthRepository.wrongPassword);
    });

    authTestWidgets('đang gửi: spinner, khoá ô nhập và chặn bấm đôi', (
      tester,
      repo,
    ) async {
      final blocker = repo.block('signInWithPassword');
      await openLogin(tester, repo);
      await enterIn(tester, _idField, 'name@example.com');
      await enterIn(tester, _pwField, 'Hoa@12345');

      await tapKey(tester, 'login_submit_button');
      expect(
        find.descendant(
          of: byKey('login_submit_button'),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: byKey(_idField),
                matching: find.byType(TextField),
              ),
            )
            .enabled,
        isFalse,
      );
      // Bấm thêm nhiều lần + các nút khác khi đang bận
      await tester.tap(byKey('login_submit_button'));
      await tester.pump();
      await tester.tap(byKey('login_google_button'), warnIfMissed: false);
      await tester.tap(byKey('login_otp_link'), warnIfMissed: false);
      await tester.pump();
      expect(repo.calls, ['signInWithPassword']);

      blocker.complete();
      await settle(tester);
      expect(repo.calls, ['signInWithPassword']);
      expect(find.text(kLoginSuccessText), findsOneWidget);
    });

    authTestWidgets('sau khi thất bại có thể bấm lại', (tester, repo) async {
      await openLogin(tester, repo);
      await enterIn(tester, _idField, 'name@example.com');
      await enterIn(tester, _pwField, MockAuthRepository.wrongPassword);
      await tapKey(tester, 'login_submit_button');
      await settle(tester);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await enterIn(tester, _pwField, 'Hoa@12345');
      await tapKey(tester, 'login_submit_button');
      await settle(tester);

      expect(repo.count('signInWithPassword'), 2);
      expect(find.text(kLoginSuccessText), findsOneWidget);
    });

    authTestWidgets('lỗi không phải AuthFailure hiện câu chung, không crash', (
      tester,
      repo,
    ) async {
      repo.failWith('signInWithPassword', StateError('boom'));
      await openLogin(tester, repo);
      await enterIn(tester, _idField, 'name@example.com');
      await enterIn(tester, _pwField, 'x');
      await tapKey(tester, 'login_submit_button');
      await settle(tester);

      expect(
        snackText('Đã có lỗi xảy ra. Vui lòng thử lại sau.'),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    authTestWidgets('mất mạng: hiện câu lỗi mạng', (tester, repo) async {
      repo.failWith('signInWithPassword', AuthFailure.network);
      await openLogin(tester, repo);
      await enterIn(tester, _idField, 'name@example.com');
      await enterIn(tester, _pwField, 'x');
      await tapKey(tester, 'login_submit_button');
      await settle(tester);

      expect(snackText(AuthFailure.network.message), findsOneWidget);
    });

    authTestWidgets('rời màn khi đang gửi rồi hoàn tất: không crash', (
      tester,
      repo,
    ) async {
      final blocker = repo.block('signInWithPassword');
      await openLogin(tester, repo);
      await enterIn(tester, _idField, 'name@example.com');
      await enterIn(tester, _pwField, 'x');
      await tapKey(tester, 'login_submit_button');

      await unmountApp(tester);
      blocker.complete();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });
  });

  group('bàn phím và ô mật khẩu', () {
    authTestWidgets('nút mắt đổi trạng thái che/hiện mật khẩu', (
      tester,
      repo,
    ) async {
      await openLogin(tester, repo);
      await enterIn(tester, _pwField, 'Hoa@12345');
      EditableText editable() => tester.widget<EditableText>(
        find.descendant(
          of: byKey(_pwField),
          matching: find.byType(EditableText),
        ),
      );
      expect(editable().obscureText, isTrue);
      expect(find.byTooltip('Hiện mật khẩu'), findsOneWidget);

      await tapKey(tester, 'login_password_toggle');
      expect(editable().obscureText, isFalse);
      expect(find.byTooltip('Ẩn mật khẩu'), findsOneWidget);
      expect(textOf(tester, _pwField), 'Hoa@12345');

      await tapKey(tester, 'login_password_toggle');
      expect(editable().obscureText, isTrue);
    });

    authTestWidgets('ô 1: nút "next" chuyển sang ô mật khẩu', (
      tester,
      repo,
    ) async {
      await openLogin(tester, repo);
      await tester.tap(byKey(_idField));
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();

      final pwEditable = tester.widget<EditableText>(
        find.descendant(
          of: byKey(_pwField),
          matching: find.byType(EditableText),
        ),
      );
      expect(pwEditable.focusNode.hasFocus, isTrue);
    });

    authTestWidgets('ô 2: nút "done" gửi form', (tester, repo) async {
      await openLogin(tester, repo);
      await enterIn(tester, _idField, 'name@example.com');
      await enterIn(tester, _pwField, 'Hoa@12345');
      await tester.tap(byKey(_pwField));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settle(tester);

      expect(repo.count('signInWithPassword'), 1);
      expect(find.text(kLoginSuccessText), findsOneWidget);
    });

    authTestWidgets('thuộc tính bàn phím và autofill', (tester, repo) async {
      await openLogin(tester, repo);
      final id = tester.widget<TextField>(
        find.descendant(of: byKey(_idField), matching: find.byType(TextField)),
      );
      final pw = tester.widget<TextField>(
        find.descendant(of: byKey(_pwField), matching: find.byType(TextField)),
      );
      expect(id.keyboardType, TextInputType.emailAddress);
      expect(id.textInputAction, TextInputAction.next);
      expect(id.autofillHints, contains(AutofillHints.email));
      expect(pw.textInputAction, TextInputAction.done);
      expect(pw.autofillHints, contains(AutofillHints.password));
    });
  });

  group('Đăng nhập OTP', () {
    authTestWidgets('để trống: chỉ báo lỗi ô định danh, không gọi repo', (
      tester,
      repo,
    ) async {
      await openLogin(tester, repo);
      await tapKey(tester, 'login_otp_link');

      expect(find.text(_emptyId), findsOneWidget);
      expect(byKey(_pwError), findsNothing);
      expect(repo.calls, isEmpty);
      expect(find.byType(OtpVerificationScreen), findsNothing);
    });

    authTestWidgets('số điện thoại: câu "chưa được hỗ trợ"', (
      tester,
      repo,
    ) async {
      await openLogin(tester, repo);
      await enterIn(tester, _idField, '0912345678');
      await tapKey(tester, 'login_otp_link');

      expect(find.text(_phoneUnsupported), findsOneWidget);
      expect(repo.calls, isEmpty);
    });

    authTestWidgets('email hợp lệ: gửi OTP rồi mở màn OTP (purpose=login)', (
      tester,
      repo,
    ) async {
      await openLogin(tester, repo);
      await enterIn(tester, _idField, ' phuongha@gmail.com ');
      await tapKey(tester, 'login_otp_link');
      await settle(tester);

      expect(repo.calls, ['sendLoginOtp']);
      expect(repo.lastEmail, 'phuongha@gmail.com');
      final otp = tester.widget<OtpVerificationScreen>(
        find.byType(OtpVerificationScreen),
      );
      expect(otp.email, 'phuongha@gmail.com');
      expect(otp.purpose, OtpPurpose.login);
      expect(find.text('ph***@gmail.com'), findsOneWidget);

      // Nhập đúng mã ở màn OTP -> đóng toàn bộ luồng, chỉ một SnackBar chào
      await tester.enterText(byKey('otp_input'), '123456');
      await tester.pump();
      await tester.tap(byKey('otp_confirm_button'));
      await settle(tester);
      expect(find.text(kHomeText), findsOneWidget);
      expect(find.text(kLoginSuccessText), findsOneWidget);
    });

    authTestWidgets('đang gửi: link bị khoá, hiện spinner, chặn bấm đôi', (
      tester,
      repo,
    ) async {
      final blocker = repo.block('sendLoginOtp');
      await openLogin(tester, repo);
      await enterIn(tester, _idField, 'a@b.vn');
      await tapKey(tester, 'login_otp_link');

      expect(
        find.descendant(
          of: byKey('login_otp_link'),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      await tester.tap(byKey('login_otp_link'), warnIfMissed: false);
      await tester.tap(byKey('login_submit_button'), warnIfMissed: false);
      await tester.pump();
      expect(repo.calls, ['sendLoginOtp']);

      blocker.complete();
      await settle(tester);
      expect(find.byType(OtpVerificationScreen), findsOneWidget);
    });

    authTestWidgets('quá nhiều yêu cầu: SnackBar lỗi, ở lại màn đăng nhập', (
      tester,
      repo,
    ) async {
      repo.failWith(
        'sendLoginOtp',
        const AuthFailure(
          AuthFailureCode.rateLimited,
          'Bạn thao tác quá nhanh.',
        ),
      );
      await openLogin(tester, repo);
      await enterIn(tester, _idField, 'a@b.vn');
      await tapKey(tester, 'login_otp_link');
      await settle(tester);

      expect(snackText('Bạn thao tác quá nhanh.'), findsOneWidget);
      expect(find.byType(OtpVerificationScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    authTestWidgets('sửa email ở màn OTP (back) quay lại màn đăng nhập', (
      tester,
      repo,
    ) async {
      await openLogin(tester, repo);
      await enterIn(tester, _idField, 'phuongha@gmail.com');
      await tapKey(tester, 'login_otp_link');
      await settle(tester);

      await tester.tap(byKey('otp_edit_email_button'));
      await tester.pumpAndSettle();

      expect(find.byType(OtpVerificationScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(textOf(tester, _idField), 'phuongha@gmail.com');
    });
  });

  group('Google', () {
    authTestWidgets('thành công: hoàn tất đăng nhập', (tester, repo) async {
      await openLogin(tester, repo);
      await tapKey(tester, 'login_google_button');
      await settle(tester);

      expect(repo.count('signInWithGoogle'), 1);
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.text(kLoginSuccessText), findsOneWidget);
    });

    authTestWidgets('đang mở trình duyệt: spinner và chặn bấm đôi', (
      tester,
      repo,
    ) async {
      final blocker = repo.block('signInWithGoogle');
      await openLogin(tester, repo);
      await tapKey(tester, 'login_google_button');

      expect(
        find.descendant(
          of: byKey('login_google_button'),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      await tester.tap(byKey('login_google_button'));
      await tester.pump();
      expect(repo.count('signInWithGoogle'), 1);
      blocker.complete();
      await settle(tester);
    });

    authTestWidgets('lỗi: SnackBar; huỷ: im lặng', (tester, repo) async {
      repo.failWith(
        'signInWithGoogle',
        const AuthFailure(AuthFailureCode.network, 'Mất mạng.'),
      );
      await openLogin(tester, repo);
      await tapKey(tester, 'login_google_button');
      await settle(tester);
      expect(snackText('Mất mạng.'), findsOneWidget);

      ScaffoldMessenger.of(
        tester.element(find.byType(LoginScreen)),
      ).clearSnackBars();
      await tester.pump();
      repo.failWith(
        'signInWithGoogle',
        const AuthFailure(AuthFailureCode.cancelled, 'Đã huỷ.'),
      );
      await tapKey(tester, 'login_google_button');
      await settle(tester);
      expect(find.byType(SnackBar), findsNothing);
    });

    authTestWidgets('OAuth quay về (signedInChanges=true) hoàn tất đăng nhập', (
      tester,
      repo,
    ) async {
      await openLogin(tester, repo);
      repo.emitSignedIn(true);
      await settle(tester);

      expect(find.byType(LoginScreen), findsNothing);
      expect(find.text(kLoginSuccessText), findsOneWidget);
    });
  });

  group('liên kết khác', () {
    authTestWidgets('Quên mật khẩu? hiện SnackBar "sớm ra mắt"', (
      tester,
      repo,
    ) async {
      await openLogin(tester, repo);
      await tapKey(tester, 'login_forgot_password_link');

      expect(
        snackText('Tính năng đặt lại mật khẩu sẽ sớm ra mắt.'),
        findsOneWidget,
      );
    });

    authTestWidgets('Khám phá cửa hàng: pop khi có route trước', (
      tester,
      repo,
    ) async {
      await openLogin(tester, repo);
      await tapKey(tester, 'login_explore_link');
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsNothing);
      expect(find.text(kHomeText), findsOneWidget);
    });

    authTestWidgets('Khám phá cửa hàng: SnackBar khi là route đầu', (
      tester,
      repo,
    ) async {
      await pumpAuthApp(tester, repo, home: const LoginScreen());
      await tapKey(tester, 'login_explore_link');
      await tester.pump();

      expect(snackText('Trang chủ đang được phát triển.'), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    authTestWidgets('Đăng ký ngay mở màn đăng ký', (tester, repo) async {
      await openLogin(tester, repo);
      await tapKey(tester, 'login_register_link');
      await tester.pumpAndSettle();

      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(find.text('Tạo tài khoản mới'), findsOneWidget);
    });
  });
}
