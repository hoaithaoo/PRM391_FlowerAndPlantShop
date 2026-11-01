import '../models/checkout_flow_models.dart';
import '../models/checkout_invoice.dart';
import '../models/checkout_order.dart';
import '../models/checkout_payment.dart';
import '../models/checkout_request.dart';
import '../models/checkout_result.dart';
import '../models/checkout_summary.dart';
import '../models/payment_method.dart';
import '../models/voucher.dart';
import 'checkout_failure.dart';
import 'checkout_mock_data.dart';
import 'checkout_repository.dart';

class MockCheckoutRepository implements CheckoutRepository {
  const MockCheckoutRepository({
    this.summary = CheckoutMockData.summary,
    this.delay = const Duration(milliseconds: 700),
  });

  final CheckoutSummary summary;
  final Duration delay;

  @override
  Future<List<CheckoutAddress>> listAddresses() async =>
      CheckoutMockData.addresses;

  @override
  Future<CheckoutAddress> saveAddress(CheckoutAddress address) async => address;

  @override
  Future<num> estimateShippingFee({
    required double latitude,
    required double longitude,
  }) async => summary.shippingFee;

  @override
  Future<List<PickupBranch>> listStores({
    double? latitude,
    double? longitude,
  }) async => CheckoutMockData.branches;

  @override
  Future<String> getPaymentStatus(String paymentId) async => 'PENDING';

  @override
  Future<void> cancelOrder(String orderId, {String? reason}) async {}

  @override
  Future<List<Voucher>> availableVouchers({
    num? subtotal,
    num? shippingFee,
  }) async => <Voucher>[
        Voucher(
          code: 'FREESHIP15K',
          type: 'FIXED',
          scope: Voucher.shippingScope,
          value: 15000,
          minOrderAmount: 200000,
          endsAt: DateTime.now().add(const Duration(days: 90)),
          eligible: true,
          discountAmount: 15000,
        ),
        Voucher(
          code: 'HOA50K',
          type: 'FIXED',
          value: 50000,
          minOrderAmount: 300000,
          endsAt: DateTime.now().add(const Duration(days: 90)),
          eligible: true,
          discountAmount: 50000,
        ),
        Voucher(
          code: 'HOA20',
          type: 'PERCENT',
          value: 20,
          maxDiscount: 100000,
          minOrderAmount: 200000,
          endsAt: DateTime.now().add(const Duration(days: 90)),
          eligible: true,
          discountAmount: 40000,
        ),
      ];

  @override
  Future<Voucher> validateVoucher(
    String code, {
    num? subtotal,
    num? shippingFee,
  }) async {
    final normalized = code.trim().toUpperCase();
    if (normalized == 'HOA50K') {
      return const Voucher(
        code: 'HOA50K',
        type: 'FIXED',
        value: 50000,
        minOrderAmount: 300000,
        eligible: true,
        discountAmount: 50000,
      );
    }
    if (normalized == 'HOA20') {
      return const Voucher(
        code: 'HOA20',
        type: 'PERCENT',
        value: 20,
        maxDiscount: 100000,
        minOrderAmount: 200000,
        eligible: true,
        discountAmount: 40000,
      );
    }
    if (normalized == 'HOAVIP') {
      return const Voucher(
        code: 'HOAVIP',
        type: 'FIXED',
        value: 100000,
        minOrderAmount: 500000,
        eligible: true,
        discountAmount: 100000,
      );
    }
    throw const CheckoutFailure(code: CheckoutErrorCode.voucherNotFound);
  }

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
        discountAmount: summary.discount,
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
