import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/auth/auth.dart';
import 'package:plant_flower_mobile/features/auth/state/register_controller.dart';
import 'package:plant_flower_mobile/features/auth/state/register_state.dart';

import '../support/auth_test_harness.dart';

const _validAddress = '470 An Dương Vương, P. An Lạc, Bình Tân, TP.HCM';

void main() {
  late FakeAuthRepository repo;
  late RegisterController c;

  void fillValid({String email = 'phuongha@gmail.com'}) {
    c.textOf(RegisterField.fullName).text = 'Nguyễn Phương Hà';
    c.textOf(RegisterField.phone).text = '0912345678';
    c.textOf(RegisterField.email).text = email;
    c.textOf(RegisterField.address).text = _validAddress;
    c.textOf(RegisterField.password).text = 'Hoa@12345';
    c.textOf(RegisterField.confirmPassword).text = 'Hoa@12345';
    c.toggleAgreement();
  }

  setUp(() {
    repo = FakeAuthRepository();
    c = RegisterController(repository: repo);
  });
  tearDown(() => c.dispose());

  group('RegisterState / RegisterErrors', () {
    test('form trống: 7 lỗi (6 ô + checkbox) nhưng chưa hiện layout lỗi', () {
      final state = c.state;
      expect(state.errors.count, 7);
      expect(state.errors.hasAny, isTrue);
      expect(state.showErrors, isFalse);
      expect(state.showErrorLayout, isFalse);
    });

    test('keyName khớp hậu tố key của UI', () {
      expect(RegisterField.fullName.keyName, 'full_name');
      expect(RegisterField.confirmPassword.keyName, 'confirm_password');
    });

    test('dữ liệu y hệt thiết kế lỗi: 6 lỗi, địa chỉ hợp lệ', () {
      c.textOf(RegisterField.fullName).text = 'Phương Hà 123@#';
      c.textOf(RegisterField.phone).text = '0912-abc-xyz';
      c.textOf(RegisterField.email).text = 'phuongha.fleuré@domain';
      c.textOf(RegisterField.address).text = _validAddress;
      c.textOf(RegisterField.password).text = 'hoa12345';
      c.textOf(RegisterField.confirmPassword).text = 'Hoa@12345';

      final errors = c.state.errors;
      expect(errors.count, 6);
      expect(errors.address, isNull);
      expect(errors.of(RegisterField.fullName), isNotNull);
      expect(errors.of(RegisterField.address), isNull);
      expect(errors.agreement, isNotNull);
    });

    test('nội dung ô nhập được đồng bộ vào state', () {
      c.textOf(RegisterField.email).text = 'a@b.vn';
      expect(c.state.email, 'a@b.vn');
    });
  });

  group('submit', () {
    test('còn lỗi: invalid, bật layout lỗi, không gọi repo', () async {
      final result = await c.submit();
      expect(result.outcome, RegisterOutcome.invalid);
      expect(c.state.showErrors, isTrue);
      expect(c.state.showErrorLayout, isTrue);
      expect(repo.calls, isEmpty);
    });

    test(
      'hợp lệ: signUp với dữ liệu đã trim, trả needsEmailVerification',
      () async {
        fillValid(email: ' phuongha@gmail.com ');
        c.textOf(RegisterField.fullName).text = '  Nguyễn Phương Hà  ';
        final result = await c.submit();

        expect(result.outcome, RegisterOutcome.needsEmailVerification);
        expect(result.email, 'phuongha@gmail.com');
        expect(repo.lastSignUp!.fullName, 'Nguyễn Phương Hà');
        expect(repo.lastSignUp!.email, 'phuongha@gmail.com');
        expect(repo.lastSignUp!.password, 'Hoa@12345');
        expect(c.state.isSubmitting, isFalse);
        expect(c.state.showErrorLayout, isFalse);
      },
    );

    test('signUp trả signedIn', () async {
      repo.forcedSignUpResult = SignUpResult.signedIn;
      fillValid();
      expect((await c.submit()).outcome, RegisterOutcome.signedIn);
    });

    test(
      'email đã tồn tại: failed kèm message, trở lại trạng thái rảnh',
      () async {
        fillValid(email: MockAuthRepository.existingEmail);
        final result = await c.submit();

        expect(result.outcome, RegisterOutcome.failed);
        expect(
          result.message,
          'Email này đã được đăng ký. Vui lòng đăng nhập.',
        );
        expect(c.state.isSubmitting, isFalse);
        expect(c.state.showErrorLayout, isFalse);
      },
    );

    test('đang gửi thì submit/Google lần sau bị bỏ qua', () async {
      final blocker = repo.block('signUp');
      fillValid();
      final first = c.submit();
      await Future<void>.delayed(Duration.zero);

      expect(c.state.isSubmitting, isTrue);
      expect((await c.submit()).outcome, RegisterOutcome.busy);
      expect(await c.signInWithGoogle(), isNull);
      expect(repo.calls, ['signUp']);

      blocker.complete();
      expect((await first).outcome, RegisterOutcome.needsEmailVerification);
    });
  });

  group('showErrors tự tắt khi hết lỗi', () {
    test(
      'sửa hết lỗi: về layout thường; xóa một ô sau đó không bật lại lỗi',
      () async {
        await c.submit();
        expect(c.state.showErrorLayout, isTrue);

        fillValid();
        expect(c.state.errors.hasAny, isFalse);
        expect(c.state.showErrors, isFalse);
        expect(c.state.showErrorLayout, isFalse);

        c.textOf(RegisterField.email).text = '';
        expect(c.state.errors.hasAny, isTrue);
        expect(c.state.showErrors, isFalse);
        expect(c.state.showErrorLayout, isFalse);
      },
    );

    test('lỗi chỉ hiện lại ở lần submit kế tiếp', () async {
      await c.submit();
      fillValid();
      c.textOf(RegisterField.email).text = 'sai';
      expect(c.state.showErrorLayout, isFalse);

      final result = await c.submit();
      expect(result.outcome, RegisterOutcome.invalid);
      expect(c.state.showErrors, isTrue);
      expect(c.state.showErrorLayout, isTrue);
    });

    test('đang ở layout lỗi: lỗi vẫn cập nhật realtime', () async {
      await c.submit();
      c.textOf(RegisterField.fullName).text = 'Hà';
      expect(c.state.showErrorLayout, isTrue);
      expect(c.state.errors.count, 6);
    });

    test('Google và submit lỗi lạ trả câu chung', () async {
      repo.failWith('signInWithGoogle', StateError('boom'));
      expect(await c.signInWithGoogle(), AuthFailure.unknown.message);
      expect(c.state.isGoogleLoading, isFalse);

      fillValid();
      repo.failWith('signUp', StateError('boom'));
      final result = await c.submit();
      expect(result.outcome, RegisterOutcome.failed);
      expect(result.message, AuthFailure.unknown.message);
      expect(c.state.isSubmitting, isFalse);
    });
  });

  group('Google và công tắc', () {
    test('Google thành công trả null', () async {
      expect(await c.signInWithGoogle(), isNull);
      expect(c.state.isGoogleLoading, isFalse);
    });

    test('Google lỗi trả message; huỷ trả null', () async {
      repo.failWith('signInWithGoogle', AuthFailure.network);
      expect(await c.signInWithGoogle(), AuthFailure.network.message);

      repo.failWith(
        'signInWithGoogle',
        const AuthFailure(AuthFailureCode.cancelled, 'x'),
      );
      expect(await c.signInWithGoogle(), isNull);
    });

    test('toggleAgreement và hai công tắc mắt', () {
      expect(c.state.agreed, isFalse);
      c.toggleAgreement();
      expect(c.state.agreed, isTrue);

      expect(c.state.obscurePassword, isTrue);
      expect(c.state.obscureConfirmPassword, isTrue);
      c.toggleObscurePassword();
      expect(c.state.obscurePassword, isFalse);
      expect(c.state.obscureConfirmPassword, isTrue);
      c.toggleObscureConfirmPassword();
      expect(c.state.obscureConfirmPassword, isFalse);
    });
  });

  test('dispose khi đang gửi rồi hoàn tất: không ném lỗi', () async {
    final other = RegisterController(repository: repo);
    final blocker = repo.block('signUp');
    other.textOf(RegisterField.fullName).text = 'Nguyễn Phương Hà';
    other.textOf(RegisterField.phone).text = '0912345678';
    other.textOf(RegisterField.email).text = 'a@b.vn';
    other.textOf(RegisterField.address).text = _validAddress;
    other.textOf(RegisterField.password).text = 'Hoa@12345';
    other.textOf(RegisterField.confirmPassword).text = 'Hoa@12345';
    other.toggleAgreement();
    final pending = other.submit();
    await Future<void>.delayed(Duration.zero);

    other.dispose();
    blocker.complete();
    await expectLater(pending, completes);
  });
}
