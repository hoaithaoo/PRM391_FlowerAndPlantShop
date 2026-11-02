class Voucher {
  const Voucher({
    required this.code,
    this.type,
    this.scope = orderScope,
    this.value,
    this.maxDiscount,
    this.minOrderAmount = 0,
    this.endsAt,
    this.eligible = true,
    required this.discountAmount,
    this.ineligibleReason,
    this.missingAmount = 0,
  });

  static const orderScope = 'ORDER';
  static const shippingScope = 'SHIPPING';

  final String code;
  final String? type;

  /// [orderScope] giảm tiền hàng, [shippingScope] giảm phí ship.
  final String scope;
  final num? value;
  final num? maxDiscount;
  final num minOrderAmount;
  final DateTime? endsAt;
  final bool eligible;
  final num discountAmount;
  final String? ineligibleReason;
  final num missingAmount;

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      code: _requiredString(json, 'code'),
      type: json['type'] as String?,
      scope: json['scope'] as String? ?? orderScope,
      value: _optionalNumber(json, 'value'),
      maxDiscount: _optionalNumber(json, 'maxDiscount'),
      minOrderAmount: _optionalNumber(json, 'minOrderAmount') ?? 0,
      endsAt: json['endsAt'] != null
          ? DateTime.tryParse(json['endsAt'].toString())
          : null,
      eligible: json['eligible'] as bool? ?? true,
      discountAmount: _optionalNumber(json, 'discountAmount') ?? 0,
      ineligibleReason: json['ineligibleReason'] as String?,
      missingAmount: _optionalNumber(json, 'missingAmount') ?? 0,
    );
  }

  bool get isShipping => scope == shippingScope;

  /// Số tiền giảm xem trước trên phí [base]. Phí ship đổi theo địa chỉ nên app
  /// tự tính lại; số cuối cùng do server quyết định khi đặt hàng.
  num discountOn(num base) {
    final amount = value;
    if (amount == null) return discountAmount;
    num discount = type == 'PERCENT' ? (base * amount / 100).floor() : amount;
    final cap = maxDiscount;
    if (type == 'PERCENT' && cap != null && discount > cap) discount = cap;
    return discount > base ? base : discount;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'code': code,
      if (type != null) 'type': type,
      'scope': scope,
      if (value != null) 'value': value,
      if (maxDiscount != null) 'maxDiscount': maxDiscount,
      'minOrderAmount': minOrderAmount,
      if (endsAt != null) 'endsAt': endsAt!.toIso8601String(),
      'eligible': eligible,
      'discountAmount': discountAmount,
      if (ineligibleReason != null) 'ineligibleReason': ineligibleReason,
      'missingAmount': missingAmount,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Voucher &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw FormatException('Invalid or missing field: $key');
}

num? _optionalNumber(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}
