class CheckoutFailure implements Exception {
  const CheckoutFailure({required this.code, this.statusCode});

  const CheckoutFailure.network()
    : code = CheckoutErrorCode.network,
      statusCode = null;

  final String code;
  final int? statusCode;
}

abstract final class CheckoutErrorCode {
  static const productOutOfStock = 'PRODUCT_OUT_OF_STOCK';
  static const checkoutConflict = 'CHECKOUT_CONFLICT';
  static const cartEmpty = 'CART_EMPTY';
  static const validationError = 'VALIDATION_ERROR';
  static const authTokenInvalid = 'AUTH_TOKEN_INVALID';
  static const authTokenMissing = 'AUTH_TOKEN_MISSING';
  static const malformedResponse = 'MALFORMED_RESPONSE';
  static const network = 'NETWORK_ERROR';
}
