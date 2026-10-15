import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/auth_models.dart';
import 'auth_failure.dart';
import 'auth_repository.dart';

/// Hiện thực [AuthRepository] bằng Supabase Auth.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._auth);

  /// Deep link phải khai báo trong Supabase Dashboard > Redirect URLs và
  /// AndroidManifest/Info.plist (xem docs/supabase-auth.md).
  static const mobileRedirectUrl =
      'com.plantflowershop.mobile://login-callback/';

  final GoTrueClient _auth;

  @override
  bool get isSignedIn => _auth.currentSession != null;

  @override
  Stream<bool> get signedInChanges => _auth.onAuthStateChange
      .where(
        (state) =>
            state.event == AuthChangeEvent.signedIn ||
            state.event == AuthChangeEvent.signedOut,
      )
      .map((state) => state.session != null);

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _guard(
      () => _auth.signInWithPassword(email: email.trim(), password: password),
    );
  }

  @override
  Future<void> signInWithGoogle() {
    return _guard(() async {
      final launched = await _auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : mobileRedirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw const AuthFailure(
          AuthFailureCode.cancelled,
          'Không mở được trang đăng nhập Google.',
        );
      }
    });
  }

  @override
  Future<void> sendLoginOtp({required String email}) {
    return _guard(
      () => _auth.signInWithOtp(email: email.trim(), shouldCreateUser: false),
    );
  }

  @override
  Future<void> verifyOtp({
    required String email,
    required String token,
    required OtpPurpose purpose,
  }) {
    return _guard(
      () => _auth.verifyOTP(
        email: email.trim(),
        token: token.trim(),
        type: purpose == OtpPurpose.signup ? OtpType.signup : OtpType.email,
      ),
    );
  }

  @override
  Future<void> resendOtp({required String email, required OtpPurpose purpose}) {
    return switch (purpose) {
      OtpPurpose.login => sendLoginOtp(email: email),
      OtpPurpose.signup => _guard(
        () => _auth.resend(type: OtpType.signup, email: email.trim()),
      ),
    };
  }

  @override
  Future<SignUpResult> signUp(RegisterRequest request) {
    return _guard(() async {
      final response = await _auth.signUp(
        email: request.email.trim(),
        password: request.password,
        // Backend đọc full_name khi tạo profile lần đầu
        data: {
          'full_name': request.fullName.trim(),
          'phone': request.phone.trim(),
          'address': request.address.trim(),
        },
      );
      // Supabase trả user không có identity khi email đã tồn tại
      if (response.user?.identities?.isEmpty ?? false) {
        throw const AuthFailure(
          AuthFailureCode.userAlreadyExists,
          'Email này đã được đăng ký. Vui lòng đăng nhập.',
        );
      }
      return response.session == null
          ? SignUpResult.needsEmailVerification
          : SignUpResult.signedIn;
    });
  }

  @override
  Future<void> signOut() => _guard(_auth.signOut);

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthFailure {
      rethrow;
    } on AuthRetryableFetchException {
      throw AuthFailure.network;
    } on AuthException catch (error) {
      throw mapAuthException(error);
    } catch (_) {
      throw AuthFailure.unknown;
    }
  }

  /// Chuyển mã lỗi của Supabase sang thông báo tiếng Việt.
  @visibleForTesting
  static AuthFailure mapAuthException(AuthException error) {
    return switch (error.code) {
      'invalid_credentials' => const AuthFailure(
        AuthFailureCode.invalidCredentials,
        'Email hoặc mật khẩu không đúng.',
      ),
      'email_not_confirmed' => const AuthFailure(
        AuthFailureCode.emailNotConfirmed,
        'Email chưa được xác thực. Vui lòng kiểm tra hộp thư của bạn.',
      ),
      'user_already_exists' || 'email_exists' => const AuthFailure(
        AuthFailureCode.userAlreadyExists,
        'Email này đã được đăng ký. Vui lòng đăng nhập.',
      ),
      'otp_expired' || 'otp_disabled' => const AuthFailure(
        AuthFailureCode.invalidOtp,
        'Mã OTP không đúng hoặc đã hết hạn.',
      ),
      'user_not_found' => const AuthFailure(
        AuthFailureCode.invalidCredentials,
        'Không tìm thấy tài khoản với email này.',
      ),
      'over_email_send_rate_limit' ||
      'over_request_rate_limit' => const AuthFailure(
        AuthFailureCode.rateLimited,
        'Bạn thao tác quá nhanh. Vui lòng thử lại sau ít phút.',
      ),
      'weak_password' => const AuthFailure(
        AuthFailureCode.weakPassword,
        'Mật khẩu quá yếu. Vui lòng chọn mật khẩu mạnh hơn.',
      ),
      _ => AuthFailure.unknown,
    };
  }
}
