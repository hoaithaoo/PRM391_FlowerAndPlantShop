import '../models/checkout_flow_models.dart';
import '../models/checkout_request.dart';
import '../models/checkout_result.dart';
import '../models/voucher.dart';
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
    return _parse(() => CheckoutResult.fromJson(response));
  }

  @override
  Future<List<CheckoutAddress>> listAddresses() async {
    final data = await _remoteDataSource.listAddresses();
    return _parse(() {
      final items = data['items'];
      if (items is! List) throw const FormatException('Missing items.');
      return items
          .map((item) => CheckoutAddress.fromJson(_asMap(item)))
          .toList(growable: false);
    });
  }

  @override
  Future<CheckoutAddress> saveAddress(CheckoutAddress address) async {
    final data = address.isNew
        ? await _remoteDataSource.createAddress(address.toJson())
        : await _remoteDataSource.updateAddress(address.id, address.toJson());
    return _parse(() => CheckoutAddress.fromJson(data));
  }

  @override
  Future<num> estimateShippingFee({
    required double latitude,
    required double longitude,
  }) async {
    final data = await _remoteDataSource.estimateShipping(
      latitude: latitude,
      longitude: longitude,
    );
    return _parse(() {
      final fee = data['shippingFee'];
      if (fee is! num) throw const FormatException('Missing shippingFee.');
      return fee;
    });
  }

  @override
  Future<List<PickupBranch>> listStores({
    double? latitude,
    double? longitude,
  }) async {
    final data = await _remoteDataSource.listStores(
      latitude: latitude,
      longitude: longitude,
    );
    return _parse(() {
      final items = data['items'];
      if (items is! List) throw const FormatException('Missing items.');
      return items
          .map((item) => PickupBranch.fromJson(_asMap(item)))
          .toList(growable: false);
    });
  }

  @override
  Future<String> getPaymentStatus(String paymentId) async {
    final data = await _remoteDataSource.getPaymentStatus(paymentId);
    return _parse(() {
      final status = data['status'];
      if (status is! String) throw const FormatException('Missing status.');
      return status;
    });
  }

  @override
  Future<void> cancelOrder(String orderId, {String? reason}) {
    return _remoteDataSource.cancelOrder(orderId, reason: reason);
  }

  @override
  Future<List<Voucher>> availableVouchers() async {
    final data = await _remoteDataSource.availableVouchers();
    return _parse(() {
      final items = data['items'];
      if (items is! List) throw const FormatException('Missing items.');
      return items
          .map((item) => Voucher.fromJson(_asMap(item)))
          .toList(growable: false);
    });
  }

  @override
  Future<Voucher> validateVoucher(String code) async {
    final data = await _remoteDataSource.validateVoucher(code);
    return _parse(() => Voucher.fromJson(data));
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is! Map) throw const FormatException('Expected an object.');
    return Map<String, dynamic>.from(value);
  }

  T _parse<T>(T Function() parse) {
    try {
      return parse();
    } on FormatException {
      throw const CheckoutFailure(code: CheckoutErrorCode.malformedResponse);
    } on TypeError {
      throw const CheckoutFailure(code: CheckoutErrorCode.malformedResponse);
    }
  }
}
