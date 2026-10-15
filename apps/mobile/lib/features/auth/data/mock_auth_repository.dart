import 'dart:async';

import '../models/auth_models.dart';
import 'auth_failure.dart';
import 'auth_repository.dart';

/// Repository giả lập dùng khi chưa cấu hình Supabase (chạy demo) và trong test.
///
/// Quy ước demo:
/// - Mật khẩu [wrongPassword] luôn bị từ chối, mật khẩu khác đều đăng nhập được.
/// - Mã OTP đúng là [validOtp].
/// - Email [existingEmail] coi như đã được đăng ký.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository({this.delay = const Duration(milliseconds: 600)});

  static const validOtp = '123456';
  static const wrongPassword = 'wrong-password';
  static const existingEmail = 'existing@fleure.vn';

  final Duration delay;
  final _signedIn = StreamController<bool>.broadcast();
  bool _isSignedIn = false;

  @override
  bool get isSignedIn => _isSignedIn;

  @override
  Stream<bool> get signedInChanges => _signedIn.stream;

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(delay);
    if (password == wrongPassword) {
      throw const AuthFailure(
        AuthFailureCode.invalidCredentials,
        'Email hoặc mật khẩu không đúng.',
      );
    }
    _setSignedIn(true);
  }

  @override
  Future<void> signInWithGoogle() async {
    await Future<void>.delayed(delay);
    _setSignedIn(true);
  }

  @override
  Future<void> sendLoginOtp({required String email}) async {
    await Future<void>.delayed(delay);
  }

  @override
  Future<void> verifyOtp({
    required String email,
    required String token,
    required OtpPurpose purpose,
  }) async {
    await Future<void>.delayed(delay);
    if (token != validOtp) {
      throw const AuthFailure(
        AuthFailureCode.invalidOtp,
        'Mã OTP không đúng hoặc đã hết hạn.',
      );
    }
    _setSignedIn(true);
  }

  @override
  Future<void> resendOtp({
    required String email,
    required OtpPurpose purpose,
  }) async {
    await Future<void>.delayed(delay);
  }

  @override
  Future<SignUpResult> signUp(RegisterRequest request) async {
    await Future<void>.delayed(delay);
    if (request.email.trim().toLowerCase() == existingEmail) {
      throw const AuthFailure(
        AuthFailureCode.userAlreadyExists,
        'Email này đã được đăng ký. Vui lòng đăng nhập.',
      );
    }
    return SignUpResult.needsEmailVerification;
  }

  @override
  Future<void> signOut() async {
    _setSignedIn(false);
  }

  void _setSignedIn(bool value) {
    _isSignedIn = value;
    _signedIn.add(value);
  }

  Future<void> dispose() => _signedIn.close();
}
