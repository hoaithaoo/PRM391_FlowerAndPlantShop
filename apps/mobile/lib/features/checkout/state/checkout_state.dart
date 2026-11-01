import '../models/checkout_result.dart';

enum CheckoutStatus {
  initial,
  submitting,
  success,
  error,
  authenticationRequired,
}

class CheckoutState {
  const CheckoutState({
    this.status = CheckoutStatus.initial,
    this.result,
    this.errorMessage,
    this.errorCode,
  });

  final CheckoutStatus status;
  final CheckoutResult? result;
  final String? errorMessage;
  final String? errorCode;

  bool get isSubmitting => status == CheckoutStatus.submitting;
}
