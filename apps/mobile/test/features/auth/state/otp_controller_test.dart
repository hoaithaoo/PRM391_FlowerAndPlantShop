import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/auth/auth.dart';
import 'package:plant_flower_mobile/features/auth/state/otp_controller.dart';
import 'package:plant_flower_mobile/features/auth/state/otp_state.dart';

import '../support/auth_test_harness.dart';

const _email = 'a@b.vn';

OtpController make(
  FakeAuthRepository repo, {
  OtpPurpose purpose = OtpPurpose.login,
  Duration cooldown = const Duration(seconds: 60),
}) {
  return OtpController(
    repository: repo,
    email: _email,
    purpose: purpose,
    resendCooldown: cooldown,
  );
}

void main() {
  group('OtpState', () {
    test('countdownLabel làm tròn lên theo giây và định dạng mm:ss', () {
      String label(Duration d) => OtpState(remaining: d).countdownLabel;
      expect(label(const Duration(seconds: 60)), '01:00');
      expect(label(const Duration(seconds: 44)), '00:44');
      expect(label(const Duration(milliseconds: 59200)), '01:00');
      expect(label(const Duration(milliseconds: 500)), '00:01');
      expect(label(Duration.zero), '00:00');
    });

    test('isComplete / canSubmit / canResend', () {
      expect(const OtpState(code: '12345').isComplete, isFalse);
      expect(const OtpState(code: '123456').isComplete, isTrue);
      expect(const OtpState(code: '123456').canSubmit, isTrue);
      expect(
        const OtpState(code: '123456', isVerifying: true).canSubmit,
        isFalse,
      );
      expect(const OtpState().canResend, isTrue); // remaining = 0
      expect(
        const OtpState(remaining: Duration(seconds: 1)).canResend,
        isFalse,
      );
      expect(const OtpState(isResending: true).canResend, isFalse);
    });
  });

  group('OtpController', () {
    testWidgets('setCode chỉ giữ chữ số, tối đa 6, và xoá cờ lỗi', (
      tester,
    ) async {
      final c = make(FakeAuthRepository());
      c.setCode('12a3-4');
      expect(c.state.code, '1234');
      c.setCode('1234567890');
      expect(c.state.code, '123456');
      c.setCode('');
      expect(c.state.code, '');
      c.dispose();
    });

    testWidgets('đếm ngược tới 0 rồi dừng, canResend bật', (tester) async {
      final c = make(
        FakeAuthRepository(),
        cooldown: const Duration(seconds: 3),
      );
      expect(c.state.remaining, const Duration(seconds: 3));
      expect(c.state.canResend, isFalse);

      await tester.pump(const Duration(seconds: 1));
      expect(c.state.countdownLabel, '00:02');
      await tester.pump(const Duration(seconds: 2));
      expect(c.state.remaining, Duration.zero);
      expect(c.state.canResend, isTrue);
      await tester.pump(const Duration(seconds: 5));
      expect(c.state.remaining, Duration.zero); // không âm
      c.dispose();
    });

    testWidgets('cooldown = 0: gửi lại được ngay, không tạo timer', (
      tester,
    ) async {
      final c = make(FakeAuthRepository(), cooldown: Duration.zero);
      expect(c.state.canResend, isTrue);
      c.dispose();
    });

    testWidgets('verify chưa đủ 6 số -> invalid, không gọi repo', (
      tester,
    ) async {
      final repo = FakeAuthRepository();
      final c = make(repo)..setCode('123');
      final result = await resolve(tester, c.verify());

      expect(result.status, OtpResultStatus.invalid);
      expect(result.message, 'Vui lòng nhập đủ 6 chữ số của mã OTP.');
      expect(repo.calls, isEmpty);
      c.dispose();
    });

    testWidgets('verify đúng -> success, truyền email/token/purpose', (
      tester,
    ) async {
      final repo = FakeAuthRepository();
      final c = make(repo, purpose: OtpPurpose.signup)..setCode('123456');
      final result = await resolve(tester, c.verify());

      expect(result.status, OtpResultStatus.success);
      expect(repo.lastEmail, _email);
      expect(repo.lastToken, '123456');
      expect(repo.lastPurpose, OtpPurpose.signup);
      expect(c.state.isVerifying, isFalse);
      c.dispose();
    });

    testWidgets('verify sai -> failure, xoá mã và bật hasError', (
      tester,
    ) async {
      final repo = FakeAuthRepository();
      final c = make(repo)..setCode('000000');
      final result = await resolve(tester, c.verify());

      expect(result.status, OtpResultStatus.failure);
      expect(result.message, 'Mã OTP không đúng hoặc đã hết hạn.');
      expect(c.state.code, '');
      expect(c.state.hasError, isTrue);
      expect(c.state.isVerifying, isFalse);

      c.setCode('1');
      expect(c.state.hasError, isFalse);
      c.dispose();
    });

    testWidgets('verify gặp lỗi lạ -> câu chung, vẫn dọn trạng thái', (
      tester,
    ) async {
      final repo = FakeAuthRepository()..failWith('verifyOtp', StateError('x'));
      final c = make(repo)..setCode('123456');
      final result = await resolve(tester, c.verify());

      expect(result.status, OtpResultStatus.failure);
      expect(result.message, 'Đã có lỗi xảy ra. Vui lòng thử lại sau.');
      expect(c.state.isVerifying, isFalse);
      c.dispose();
    });

    testWidgets('verify lần hai khi đang chạy bị bỏ qua', (tester) async {
      final repo = FakeAuthRepository();
      final blocker = repo.block('verifyOtp');
      final c = make(repo)..setCode('123456');

      final first = c.verify();
      await tester.pump();
      expect(c.state.isVerifying, isTrue);
      final second = await resolve(tester, c.verify());
      expect(second.status, OtpResultStatus.ignored);

      blocker.complete();
      expect((await resolve(tester, first)).status, OtpResultStatus.success);
      expect(repo.count('verifyOtp'), 1);
      c.dispose();
    });

    testWidgets('resend trước khi hết cooldown bị bỏ qua', (tester) async {
      final repo = FakeAuthRepository();
      final c = make(repo);
      final result = await resolve(tester, c.resend());

      expect(result.status, OtpResultStatus.ignored);
      expect(repo.calls, isEmpty);
      c.dispose();
    });

    testWidgets('resend sau cooldown: gọi repo và đếm lại từ đầu', (
      tester,
    ) async {
      final repo = FakeAuthRepository();
      final c = make(repo, cooldown: const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 5));
      expect(c.state.canResend, isTrue);

      final result = await resolve(tester, c.resend());
      expect(result.status, OtpResultStatus.success);
      expect(repo.calls, ['resendOtp']);
      expect(c.state.remaining, const Duration(seconds: 5));
      expect(c.state.canResend, isFalse);
      expect(c.state.isResending, isFalse);

      await tester.pump(const Duration(seconds: 5));
      expect(c.state.canResend, isTrue);
      c.dispose();
    });

    testWidgets('resend thất bại: báo lỗi, vẫn gửi lại được', (tester) async {
      final repo = FakeAuthRepository()
        ..failWith(
          'resendOtp',
          const AuthFailure(AuthFailureCode.rateLimited, 'Quá nhanh.'),
        );
      final c = make(repo, cooldown: Duration.zero);
      final result = await resolve(tester, c.resend());

      expect(result.status, OtpResultStatus.failure);
      expect(result.message, 'Quá nhanh.');
      expect(c.state.canResend, isTrue);
      c.dispose();
    });

    testWidgets('resend lần hai khi đang gửi bị bỏ qua', (tester) async {
      final repo = FakeAuthRepository();
      final blocker = repo.block('resendOtp');
      final c = make(repo, cooldown: Duration.zero);

      final first = c.resend();
      await tester.pump();
      expect(
        (await resolve(tester, c.resend())).status,
        OtpResultStatus.ignored,
      );
      blocker.complete();
      await resolve(tester, first);
      expect(repo.count('resendOtp'), 1);
      c.dispose();
    });

    testWidgets('dispose huỷ timer: thời gian trôi tiếp không phát sinh lỗi', (
      tester,
    ) async {
      final c = make(FakeAuthRepository());
      c.dispose();
      await tester.pump(const Duration(seconds: 120));
      expect(tester.takeException(), isNull);
    });

    testWidgets('dispose khi verify đang chạy rồi hoàn tất: không ném lỗi', (
      tester,
    ) async {
      final repo = FakeAuthRepository();
      final blocker = repo.block('verifyOtp');
      final c = make(repo)..setCode('123456');
      final pending = c.verify();
      await tester.pump();

      c.dispose();
      blocker.complete();
      await resolve(tester, pending);
      expect(tester.takeException(), isNull);
    });
  });
}
