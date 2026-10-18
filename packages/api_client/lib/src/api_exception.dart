/// Lỗi trả về từ backend theo error envelope (`docs/spec.md` mục 4.2),
/// hoặc lỗi mạng khi không gọi được server.
class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
  });

  /// Không kết nối được server (mất mạng, timeout, DNS...).
  const ApiException.network([
    this.message = 'Không thể kết nối máy chủ. Vui lòng kiểm tra mạng.',
  ]) : statusCode = 0,
       code = networkErrorCode;

  static const networkErrorCode = 'NETWORK_ERROR';

  /// HTTP status; 0 khi là lỗi mạng.
  final int statusCode;

  /// `error.code` của backend, ví dụ `PRODUCT_NOT_FOUND`.
  final String code;

  /// Câu tiếng Việt có thể hiển thị cho người dùng.
  final String message;

  bool get isNetworkError => code == networkErrorCode;
  bool get isNotFound => statusCode == 404;

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}
