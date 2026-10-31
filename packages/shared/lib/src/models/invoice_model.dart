import '../enums/app_enums.dart';

class InvoiceItemModel {
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const InvoiceItemModel({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory InvoiceItemModel.fromJson(Map<String, dynamic> json) {
    return InvoiceItemModel(
      productName: json['productName'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'productName': productName,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'totalPrice': totalPrice,
  };
}

class InvoiceModel {
  final String id;
  final String invoiceNumber;
  final String orderId;
  final String orderCode;
  final String customerName;
  final String? customerEmail;
  final double subtotal;
  final double taxRate;
  final double taxAmount;
  final double totalAmount;
  final InvoiceStatus status;
  final DateTime issuedAt;
  final List<InvoiceItemModel> items;

  const InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.orderId,
    required this.orderCode,
    required this.customerName,
    this.customerEmail,
    required this.subtotal,
    required this.taxRate,
    required this.taxAmount,
    required this.totalAmount,
    required this.status,
    required this.issuedAt,
    this.items = const [],
  });

  InvoiceModel copyWith({
    String? id,
    String? invoiceNumber,
    String? orderId,
    String? orderCode,
    String? customerName,
    String? customerEmail,
    double? subtotal,
    double? taxRate,
    double? taxAmount,
    double? totalAmount,
    InvoiceStatus? status,
    DateTime? issuedAt,
    List<InvoiceItemModel>? items,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      orderId: orderId ?? this.orderId,
      orderCode: orderCode ?? this.orderCode,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      subtotal: subtotal ?? this.subtotal,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      issuedAt: issuedAt ?? this.issuedAt,
      items: items ?? this.items,
    );
  }

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] as String? ?? '',
      invoiceNumber: json['invoiceNumber'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      orderCode: json['orderCode'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
      customerEmail: json['customerEmail'] as String?,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxRate: (json['taxRate'] as num?)?.toDouble() ?? 0.08,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: InvoiceStatus.fromString(json['status'] as String?),
      issuedAt: json['issuedAt'] != null
          ? DateTime.tryParse(json['issuedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => InvoiceItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'invoiceNumber': invoiceNumber,
    'orderId': orderId,
    'orderCode': orderCode,
    'customerName': customerName,
    'customerEmail': customerEmail,
    'subtotal': subtotal,
    'taxRate': taxRate,
    'taxAmount': taxAmount,
    'totalAmount': totalAmount,
    'status': status.toApiString(),
    'issuedAt': issuedAt.toIso8601String(),
    'items': items.map((e) => e.toJson()).toList(),
  };
}
