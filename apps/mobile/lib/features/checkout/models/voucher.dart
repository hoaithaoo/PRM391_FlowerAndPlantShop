class Voucher {
  const Voucher({
    required this.code,
    this.type,
    this.value,
    this.maxDiscount,
    this.minOrderAmount = 0,
    this.endsAt,
    this.eligible = true,
    required this.discountAmount,
    this.ineligibleReason,
    this.missingAmount = 0,
  });

  final String code;
  final String? type;
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

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'code': code,
      if (type != null) 'type': type,
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
