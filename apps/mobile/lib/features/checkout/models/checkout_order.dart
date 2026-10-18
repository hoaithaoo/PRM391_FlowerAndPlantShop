class CheckoutOrder {
  const CheckoutOrder({
    required this.id,
    required this.orderCode,
    required this.status,
  });

  final String id;
  final String orderCode;
  final String status;

  factory CheckoutOrder.fromJson(Map<String, dynamic> json) {
    return CheckoutOrder(
      id: _requiredString(json, 'id'),
      orderCode: _requiredString(json, 'orderCode'),
      status: _requiredString(json, 'status'),
    );
  }
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw FormatException('Invalid or missing field: $key');
}
