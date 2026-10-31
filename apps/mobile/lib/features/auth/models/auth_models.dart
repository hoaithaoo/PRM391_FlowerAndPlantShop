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

/// Kết quả đăng ký: có thể cần bấm link xác nhận trong email trước khi có phiên.
enum SignUpResult { signedIn, needsEmailVerification }

/// Dữ liệu hoàn thiện thông tin còn thiếu (sau khi đăng ký Google).
class CompleteProfileRequest {
  const CompleteProfileRequest({
    required this.fullName,
    required this.phone,
    required this.address,
  });

  final String fullName;
  final String phone;
  final String address;
}
