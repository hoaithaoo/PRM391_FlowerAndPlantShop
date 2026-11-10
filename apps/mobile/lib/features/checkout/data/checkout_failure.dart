class CheckoutFailure implements Exception {
  const CheckoutFailure({required this.code, this.statusCode, this.message});

  const CheckoutFailure.network({this.message})
    : code = CheckoutErrorCode.network,
      statusCode = null;

  final String code;
  final int? statusCode;
  final String? message;
}

abstract final class CheckoutErrorCode {
  static const productOutOfStock = 'PRODUCT_OUT_OF_STOCK';
  static const checkoutConflict = 'CHECKOUT_CONFLICT';
  static const cartEmpty = 'CART_EMPTY';
  static const storeNotFound = 'STORE_NOT_FOUND';
  static const pickupTimeInvalid = 'PICKUP_TIME_INVALID';
  static const forbidden = 'FORBIDDEN';
  static const validationError = 'VALIDATION_ERROR';
  static const authTokenInvalid = 'AUTH_TOKEN_INVALID';
  static const authTokenMissing = 'AUTH_TOKEN_MISSING';
  static const malformedResponse = 'MALFORMED_RESPONSE';
  static const network = 'NETWORK_ERROR';
  static const voucherNotFound = 'VOUCHER_NOT_FOUND';
  static const voucherExpired = 'VOUCHER_EXPIRED';
  static const voucherUsageExceeded = 'VOUCHER_USAGE_EXCEEDED';
  static const voucherMinOrderNotMet = 'VOUCHER_MIN_ORDER_NOT_MET';
  static const voucherNotApplicable = 'VOUCHER_NOT_APPLICABLE';
}
