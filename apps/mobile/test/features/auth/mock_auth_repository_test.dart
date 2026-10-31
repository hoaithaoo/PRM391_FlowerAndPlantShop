import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/auth/auth.dart';

void main() {
  late MockAuthRepository repository;

  setUp(() => repository = MockAuthRepository(delay: Duration.zero));
  tearDown(() => repository.dispose());

  Future<void> expectFailure(
    Future<void> Function() action,
    AuthFailureCode code,
  ) async {
    await expectLater(
      action(),
      throwsA(isA<AuthFailure>().having((e) => e.code, 'code', code)),
    );
  }

  group('signInWithPassword', () {
    test('mật khẩu đúng -> đăng nhập, isSignedIn = true', () async {
      expect(repository.isSignedIn, isFalse);
      await repository.signInWithPassword(
        email: 'a@b.vn',
        password: 'Hoa@12345',
      );
      expect(repository.isSignedIn, isTrue);
    });

    test('wrong-password -> invalidCredentials, không đăng nhập', () async {
      await expectFailure(
        () => repository.signInWithPassword(
          email: 'a@b.vn',
          password: MockAuthRepository.wrongPassword,
        ),
        AuthFailureCode.invalidCredentials,
      );
      expect(repository.isSignedIn, isFalse);
    });

    test('lỗi mang câu tiếng Việt để hiển thị', () async {
      try {
        await repository.signInWithPassword(
          email: 'a@b.vn',
          password: 'wrong-password',
        );
        fail('phải ném AuthFailure');
      } on AuthFailure catch (e) {
        expect(e.message, 'Email hoặc mật khẩu không đúng.');
      }
    });
  });

  group('signedInChanges', () {
    test('đăng nhập phát true, đăng xuất phát false', () async {
      final events = <bool>[];
      final sub = repository.signedInChanges.listen(events.add);

      await repository.signInWithPassword(email: 'a@b.vn', password: 'x');
      await repository.signOut();
      await Future<void>.delayed(Duration.zero);

      expect(events, [true, false]);
      await sub.cancel();
    });

    test('đăng nhập sai không phát sự kiện', () async {
      final events = <bool>[];
      final sub = repository.signedInChanges.listen(events.add);

      await expectFailure(
        () => repository.signInWithPassword(
          email: 'a@b.vn',
          password: MockAuthRepository.wrongPassword,
        ),
        AuthFailureCode.invalidCredentials,
      );
      await Future<void>.delayed(Duration.zero);

      expect(events, isEmpty);
      await sub.cancel();
    });

    test('là broadcast stream: nhiều listener cùng nhận', () async {
      final a = <bool>[];
      final b = <bool>[];
      final subA = repository.signedInChanges.listen(a.add);
      final subB = repository.signedInChanges.listen(b.add);

      await repository.signInWithGoogle();
      await Future<void>.delayed(Duration.zero);

      expect(a, [true]);
      expect(b, [true]);
      await subA.cancel();
      await subB.cancel();
    });
  });

  group('signInWithGoogle', () {
    test('đăng nhập thành công', () async {
      await repository.signInWithGoogle();
      expect(repository.isSignedIn, isTrue);
    });
  });

  group('resendSignupEmail', () {
    test('hoàn tất không lỗi và không đăng nhập', () async {
      await repository.resendSignupEmail(email: 'a@b.vn');
      await repository.resendSignupEmail(email: 'a@b.vn');
      expect(repository.isSignedIn, isFalse);
    });

    test('không phát sự kiện signedInChanges', () async {
      final events = <bool>[];
      final sub = repository.signedInChanges.listen(events.add);
      await repository.resendSignupEmail(email: 'a@b.vn');
      await Future<void>.delayed(Duration.zero);
      expect(events, isEmpty);
      await sub.cancel();
    });
  });

  group('simulateEmailConfirmed', () {
    test('đặt isSignedIn = true và phát true', () async {
      final events = <bool>[];
      final sub = repository.signedInChanges.listen(events.add);

      repository.simulateEmailConfirmed();
      await Future<void>.delayed(Duration.zero);

      expect(repository.isSignedIn, isTrue);
      expect(events, [true]);
      await sub.cancel();
    });

    test('sau đó signOut phát false', () async {
      final events = <bool>[];
      final sub = repository.signedInChanges.listen(events.add);

      repository.simulateEmailConfirmed();
      await repository.signOut();
      await Future<void>.delayed(Duration.zero);

      expect(events, [true, false]);
      expect(repository.isSignedIn, isFalse);
      await sub.cancel();
    });
  });

  group('signUp', () {
    RegisterRequest request(String email) => RegisterRequest(
      fullName: 'Nguyễn Phương Hà',
      phone: '0912345678',
      email: email,
      address: '470 An Dương Vương, Bình Tân',
      password: 'Hoa@12345',
    );

    test('email mới -> needsEmailVerification, chưa đăng nhập', () async {
      final result = await repository.signUp(request('new@fleure.vn'));
      expect(result, SignUpResult.needsEmailVerification);
      expect(repository.isSignedIn, isFalse);
    });

    test('email đã tồn tại -> AuthFailure userAlreadyExists', () async {
      await expectLater(
        repository.signUp(request(MockAuthRepository.existingEmail)),
        throwsA(
          isA<AuthFailure>()
              .having((e) => e.code, 'code', AuthFailureCode.userAlreadyExists)
              .having(
                (e) => e.message,
                'message',
                'Email này đã được đăng ký. Vui lòng đăng nhập.',
              ),
        ),
      );
    });

    test('email đã tồn tại: bỏ qua hoa/thường và khoảng trắng', () async {
      await expectLater(
        repository.signUp(request('  Existing@Fleure.VN ')),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.code,
            'code',
            AuthFailureCode.userAlreadyExists,
          ),
        ),
      );
    });
  });

  group('passwordRecovery', () {
    test('simulatePasswordRecovery phát true qua stream và cập nhật trạng thái', () async {
      expect(repository.isInPasswordRecovery, isFalse);
      final events = <bool>[];
      final sub = repository.passwordRecoveryChanges.listen(events.add);

      repository.simulatePasswordRecovery();
      await Future<void>.delayed(Duration.zero);

      expect(repository.isInPasswordRecovery, isTrue);
      expect(events, [true]);

      await repository.updatePassword(newPassword: 'Password@123');
      await Future<void>.delayed(Duration.zero);

      expect(repository.isInPasswordRecovery, isFalse);
      expect(events, [true, false]);
      await sub.cancel();
    });

    test('cancelPasswordRecovery đặt lại trạng thái và phát false', () async {
      repository.simulatePasswordRecovery();
      expect(repository.isInPasswordRecovery, isTrue);

      await repository.cancelPasswordRecovery();
      expect(repository.isInPasswordRecovery, isFalse);
    });

    test('sendPasswordResetEmail lưu email đã gửi', () async {
      await repository.sendPasswordResetEmail(email: 'user@fleure.vn');
      expect(repository.currentUserEmail, 'user@fleure.vn');
    });
  });

  group('signOut', () {
    test('đăng xuất sau khi đăng nhập', () async {
      await repository.signInWithGoogle();
      expect(repository.isSignedIn, isTrue);
      await repository.signOut();
      expect(repository.isSignedIn, isFalse);
    });

    test('đăng xuất khi chưa đăng nhập không lỗi', () async {
      await repository.signOut();
      expect(repository.isSignedIn, isFalse);
    });
  });

  group('AuthFailure', () {
    test('hằng network / unknown có code và câu tiếng Việt', () {
      expect(AuthFailure.network.code, AuthFailureCode.network);
      expect(
        AuthFailure.network.message,
        'Không có kết nối mạng. Vui lòng kiểm tra và thử lại.',
      );
      expect(AuthFailure.unknown.code, AuthFailureCode.unknown);
      expect(
        AuthFailure.unknown.message,
        'Đã có lỗi xảy ra. Vui lòng thử lại sau.',
      );
    });

    test('toString chứa tên code và message', () {
      expect(
        AuthFailure.unknown.toString(),
        'AuthFailure(unknown): Đã có lỗi xảy ra. Vui lòng thử lại sau.',
      );
    });
  });
}
