/// Mục đích của mã OTP gửi về email.
enum OtpPurpose {
  /// Đăng nhập không mật khẩu bằng mã 6 số (link "Đăng nhập OTP").
  login,

  /// Xác thực email sau khi đăng ký tài khoản mới.
  signup,
}

/// Dữ liệu form đăng ký gửi lên Supabase Auth.
class RegisterRequest {
  const RegisterRequest({
    required this.fullName,
    required this.phone,
    required this.email,
    required this.address,
    required this.password,
  });

  final String fullName;
  final String phone;
  final String email;
  final String address;
  final String password;
}

/// Kết quả đăng ký: có thể cần xác thực email trước khi có phiên đăng nhập.
enum SignUpResult { signedIn, needsEmailVerification }

/// Tham số điều hướng sang màn xác thực OTP.
class OtpArgs {
  const OtpArgs({required this.email, required this.purpose});

  final String email;
  final OtpPurpose purpose;
}
