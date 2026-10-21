import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/auth/auth.dart';

import '../support/auth_test_harness.dart';
import '../support/register_test_helpers.dart';

const _customHome = 'CUSTOM_SIGNED_IN_HOME';

/// Dựng AuthSessionGate làm màn gốc (đúng như main.dart).
Future<GlobalKey<NavigatorState>> pumpGate(
  WidgetTester tester,
  FakeAuthRepository repo, {
  WidgetBuilder? signedInBuilder,
  Size size = kSmallPhone,
  double textScale = 1,
}) {
  return pumpAuthApp(
    tester,
    repo,
    size: size,
    textScale: textScale,
    home: AuthSessionGate(signedInBuilder: signedInBuilder),
  );
}

/// Gỡ cây widget (huỷ Timer của các màn) rồi kết thúc test.
void gateTest(
  String description,
  Future<void> Function(WidgetTester tester, FakeAuthRepository repo) body,
) {
  authTestWidgets(description, (tester, repo) async {
    await body(tester, repo);
    await unmountApp(tester);
  });
}

Future<void> loginWithPassword(WidgetTester tester) async {
  await enterIn(tester, 'login_identifier_field', 'name@example.com');
  await enterIn(tester, 'login_password_field', 'Hoa@12345');
  await tapKey(tester, 'login_submit_button');
  await settle(tester);
}

void main() {
  group('theo phiên đăng nhập', () {
    gateTest('chưa đăng nhập -> LoginScreen, không có màn tạm', (
      tester,
      repo,
    ) async {
      await pumpGate(tester, repo);

      expect(find.byType(AuthSessionGate), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(SignedInPlaceholder), findsNothing);
      expect(find.text('Chào mừng bạn'), findsOneWidget);
      // Không còn màn "Đăng nhập để tiếp tục"
      expect(find.text('Đăng nhập để tiếp tục'), findsNothing);
    });

    gateTest('đã đăng nhập sẵn -> màn tạm với nút Đăng xuất', (
      tester,
      repo,
    ) async {
      repo.simulateEmailConfirmed();
      expect(repo.isSignedIn, isTrue);
      await pumpGate(tester, repo);

      expect(find.byType(SignedInPlaceholder), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.text('Bạn đã đăng nhập'), findsOneWidget);
      expect(find.text('Trang chủ đang được phát triển.'), findsOneWidget);
      expect(byKey('signed_in_sign_out'), findsOneWidget);
      expect(find.text('Đăng xuất'), findsOneWidget);
    });

    gateTest('đăng nhập bằng mật khẩu xong: tự chuyển sang màn đã đăng nhập', (
      tester,
      repo,
    ) async {
      await pumpGate(tester, repo);
      await loginWithPassword(tester);

      expect(repo.count('signInWithPassword'), 1);
      expect(find.byType(SignedInPlaceholder), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.text(kLoginSuccessText), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    gateTest('đăng nhập sai mật khẩu: ở lại LoginScreen', (tester, repo) async {
      await pumpGate(tester, repo);
      await enterIn(tester, 'login_identifier_field', 'name@example.com');
      await enterIn(
        tester,
        'login_password_field',
        MockAuthRepository.wrongPassword,
      );
      await tapKey(tester, 'login_submit_button');
      await settle(tester);

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(SignedInPlaceholder), findsNothing);
      expect(snackText('Email hoặc mật khẩu không đúng.'), findsOneWidget);
    });

    gateTest('Google quay về app (signedInChanges=true) -> màn đã đăng nhập', (
      tester,
      repo,
    ) async {
      await pumpGate(tester, repo);

      repo.emitSignedIn(true);
      await settle(tester);

      expect(find.byType(SignedInPlaceholder), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.text(kLoginSuccessText), findsOneWidget);
    });

    gateTest('đăng xuất -> quay lại LoginScreen mới (ô nhập trống)', (
      tester,
      repo,
    ) async {
      await pumpGate(tester, repo);
      await loginWithPassword(tester);
      expect(find.byType(SignedInPlaceholder), findsOneWidget);

      await tapKey(tester, 'signed_in_sign_out');
      await settle(tester);

      expect(repo.count('signOut'), 1);
      expect(repo.isSignedIn, isFalse);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(SignedInPlaceholder), findsNothing);
      expect(textOf(tester, 'login_identifier_field'), isEmpty);
      expect(textOf(tester, 'login_password_field'), isEmpty);
    });

    gateTest('đăng nhập lại sau khi đăng xuất vẫn chuyển màn', (
      tester,
      repo,
    ) async {
      await pumpGate(tester, repo);
      await loginWithPassword(tester);
      await tapKey(tester, 'signed_in_sign_out');
      await settle(tester);

      await loginWithPassword(tester);

      expect(repo.count('signInWithPassword'), 2);
      expect(find.byType(SignedInPlaceholder), findsOneWidget);
    });

    gateTest('signedInChanges=false khi chưa đăng nhập: giữ LoginScreen', (
      tester,
      repo,
    ) async {
      await pumpGate(tester, repo);

      repo.emitSignedIn(false);
      await settle(tester);

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(SignedInPlaceholder), findsNothing);
    });

    gateTest('màn gốc: không thể pop (không có route nào bên dưới)', (
      tester,
      repo,
    ) async {
      final nav = await pumpGate(tester, repo);
      expect(nav.currentState!.canPop(), isFalse);

      repo.simulateEmailConfirmed();
      await settle(tester);
      expect(nav.currentState!.canPop(), isFalse);
    });
  });

  group('signedInBuilder tuỳ biến', () {
    gateTest('dùng builder thay cho màn tạm khi đã đăng nhập', (
      tester,
      repo,
    ) async {
      repo.simulateEmailConfirmed();
      await pumpGate(
        tester,
        repo,
        signedInBuilder: (_) => const Scaffold(body: Text(_customHome)),
      );

      expect(find.text(_customHome), findsOneWidget);
      expect(find.byType(SignedInPlaceholder), findsNothing);
      expect(find.byType(LoginScreen), findsNothing);
    });

    gateTest(
      'chưa đăng nhập vẫn hiện LoginScreen, đăng nhập xong mới gọi builder',
      (tester, repo) async {
        var builds = 0;
        await pumpGate(
          tester,
          repo,
          signedInBuilder: (_) {
            builds++;
            return const Scaffold(body: Text(_customHome));
          },
        );
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(builds, 0);

        await loginWithPassword(tester);

        expect(find.text(_customHome), findsOneWidget);
        expect(find.byType(LoginScreen), findsNothing);
        expect(builds, greaterThan(0));
      },
    );

    gateTest('builder nhận context có AuthScope', (tester, repo) async {
      repo.simulateEmailConfirmed();
      AuthRepository? seen;
      await pumpGate(
        tester,
        repo,
        signedInBuilder: (context) {
          seen = AuthScope.of(context);
          return const SizedBox();
        },
      );

      expect(seen, same(repo));
    });
  });

  group('luồng đầy đủ', () {
    gateTest('đăng ký -> màn kiểm tra email -> bấm link -> màn đã đăng nhập', (
      tester,
      repo,
    ) async {
      final nav = await pumpGate(tester, repo);

      await tapKey(tester, 'login_register_link');
      await tester.pumpAndSettle();
      expect(find.byType(RegisterScreen), findsOneWidget);

      await fillRegister(tester);
      await tapAgreement(tester);
      await tapKey(tester, 'register_submit_button');
      await settle(tester);

      expect(repo.calls, ['signUp']);
      expect(find.byType(EmailVerificationScreen), findsOneWidget);
      expect(
        tester
            .widget<EmailVerificationScreen>(
              find.byType(EmailVerificationScreen),
            )
            .email,
        'phuongha@gmail.com',
      );
      expect(repo.isSignedIn, isFalse);

      repo.simulateEmailConfirmed();
      await tester.pump();
      await tester.pumpAndSettle();

      // Màn gốc là màn đã đăng nhập, không còn màn auth nằm trên
      expect(find.byType(SignedInPlaceholder), findsOneWidget);
      expect(
        find.byType(EmailVerificationScreen, skipOffstage: false),
        findsNothing,
      );
      expect(find.byType(RegisterScreen, skipOffstage: false), findsNothing);
      expect(find.byType(LoginScreen, skipOffstage: false), findsNothing);
      expect(nav.currentState!.canPop(), isFalse);
      expect(find.text(kLoginSuccessText), findsOneWidget);

      // Chỉ một lời chào: đợi SnackBar tự đóng thì không còn cái nào xếp hàng
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SnackBar), findsNothing);
    });

    gateTest('đăng ký, "Dùng email khác" rồi đăng ký lại bằng email mới', (
      tester,
      repo,
    ) async {
      await pumpGate(tester, repo);
      await tapKey(tester, 'login_register_link');
      await tester.pumpAndSettle();
      await fillRegister(tester, email: 'cu@gmail.com');
      await tapAgreement(tester);
      await tapKey(tester, 'register_submit_button');
      await settle(tester);
      expect(find.byType(EmailVerificationScreen), findsOneWidget);

      await tapKey(tester, 'verify_email_change_email_link');
      await tester.pumpAndSettle();
      expect(find.byType(RegisterScreen), findsOneWidget);
      // Dữ liệu đã nhập vẫn còn để sửa email
      expect(textOf(tester, 'register_email_field'), 'cu@gmail.com');

      await enterIn(tester, 'register_email_field', 'moi@gmail.com');
      await tapKey(tester, 'register_submit_button');
      await settle(tester);

      expect(repo.lastSignUp!.email, 'moi@gmail.com');
      expect(
        tester
            .widget<EmailVerificationScreen>(
              find.byType(EmailVerificationScreen),
            )
            .email,
        'moi@gmail.com',
      );
    });

    gateTest('đăng ký, "Đã xác nhận? Đăng nhập" về LoginScreen rồi đăng nhập', (
      tester,
      repo,
    ) async {
      await pumpGate(tester, repo);
      await tapKey(tester, 'login_register_link');
      await tester.pumpAndSettle();
      await fillRegister(tester);
      await tapAgreement(tester);
      await tapKey(tester, 'register_submit_button');
      await settle(tester);

      await tapKey(tester, 'verify_email_login_link');
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(EmailVerificationScreen), findsNothing);
      expect(find.byType(RegisterScreen), findsNothing);

      await loginWithPassword(tester);
      expect(find.byType(SignedInPlaceholder), findsOneWidget);
      expect(find.text(kLoginSuccessText), findsOneWidget);
    });

    gateTest('signUp trả signedIn: vào thẳng màn đã đăng nhập', (
      tester,
      repo,
    ) async {
      repo.forcedSignUpResult = SignUpResult.signedIn;
      await pumpGate(tester, repo);
      await tapKey(tester, 'login_register_link');
      await tester.pumpAndSettle();
      await fillRegister(tester);
      await tapAgreement(tester);

      // Backend tự đăng nhập khi tắt xác nhận email: phiên đến cùng lúc signUp
      await tapKey(tester, 'register_submit_button');
      await settle(tester);
      repo.simulateEmailConfirmed();
      await settle(tester);

      expect(find.byType(SignedInPlaceholder), findsOneWidget);
      expect(find.byType(RegisterScreen, skipOffstage: false), findsNothing);
      expect(find.byType(EmailVerificationScreen), findsNothing);
    });

    gateTest('gửi lại email trong luồng đăng ký rồi bấm link vẫn vào app', (
      tester,
      repo,
    ) async {
      await pumpGate(tester, repo);
      await tapKey(tester, 'login_register_link');
      await tester.pumpAndSettle();
      await fillRegister(tester);
      await tapAgreement(tester);
      await tapKey(tester, 'register_submit_button');
      await settle(tester);

      await tester.pump(const Duration(seconds: 60));
      await tapKey(tester, 'verify_email_resend_button');
      await tester.pump(const Duration(milliseconds: 10));
      expect(repo.count('resendSignupEmail'), 1);
      expect(repo.lastEmail, 'phuongha@gmail.com');

      repo.simulateEmailConfirmed();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(SignedInPlaceholder), findsOneWidget);
    });
  });

  group('bố cục màn đã đăng nhập', () {
    for (final size in [kSmallPhone, kPhone]) {
      final label = '${size.width.toInt()}x${size.height.toInt()}';
      gateTest('không overflow ở $label, chữ 1.3x', (tester, repo) async {
        repo.simulateEmailConfirmed();
        await pumpGate(tester, repo, size: size, textScale: 1.3);

        expect(find.byType(SignedInPlaceholder), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
