import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/auth/auth.dart';
import 'package:plant_flower_mobile/features/auth/widgets/auth_common.dart';
import 'package:plant_flower_mobile/features/auth/widgets/otp_widgets.dart';

import '../support/auth_test_harness.dart';

const _email = 'phuongha@gmail.com';
const _wrongOtpMessage = 'Mã OTP không đúng hoặc đã hết hạn.';

Future<GlobalKey<NavigatorState>> openOtp(
  WidgetTester tester,
  FakeAuthRepository repo, {
  String email = _email,
  OtpPurpose purpose = OtpPurpose.login,
  Size size = kSmallPhone,
  double textScale = 1,
}) async {
  final nav = await pumpAuthApp(tester, repo, size: size, textScale: textScale);
  await pushRoute(
    tester,
    nav,
    AuthRoutes.otp,
    arguments: OtpArgs(email: email, purpose: purpose),
  );
  return nav;
}

OtpDigitBox box(WidgetTester tester, int i) =>
    tester.widget<OtpDigitBox>(byKey('otp_digit_$i'));

List<String?> digits(WidgetTester tester) => [
  for (var i = 0; i < 6; i++) box(tester, i).digit,
];

bool confirmEnabled(WidgetTester tester) =>
    tester.widget<AuthPrimaryButton>(byKey('otp_confirm_button')).onPressed !=
    null;

Future<void> typeCode(WidgetTester tester, String code) async {
  await tester.enterText(byKey('otp_input'), code);
  await tester.pump();
}

String countdown(WidgetTester tester) =>
    tester.widget<Text>(byKey('otp_countdown')).data!;

void main() {
  group('hiển thị', () {
    authTestWidgets('có đủ nội dung theo thiết kế', (tester, repo) async {
      await openOtp(tester, repo);

      expect(find.byType(OtpVerificationScreen), findsOneWidget);
      // Tiêu đề header + tiêu đề thẻ; không dùng lỗi copy "Chi Tiết Tác Phẩm"
      expect(find.text('Xác thực Email'), findsNWidgets(2));
      expect(find.text('Chi Tiết Tác Phẩm'), findsNothing);
      expect(find.text('Bảo mật cao cấp'), findsOneWidget);
      expect(find.text('Kiểm tra hộp thư đến của bạn'), findsOneWidget);
      expect(
        find.text(
          'Chúng tôi đã gửi mã xác thực gồm 6 chữ số đến email của bạn.',
        ),
        findsOneWidget,
      );
      expect(find.text('MÃ OTP (6 CHỮ SỐ)'), findsOneWidget);
      expect(find.text('Bạn chưa nhận được mã?'), findsOneWidget);
      expect(find.text('Gửi lại mã sau'), findsOneWidget);
      expect(find.text('Xác nhận'), findsOneWidget);
      expect(
        find.textContaining('Mã OTP có hiệu lực trong 5 phút'),
        findsOneWidget,
      );
      for (var i = 0; i < 6; i++) {
        expect(byKey('otp_digit_$i'), findsOneWidget);
      }
      for (final key in [
        'otp_back_button',
        'otp_email_text',
        'otp_edit_email_button',
        'otp_input',
        'otp_countdown',
        'otp_confirm_button',
      ]) {
        expect(byKey(key), findsOneWidget, reason: key);
      }
      expect(byKey('otp_resend_button'), findsNothing);
      // Bỏ avatar/chuông/chia sẻ của header thiết kế
      expect(find.byType(CircleAvatar), findsNothing);
      expect(find.byIcon(Icons.share), findsNothing);
      expect(find.byIcon(Icons.notifications_outlined), findsNothing);
    });

    authTestWidgets('email được che trên chip', (tester, repo) async {
      await openOtp(tester, repo);
      final text = tester.widget<Text>(byKey('otp_email_text'));
      expect(text.data, 'ph***@gmail.com');
      expect(find.text(_email), findsNothing);
    });

    authTestWidgets('ban đầu 6 ô trống, nút Xác nhận bị khoá', (
      tester,
      repo,
    ) async {
      await openOtp(tester, repo);
      expect(digits(tester), everyElement(isNull));
      expect(confirmEnabled(tester), isFalse);
      expect(countdown(tester), '01:00');
    });

    for (final size in [kSmallPhone, kPhone]) {
      final label = '${size.width.toInt()}x${size.height.toInt()}';

      authTestWidgets('không overflow ở $label (trống, đủ 6 số, báo lỗi)', (
        tester,
        repo,
      ) async {
        await openOtp(tester, repo, size: size);
        expect(tester.takeException(), isNull);

        await tester.tap(byKey('otp_input'));
        await typeCode(tester, '000000');
        expect(tester.takeException(), isNull);

        await tester.ensureVisible(byKey('otp_confirm_button'));
        await tester.pump();
        await tester.tap(byKey('otp_confirm_button'));
        await settle(tester);
        expect(box(tester, 0).hasError, isTrue);
        expect(tester.takeException(), isNull);
      });

      authTestWidgets('không overflow ở $label khi bàn phím mở', (
        tester,
        repo,
      ) async {
        showKeyboard(tester, 300);
        await openOtp(tester, repo, size: size);
        await tapKey(tester, 'otp_input');
        expect(tester.takeException(), isNull);
      });
    }

    authTestWidgets('email rất dài được cắt bằng dấu ..., không overflow', (
      tester,
      repo,
    ) async {
      await openOtp(
        tester,
        repo,
        email:
            'nguyen.van.phuong.ha.1990.abcdef@subdomain.example-company.com.vn',
      );
      expect(tester.takeException(), isNull);
    });

    // Banner OTP cao tối thiểu 96px (minHeight) nên giãn theo khi chữ phóng to,
    // không tràn đáy ở 1.3x trên màn 360x640.
    group('chữ phóng to', () {
      authTestWidgets('không overflow khi chữ phóng to 1.3x', (
        tester,
        repo,
      ) async {
        await openOtp(tester, repo, textScale: 1.3);
        expect(tester.takeException(), isNull);
      });
    });
  });

  group('nhập mã', () {
    authTestWidgets('gõ từng số hiện vào ô tương ứng', (tester, repo) async {
      await openOtp(tester, repo);
      await tester.tap(byKey('otp_input'));
      await typeCode(tester, '1');
      expect(digits(tester), ['1', null, null, null, null, null]);
      await typeCode(tester, '12');
      await typeCode(tester, '123');
      expect(digits(tester), ['1', '2', '3', null, null, null]);
      expect(confirmEnabled(tester), isFalse);
    });

    authTestWidgets('ô đang focus là ô kế tiếp cần nhập', (tester, repo) async {
      await openOtp(tester, repo);
      expect(box(tester, 0).isFocused, isFalse); // chưa focus
      await tester.tap(byKey('otp_input'));
      await tester.pump();
      expect(box(tester, 0).isFocused, isTrue);

      await typeCode(tester, '12');
      expect(box(tester, 0).isFocused, isFalse);
      expect(box(tester, 2).isFocused, isTrue);

      await typeCode(tester, '123456');
      expect(box(tester, 5).isFocused, isTrue); // đủ 6 số: dừng ở ô cuối
    });

    authTestWidgets('Backspace lùi về ô trước', (tester, repo) async {
      await openOtp(tester, repo);
      await tester.tap(byKey('otp_input'));
      await typeCode(tester, '123');
      await typeCode(tester, '12');

      expect(digits(tester), ['1', '2', null, null, null, null]);
      expect(box(tester, 2).isFocused, isTrue);
      await typeCode(tester, '');
      expect(digits(tester), everyElement(isNull));
      expect(box(tester, 0).isFocused, isTrue);
    });

    authTestWidgets('dán 6 số điền hết các ô và bật nút Xác nhận', (
      tester,
      repo,
    ) async {
      await openOtp(tester, repo);
      await tester.tap(byKey('otp_input'));
      await typeCode(tester, '482915');

      expect(digits(tester), ['4', '8', '2', '9', '1', '5']);
      expect(confirmEnabled(tester), isTrue);
    });

    authTestWidgets('dán chuỗi dài hơn 6 số: chỉ giữ 6 số đầu', (
      tester,
      repo,
    ) async {
      await openOtp(tester, repo);
      await tester.tap(byKey('otp_input'));
      await typeCode(tester, '123456789');

      expect(digits(tester), ['1', '2', '3', '4', '5', '6']);
      expect(textOf(tester, 'otp_input'), '123456');
    });

    authTestWidgets('chỉ nhận chữ số: chữ cái và ký tự lạ bị loại', (
      tester,
      repo,
    ) async {
      await openOtp(tester, repo);
      await tester.tap(byKey('otp_input'));
      await typeCode(tester, 'ab1-2 c3');

      expect(digits(tester), ['1', '2', '3', null, null, null]);
      expect(textOf(tester, 'otp_input'), '123');
    });

    authTestWidgets('chạm vào một ô bất kỳ vẫn focus ô nhập', (
      tester,
      repo,
    ) async {
      await openOtp(tester, repo);
      // Lớp TextField trong suốt phủ lên các ô nên chạm vào toạ độ của ô
      await tester.tapAt(tester.getCenter(byKey('otp_digit_4')));
      await tester.pump();

      final editable = tester.widget<EditableText>(
        find.descendant(
          of: byKey('otp_input'),
          matching: find.byType(EditableText),
        ),
      );
      expect(editable.focusNode.hasFocus, isTrue);
    });

    authTestWidgets('thuộc tính bàn phím: số + oneTimeCode', (
      tester,
      repo,
    ) async {
      await openOtp(tester, repo);
      final field = tester.widget<TextField>(byKey('otp_input'));
      expect(field.keyboardType, TextInputType.number);
      expect(field.autofillHints, contains(AutofillHints.oneTimeCode));
    });

    authTestWidgets('đủ 6 số KHÔNG tự gọi xác nhận', (tester, repo) async {
      await openOtp(tester, repo);
      await tester.tap(byKey('otp_input'));
      await typeCode(tester, '123456');
      await settle(tester);

      expect(repo.calls, isEmpty);
      expect(find.byType(OtpVerificationScreen), findsOneWidget);
    });
  });

  group('xác nhận', () {
    authTestWidgets('mã đúng: gọi verifyOtp(login) và hoàn tất đăng nhập', (
      tester,
      repo,
    ) async {
      await openOtp(tester, repo);
      await tester.tap(byKey('otp_input'));
      await typeCode(tester, MockAuthRepository.validOtp);
      await tapKey(tester, 'otp_confirm_button');
      await settle(tester);

      expect(repo.calls, ['verifyOtp']);
      expect(repo.lastEmail, _email);
      expect(repo.lastToken, '123456');
      expect(repo.lastPurpose, OtpPurpose.login);
      expect(find.byType(OtpVerificationScreen), findsNothing);
      expect(find.text(kHomeText), findsOneWidget);
      expect(find.text(kLoginSuccessText), findsOneWidget);
    });

    authTestWidgets('purpose=signup được truyền xuống repository', (
      tester,
      repo,
    ) async {
      await openOtp(tester, repo, purpose: OtpPurpose.signup);
      await tester.tap(byKey('otp_input'));
      await typeCode(tester, '123456');
      await tapKey(tester, 'otp_confirm_button');
      await settle(tester);

      expect(repo.lastPurpose, OtpPurpose.signup);
      expect(find.text(kLoginSuccessText), findsOneWidget);
    });

    authTestWidgets('bàn phím "done" với đủ 6 số cũng xác nhận', (
      tester,
      repo,
    ) async {
      await openOtp(tester, repo);
      await tester.tap(byKey('otp_input'));
      await typeCode(tester, '123456');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settle(tester);

      expect(repo.count('verifyOtp'), 1);
      expect(find.text(kLoginSuccessText), findsOneWidget);
    });

    authTestWidgets('bàn phím "done" khi chưa đủ số: không làm gì', (
      tester,
      repo,
    ) async {
      await openOtp(tester, repo);
      await tester.tap(byKey('otp_input'));
      await typeCode(tester, '123');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settle(tester);

      expect(repo.calls, isEmpty);
      expect(find.byType(SnackBar), findsNothing);
    });

    authTestWidgets('mã sai: SnackBar, xoá các ô, focus ô đầu, tô viền đỏ', (
      tester,
      repo,
    ) async {
      await openOtp(tester, repo);
      await tester.tap(byKey('otp_input'));
      await typeCode(tester, '000000');
      await tapKey(tester, 'otp_confirm_button');
      await settle(tester);

      expect(snackText(_wrongOtpMessage), findsOneWidget);
      expect(find.byType(OtpVerificationScreen), findsOneWidget);
      expect(digits(tester), everyElement(isNull));
      expect(textOf(tester, 'otp_input'), '');
      expect(box(tester, 0).isFocused, isTrue);
      for (var i = 0; i < 6; i++) {
        expect(box(tester, i).hasError, isTrue, reason: 'ô $i');
      }
      expect(confirmEnabled(tester), isFalse);
      expect(repo.isSignedIn, isFalse);
    });

    authTestWidgets('nhập lại sau khi sai: bỏ viền đỏ và xác nhận được', (
      tester,
      repo,
    ) async {
      await openOtp(tester, repo);
      await tester.tap(byKey('otp_input'));
      await typeCode(tester, '000000');
      await tapKey(tester, 'otp_confirm_button');
      await settle(tester);
      expect(box(tester, 0).hasError, isTrue);

      await typeCode(tester, '1');
      expect(box(tester, 0).hasError, isFalse);

      await typeCode(tester, '123456');
      await tapKey(tester, 'otp_confirm_button');
      await settle(tester);
      expect(repo.count('verifyOtp'), 2);
      expect(find.text(kLoginSuccessText), findsOneWidget);
    });

    authTestWidgets('đang xác nhận: spinner và chặn bấm đôi', (
      tester,
      repo,
    ) async {
      final blocker = repo.block('verifyOtp');
      await openOtp(tester, repo);
      await tester.tap(byKey('otp_input'));
      await typeCode(tester, '123456');
      await tapKey(tester, 'otp_confirm_button');

      expect(
        find.descendant(
          of: byKey('otp_confirm_button'),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      await tester.tap(byKey('otp_confirm_button'));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(repo.count('verifyOtp'), 1);

      blocker.complete();
      await settle(tester);
      expect(repo.count('verifyOtp'), 1);
      expect(find.text(kLoginSuccessText), findsOneWidget);
    });

    authTestWidgets('mất mạng: hiện câu lỗi mạng và xoá ô', (
      tester,
      repo,
    ) async {
      repo.failWith('verifyOtp', AuthFailure.network);
      await openOtp(tester, repo);
      await tester.tap(byKey('otp_input'));
      await typeCode(tester, '123456');
      await tapKey(tester, 'otp_confirm_button');
      await settle(tester);

      expect(snackText(AuthFailure.network.message), findsOneWidget);
      expect(digits(tester), everyElement(isNull));
    });

    authTestWidgets('lỗi không phải AuthFailure: câu chung, không crash', (
      tester,
      repo,
    ) async {
      repo.failWith('verifyOtp', StateError('boom'));
      await openOtp(tester, repo);
      await tester.tap(byKey('otp_input'));
      await typeCode(tester, '123456');
      await tapKey(tester, 'otp_confirm_button');
      await settle(tester);

      expect(
        snackText('Đã có lỗi xảy ra. Vui lòng thử lại sau.'),
        findsOneWidget,
      );
    });

    authTestWidgets('rời màn khi đang xác nhận rồi hoàn tất: không crash', (
      tester,
      repo,
    ) async {
      final blocker = repo.block('verifyOtp');
      await openOtp(tester, repo);
      await tester.tap(byKey('otp_input'));
      await typeCode(tester, '123456');
      await tapKey(tester, 'otp_confirm_button');

      await unmountApp(tester);
      blocker.complete();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });
  });

  group('đếm ngược và gửi lại mã', () {
    authTestWidgets('đếm ngược từng giây theo dạng mm:ss', (
      tester,
      repo,
    ) async {
      await openOtp(tester, repo);
      expect(countdown(tester), '01:00');

      await tester.pump(const Duration(seconds: 1));
      expect(countdown(tester), '00:59');
      await tester.pump(const Duration(seconds: 15));
      expect(countdown(tester), '00:44');
      await tester.pump(const Duration(seconds: 43));
      expect(countdown(tester), '00:01');
      expect(byKey('otp_resend_button'), findsNothing);
    });

    authTestWidgets('hết 60 giây: thay đồng hồ bằng nút "Gửi lại mã"', (
      tester,
      repo,
    ) async {
      await openOtp(tester, repo);
      await tester.pump(const Duration(seconds: 60));

      expect(byKey('otp_countdown'), findsNothing);
      expect(find.text('Gửi lại mã sau'), findsNothing);
      expect(byKey('otp_resend_button'), findsOneWidget);
      expect(find.text('Gửi lại mã'), findsOneWidget);
    });

    authTestWidgets('gửi lại: gọi repo, báo thành công, đếm lại từ 01:00', (
      tester,
      repo,
    ) async {
      await openOtp(tester, repo, purpose: OtpPurpose.signup);
      await tester.pump(const Duration(seconds: 60));
      await tapKey(tester, 'otp_resend_button');
      await settle(tester);

      expect(repo.calls, ['resendOtp']);
      expect(repo.lastEmail, _email);
      expect(repo.lastPurpose, OtpPurpose.signup);
      expect(snackText('Đã gửi lại mã xác thực.'), findsOneWidget);
      expect(byKey('otp_resend_button'), findsNothing);
      expect(countdown(tester), '01:00');

      await tester.pump(const Duration(seconds: 1));
      expect(countdown(tester), '00:59');
    });

    authTestWidgets('đang gửi lại: spinner và chặn bấm đôi', (
      tester,
      repo,
    ) async {
      final blocker = repo.block('resendOtp');
      await openOtp(tester, repo);
      await tester.pump(const Duration(seconds: 60));
      await tapKey(tester, 'otp_resend_button');

      expect(
        find.descendant(
          of: byKey('otp_resend_button'),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      await tester.tap(byKey('otp_resend_button'), warnIfMissed: false);
      await tester.pump();
      expect(repo.count('resendOtp'), 1);

      blocker.complete();
      await settle(tester);
      expect(repo.count('resendOtp'), 1);
    });

    authTestWidgets('gửi lại thất bại: SnackBar lỗi, vẫn có nút gửi lại', (
      tester,
      repo,
    ) async {
      repo.failWith(
        'resendOtp',
        const AuthFailure(
          AuthFailureCode.rateLimited,
          'Bạn thao tác quá nhanh.',
        ),
      );
      await openOtp(tester, repo);
      await tester.pump(const Duration(seconds: 60));
      await tapKey(tester, 'otp_resend_button');
      await settle(tester);

      expect(snackText('Bạn thao tác quá nhanh.'), findsOneWidget);
      expect(byKey('otp_resend_button'), findsOneWidget);
      expect(byKey('otp_countdown'), findsNothing);
    });

    authTestWidgets('gỡ màn: timer bị huỷ, không lỗi khi thời gian trôi tiếp', (
      tester,
      repo,
    ) async {
      await openOtp(tester, repo);
      await tester.pump(const Duration(seconds: 5));
      await unmountApp(tester);
      await tester.pump(const Duration(seconds: 120));

      expect(tester.takeException(), isNull);
    });
  });

  group('điều hướng', () {
    authTestWidgets('nút back và nút sửa email đều pop về màn trước', (
      tester,
      repo,
    ) async {
      final nav = await openOtp(tester, repo);
      await tester.tap(byKey('otp_back_button'));
      await tester.pumpAndSettle();
      expect(find.byType(OtpVerificationScreen), findsNothing);
      expect(find.text(kHomeText), findsOneWidget);

      unawaited(
        nav.currentState!.pushNamed(
          AuthRoutes.otp,
          arguments: const OtpArgs(email: _email, purpose: OtpPurpose.login),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(byKey('otp_edit_email_button'));
      await tester.pumpAndSettle();
      expect(find.byType(OtpVerificationScreen), findsNothing);
      expect(find.text(kHomeText), findsOneWidget);
    });

    authTestWidgets('là route đầu thì back không làm gì và không crash', (
      tester,
      repo,
    ) async {
      await pumpAuthApp(
        tester,
        repo,
        home: const OtpVerificationScreen(
          email: _email,
          purpose: OtpPurpose.login,
        ),
      );
      await tester.tap(byKey('otp_back_button'));
      await tester.tap(byKey('otp_edit_email_button'));
      await tester.pumpAndSettle();

      expect(find.byType(OtpVerificationScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
