import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/checkout/checkout.dart';

const _orderResult = CheckoutResult(
  order: CheckoutOrder(id: 'order-1', orderCode: 'ORD-1', status: 'PENDING'),
  invoice: CheckoutInvoice(
    id: 'invoice-1',
    invoiceNumber: 'INV-1',
    subtotalAmount: 700000,
    taxAmount: 0,
    shippingFee: 15000,
    grandTotal: 715000,
  ),
  payment: CheckoutPayment(
    id: 'payment-1',
    paymentCode: 'PAY123',
    status: 'PENDING',
  ),
);

const _address = CheckoutAddress(
  id: 'address-1',
  label: 'Nhà riêng',
  recipientName: 'Minh Anh',
  phone: '0901234567',
  addressLine: '15 Nguyễn Thiện Thuật',
  ward: 'Phường 2',
  district: 'Quận 3',
  city: 'TP. Hồ Chí Minh',
  latitude: 10.77,
  longitude: 106.68,
);

const _order = PlacedOrder(
  result: _orderResult,
  summary: CheckoutSummary(
    subtotal: 700000,
    tax: 0,
    shippingFee: 15000,
    grandTotal: 715000,
  ),
  address: _address,
);

const _request = CheckoutRequest(
  receiverName: 'Minh Anh',
  phone: '0901234567',
  address: '15 Nguyễn Thiện Thuật',
  latitude: 10.77,
  longitude: 106.68,
  paymentMethod: PaymentMethod.sepay,
);

class _FakeRepository extends MockCheckoutRepository {
  _FakeRepository({this.statuses = const <String>[]});

  final List<String> statuses;
  final keys = <String>[];
  final cancelled = <String>[];
  Object? checkoutError;
  int statusCalls = 0;

  @override
  Future<CheckoutResult> checkout(
    CheckoutRequest request, {
    required String idempotencyKey,
  }) async {
    keys.add(idempotencyKey);
    if (checkoutError case final error?) throw error;
    return _orderResult;
  }

  @override
  Future<String> getPaymentStatus(String paymentId) async {
    final index = statusCalls++;
    return index < statuses.length ? statuses[index] : 'PENDING';
  }

  @override
  Future<void> cancelOrder(String orderId, {String? reason}) async {
    cancelled.add(orderId);
  }
}

Future<void> _pumpQr(WidgetTester tester, _FakeRepository repository) async {
  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(body: Text('home'))),
  );
  tester
      .state<NavigatorState>(find.byType(Navigator))
      .push<void>(
        MaterialPageRoute<void>(
          builder: (_) => SepayQrScreen(order: _order, repository: repository),
        ),
      );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Vượt một chu kỳ poll rồi chờ chuyển màn xong. Không dùng pumpAndSettle vì
/// đồng hồ đếm ngược của màn QR luôn chạy.
Future<void> _pollOnce(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  group('CheckoutAddress', () {
    test('round-trips the single address string the backend stores', () {
      final parsed = CheckoutAddress.fromJson({
        'id': 'address-1',
        'recipientName': 'Minh Anh',
        'recipientPhone': '0901234567',
        'addressLine': '15 Nguyễn Thiện Thuật, Phường 2, Quận 3, TP. HCM',
        'latitude': 10.77,
        'longitude': 106,
      });

      expect(parsed.addressLine, '15 Nguyễn Thiện Thuật');
      expect(parsed.ward, 'Phường 2');
      expect(parsed.city, 'TP. HCM');
      expect(parsed.longitude, 106.0);
      expect(parsed.toJson()['addressLine'], parsed.fullAddress);
    });

    test('keeps a free-form address intact', () {
      final parsed = CheckoutAddress.fromJson({
        'id': 'address-1',
        'recipientName': 'Minh Anh',
        'recipientPhone': '0901234567',
        'addressLine': 'Quận 3, TP.HCM',
      });

      expect(parsed.fullAddress, 'Quận 3, TP.HCM');
      expect(parsed.hasCoordinates, isFalse);
    });

    test('strips spaces from the phone number', () {
      expect(
        _address.copyWith(phone: '090 123 4567').normalizedPhone,
        '0901234567',
      );
    });
  });

  group('CheckoutController idempotency', () {
    var counter = 0;
    String nextKey() => 'key-${++counter}';

    test('reuses the key when a failed request is retried', () async {
      final repository = _FakeRepository()
        ..checkoutError = const CheckoutFailure.network();
      final controller = CheckoutController(
        repository: repository,
        idempotencyKeyFactory: nextKey,
      );

      await controller.submit(_request);
      await controller.submit(_request);

      expect(repository.keys, hasLength(2));
      expect(repository.keys.toSet(), hasLength(1));
    });

    test('uses a new key when the request changes', () async {
      final repository = _FakeRepository()
        ..checkoutError = const CheckoutFailure.network();
      final controller = CheckoutController(
        repository: repository,
        idempotencyKeyFactory: nextKey,
      );

      await controller.submit(_request);
      await controller.submit(
        const CheckoutRequest(
          receiverName: 'Người khác',
          phone: '0901234567',
          address: '15 Nguyễn Thiện Thuật',
          latitude: 10.77,
          longitude: 106.68,
          paymentMethod: PaymentMethod.sepay,
        ),
      );

      expect(repository.keys.toSet(), hasLength(2));
    });

    test('uses a new key after a successful order', () async {
      final repository = _FakeRepository();
      final controller = CheckoutController(
        repository: repository,
        idempotencyKeyFactory: nextKey,
      );

      await controller.submit(_request);
      await controller.submit(_request);

      expect(repository.keys.toSet(), hasLength(2));
    });
  });

  group('SepayQrScreen polling', () {
    testWidgets('shows the real amount and code, then succeeds on PAID', (
      tester,
    ) async {
      final repository = _FakeRepository(statuses: ['PENDING', 'PAID']);
      await _pumpQr(tester, repository);

      expect(find.textContaining('715.000'), findsWidgets);
      expect(find.text('PAY123'), findsOneWidget);

      await _pollOnce(tester);
      expect(find.byType(PaymentSuccessScreen), findsNothing);

      await _pollOnce(tester);
      expect(find.byType(PaymentSuccessScreen), findsOneWidget);
      expect(repository.statusCalls, 2);
    });

    testWidgets('EXPIRED leads to failure and offers no cancel button', (
      tester,
    ) async {
      final repository = _FakeRepository(statuses: ['EXPIRED']);
      await _pumpQr(tester, repository);

      await _pollOnce(tester);
      expect(find.byType(PaymentFailureScreen), findsOneWidget);
      expect(find.byKey(const Key('payment-cancel-order')), findsNothing);
      expect(
        find.text(
          'Mã thanh toán đã hết hạn. Đơn hàng đã tự hủy, hàng và voucher đã được trả lại.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('FAILED offers no cancel button', (tester) async {
      final repository = _FakeRepository(statuses: ['FAILED']);
      await _pumpQr(tester, repository);

      await _pollOnce(tester);

      expect(find.byType(PaymentFailureScreen), findsOneWidget);
      expect(find.byKey(const Key('payment-cancel-order')), findsNothing);
    });

    testWidgets('REVIEW stops polling and stays on the QR screen', (
      tester,
    ) async {
      final repository = _FakeRepository(statuses: ['REVIEW']);
      await _pumpQr(tester, repository);

      await _pollOnce(tester);
      expect(
        find.text('Thanh toán đang được cửa hàng kiểm tra'),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 9));
      expect(repository.statusCalls, 1);
    });

    testWidgets('leaving the screen stops polling', (tester) async {
      final repository = _FakeRepository();
      await _pumpQr(tester, repository);

      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.byType(SepayQrScreen), findsNothing);
      final calls = repository.statusCalls;

      await tester.pump(const Duration(seconds: 9));
      expect(repository.statusCalls, calls);
    });
  });
}
