import '../utils/auth_validators.dart';

/// Trạng thái của màn hình Quên mật khẩu (gửi link reset password về email).
class ForgotPasswordState {
  const ForgotPasswordState({
    this.email = '',
    this.isSubmitting = false,
    this.isResending = false,
    this.emailSent = false,
    this.resendCount = 0,
    this.remainingCooldown = Duration.zero,
    this.showErrors = false,
    this.generalError,
  });

  final String email;
  final bool isSubmitting;
  final bool isResending;
  final bool emailSent;
  final int resendCount;
  final Duration remainingCooldown;
  final bool showErrors;
  final String? generalError;

  bool get isBusy => isSubmitting || isResending;

  /// Nút gửi lại chỉ được bấm khi đã gửi email ít nhất 1 lần, đã hết đếm ngược và không bận.
  bool get canResend =>
      emailSent && remainingCooldown == Duration.zero && !isBusy;

  String? get emailError =>
      showErrors ? AuthValidators.email(email) : null;

  bool get hasErrors => AuthValidators.email(email) != null;

  ForgotPasswordState copyWith({
    String? email,
    bool? isSubmitting,
    bool? isResending,
    bool? emailSent,
    int? resendCount,
    Duration? remainingCooldown,
    bool? showErrors,
    String? generalError,
    bool clearError = false,
  }) {
    return ForgotPasswordState(
      email: email ?? this.email,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isResending: isResending ?? this.isResending,
      emailSent: emailSent ?? this.emailSent,
      resendCount: resendCount ?? this.resendCount,
      remainingCooldown: remainingCooldown ?? this.remainingCooldown,
      showErrors: showErrors ?? this.showErrors,
      generalError: clearError ? null : (generalError ?? this.generalError),
    );
  }
}
