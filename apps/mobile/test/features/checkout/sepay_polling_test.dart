import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_api_client/plant_flower_api_client.dart';
import 'package:plant_flower_mobile/features/checkout/data/checkout_api.dart';
import 'package:plant_flower_mobile/features/checkout/models/checkout_flow_models.dart';
import 'package:plant_flower_mobile/features/checkout/models/checkout_invoice.dart';
import 'package:plant_flower_mobile/features/checkout/models/checkout_order.dart';
import 'package:plant_flower_mobile/features/checkout/models/checkout_payment.dart';
import 'package:plant_flower_mobile/features/checkout/models/checkout_result.dart';
import 'package:plant_flower_mobile/features/checkout/models/checkout_summary.dart';
import 'package:plant_flower_mobile/features/checkout/screens/sepay_qr_screen.dart';
import 'package:plant_flower_mobile/features/checkout/state/checkout_flow_controller.dart';

void main() {
  testWidgets('polling không chạy chồng và dừng khi rời màn hình', (
    tester,
  ) async {
    final api = _PendingPaymentApi();
    final controller = CheckoutFlowController(
      addresses: const [
        CheckoutAddress(
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
        ),
      ],
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: SepayQrScreen(
          controller: controller,
          summary: _summary,
          result: _result,
          api: api,
          pollInterval: const Duration(milliseconds: 10),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    expect(api.calls, greaterThan(0));
    expect(api.maxConcurrent, 1);

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump(const Duration(milliseconds: 100));
    final callsAfterDispose = api.calls;
    await tester.pump(const Duration(milliseconds: 100));
    expect(api.calls, callsAfterDispose);
  });
}

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

class _PendingPaymentApi extends CheckoutApi {
  _PendingPaymentApi()
    : super(
        ApiClient(baseUrl: 'https://api.example.com'),
        accessTokenProvider: () async => 'token',
      );

  int calls = 0;
  int concurrent = 0;
  int maxConcurrent = 0;

  @override
  Future<CheckoutPaymentStatusResult> getPaymentStatus(String paymentId) async {
    calls++;
    concurrent++;
    if (concurrent > maxConcurrent) maxConcurrent = concurrent;
    await Future<void>.delayed(const Duration(milliseconds: 30));
    concurrent--;
    return const CheckoutPaymentStatusResult(
      id: 'payment-id',
      invoiceId: 'invoice-id',
      amount: 120000,
      status: CheckoutPaymentStatus.pending,
      paymentCode: 'PAY001',
    );
  }
}
