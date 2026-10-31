import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/auth/auth.dart';
import 'package:plant_flower_mobile/features/auth/state/email_verification_controller.dart';
import 'package:plant_flower_mobile/features/auth/state/email_verification_state.dart';

import '../support/auth_test_harness.dart';

const _email = 'phuongha@gmail.com';
const _cooldown = Duration(seconds: 60);

typedef _Create =
    EmailVerificationController Function({
      Duration cooldown,
      bool disposedByTest,
    });

/// Test dùng đồng hồ giả của `testWidgets`: `tester.pump(duration)` tua thời
/// gian để Timer của controller chạy (không cần thêm dev_dependency
/// fake_async). Controller luôn được dispose ở cuối để không rò Timer.
void _controllerTest(
  String description,
  Future<void> Function(
    WidgetTester tester,
    FakeAuthRepository repo,
    _Create create,
  )
  body,
) {
  testWidgets(description, (tester) async {
    final repo = FakeAuthRepository();
    final controllers = <EmailVerificationController>[];
    EmailVerificationController create({
      Duration cooldown = _cooldown,
      bool disposedByTest = false,
    }) {
      final c = EmailVerificationController(
        repository: repo,
        email: _email,
        resendCooldown: cooldown,
      );
      if (!disposedByTest) controllers.add(c);
      return c;
    }

    try {
      await body(tester, repo, create);
    } finally {
      for (final c in controllers) {
        c.dispose();
      }
      unawaited(repo.dispose());
    }
  });
}

void main() {
  group('EmailVerificationState', () {
    test('mặc định: không gửi, hết đếm ngược, được phép gửi lại', () {
      const state = EmailVerificationState();
      expect(state.isResending, isFalse);
      expect(state.remaining, Duration.zero);
      expect(state.canResend, isTrue);
      expect(state.remainingSeconds, 0);
    });

    test('canResend false khi còn đếm ngược hoặc đang gửi', () {
      expect(
        const EmailVerificationState(remaining: Duration(seconds: 1)).canResend,
        isFalse,
      );
      expect(
        const EmailVerificationState(isResending: true).canResend,
        isFalse,
      );
    });

    test('remainingSeconds làm tròn lên', () {
      int secs(int ms) => EmailVerificationState(
        remaining: Duration(milliseconds: ms),
      ).remainingSeconds;
      expect(secs(1), 1);
      expect(secs(999), 1);
      expect(secs(1000), 1);
      expect(secs(1001), 2);
      expect(secs(60000), 60);
    });

    test('copyWith giữ nguyên trường không truyền', () {
      const base = EmailVerificationState(
        isResending: true,
        remaining: Duration(seconds: 5),
      );
      expect(base.copyWith().isResending, isTrue);
      expect(base.copyWith().remaining, const Duration(seconds: 5));
      expect(base.copyWith(isResending: false).isResending, isFalse);
      expect(base.copyWith(remaining: Duration.zero).remaining, Duration.zero);
    });

    test('ResendResult hằng success / ignored', () {
      expect(ResendResult.success.status, ResendStatus.success);
      expect(ResendResult.success.message, isNull);
      expect(ResendResult.ignored.status, ResendStatus.ignored);
    });
  });

  group('đếm ngược', () {
    _controllerTest('bắt đầu ngay khi tạo: chưa được gửi lại', (
      tester,
      repo,
      create,
    ) async {
      final c = create();
      expect(c.email, _email);
      expect(c.state.remaining, _cooldown);
      expect(c.state.remainingSeconds, 60);
      expect(c.state.canResend, isFalse);
      expect(c.state.isResending, isFalse);
    });

    _controllerTest('giảm mỗi giây và báo listener', (
      tester,
      repo,
      create,
    ) async {
      final c = create();
      var notifications = 0;
      c.addListener(() => notifications++);

      await tester.pump(const Duration(seconds: 1));
      expect(c.state.remainingSeconds, 59);
      await tester.pump(const Duration(seconds: 1));
      expect(c.state.remainingSeconds, 58);
      expect(notifications, 2);

      await tester.pump(const Duration(seconds: 10));
      expect(c.state.remainingSeconds, 48);
    });

    _controllerTest('hết 60 giây thì canResend và dừng Timer', (
      tester,
      repo,
      create,
    ) async {
      final c = create();
      await tester.pump(const Duration(seconds: 59));
      expect(c.state.canResend, isFalse);
      expect(c.state.remainingSeconds, 1);

      await tester.pump(const Duration(seconds: 1));
      expect(c.state.remaining, Duration.zero);
      expect(c.state.canResend, isTrue);

      // Không còn Timer chạy sau khi hết: thêm thời gian không đổi gì
      var notifications = 0;
      c.addListener(() => notifications++);
      await tester.pump(const Duration(seconds: 30));
      expect(notifications, 0);
      expect(c.state.remaining, Duration.zero);
    });

    _controllerTest('cooldown ngắn tuỳ biến (3 giây)', (
      tester,
      repo,
      create,
    ) async {
      final c = create(cooldown: const Duration(seconds: 3));
      expect(c.state.remainingSeconds, 3);
      await tester.pump(const Duration(seconds: 3));
      expect(c.state.canResend, isTrue);
    });

    _controllerTest('Duration.zero: gửi lại được ngay, không có Timer', (
      tester,
      repo,
      create,
    ) async {
      final c = create(cooldown: Duration.zero);
      expect(c.state.canResend, isTrue);
      expect(c.state.remaining, Duration.zero);
    });
  });

  group('resend', () {
    _controllerTest('còn đếm ngược -> ignored, không gọi repo', (
      tester,
      repo,
      create,
    ) async {
      final c = create();
      final result = await c.resend();
      expect(result.status, ResendStatus.ignored);
      expect(result.message, isNull);
      expect(repo.calls, isEmpty);

      await tester.pump(const Duration(seconds: 59));
      expect((await c.resend()).status, ResendStatus.ignored);
      expect(repo.calls, isEmpty);
    });

    _controllerTest('thành công: gọi repo với email và đếm ngược lại', (
      tester,
      repo,
      create,
    ) async {
      final c = create();
      await tester.pump(_cooldown);
      expect(c.state.canResend, isTrue);

      final result = await resolve(tester, c.resend());

      expect(result.status, ResendStatus.success);
      expect(repo.calls, ['resendSignupEmail']);
      expect(repo.lastEmail, _email);
      expect(c.state.isResending, isFalse);
      expect(c.state.canResend, isFalse);
      // Đếm ngược bắt đầu lại từ đầu
      expect(c.state.remainingSeconds, 60);

      await tester.pump(_cooldown);
      expect(c.state.canResend, isTrue);
    });

    _controllerTest('đang gửi: isResending, lần gọi thứ hai bị ignored', (
      tester,
      repo,
      create,
    ) async {
      final blocker = repo.block('resendSignupEmail');
      final c = create(cooldown: Duration.zero);

      final first = c.resend();
      await tester.pump();
      expect(c.state.isResending, isTrue);
      expect(c.state.canResend, isFalse);

      expect((await c.resend()).status, ResendStatus.ignored);
      expect(repo.count('resendSignupEmail'), 1);

      blocker.complete();
      final result = await resolve(tester, first);
      expect(result.status, ResendStatus.success);
      expect(c.state.isResending, isFalse);
      expect(repo.count('resendSignupEmail'), 1);
    });

    _controllerTest('AuthFailure: failure kèm đúng message, không đếm lại', (
      tester,
      repo,
      create,
    ) async {
      repo.failWith(
        'resendSignupEmail',
        const AuthFailure(
          AuthFailureCode.rateLimited,
          'Bạn thao tác quá nhanh.',
        ),
      );
      final c = create(cooldown: Duration.zero);

      final result = await resolve(tester, c.resend());

      expect(result.status, ResendStatus.failure);
      expect(result.message, 'Bạn thao tác quá nhanh.');
      expect(c.state.isResending, isFalse);
      // Gửi lỗi nên không bị khoá thêm, người dùng thử lại được
      expect(c.state.canResend, isTrue);
      expect(c.state.remaining, Duration.zero);
    });

    _controllerTest('lỗi mạng: dùng câu lỗi mạng của AuthFailure', (
      tester,
      repo,
      create,
    ) async {
      repo.failWith('resendSignupEmail', AuthFailure.network);
      final c = create(cooldown: Duration.zero);

      final result = await resolve(tester, c.resend());

      expect(result.status, ResendStatus.failure);
      expect(result.message, AuthFailure.network.message);
    });

    _controllerTest('lỗi lạ: failure với câu AuthFailure.unknown', (
      tester,
      repo,
      create,
    ) async {
      repo.failWith('resendSignupEmail', StateError('boom'));
      final c = create(cooldown: Duration.zero);

      final result = await resolve(tester, c.resend());

      expect(result.status, ResendStatus.failure);
      expect(result.message, AuthFailure.unknown.message);
      expect(c.state.isResending, isFalse);
      expect(c.state.canResend, isTrue);
    });

    _controllerTest('thất bại rồi thử lại thành công thì mới đếm ngược', (
      tester,
      repo,
      create,
    ) async {
      repo.failWith('resendSignupEmail', AuthFailure.network);
      final c = create(cooldown: const Duration(seconds: 30));
      await tester.pump(const Duration(seconds: 30));

      expect((await resolve(tester, c.resend())).status, ResendStatus.failure);
      expect(c.state.canResend, isTrue);

      repo.clearFailure('resendSignupEmail');
      expect((await resolve(tester, c.resend())).status, ResendStatus.success);
      expect(repo.count('resendSignupEmail'), 2);
      expect(c.state.canResend, isFalse);
      expect(c.state.remainingSeconds, 30);
    });
  });

  group('dispose', () {
    _controllerTest('huỷ Timer: không còn thông báo sau dispose', (
      tester,
      repo,
      create,
    ) async {
      final c = create(disposedByTest: true);
      var notifications = 0;
      c.addListener(() => notifications++);
      await tester.pump(const Duration(seconds: 2));
      expect(notifications, 2);

      c.dispose();
      await tester.pump(const Duration(minutes: 2));
      expect(notifications, 2);
    });

    _controllerTest(
      'resend hoàn tất sau dispose: không ném lỗi, không bắt đầu đếm ngược',
      (tester, repo, create) async {
        final blocker = repo.block('resendSignupEmail');
        final c = create(
          cooldown: const Duration(seconds: 30),
          disposedByTest: true,
        );
        await tester.pump(const Duration(seconds: 30));
        var notifications = 0;
        c.addListener(() => notifications++);

        final pending = c.resend();
        await tester.pump();
        expect(c.state.isResending, isTrue);
        final before = notifications;

        c.dispose();
        blocker.complete();
        final result = await resolve(tester, pending);
        await tester.pump(const Duration(minutes: 1));

        expect(result.status, ResendStatus.success);
        expect(notifications, before);
        expect(tester.takeException(), isNull);
      },
    );

    _controllerTest('resend lỗi hoàn tất sau dispose: không ném lỗi', (
      tester,
      repo,
      create,
    ) async {
      final blocker = repo.block('resendSignupEmail');
      repo.failWith('resendSignupEmail', AuthFailure.network);
      final c = create(cooldown: Duration.zero, disposedByTest: true);

      final pending = c.resend();
      await tester.pump();
      c.dispose();
      blocker.complete();

      final result = await resolve(tester, pending);
      expect(result.status, ResendStatus.failure);
      expect(tester.takeException(), isNull);
    });
  });
}
