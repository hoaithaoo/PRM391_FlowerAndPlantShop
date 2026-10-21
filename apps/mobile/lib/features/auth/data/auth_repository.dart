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

  /// Gửi lại email chứa link xác nhận đăng ký. Bấm link sẽ mở lại app qua deep
  /// link và phiên đăng nhập đến qua [signedInChanges].
  Future<void> resendSignupEmail({required String email});

  Future<SignUpResult> signUp(RegisterRequest request);

  Future<void> signOut();
}
