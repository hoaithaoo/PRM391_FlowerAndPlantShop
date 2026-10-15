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

  group('verifyOtp', () {
    test('mã đúng 123456 -> đăng nhập (cả login lẫn signup)', () async {
      await repository.verifyOtp(
        email: 'a@b.vn',
        token: '123456',
        purpose: OtpPurpose.login,
      );
      expect(repository.isSignedIn, isTrue);

      await repository.signOut();
      await repository.verifyOtp(
        email: 'a@b.vn',
        token: MockAuthRepository.validOtp,
        purpose: OtpPurpose.signup,
      );
      expect(repository.isSignedIn, isTrue);
    });

    test('mã sai -> AuthFailure invalidOtp, không đăng nhập', () async {
      await expectFailure(
        () => repository.verifyOtp(
          email: 'a@b.vn',
          token: '000000',
          purpose: OtpPurpose.login,
        ),
        AuthFailureCode.invalidOtp,
      );
      expect(repository.isSignedIn, isFalse);
    });

    test('mã rỗng cũng bị từ chối', () async {
      await expectFailure(
        () => repository.verifyOtp(
          email: 'a@b.vn',
          token: '',
          purpose: OtpPurpose.signup,
        ),
        AuthFailureCode.invalidOtp,
      );
    });
  });

  group('sendLoginOtp / resendOtp', () {
    test('hoàn tất không lỗi và không đăng nhập', () async {
      await repository.sendLoginOtp(email: 'a@b.vn');
      await repository.resendOtp(email: 'a@b.vn', purpose: OtpPurpose.login);
      await repository.resendOtp(email: 'a@b.vn', purpose: OtpPurpose.signup);
      expect(repository.isSignedIn, isFalse);
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
