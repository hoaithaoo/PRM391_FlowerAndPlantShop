import '../utils/auth_validators.dart';

/// Kết quả một thao tác ở màn OTP.
enum OtpResultStatus {
  /// Thành công (đã xác thực hoặc đã gửi lại mã).
  success,

  /// Chưa đủ 6 số.
  invalid,

  /// Server trả lỗi, [OtpResult.message] là câu tiếng Việt để hiển thị.
  failure,

  /// Đang bận hoặc chưa hết thời gian chờ nên bỏ qua.
  ignored,
}

class OtpResult {
  const OtpResult(this.status, [this.message]);

  static const success = OtpResult(OtpResultStatus.success);
  static const ignored = OtpResult(OtpResultStatus.ignored);

  /// Lỗi không xác định (không phải AuthFailure).
  static const unknown = OtpResult(
    OtpResultStatus.failure,
    'Đã có lỗi xảy ra. Vui lòng thử lại sau.',
  );

  final OtpResultStatus status;
  final String? message;
}

/// Trạng thái bất biến của màn Xác thực Email OTP.
class OtpState {
  const OtpState({
    this.code = '',
    this.hasError = false,
    this.isVerifying = false,
    this.isResending = false,
    this.remaining = Duration.zero,
  });

  /// Các chữ số đã nhập (tối đa [AuthValidators.otpLength]).
  final String code;

  /// Mã vừa nhập bị sai: tô viền đỏ các ô cho tới khi người dùng nhập lại.
  final bool hasError;
  final bool isVerifying;
  final bool isResending;

  /// Thời gian còn lại trước khi được gửi lại mã.
  final Duration remaining;

  bool get isComplete => code.length == AuthValidators.otpLength;

  bool get canSubmit => isComplete && !isVerifying;

  bool get canResend => remaining <= Duration.zero && !isResending;

  /// Số giây còn lại làm tròn lên, dùng cho đồng hồ mm:ss.
  int get remainingSeconds => (remaining.inMilliseconds / 1000).ceil();

  /// Dạng "00:44".
  String get countdownLabel {
    final seconds = remainingSeconds;
    final mm = (seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  OtpState copyWith({
    String? code,
    bool? hasError,
    bool? isVerifying,
    bool? isResending,
    Duration? remaining,
  }) {
    return OtpState(
      code: code ?? this.code,
      hasError: hasError ?? this.hasError,
      isVerifying: isVerifying ?? this.isVerifying,
      isResending: isResending ?? this.isResending,
      remaining: remaining ?? this.remaining,
    );
  }
}
