import '../models/checkout_request.dart';
import '../models/checkout_result.dart';
import 'checkout_failure.dart';
import 'checkout_remote_data_source.dart';
import 'checkout_repository.dart';

class CheckoutRepositoryImpl implements CheckoutRepository {
  const CheckoutRepositoryImpl(this._remoteDataSource);

  final CheckoutRemoteDataSource _remoteDataSource;

  @override
  Future<CheckoutResult> checkout(
    CheckoutRequest request, {
    required String idempotencyKey,
  }) async {
    final response = await _remoteDataSource.checkout(
      request,
      idempotencyKey: idempotencyKey,
    );

    try {
      return CheckoutResult.fromJson(response);
    } on FormatException {
      throw const CheckoutFailure(code: CheckoutErrorCode.malformedResponse);
    }
  }
}
