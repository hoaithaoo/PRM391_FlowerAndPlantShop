import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/auth/auth.dart';
import 'package:plant_flower_mobile/features/auth/widgets/auth_common.dart';

import '../support/auth_test_harness.dart';

const _email = 'phuongha@gmail.com';
const _resendButton = 'verify_email_resend_button';
const _cooldownLabel = 'verify_email_cooldown';
const _resentText = 'Đã gửi lại email xác nhận.';

/// `testWidgets` kèm repo giả. Màn có Timer đếm ngược nên luôn gỡ cây widget ở
/// cuối để huỷ Timer trước khi test kết thúc.
void verifyTest(
  String description,
  Future<void> Function(WidgetTester tester, FakeAuthRepository repo) body, {
  Object? skip,
}) {
  authTestWidgets(description, (tester, repo) async {
    await body(tester, repo);
    await unmountApp(tester);
  }, skip: skip);
}

/// Mở màn kiểm tra email phía trên màn nền (HOME > verify-email).
Future<GlobalKey<NavigatorState>> openVerify(
  WidgetTester tester,
  FakeAuthRepository repo, {
  String email = _email,
  Size size = kSmallPhone,
  double textScale = 1,
}) async {
  final nav = await pumpAuthApp(tester, repo, size: size, textScale: textScale);
  await pushRoute(tester, nav, AuthRoutes.verifyEmail, arguments: email);
  return nav;
}

AuthPrimaryButton resendButton(WidgetTester tester) =>
    tester.widget<AuthPrimaryButton>(byKey(_resendButton));

String cooldownText(WidgetTester tester) =>
    tester.widget<Text>(byKey(_cooldownLabel)).data!;

/// Tua hết thời gian chờ 60 giây để nút Gửi lại được bật.
Future<void> waitCooldown(WidgetTester tester) =>
    tester.pump(const Duration(seconds: 60));

void main() {
  group('hiển thị', () {
    verifyTest('có đủ nội dung theo thiết kế', (tester, repo) async {
      await openVerify(tester, repo);

      expect(find.byType(EmailVerificationScreen), findsOneWidget);
      expect(byKey('verify_email_title'), findsOneWidget);
      expect(find.text('Kiểm tra email của bạn'), findsOneWidget);
      expect(find.text('Kiểm tra email'), findsOneWidget); // tiêu đề header
      expect(find.text('Chúng tôi đã gửi link xác nhận tới'), findsOneWidget);
      expect(find.text('Bảo mật cao cấp'), findsOneWidget);
      expect(find.text('Kiểm tra hộp thư đến của bạn'), findsOneWidget);
      expect(find.text('Gửi lại email'), findsOneWidget);
      expect(find.text('Dùng email khác'), findsOneWidget);
      expect(byKey('verify_email_back_button'), findsOneWidget);
      expect(byKey('verify_email_change_email_link'), findsOneWidget);
      expect(byKey('verify_email_login_link'), findsOneWidget);
    });

    verifyTest('chip hiển thị email đầy đủ, không che', (tester, repo) async {
      await openVerify(tester, repo, email: 'phuongha@gmail.com');

      expect(
        tester.widget<Text>(byKey('verify_email_address')).data,
        'phuongha@gmail.com',
      );
      expect(find.text('phuongha@gmail.com'), findsOneWidget);
      expect(find.textContaining('***'), findsNothing);
    });

    verifyTest('hướng dẫn bấm link trong email và mở lại ứng dụng', (
      tester,
      repo,
    ) async {
      await openVerify(tester, repo);

      expect(
        find.text(
          'Bấm vào link trong email để hoàn tất đăng ký. '
          'Link sẽ mở lại ứng dụng.',
        ),
        findsOneWidget,
      );
    });

    verifyTest('có ghi chú kiểm tra thư mục spam', (tester, repo) async {
      await openVerify(tester, repo);

      expect(
        find.text(
          'Chưa thấy email? Hãy kiểm tra cả thư mục spam hoặc thư rác.',
        ),
        findsOneWidget,
      );
    });

    verifyTest('không còn dấu vết OTP', (tester, repo) async {
      await openVerify(tester, repo);

      expect(find.textContaining('OTP'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.textContaining('mã xác'), findsNothing);
    });

    verifyTest(
      'ban đầu đang đếm ngược: nút bị vô hiệu, có dòng "Gửi lại sau"',
      (tester, repo) async {
        await openVerify(tester, repo);

        expect(find.text('Gửi lại email'), findsOneWidget);
        expect(resendButton(tester).onPressed, isNull);
        expect(byKey(_cooldownLabel), findsOneWidget);
        expect(cooldownText(tester), 'Gửi lại sau 60s');
      },
    );
  });

  group('đếm ngược', () {
    verifyTest('dòng "Gửi lại sau Ns" giảm mỗi giây', (tester, repo) async {
      await openVerify(tester, repo);
      await tester.pump(const Duration(seconds: 15));

      expect(cooldownText(tester), 'Gửi lại sau 45s');
      await tester.pump(const Duration(seconds: 1));
      expect(cooldownText(tester), 'Gửi lại sau 44s');
    });

    verifyTest('hết giờ: dòng đếm ngược biến mất, nút được bật', (
      tester,
      repo,
    ) async {
      await openVerify(tester, repo);
      await waitCooldown(tester);

      expect(byKey(_cooldownLabel), findsNothing);
      expect(resendButton(tester).onPressed, isNotNull);
    });

    verifyTest('bấm nút khi đang đếm ngược không gọi repo', (
      tester,
      repo,
    ) async {
      await openVerify(tester, repo);
      await tester.pump(const Duration(seconds: 20));

      await tester.tap(byKey(_resendButton), warnIfMissed: false);
      await tester.pump();

      expect(repo.calls, isEmpty);
      expect(find.byType(SnackBar), findsNothing);
    });
  });

  group('gửi lại email', () {
    verifyTest('thành công: gọi repo, SnackBar, đếm ngược lại từ đầu', (
      tester,
      repo,
    ) async {
      await openVerify(tester, repo);
      await waitCooldown(tester);

      await tapKey(tester, _resendButton);
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump(const Duration(milliseconds: 300));

      expect(repo.calls, ['resendSignupEmail']);
      expect(repo.lastEmail, _email);
      expect(snackText(_resentText), findsOneWidget);
      expect(byKey(_cooldownLabel), findsOneWidget);
      expect(cooldownText(tester), matches(RegExp(r'^Gửi lại sau (59|60)s$')));
      expect(resendButton(tester).onPressed, isNull);
    });

    verifyTest('đang gửi: hiện spinner, chặn bấm đôi', (tester, repo) async {
      await openVerify(tester, repo);
      await waitCooldown(tester);
      final blocker = repo.block('resendSignupEmail');

      await tapKey(tester, _resendButton);
      expect(
        find.descendant(
          of: byKey(_resendButton),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      await tester.tap(byKey(_resendButton), warnIfMissed: false);
      await tester.pump();
      expect(repo.count('resendSignupEmail'), 1);

      blocker.complete();
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump(const Duration(milliseconds: 300));
      expect(repo.count('resendSignupEmail'), 1);
      expect(snackText(_resentText), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    verifyTest('gửi lại lần hai sau khi hết đếm ngược lại', (
      tester,
      repo,
    ) async {
      await openVerify(tester, repo);
      await waitCooldown(tester);
      await tapKey(tester, _resendButton);
      await tester.pump(const Duration(milliseconds: 10));
      await waitCooldown(tester);
      await waitCooldown(tester);

      await tapKey(tester, _resendButton);
      await tester.pump(const Duration(milliseconds: 10));

      expect(repo.count('resendSignupEmail'), 2);
    });

    verifyTest('lỗi AuthFailure: hiện đúng message, nút bật lại để thử tiếp', (
      tester,
      repo,
    ) async {
      repo.failWith(
        'resendSignupEmail',
        const AuthFailure(
          AuthFailureCode.rateLimited,
          'Bạn thao tác quá nhanh. Vui lòng thử lại sau ít phút.',
        ),
      );
      await openVerify(tester, repo);
      await waitCooldown(tester);

      await tapKey(tester, _resendButton);
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        snackText('Bạn thao tác quá nhanh. Vui lòng thử lại sau ít phút.'),
        findsOneWidget,
      );
      expect(snackText(_resentText), findsNothing);
      // Không bị khoá thêm: không đếm ngược, nút vẫn bấm được
      expect(byKey(_cooldownLabel), findsNothing);
      expect(resendButton(tester).onPressed, isNotNull);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    verifyTest('mất mạng: hiện câu lỗi mạng', (tester, repo) async {
      repo.failWith('resendSignupEmail', AuthFailure.network);
      await openVerify(tester, repo);
      await waitCooldown(tester);

      await tapKey(tester, _resendButton);
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump(const Duration(milliseconds: 300));

      expect(snackText(AuthFailure.network.message), findsOneWidget);
    });

    verifyTest('lỗi lạ: hiện câu chung, không crash', (tester, repo) async {
      repo.failWith('resendSignupEmail', StateError('boom'));
      await openVerify(tester, repo);
      await waitCooldown(tester);

      await tapKey(tester, _resendButton);
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump(const Duration(milliseconds: 300));

      expect(snackText(AuthFailure.unknown.message), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    verifyTest('rời màn khi đang gửi rồi hoàn tất: không crash', (
      tester,
      repo,
    ) async {
      await openVerify(tester, repo);
      await waitCooldown(tester);
      final blocker = repo.block('resendSignupEmail');
      await tapKey(tester, _resendButton);

      await unmountApp(tester);
      blocker.complete();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });
  });

  group('điều hướng', () {
    verifyTest('"Dùng email khác" quay lại màn trước', (tester, repo) async {
      await openVerify(tester, repo);

      await tapKey(tester, 'verify_email_change_email_link');
      await tester.pumpAndSettle();

      expect(find.byType(EmailVerificationScreen), findsNothing);
      expect(find.text(kHomeText), findsOneWidget);
    });

    verifyTest('nút back ở header quay lại màn trước', (tester, repo) async {
      await openVerify(tester, repo);

      await tapKey(tester, 'verify_email_back_button');
      await tester.pumpAndSettle();

      expect(find.byType(EmailVerificationScreen), findsNothing);
      expect(find.text(kHomeText), findsOneWidget);
    });

    verifyTest('"Dùng email khác" chỉ pop một màn (về màn Đăng ký)', (
      tester,
      repo,
    ) async {
      final nav = await pumpAuthApp(tester, repo);
      await pushRoute(tester, nav, AuthRoutes.register);
      await pushRoute(tester, nav, AuthRoutes.verifyEmail, arguments: _email);

      await tapKey(tester, 'verify_email_change_email_link');
      await tester.pumpAndSettle();

      expect(find.byType(EmailVerificationScreen), findsNothing);
      expect(find.byType(RegisterScreen), findsOneWidget);
    });

    verifyTest('"Đã xác nhận? Đăng nhập" về màn đầu tiên của Navigator', (
      tester,
      repo,
    ) async {
      final nav = await pumpAuthApp(tester, repo);
      await pushRoute(tester, nav, AuthRoutes.login);
      await pushRoute(tester, nav, AuthRoutes.register);
      await pushRoute(tester, nav, AuthRoutes.verifyEmail, arguments: _email);

      await tapKey(tester, 'verify_email_login_link');
      await tester.pumpAndSettle();

      expect(find.byType(EmailVerificationScreen), findsNothing);
      expect(find.byType(RegisterScreen), findsNothing);
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.text(kHomeText), findsOneWidget);
      expect(nav.currentState!.canPop(), isFalse);
      // Không tự báo đăng nhập thành công khi chưa có phiên
      expect(find.text(kLoginSuccessText), findsNothing);
    });

    verifyTest('là route đầu tiên: "Dùng email khác" không crash, ở lại màn', (
      tester,
      repo,
    ) async {
      await pumpAuthApp(
        tester,
        repo,
        home: const EmailVerificationScreen(email: _email),
      );

      await tapKey(tester, 'verify_email_change_email_link');
      await tapKey(tester, 'verify_email_back_button');
      await tester.pumpAndSettle();

      expect(find.byType(EmailVerificationScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('link xác nhận (signedInChanges)', () {
    verifyTest('simulateEmailConfirmed -> completeAuth: về màn đầu, chào', (
      tester,
      repo,
    ) async {
      final nav = await pumpAuthApp(tester, repo);
      await pushRoute(tester, nav, AuthRoutes.register);
      await pushRoute(tester, nav, AuthRoutes.verifyEmail, arguments: _email);

      repo.simulateEmailConfirmed();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(repo.isSignedIn, isTrue);
      expect(find.byType(EmailVerificationScreen), findsNothing);
      expect(find.byType(RegisterScreen), findsNothing);
      expect(find.text(kHomeText), findsOneWidget);
      expect(nav.currentState!.canPop(), isFalse);
      expect(find.text(kLoginSuccessText), findsOneWidget);
    });

    verifyTest('phát signedIn nhiều lần chỉ completeAuth đúng một lần', (
      tester,
      repo,
    ) async {
      // Màn là route đầu tiên nên không bị pop và luôn còn lắng nghe stream;
      // hai lần phát liên tiếp mà gọi completeAuth hai lần sẽ xếp hai SnackBar
      await pumpAuthApp(
        tester,
        repo,
        home: const EmailVerificationScreen(email: _email),
      );

      repo.emitSignedIn(true);
      repo.emitSignedIn(true);
      repo.simulateEmailConfirmed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(kLoginSuccessText), findsOneWidget);

      // Đợi SnackBar thứ nhất tự đóng: nếu còn SnackBar xếp hàng thì sẽ hiện
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SnackBar), findsNothing);
    });

    verifyTest('signedIn = false không hoàn tất đăng nhập', (
      tester,
      repo,
    ) async {
      await openVerify(tester, repo);

      repo.emitSignedIn(false);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(EmailVerificationScreen), findsOneWidget);
      expect(find.text(kLoginSuccessText), findsNothing);
    });

    verifyTest('xoá SnackBar "Đã gửi lại" cũ để lời chào hiện ngay', (
      tester,
      repo,
    ) async {
      await openVerify(tester, repo);
      await waitCooldown(tester);
      await tapKey(tester, _resendButton);
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump(const Duration(milliseconds: 300));
      expect(snackText(_resentText), findsOneWidget);

      repo.simulateEmailConfirmed();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(snackText(_resentText), findsNothing);
      expect(find.text(kLoginSuccessText), findsOneWidget);
    });
  });

  group('bố cục', () {
    const longEmail =
        'nguyen.phuong.ha.rat.rat.dai.de.thu.tran@mot-ten-mien-rat-dai.com.vn';

    for (final size in [kSmallPhone, kPhone]) {
      final label = '${size.width.toInt()}x${size.height.toInt()}';

      verifyTest('không overflow ở $label (kể cả khi đang gửi và có lỗi)', (
        tester,
        repo,
      ) async {
        await openVerify(tester, repo, size: size);
        expect(tester.takeException(), isNull);

        await tester.pump(const Duration(seconds: 61));
        expect(tester.takeException(), isNull);

        final blocker = repo.block('resendSignupEmail');
        repo.failWith('resendSignupEmail', AuthFailure.network);
        await tapKey(tester, _resendButton);
        expect(tester.takeException(), isNull);
        blocker.complete();
        await tester.pump(const Duration(milliseconds: 10));
        await tester.pump(const Duration(milliseconds: 300));
        expect(snackText(AuthFailure.network.message), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      verifyTest('không overflow ở $label khi email rất dài', (
        tester,
        repo,
      ) async {
        await openVerify(tester, repo, size: size, email: longEmail);
        expect(tester.takeException(), isNull);
        expect(find.text(longEmail), findsOneWidget);
      });

      verifyTest('không overflow ở $label khi bàn phím/inset 300px', (
        tester,
        repo,
      ) async {
        showKeyboard(tester, 300);
        await openVerify(tester, repo, size: size);
        expect(tester.takeException(), isNull);

        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -3000),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        // Cuộn được tới nút cuối cùng dù bàn phím che bớt
        await tester.ensureVisible(byKey('verify_email_login_link'));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });

      verifyTest('không overflow ở $label khi chữ phóng to 1.3x', (
        tester,
        repo,
      ) async {
        await openVerify(tester, repo, size: size, textScale: 1.3);
        expect(tester.takeException(), isNull);

        await tester.pump(const Duration(seconds: 61));
        expect(tester.takeException(), isNull);
      });
    }

    verifyTest('chữ 1.3x + bàn phím + email dài ở 360x640 không overflow', (
      tester,
      repo,
    ) async {
      showKeyboard(tester, 280);
      await openVerify(tester, repo, email: longEmail, textScale: 1.3);
      expect(tester.takeException(), isNull);
    });

    verifyTest('cuộn được tới mọi nút ở 360x640', (tester, repo) async {
      await openVerify(tester, repo);

      for (final key in [
        _resendButton,
        'verify_email_change_email_link',
        'verify_email_login_link',
      ]) {
        await tester.ensureVisible(byKey(key));
        await tester.pump();
        final rect = tester.getRect(byKey(key));
        expect(rect.bottom, lessThanOrEqualTo(640), reason: key);
        expect(rect.top, greaterThanOrEqualTo(0), reason: key);
      }
    });
  });
}
