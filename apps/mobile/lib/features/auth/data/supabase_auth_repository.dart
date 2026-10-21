import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/auth_models.dart';
import 'address_geocoder.dart';
import 'auth_failure.dart';
import 'auth_repository.dart';

/// Hiện thực [AuthRepository] bằng Supabase Auth.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._auth, {AddressGeocoder? geocoder})
    : _geocoder = geocoder;

  /// Deep link phải khai báo trong Supabase Dashboard > Redirect URLs và
  /// AndroidManifest/Info.plist (xem docs/supabase-auth.md).
  static const mobileRedirectUrl =
      'com.plantflowershop.mobile://login-callback/';

  final GoTrueClient _auth;
  final AddressGeocoder? _geocoder;

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
  Future<void> resendSignupEmail({required String email}) {
    return _guard(
      () => _auth.resend(
        type: OtpType.signup,
        email: email.trim(),
        emailRedirectTo: kIsWeb ? null : mobileRedirectUrl,
      ),
    );
  }

  @override
  Future<SignUpResult> signUp(RegisterRequest request) {
    return _guard(() async {
      // Không tìm được toạ độ thì vẫn đăng ký, lat/lng để null
      final point = await _geocoder?.geocode(request.address);
      final response = await _auth.signUp(
        email: request.email.trim(),
        password: request.password,
        // Link trong email xác nhận sẽ mở lại app qua deep link này
        emailRedirectTo: kIsWeb ? null : mobileRedirectUrl,
        data: signUpMetadata(request, point),
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

  /// Metadata lưu vào `raw_user_meta_data`. Trigger trên `auth.users` đọc các
  /// key này để tạo profile và địa chỉ mặc định khi email được xác nhận.
  @visibleForTesting
  static Map<String, dynamic> signUpMetadata(
    RegisterRequest request,
    GeoPoint? point,
  ) {
    return {
      'full_name': request.fullName.trim(),
      'phone': request.phone.trim(),
      'address': request.address.trim(),
      'latitude': point?.latitude,
      'longitude': point?.longitude,
    };
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthFailure {
      rethrow;
    } on AuthRetryableFetchException catch (error) {
      debugPrint('[Auth] Lỗi mạng: ${error.message}');
      throw AuthFailure.network;
    } on AuthException catch (error) {
      debugPrint(
        '[Auth] AuthException: code=${error.code}, '
        'status=${error.statusCode}, message=${error.message}',
      );
      throw mapAuthException(error);
    } catch (error, stackTrace) {
      debugPrint('[Auth] Lỗi không xác định: $error\n$stackTrace');
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
