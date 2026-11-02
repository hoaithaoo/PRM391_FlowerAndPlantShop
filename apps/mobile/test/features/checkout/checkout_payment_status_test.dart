import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/checkout/data/checkout_api.dart';

void main() {
  test('parse đúng trạng thái thanh toán và dữ liệu backend', () {
    final result = CheckoutPaymentStatusResult.fromJson({
      'id': 'payment-uuid',
      'invoiceId': 'invoice-uuid',
      'paymentCode': 'DH-001',
      'amount': '125000',
      'status': 'PAID',
      'paidAt': '2026-11-02T08:30:00.000Z',
    });

    expect(result.id, 'payment-uuid');
    expect(result.amount, 125000);
    expect(result.status, CheckoutPaymentStatus.paid);
    expect(result.paymentCode, 'DH-001');
    expect(result.paidAt, DateTime.utc(2026, 11, 2, 8, 30));
  });

  test('hỗ trợ trạng thái REVIEW mà không coi là thất bại', () {
    final result = CheckoutPaymentStatusResult.fromJson({
      'id': 'payment-uuid',
      'invoiceId': 'invoice-uuid',
      'amount': 125000,
      'status': 'REVIEW',
      'paidAt': null,
    });

    expect(result.status, CheckoutPaymentStatus.review);
  });
}
