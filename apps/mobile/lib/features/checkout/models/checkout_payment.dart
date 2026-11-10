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

enum CheckoutPaymentStatus { pending, paid, failed, expired, review }

/// Dữ liệu đầy đủ từ endpoint trạng thái thanh toán. Luồng giao diện hiện chỉ
/// cần `status`, nhưng model này giữ nguyên hợp đồng để các nơi khác có thể dùng
/// mã giao dịch, số tiền và thời điểm thanh toán mà không cần API client thứ hai.
class CheckoutPaymentStatusResult {
  const CheckoutPaymentStatusResult({
    required this.id,
    required this.invoiceId,
    required this.amount,
    required this.status,
    this.paymentCode,
    this.paidAt,
  });

  final String id;
  final String invoiceId;
  final num amount;
  final CheckoutPaymentStatus status;
  final String? paymentCode;
  final DateTime? paidAt;

  factory CheckoutPaymentStatusResult.fromJson(Map<String, dynamic> json) {
    final status = switch (_requiredString(json, 'status').toUpperCase()) {
      'PENDING' => CheckoutPaymentStatus.pending,
      'PAID' => CheckoutPaymentStatus.paid,
      'FAILED' => CheckoutPaymentStatus.failed,
      'EXPIRED' => CheckoutPaymentStatus.expired,
      'REVIEW' => CheckoutPaymentStatus.review,
      _ => throw const FormatException('Payment status invalid'),
    };
    return CheckoutPaymentStatusResult(
      id: _requiredString(json, 'id'),
      invoiceId: _requiredString(json, 'invoiceId'),
      amount: _requiredNumber(json, 'amount'),
      status: status,
      paymentCode: _optionalString(json['paymentCode']),
      paidAt: DateTime.tryParse(json['paidAt']?.toString() ?? ''),
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

num _requiredNumber(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is num) return value;
  if (value is String) {
    final parsed = num.tryParse(value);
    if (parsed != null) return parsed;
  }
  throw FormatException('Invalid or missing field: $key');
}
