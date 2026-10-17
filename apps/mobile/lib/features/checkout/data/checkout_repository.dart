import '../models/checkout_request.dart';
import '../models/checkout_result.dart';

abstract interface class CheckoutRepository {
  Future<CheckoutResult> checkout(
    CheckoutRequest request, {
    required String idempotencyKey,
  });
}
