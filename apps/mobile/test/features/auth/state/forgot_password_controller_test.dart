import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/auth/auth.dart';

import '../support/auth_test_harness.dart';

void main() {
  late FakeAuthRepository repo;
  late ForgotPasswordController controller;

  setUp(() {
    repo = FakeAuthRepository();
    controller = ForgotPasswordController(
      repository: repo,
      initialCooldown: const Duration(seconds: 60),
      subsequentCooldown: const Duration(seconds: 30),
    );
  });

  tearDown(() => controller.dispose());

  group('ForgotPasswordController - Gửi Link đặt lại mật khẩu', () {
    test('email rỗng hoặc sai định dạng: báo lỗi và không gọi repo', () async {
      controller.emailController.text = 'invalid_email';
      final result = await controller.sendResetLink();

      expect(result.outcome, ForgotPasswordOutcome.invalid);
      expect(controller.state.showErrors, isTrue);
      expect(controller.state.emailError, isNotNull);
      expect(repo.calls, isEmpty);
    });

    test('email đúng: gọi sendPasswordResetEmail, bật emailSent và cooldown 60s', () async {
      controller.emailController.text = 'user@gmail.com';
      final result = await controller.sendResetLink();

      expect(result.outcome, ForgotPasswordOutcome.linkSent);
      expect(repo.calls, ['sendPasswordResetEmail']);
      expect(repo.lastEmail, 'user@gmail.com');
      expect(controller.state.emailSent, isTrue);
      expect(controller.state.resendCount, 1);
      expect(controller.state.remainingCooldown.inSeconds, 60);
      expect(controller.state.canResend, isFalse);
    });

    test('lỗi mạng khi gửi link: hiển thị generalError', () async {
      controller.emailController.text = 'user@gmail.com';
      repo.failWith(
        'sendPasswordResetEmail',
        const AuthFailure(AuthFailureCode.network, 'Lỗi mạng.'),
      );

      final result = await controller.sendResetLink();
      expect(result.outcome, ForgotPasswordOutcome.failed);
      expect(controller.state.generalError, 'Lỗi mạng.');
      expect(controller.state.emailSent, isFalse);
    });
  });

  group('ForgotPasswordController - Rate limit Resend link', () {
    test('khi đang trong thời gian đếm ngược thì canResend là false', () async {
      controller.emailController.text = 'user@gmail.com';
      await controller.sendResetLink();

      expect(controller.state.canResend, isFalse);

      final resendResult = await controller.resendResetLink();
      expect(resendResult.outcome, ForgotPasswordOutcome.busy);
      expect(repo.count('sendPasswordResetEmail'), 1);
    });

    test('lần gửi lại sau (lần 2) thời gian đếm ngược chuyển thành 30 giây', () async {
      final fastController = ForgotPasswordController(
        repository: repo,
        initialCooldown: Duration.zero,
        subsequentCooldown: const Duration(seconds: 30),
      );
      addTearDown(fastController.dispose);

      fastController.emailController.text = 'user@gmail.com';
      await fastController.sendResetLink();

      expect(fastController.state.canResend, isTrue);

      final resendResult = await fastController.resendResetLink();
      expect(resendResult.outcome, ForgotPasswordOutcome.resendSuccess);
      expect(repo.count('sendPasswordResetEmail'), 2);
      expect(fastController.state.resendCount, 2);
      expect(fastController.state.remainingCooldown.inSeconds, 30);
      expect(fastController.state.canResend, isFalse);
    });

    test('changeEmail đặt lại emailSent và huỷ đếm ngược', () async {
      controller.emailController.text = 'user@gmail.com';
      await controller.sendResetLink();
      expect(controller.state.emailSent, isTrue);

      controller.changeEmail();
      expect(controller.state.emailSent, isFalse);
      expect(controller.state.remainingCooldown, Duration.zero);
    });
  });
}
