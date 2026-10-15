/// Kiểm tra dữ liệu form auth. Trả về null nếu hợp lệ, ngược lại là thông báo lỗi.
///
/// Câu chữ báo lỗi lấy theo màn "Đăng ký - Lỗi" trên Penpot.
abstract final class AuthValidators {
  static final _emailPattern = RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*\.[A-Za-z]{2,}$",
  );
  // Số Việt Nam: 0xxxxxxxxx hoặc +84xxxxxxxxx (9 chữ số sau đầu số)
  static final _phonePattern = RegExp(r'^(?:\+84|0)\d{9}$');
  // Chữ cái (kể cả tiếng Việt có dấu) và khoảng trắng
  static final _namePattern = RegExp(r"^[\p{L}\s]+$", unicode: true);
  static final _uppercase = RegExp(r'[A-Z]');
  static final _digit = RegExp(r'\d');
  static final _special = RegExp(r'[^A-Za-z0-9\s]');
  static final _otpPattern = RegExp(r'^\d{6}$');

  static const passwordMinLength = 8;
  static const otpLength = 6;

  static bool isEmail(String value) => _emailPattern.hasMatch(value.trim());

  /// Cho phép khoảng trắng giữa các nhóm số như placeholder "(+84) 912 345 678".
  static bool isPhone(String value) =>
      _phonePattern.hasMatch(value.replaceAll(RegExp(r'\s'), ''));

  static String? fullName(String value) {
    final name = value.trim();
    if (name.isEmpty) return 'Vui lòng nhập họ và tên.';
    if (!_namePattern.hasMatch(name)) {
      return 'Tên không được chứa số và các ký tự đặc biệt.';
    }
    if (name.length > 100) return 'Họ và tên tối đa 100 ký tự.';
    return null;
  }

  static String? phone(String value) {
    final phone = value.trim();
    if (phone.isEmpty) return 'Vui lòng nhập số điện thoại.';
    if (!isPhone(phone)) {
      return 'Số điện thoại chỉ được chứa chữ số hoặc định dạng (+mã quốc gia) '
          'số (ví dụ: +84912345678 hoặc 0912345678), không được chứa chữ cái '
          'hay ký tự đặc biệt.';
    }
    return null;
  }

  static String? email(String value) {
    final email = value.trim();
    if (email.isEmpty) return 'Vui lòng nhập địa chỉ email.';
    if (!isEmail(email)) {
      return 'Email không đúng định dạng tiêu chuẩn (ví dụ hợp lệ: '
          'name@example.com).';
    }
    return null;
  }

  static String? address(String value) {
    final address = value.trim();
    if (address.isEmpty) return 'Vui lòng nhập địa chỉ nhận hàng.';
    if (address.length < 5) {
      return 'Địa chỉ quá ngắn, vui lòng nhập chi tiết hơn.';
    }
    return null;
  }

  static String? password(String value) {
    if (value.isEmpty) return 'Vui lòng nhập mật khẩu.';
    if (!PasswordRules.of(value).allPassed) {
      return 'Mật khẩu phải tối thiểu 8 ký tự, có ít nhất 1 chữ cái in hoa, 1 '
          'chữ số và 1 ký tự đặc biệt (@, #, \$, %, v.v.).';
    }
    return null;
  }

  static String? confirmPassword(String value, String password) {
    if (value.isEmpty) return 'Vui lòng nhập lại mật khẩu.';
    if (value != password) {
      return 'Mật khẩu xác nhận không khớp với mật khẩu đã nhập.';
    }
    return null;
  }

  static String? agreement(bool accepted) {
    return accepted
        ? null
        : 'Vui lòng đồng ý với Điều khoản dịch vụ và Chính sách bảo mật.';
  }

  /// Ô "Số điện thoại hoặc Email" ở màn đăng nhập.
  ///
  /// Supabase hiện chỉ bật đăng nhập bằng email nên số điện thoại bị từ chối
  /// với thông báo rõ ràng thay vì báo sai định dạng.
  static String? loginIdentifier(String value) {
    final identifier = value.trim();
    if (identifier.isEmpty) return 'Vui lòng nhập số điện thoại hoặc email.';
    if (isPhone(identifier)) {
      return 'Đăng nhập bằng số điện thoại chưa được hỗ trợ, vui lòng dùng email.';
    }
    if (!isEmail(identifier)) {
      return 'Email không đúng định dạng tiêu chuẩn (ví dụ hợp lệ: '
          'name@example.com).';
    }
    return null;
  }

  static String? loginPassword(String value) {
    return value.isEmpty ? 'Vui lòng nhập mật khẩu.' : null;
  }

  static String? otp(String value) {
    if (!_otpPattern.hasMatch(value)) {
      return 'Vui lòng nhập đủ 6 chữ số của mã OTP.';
    }
    return null;
  }

  /// Che email để hiển thị trên chip OTP: phuongha@gmail.com -> ph***@gmail.com.
  static String maskEmail(String value) {
    final email = value.trim();
    final at = email.indexOf('@');
    if (at <= 0) return email;
    final name = email.substring(0, at);
    final visible = name.length <= 2
        ? name.substring(0, 1)
        : name.substring(0, 2);
    return '$visible***${email.substring(at)}';
  }
}

/// Trạng thái từng điều kiện mật khẩu, dùng cho checklist ở màn đăng ký lỗi.
class PasswordRules {
  const PasswordRules({
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasDigit,
    required this.hasSpecial,
  });

  factory PasswordRules.of(String value) {
    return PasswordRules(
      hasMinLength: value.length >= AuthValidators.passwordMinLength,
      hasUppercase: AuthValidators._uppercase.hasMatch(value),
      hasDigit: AuthValidators._digit.hasMatch(value),
      hasSpecial: AuthValidators._special.hasMatch(value),
    );
  }

  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasDigit;
  final bool hasSpecial;

  bool get allPassed => hasMinLength && hasUppercase && hasDigit && hasSpecial;
}
