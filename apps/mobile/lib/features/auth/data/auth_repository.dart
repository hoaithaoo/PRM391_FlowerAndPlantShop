import '../models/auth_models.dart';

/// Giao tiếp với Supabase Auth. Mọi lỗi được ném ra dưới dạng [AuthFailure].
///
/// Backend không có endpoint /login: app đăng nhập trực tiếp với Supabase rồi
/// gửi access token cho REST API (xem docs/supabase-auth.md).
abstract interface class AuthRepository {
  bool get isSignedIn;

  /// Phát `true` khi có phiên đăng nhập mới (ví dụ quay về từ Google OAuth),
  /// `false` khi đăng xuất.
  Stream<bool> get signedInChanges;

  Future<void> signInWithPassword({
    required String email,
    required String password,
  });

  /// Mở trình duyệt đăng nhập Google. Hàm trả về khi đã mở trình duyệt;
  /// phiên đăng nhập đến sau qua [signedInChanges].
  Future<void> signInWithGoogle();

  /// Gửi mã OTP 6 số để đăng nhập không mật khẩu.
  Future<void> sendLoginOtp({required String email});

  Future<void> verifyOtp({
    required String email,
    required String token,
    required OtpPurpose purpose,
  });

  /// Gửi lại mã theo mục đích (đăng nhập hoặc xác thực đăng ký).
  Future<void> resendOtp({required String email, required OtpPurpose purpose});

  Future<SignUpResult> signUp(RegisterRequest request);

  Future<void> signOut();
}
