class CheckoutInvoice {
  const CheckoutInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.subtotalAmount,
    this.discountAmount = 0,
    required this.taxAmount,
    required this.shippingFee,
    required this.grandTotal,
  });

  final String id;
  final String invoiceNumber;
  final num subtotalAmount;
  final num discountAmount;
  final num taxAmount;
  final num shippingFee;
  final num grandTotal;

  factory CheckoutInvoice.fromJson(Map<String, dynamic> json) {
    return CheckoutInvoice(
      id: _requiredString(json, 'id'),
      invoiceNumber: _requiredString(json, 'invoiceNumber'),
      subtotalAmount: _requiredNumber(json, 'subtotalAmount'),
      discountAmount: _optionalNumber(json, 'discountAmount') ?? 0,
      taxAmount: _requiredNumber(json, 'taxAmount'),
      shippingFee: _requiredNumber(json, 'shippingFee'),
      grandTotal: _requiredNumber(json, 'grandTotal'),
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

num _requiredNumber(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is num) {
    return value;
  }
  if (value is String) {
    final parsedValue = num.tryParse(value);
    if (parsedValue != null) {
      return parsedValue;
    }
  }
  throw FormatException('Invalid or missing field: $key');
}

num? _optionalNumber(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is num) {
    return value;
  }
  if (value is String) {
    return num.tryParse(value);
  }
  return null;
}
