/// Kết quả một thao tác ở màn đăng nhập để màn hình quyết định điều hướng.
enum LoginResultStatus {
  /// Thao tác thành công (đã đăng nhập hoặc đã gửi OTP).
  success,

  /// Dữ liệu nhập chưa hợp lệ, lỗi đã hiện dưới từng ô.
  invalid,

  /// Server trả lỗi, [LoginResult.message] là câu tiếng Việt để hiển thị.
  failure,

  /// Đang bận (bấm đôi) hoặc người dùng tự hủy nên bỏ qua.
  ignored,
}

class LoginResult {
  const LoginResult(this.status, [this.message]);

  static const success = LoginResult(LoginResultStatus.success);
  static const invalid = LoginResult(LoginResultStatus.invalid);
  static const ignored = LoginResult(LoginResultStatus.ignored);

  /// Lỗi không xác định (không phải AuthFailure).
  static const unknown = LoginResult(
    LoginResultStatus.failure,
    'Đã có lỗi xảy ra. Vui lòng thử lại sau.',
  );

  final LoginResultStatus status;
  final String? message;
}

/// Trạng thái bất biến của màn Đăng nhập.
class LoginState {
  const LoginState({
    this.identifierError,
    this.passwordError,
    this.obscurePassword = true,
    this.isSubmitting = false,
    this.isSendingOtp = false,
    this.isGoogleLoading = false,
  });

  final String? identifierError;
  final String? passwordError;
  final bool obscurePassword;
  final bool isSubmitting;
  final bool isSendingOtp;
  final bool isGoogleLoading;

  /// Có thao tác nào đang chạy không (để chặn bấm đôi).
  bool get isBusy => isSubmitting || isSendingOtp || isGoogleLoading;

  LoginState copyWith({
    Object? identifierError = _unset,
    Object? passwordError = _unset,
    bool? obscurePassword,
    bool? isSubmitting,
    bool? isSendingOtp,
    bool? isGoogleLoading,
  }) {
    return LoginState(
      identifierError: identical(identifierError, _unset)
          ? this.identifierError
          : identifierError as String?,
      passwordError: identical(passwordError, _unset)
          ? this.passwordError
          : passwordError as String?,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSendingOtp: isSendingOtp ?? this.isSendingOtp,
      isGoogleLoading: isGoogleLoading ?? this.isGoogleLoading,
    );
  }
}

const Object _unset = Object();
