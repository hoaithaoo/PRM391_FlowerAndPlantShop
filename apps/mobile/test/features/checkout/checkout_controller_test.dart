import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/checkout/data/checkout_failure.dart';
import 'package:plant_flower_mobile/features/checkout/data/mock_checkout_repository.dart';
import 'package:plant_flower_mobile/features/checkout/models/checkout_invoice.dart';
import 'package:plant_flower_mobile/features/checkout/models/checkout_order.dart';
import 'package:plant_flower_mobile/features/checkout/models/checkout_request.dart';
import 'package:plant_flower_mobile/features/checkout/models/checkout_result.dart';
import 'package:plant_flower_mobile/features/checkout/models/payment_method.dart';
import 'package:plant_flower_mobile/features/checkout/state/checkout_controller.dart';

const _request = CheckoutRequest(
  receiverName: 'Nguyễn An',
  phone: '0901234567',
  address: '1 Nguyễn Huệ, TP.HCM',
  latitude: 10.77,
  longitude: 106.70,
  paymentMethod: PaymentMethod.cod,
);

const _result = CheckoutResult(
  order: CheckoutOrder(id: 'order-id', orderCode: 'ORD-001', status: 'NEW'),
  invoice: CheckoutInvoice(
    id: 'invoice-id',
    invoiceNumber: 'INV-001',
    subtotalAmount: 100000,
    taxAmount: 0,
    shippingFee: 20000,
    grandTotal: 120000,
  ),
);

void main() {
  test('retry kết quả chưa chắc chắn giữ nguyên Idempotency-Key', () async {
    final repository = _RecordingRepository([
      const CheckoutFailure.network(),
      _result,
    ]);
    var keyIndex = 0;
    final controller = CheckoutController(
      repository: repository,
      idempotencyKeyFactory: () => 'key-${++keyIndex}',
    );

    expect(await controller.submit(_request), isNull);
    expect(await controller.submit(_request), same(_result));
    expect(repository.keys, ['key-1', 'key-1']);
  });

  test('request khác dùng Idempotency-Key mới', () async {
    final repository = _RecordingRepository([
      const CheckoutFailure.network(),
      _result,
    ]);
    var keyIndex = 0;
    final controller = CheckoutController(
      repository: repository,
      idempotencyKeyFactory: () => 'key-${++keyIndex}',
    );

    await controller.submit(_request);
    await controller.submit(
      const CheckoutRequest(
        receiverName: 'Nguyễn Bình',
        phone: '0901234567',
        address: '1 Nguyễn Huệ, TP.HCM',
        latitude: 10.77,
        longitude: 106.70,
        paymentMethod: PaymentMethod.cod,
      ),
    );

    expect(repository.keys, ['key-1', 'key-2']);
  });

  test('hai lần bấm đồng thời chỉ gửi một checkout', () async {
    final completer = Completer<CheckoutResult>();
    final repository = _CompletingRepository(completer);
    final controller = CheckoutController(
      repository: repository,
      idempotencyKeyFactory: () => 'one-key',
    );

    final first = controller.submit(_request);
    final second = controller.submit(_request);
    expect(await second, isNull);
    expect(repository.callCount, 1);

    completer.complete(_result);
    expect(await first, same(_result));
  });
}

class _RecordingRepository extends MockCheckoutRepository {
  _RecordingRepository(this.outcomes);

  final List<Object> outcomes;
  final List<String> keys = [];

  @override
  Future<CheckoutResult> checkout(
    CheckoutRequest request, {
    required String idempotencyKey,
  }) async {
    keys.add(idempotencyKey);
    final outcome = outcomes.removeAt(0);
    if (outcome is CheckoutFailure) throw outcome;
    return outcome as CheckoutResult;
  }
}

class _CompletingRepository extends MockCheckoutRepository {
  _CompletingRepository(this.completer);

  final Completer<CheckoutResult> completer;
  int callCount = 0;

  @override
  Future<CheckoutResult> checkout(
    CheckoutRequest request, {
    required String idempotencyKey,
  }) {
    callCount++;
    return completer.future;
  }
}
