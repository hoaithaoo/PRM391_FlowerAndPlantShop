enum CartErrorCode {
  authenticationRequired,
  network,
  malformedResponse,
  productNotFound,
  productOutOfStock,
  validation,
  server,
  rejected,
}

class CartFailure implements Exception {
  const CartFailure({
    required this.code,
    required this.message,
    this.statusCode,
    this.backendCode,
  });

  final CartErrorCode code;
  final String message;
  final int? statusCode;
  final String? backendCode;
}
