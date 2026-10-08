class SepayTransactionModel {
  final String id;
  final String referenceCode;
  final String bankName;
  final String accountNumber;
  final double amountIn;
  final String content;
  final DateTime transactionDate;
  final bool isMatched;
  final String? matchedOrderCode;
  final String? matchedOrderId;

  const SepayTransactionModel({
    required this.id,
    required this.referenceCode,
    required this.bankName,
    required this.accountNumber,
    required this.amountIn,
    required this.content,
    required this.transactionDate,
    required this.isMatched,
    this.matchedOrderCode,
    this.matchedOrderId,
  });

  SepayTransactionModel copyWith({
    String? id,
    String? referenceCode,
    String? bankName,
    String? accountNumber,
    double? amountIn,
    String? content,
    DateTime? transactionDate,
    bool? isMatched,
    String? matchedOrderCode,
    String? matchedOrderId,
  }) {
    return SepayTransactionModel(
      id: id ?? this.id,
      referenceCode: referenceCode ?? this.referenceCode,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      amountIn: amountIn ?? this.amountIn,
      content: content ?? this.content,
      transactionDate: transactionDate ?? this.transactionDate,
      isMatched: isMatched ?? this.isMatched,
      matchedOrderCode: matchedOrderCode ?? this.matchedOrderCode,
      matchedOrderId: matchedOrderId ?? this.matchedOrderId,
    );
  }

  factory SepayTransactionModel.fromJson(Map<String, dynamic> json) {
    return SepayTransactionModel(
      id: json['id'] as String? ?? '',
      referenceCode: json['referenceCode'] as String? ?? '',
      bankName: json['bankName'] as String? ?? '',
      accountNumber: json['accountNumber'] as String? ?? '',
      amountIn: (json['amountIn'] as num?)?.toDouble() ?? 0.0,
      content: json['content'] as String? ?? '',
      transactionDate: json['transactionDate'] != null
          ? DateTime.tryParse(json['transactionDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      isMatched: json['isMatched'] as bool? ?? false,
      matchedOrderCode: json['matchedOrderCode'] as String?,
      matchedOrderId: json['matchedOrderId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'referenceCode': referenceCode,
    'bankName': bankName,
    'accountNumber': accountNumber,
    'amountIn': amountIn,
    'content': content,
    'transactionDate': transactionDate.toIso8601String(),
    'isMatched': isMatched,
    'matchedOrderCode': matchedOrderCode,
    'matchedOrderId': matchedOrderId,
  };
}
