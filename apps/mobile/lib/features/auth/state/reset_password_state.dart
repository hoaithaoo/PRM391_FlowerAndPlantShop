import '../utils/auth_validators.dart';

/// Trạng thái của màn hình Đổi mật khẩu mới sau khi nhấp link xác nhận từ email.
class ResetPasswordState {
  const ResetPasswordState({
    this.newPassword = '',
    this.confirmPassword = '',
    this.obscureNewPassword = true,
    this.obscureConfirmPassword = true,
    this.isSubmitting = false,
    this.showErrors = false,
    this.generalError,
  });

  final String newPassword;
  final String confirmPassword;
  final bool obscureNewPassword;
  final bool obscureConfirmPassword;
  final bool isSubmitting;
  final bool showErrors;
  final String? generalError;

  String? get newPasswordError =>
      showErrors ? AuthValidators.password(newPassword) : null;

  String? get confirmPasswordError => showErrors
      ? AuthValidators.confirmPassword(confirmPassword, newPassword)
      : null;

  bool get hasErrors =>
      AuthValidators.password(newPassword) != null ||
      AuthValidators.confirmPassword(confirmPassword, newPassword) != null;

  ResetPasswordState copyWith({
    String? newPassword,
    String? confirmPassword,
    bool? obscureNewPassword,
    bool? obscureConfirmPassword,
    bool? isSubmitting,
    bool? showErrors,
    String? generalError,
    bool clearError = false,
  }) {
    return ResetPasswordState(
      newPassword: newPassword ?? this.newPassword,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      obscureNewPassword: obscureNewPassword ?? this.obscureNewPassword,
      obscureConfirmPassword:
          obscureConfirmPassword ?? this.obscureConfirmPassword,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      showErrors: showErrors ?? this.showErrors,
      generalError: clearError ? null : (generalError ?? this.generalError),
    );
  }
}

