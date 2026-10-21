/// Lỗi auth đã được chuyển sang câu thông báo tiếng Việt cho người dùng.
class AuthFailure implements Exception {
  const AuthFailure(this.code, this.message);

  final AuthFailureCode code;
  final String message;

  static const network = AuthFailure(
    AuthFailureCode.network,
    'Không có kết nối mạng. Vui lòng kiểm tra và thử lại.',
  );

  static const unknown = AuthFailure(
    AuthFailureCode.unknown,
    'Đã có lỗi xảy ra. Vui lòng thử lại sau.',
  );

  @override
  String toString() => 'AuthFailure(${code.name}): $message';
}

enum AuthFailureCode {
  invalidCredentials,
  emailNotConfirmed,
  userAlreadyExists,
  rateLimited,
  weakPassword,
  cancelled,
  network,
  notConfigured,
  unknown,
}
