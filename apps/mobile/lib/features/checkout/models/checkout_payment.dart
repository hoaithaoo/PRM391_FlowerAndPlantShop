class CheckoutPayment {
  const CheckoutPayment({
    required this.id,
    required this.status,
    this.paymentCode,
    this.qrUrl,
  });

  final String id;
  final String? paymentCode;
  final String? qrUrl;
  final String status;

  factory CheckoutPayment.fromJson(Map<String, dynamic> json) {
    return CheckoutPayment(
      id: _requiredString(json, 'id'),
      paymentCode: _optionalString(json['paymentCode']),
      qrUrl: _optionalString(json['qrUrl']),
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

String? _optionalString(Object? value) {
  return value is String && value.isNotEmpty ? value : null;
}
