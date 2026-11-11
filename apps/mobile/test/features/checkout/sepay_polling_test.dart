import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/checkout/data/mock_checkout_repository.dart';
import 'package:plant_flower_mobile/features/checkout/models/checkout_flow_models.dart';
import 'package:plant_flower_mobile/features/checkout/models/checkout_invoice.dart';
import 'package:plant_flower_mobile/features/checkout/models/checkout_order.dart';
import 'package:plant_flower_mobile/features/checkout/models/checkout_payment.dart';
import 'package:plant_flower_mobile/features/checkout/models/checkout_result.dart';
import 'package:plant_flower_mobile/features/checkout/models/checkout_summary.dart';
import 'package:plant_flower_mobile/features/checkout/models/placed_order.dart';
import 'package:plant_flower_mobile/features/checkout/screens/sepay_qr_screen.dart';

void main() {
  testWidgets('polling không chạy chồng và dừng khi rời màn hình', (
    tester,
  ) async {
    final repository = _PendingPaymentRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: SepayQrScreen(
          order: _placedOrder,
          repository: repository,
          pollInterval: const Duration(milliseconds: 10),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    expect(repository.calls, greaterThan(0));
    expect(repository.maxConcurrent, 1);

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump(const Duration(milliseconds: 100));
    final callsAfterDispose = repository.calls;
    await tester.pump(const Duration(milliseconds: 100));
    expect(repository.calls, callsAfterDispose);
  });

  testWidgets(
    'bấm "Tôi đã chuyển khoản" lúc poll đang chạy thì dùng kết quả PAID của lần đó',
    (tester) async {
      final repository = _SlowPaidRepository();
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: SepayQrScreen(
            order: _placedOrder,
            repository: repository,
            pollInterval: const Duration(milliseconds: 10),
          ),
        ),
      );
      // Lần poll đầu đang chờ server (300ms) thì người dùng bấm xác nhận.
      await tester.pump(const Duration(milliseconds: 20));
      await tester.ensureVisible(find.byKey(const Key('sepay-confirm-transfer')));
      await tester.tap(find.byKey(const Key('sepay-confirm-transfer')));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(repository.calls, 1);
      expect(find.text('Thanh toán hoàn tất'), findsOneWidget);
      expect(
        find.text('Chưa nhận được giao dịch. Vui lòng chờ thêm ít phút.'),
        findsNothing,
      );
    },
  );
}

class _SlowPaidRepository extends MockCheckoutRepository {
  int calls = 0;

  @override
  Future<String> getPaymentStatus(String paymentId) async {
    calls++;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return 'PAID';
  }
}

const _address = CheckoutAddress(
  id: 'address-id',
  label: 'Nhà riêng',
  recipientName: 'Nguyễn An',
  phone: '0901234567',
  addressLine: '1 Nguyễn Huệ',
  ward: 'Bến Nghé',
  district: 'Quận 1',
  city: 'TP. Hồ Chí Minh',
  driverNote: '',
  isDefault: true,
  latitude: 10.77,
  longitude: 106.70,
);

const _summary = CheckoutSummary(
  items: [
    CheckoutSummaryItem(
      productId: 'product-id',
      name: 'Bó hoa',
      quantity: 1,
      unitPrice: 100000,
      subtotal: 100000,
    ),
  ],
  subtotal: 100000,
  tax: 0,
  shippingFee: 20000,
  grandTotal: 120000,
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
  payment: CheckoutPayment(
    id: 'payment-id',
    status: 'PENDING',
    paymentCode: 'PAY001',
  ),
);

const _placedOrder = PlacedOrder(
  result: _result,
  summary: _summary,
  address: _address,
);

class _PendingPaymentRepository extends MockCheckoutRepository {
  int calls = 0;
  int concurrent = 0;
  int maxConcurrent = 0;

  @override
  Future<String> getPaymentStatus(String paymentId) async {
    calls++;
    concurrent++;
    if (concurrent > maxConcurrent) maxConcurrent = concurrent;
    await Future<void>.delayed(const Duration(milliseconds: 30));
    concurrent--;
    return 'PENDING';
  }
}
