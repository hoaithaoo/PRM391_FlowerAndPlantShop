import 'dart:convert';

class ApiException implements Exception {
  final String code;
  final String message;
  final int statusCode;

  const ApiException({
    required this.code,
    required this.message,
    required this.statusCode,
  });

  @override
  String toString() => message;
}

class AuthTokenMissingException extends ApiException {
  const AuthTokenMissingException([
    String message = 'Phiên đăng nhập đã hết hạn hoặc không tìm thấy token (AUTH_TOKEN_MISSING)',
  ]) : super(code: 'AUTH_TOKEN_MISSING', message: message, statusCode: 401);
}

class AuthTokenInvalidException extends ApiException {
  const AuthTokenInvalidException([
    String message = 'Token xác thực không hợp lệ hoặc đã hết hạn (AUTH_TOKEN_INVALID)',
  ]) : super(code: 'AUTH_TOKEN_INVALID', message: message, statusCode: 401);
}

class ForbiddenException extends ApiException {
  const ForbiddenException([
    String message = 'Tài khoản không có quyền Admin truy cập hệ thống (FORBIDDEN)',
  ]) : super(code: 'FORBIDDEN', message: message, statusCode: 403);
}

class AccountDisabledException extends ApiException {
  const AccountDisabledException([
    String message = 'Tài khoản Admin này đã bị vô hiệu hóa (ACCOUNT_DISABLED)',
  ]) : super(code: 'ACCOUNT_DISABLED', message: message, statusCode: 403);
}

class AdminSelfLockForbiddenException extends ApiException {
  const AdminSelfLockForbiddenException([
    String message = 'Không thể tự khóa hoặc hạ quyền tài khoản của chính mình (ADMIN_SELF_LOCK_FORBIDDEN)',
  ]) : super(code: 'ADMIN_SELF_LOCK_FORBIDDEN', message: message, statusCode: 409);
}

class CategorySlugExistsException extends ApiException {
  const CategorySlugExistsException([
    String message = 'Đường dẫn tĩnh (Slug) danh mục đã tồn tại trong hệ thống (CATEGORY_SLUG_EXISTS)',
  ]) : super(code: 'CATEGORY_SLUG_EXISTS', message: message, statusCode: 409);
}

class CategoryHasProductsException extends ApiException {
  const CategoryHasProductsException([
    String message = 'Không thể xóa: Danh mục đang có sản phẩm liên kết (CATEGORY_HAS_PRODUCTS)',
  ]) : super(code: 'CATEGORY_HAS_PRODUCTS', message: message, statusCode: 409);
}

class OrderStatusInvalidException extends ApiException {
  const OrderStatusInvalidException([
    String message = 'Chuyển trạng thái đơn hàng không hợp lệ (INVALID_ORDER_STATE_TRANSITION)',
  ]) : super(code: 'INVALID_ORDER_STATE_TRANSITION', message: message, statusCode: 422);
}

class RateLimitedException extends ApiException {
  const RateLimitedException([
    String message = 'Bạn thao tác quá nhanh, vui lòng thử lại sau giây lát (RATE_LIMITED)',
  ]) : super(code: 'RATE_LIMITED', message: message, statusCode: 429);
}

class ServiceUnavailableException extends ApiException {
  const ServiceUnavailableException([
    String message = 'Hệ thống máy chủ đang bận hoặc bảo trì, vui lòng thử lại sau (SERVICE_UNAVAILABLE)',
  ]) : super(code: 'SERVICE_UNAVAILABLE', message: message, statusCode: 503);
}

ApiException parseApiResponseError(int statusCode, String responseBody) {
  String errorCode = 'UNKNOWN_ERROR';
  String errorMessage = 'Đã có lỗi xảy ra từ máy chủ (HTTP $statusCode)';

  try {
    final decoded = jsonDecode(responseBody);
    if (decoded is Map<String, dynamic>) {
      if (decoded['error'] is Map<String, dynamic>) {
        final errObj = decoded['error'] as Map<String, dynamic>;
        errorCode = errObj['code'] as String? ?? errorCode;
        errorMessage = errObj['message'] as String? ?? errorMessage;
      } else if (decoded['code'] != null) {
        errorCode = decoded['code'] as String;
        errorMessage = decoded['message'] as String? ?? errorMessage;
      }
    }
  } catch (_) {
    // Non-JSON response body
  }

  switch (errorCode) {
    case 'AUTH_TOKEN_MISSING':
      return AuthTokenMissingException(errorMessage);
    case 'AUTH_TOKEN_INVALID':
      return AuthTokenInvalidException(errorMessage);
    case 'FORBIDDEN':
      return ForbiddenException(errorMessage);
    case 'ACCOUNT_DISABLED':
      return AccountDisabledException(errorMessage);
    case 'ADMIN_SELF_LOCK_FORBIDDEN':
      return AdminSelfLockForbiddenException(errorMessage);
    case 'CATEGORY_SLUG_EXISTS':
      return CategorySlugExistsException(errorMessage);
    case 'CATEGORY_HAS_PRODUCTS':
    case 'CATEGORY_IN_USE':
      return CategoryHasProductsException(errorMessage);
    case 'INVALID_ORDER_STATE_TRANSITION':
      return OrderStatusInvalidException(errorMessage);
    case 'RATE_LIMITED':
      return RateLimitedException(errorMessage);
    case 'SERVICE_UNAVAILABLE':
      return ServiceUnavailableException(errorMessage);
    default:
      if (statusCode == 401) return AuthTokenInvalidException(errorMessage);
      if (statusCode == 403) return ForbiddenException(errorMessage);
      if (statusCode == 429) return RateLimitedException(errorMessage);
      if (statusCode == 503) return ServiceUnavailableException(errorMessage);
      return ApiException(code: errorCode, message: errorMessage, statusCode: statusCode);
  }
}
