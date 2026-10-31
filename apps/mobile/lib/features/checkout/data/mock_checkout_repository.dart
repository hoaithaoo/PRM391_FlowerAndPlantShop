import '../models/checkout_invoice.dart';
import '../models/checkout_order.dart';
import '../models/checkout_payment.dart';
import '../models/checkout_request.dart';
import '../models/checkout_result.dart';
import '../models/checkout_summary.dart';
import '../models/payment_method.dart';
import 'checkout_repository.dart';

class MockCheckoutRepository implements CheckoutRepository {
  const MockCheckoutRepository({
    required this.summary,
    this.delay = const Duration(milliseconds: 700),
  });

  final CheckoutSummary summary;
  final Duration delay;

  @override
  Future<CheckoutResult> checkout(
    CheckoutRequest request, {
    required String idempotencyKey,
  }) async {
    // TODO: Thay mock bằng CheckoutRepositoryImpl khi backend checkout sẵn sàng
    await Future<void>.delayed(delay);

    final suffix = idempotencyKey.length > 8
        ? idempotencyKey.substring(idempotencyKey.length - 8).toUpperCase()
        : idempotencyKey.toUpperCase();

    return CheckoutResult(
      order: CheckoutOrder(
        id: 'mock-order-$suffix',
        orderCode: 'PFS-$suffix',
        status: 'PENDING',
      ),
      invoice: CheckoutInvoice(
        id: 'mock-invoice-$suffix',
        invoiceNumber: 'INV-$suffix',
        subtotalAmount: summary.subtotal,
        taxAmount: summary.tax,
        shippingFee: summary.shippingFee,
        grandTotal: summary.grandTotal,
      ),
      payment: request.paymentMethod == PaymentMethod.sepay
          ? CheckoutPayment(
              id: 'mock-payment-$suffix',
              paymentCode: 'PFS$suffix',
              qrUrl: null,
              status: 'PENDING',
            )
          : null,
    );
  }
}
