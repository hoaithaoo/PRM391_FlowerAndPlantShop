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
  });

  final CheckoutStatus status;
  final CheckoutResult? result;
  final String? errorMessage;

  bool get isSubmitting => status == CheckoutStatus.submitting;
}
