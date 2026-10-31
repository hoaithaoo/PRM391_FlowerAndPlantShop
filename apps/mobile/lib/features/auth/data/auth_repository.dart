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

  /// Kiểm tra xem tài khoản hiện tại đã có đầy đủ SĐT và Địa chỉ hay chưa.
  bool get isProfileComplete;

  /// Metadata của người dùng hiện tại (e.g. từ Google OAuth: full_name, avatar_url).
  Map<String, dynamic>? get currentUserMetadata;

  /// Email của người dùng hiện tại (nếu có phiên).
  String? get currentUserEmail;

  /// Cập nhật thông tin còn thiếu (SĐT, Địa chỉ, toạ độ, Họ tên) sau khi đăng ký bằng Google.
  Future<void> completeProfile(CompleteProfileRequest request);

  /// Phát `true` khi người dùng nhấp vào link đặt lại mật khẩu từ email
  /// (Supabase phát sự kiện passwordRecovery), và `false` khi kết thúc/huỷ khôi phục.
  Stream<bool> get passwordRecoveryChanges;

  /// Kiểm tra xem hiện tại có đang trong phiên khôi phục mật khẩu hay không.
  bool get isInPasswordRecovery;

  /// Gửi email chứa link đặt lại mật khẩu về hòm thư người dùng.
  Future<void> sendPasswordResetEmail({required String email});

  /// Cập nhật mật khẩu mới cho phiên khôi phục hiện tại.
  /// Sau khi đổi mật khẩu thành công, phiên khôi phục tự động đăng xuất.
  Future<void> updatePassword({required String newPassword});

  /// Huỷ phiên khôi phục mật khẩu (đăng xuất khỏi phiên tạm thời).
  Future<void> cancelPasswordRecovery();
}
