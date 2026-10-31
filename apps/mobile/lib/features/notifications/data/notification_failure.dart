class NotificationFailure implements Exception {
  const NotificationFailure({required this.code, this.statusCode});

  const NotificationFailure.network()
    : code = NotificationErrorCode.network,
      statusCode = null;

  final String code;
  final int? statusCode;
}

abstract final class NotificationErrorCode {
  static const authTokenInvalid = 'AUTH_TOKEN_INVALID';
  static const authTokenMissing = 'AUTH_TOKEN_MISSING';
  static const notificationNotFound = 'NOTIFICATION_NOT_FOUND';
  static const malformedResponse = 'MALFORMED_RESPONSE';
  static const network = 'NETWORK_ERROR';
}
