import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/auth/auth.dart';
import 'package:plant_flower_mobile/features/auth/state/login_controller.dart';
import 'package:plant_flower_mobile/features/auth/state/login_gate_controller.dart';
import 'package:plant_flower_mobile/features/auth/state/login_state.dart';

import '../support/auth_test_harness.dart';

void main() {
  late FakeAuthRepository repo;
  late LoginController c;

  setUp(() {
    repo = FakeAuthRepository();
    c = LoginController(repository: repo);
  });
  tearDown(() => c.dispose());

  group('LoginState', () {
    test('copyWith giữ nguyên, đặt và xoá lỗi (null) đúng', () {
      const base = LoginState(identifierError: 'a', passwordError: 'b');
      expect(base.copyWith().identifierError, 'a');
      expect(base.copyWith(identifierError: null).identifierError, isNull);
      expect(base.copyWith(identifierError: null).passwordError, 'b');
      expect(base.copyWith(passwordError: 'c').passwordError, 'c');
    });

    test('isBusy là hợp của ba cờ đang chạy', () {
      expect(const LoginState().isBusy, isFalse);
      expect(const LoginState(isSubmitting: true).isBusy, isTrue);
      expect(const LoginState(isSendingOtp: true).isBusy, isTrue);
      expect(const LoginState(isGoogleLoading: true).isBusy, isTrue);
    });
  });

  group('LoginController.submit', () {
    test('trống: invalid, đặt lỗi cả hai ô, không gọi repo', () async {
      final result = await c.submit();
      expect(result.status, LoginResultStatus.invalid);
      expect(
        c.state.identifierError,
        'Vui lòng nhập số điện thoại hoặc email.',
      );
      expect(c.state.passwordError, 'Vui lòng nhập mật khẩu.');
      expect(repo.calls, isEmpty);
    });

    test('chỉ hiện lỗi sau lần submit đầu, rồi cập nhật realtime', () async {
      c.identifierController.text = 'abc';
      c.onIdentifierChanged('abc');
      expect(c.state.identifierError, isNull); // chưa submit

      await c.submit();
      expect(c.state.identifierError, isNotNull);

      c.identifierController.text = 'a@b.vn';
      c.onIdentifierChanged('a@b.vn');
      expect(c.state.identifierError, isNull);
      expect(c.state.passwordError, isNotNull);
    });

    test('thành công: email được trim, mật khẩu giữ nguyên', () async {
      c.identifierController.text = ' a@b.vn ';
      c.passwordController.text = ' pw ';
      final result = await c.submit();

      expect(result.status, LoginResultStatus.success);
      expect(repo.lastEmail, 'a@b.vn');
      expect(repo.lastPassword, ' pw ');
      expect(c.state.isSubmitting, isFalse);
    });

    test('sai mật khẩu: failure kèm câu tiếng Việt', () async {
      c.identifierController.text = 'a@b.vn';
      c.passwordController.text = MockAuthRepository.wrongPassword;
      final result = await c.submit();

      expect(result.status, LoginResultStatus.failure);
      expect(result.message, 'Email hoặc mật khẩu không đúng.');
      expect(c.state.isSubmitting, isFalse);
    });

    test('lỗi lạ: LoginResult.unknown', () async {
      repo.failWith('signInWithPassword', StateError('x'));
      c.identifierController.text = 'a@b.vn';
      c.passwordController.text = 'p';
      final result = await c.submit();

      expect(result.status, LoginResultStatus.failure);
      expect(result.message, 'Đã có lỗi xảy ra. Vui lòng thử lại sau.');
    });

    test('đang bận thì lần gọi sau bị bỏ qua', () async {
      final blocker = repo.block('signInWithPassword');
      c.identifierController.text = 'a@b.vn';
      c.passwordController.text = 'p';

      final first = c.submit();
      await Future<void>.delayed(Duration.zero);
      expect(c.state.isSubmitting, isTrue);
      expect((await c.submit()).status, LoginResultStatus.ignored);
      expect((await c.sendOtp()).status, LoginResultStatus.ignored);
      expect((await c.signInWithGoogle()).status, LoginResultStatus.ignored);

      blocker.complete();
      expect((await first).status, LoginResultStatus.success);
      expect(repo.calls, ['signInWithPassword']);
    });

    test('togglePasswordVisibility đảo trạng thái che', () {
      expect(c.state.obscurePassword, isTrue);
      c.togglePasswordVisibility();
      expect(c.state.obscurePassword, isFalse);
      c.togglePasswordVisibility();
      expect(c.state.obscurePassword, isTrue);
    });
  });

  group('LoginController.sendOtp', () {
    test('chỉ validate ô định danh (bỏ qua mật khẩu trống)', () async {
      c.identifierController.text = 'a@b.vn';
      final result = await c.sendOtp();

      expect(result.status, LoginResultStatus.success);
      expect(c.state.passwordError, isNull);
      expect(repo.calls, ['sendLoginOtp']);
      expect(c.state.isSendingOtp, isFalse);
    });

    test('email sai: invalid, không gọi repo', () async {
      c.identifierController.text = '0912345678';
      final result = await c.sendOtp();

      expect(result.status, LoginResultStatus.invalid);
      expect(
        c.state.identifierError,
        'Đăng nhập bằng số điện thoại chưa được hỗ trợ, vui lòng dùng email.',
      );
      expect(repo.calls, isEmpty);
    });

    test('lỗi từ server: failure kèm message', () async {
      repo.failWith(
        'sendLoginOtp',
        const AuthFailure(AuthFailureCode.rateLimited, 'Quá nhanh.'),
      );
      c.identifierController.text = 'a@b.vn';
      final result = await c.sendOtp();

      expect(result.status, LoginResultStatus.failure);
      expect(result.message, 'Quá nhanh.');
    });
  });

  group('Google', () {
    test('thành công', () async {
      expect((await c.signInWithGoogle()).status, LoginResultStatus.success);
      expect(c.state.isGoogleLoading, isFalse);
    });

    test('cancelled -> ignored (không báo lỗi)', () async {
      repo.failWith(
        'signInWithGoogle',
        const AuthFailure(AuthFailureCode.cancelled, 'x'),
      );
      expect((await c.signInWithGoogle()).status, LoginResultStatus.ignored);
    });

    test('lỗi mạng -> failure', () async {
      repo.failWith('signInWithGoogle', AuthFailure.network);
      final result = await c.signInWithGoogle();
      expect(result.status, LoginResultStatus.failure);
      expect(result.message, AuthFailure.network.message);
    });
  });

  group('dispose', () {
    test('hoàn tất request sau dispose không ném lỗi', () async {
      final other = LoginController(repository: repo);
      final blocker = repo.block('signInWithPassword');
      other.identifierController.text = 'a@b.vn';
      other.passwordController.text = 'p';
      final pending = other.submit();
      await Future<void>.delayed(Duration.zero);

      other.dispose();
      blocker.complete();
      await expectLater(pending, completes);
    });
  });

  group('LoginGateController', () {
    test('Google thành công / huỷ / lỗi / chặn bấm đôi', () async {
      final gate = LoginGateController(repository: repo);
      expect((await gate.signInWithGoogle()).status, LoginResultStatus.success);
      expect(gate.isGoogleLoading, isFalse);

      repo.failWith(
        'signInWithGoogle',
        const AuthFailure(AuthFailureCode.cancelled, 'x'),
      );
      expect((await gate.signInWithGoogle()).status, LoginResultStatus.ignored);

      repo.failWith('signInWithGoogle', AuthFailure.network);
      final failed = await gate.signInWithGoogle();
      expect(failed.status, LoginResultStatus.failure);
      expect(failed.message, AuthFailure.network.message);

      repo.failWith('signInWithGoogle', StateError('x'));
      expect(
        (await gate.signInWithGoogle()).message,
        'Đã có lỗi xảy ra. Vui lòng thử lại sau.',
      );

      final blocker = repo.block('signInWithGoogle');
      repo.failWith('signInWithGoogle', StateError('bỏ'));
      final first = gate.signInWithGoogle();
      await Future<void>.delayed(Duration.zero);
      expect(gate.isGoogleLoading, isTrue);
      expect((await gate.signInWithGoogle()).status, LoginResultStatus.ignored);
      blocker.complete();
      await first;
      gate.dispose();
    });
  });
}
