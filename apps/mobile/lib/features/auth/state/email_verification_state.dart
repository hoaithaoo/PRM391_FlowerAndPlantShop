/// Kết quả một lần bấm "Gửi lại email".
enum ResendStatus {
  /// Đã gửi lại email.
  success,

  /// Server trả lỗi, [ResendResult.message] là câu tiếng Việt để hiển thị.
  failure,

  /// Đang gửi hoặc chưa hết thời gian chờ nên bỏ qua.
  ignored,
}

class ResendResult {
  const ResendResult(this.status, [this.message]);

  static const success = ResendResult(ResendStatus.success);
  static const ignored = ResendResult(ResendStatus.ignored);

  final ResendStatus status;
  final String? message;
}

/// Trạng thái bất biến của màn "Kiểm tra email".
class EmailVerificationState {
  const EmailVerificationState({
    this.isResending = false,
    this.remaining = Duration.zero,
  });

  final bool isResending;

  /// Thời gian còn lại trước khi được gửi lại email.
  final Duration remaining;

  bool get canResend => remaining <= Duration.zero && !isResending;

  /// Số giây còn lại làm tròn lên, dùng cho nhãn đếm ngược.
  int get remainingSeconds => (remaining.inMilliseconds / 1000).ceil();

  EmailVerificationState copyWith({bool? isResending, Duration? remaining}) {
    return EmailVerificationState(
      isResending: isResending ?? this.isResending,
      remaining: remaining ?? this.remaining,
    );
  }
}
