import 'checkout_invoice.dart';
import 'checkout_order.dart';
import 'checkout_payment.dart';

class CheckoutResult {
  const CheckoutResult({
    required this.order,
    required this.invoice,
    this.payment,
  });

  final CheckoutOrder order;
  final CheckoutInvoice invoice;
  final CheckoutPayment? payment;

  factory CheckoutResult.fromJson(Map<String, dynamic> json) {
    final orderJson = _requiredMap(json, 'order');
    final invoiceJson = _requiredMap(json, 'invoice');
    final paymentValue = json['payment'];

    return CheckoutResult(
      order: CheckoutOrder.fromJson(orderJson),
      invoice: CheckoutInvoice.fromJson(invoiceJson),
      payment: paymentValue is Map
          ? CheckoutPayment.fromJson(Map<String, dynamic>.from(paymentValue))
          : null,
    );
  }
}

Map<String, dynamic> _requiredMap(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  throw FormatException('Invalid or missing field: $key');
}
