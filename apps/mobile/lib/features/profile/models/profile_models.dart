class UserProfile {
  const UserProfile({
    required this.id,
    this.email,
    this.fullName,
    this.phone,
    this.avatarUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    email: json['email'] as String?,
    fullName: json['fullName'] as String?,
    phone: json['phone'] as String?,
    avatarUrl: json['avatarUrl'] as String?,
  );

  final String id;
  final String? email;
  final String? fullName;
  final String? phone;
  final String? avatarUrl;
}

/// Một dòng trong danh sách đơn của tôi.
class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.orderCode,
    required this.status,
    required this.paymentStatus,
    required this.grandTotal,
    required this.createdAt,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) => OrderSummary(
    id: json['id'] as String,
    orderCode: json['orderCode'] as String,
    status: json['status'] as String,
    paymentStatus: json['paymentStatus'] as String,
    grandTotal: json['grandTotal'] as num,
    createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
  );

  final String id;
  final String orderCode;
  final String status;
  final String paymentStatus;
  final num grandTotal;
  final DateTime createdAt;

  /// Khớp điều kiện của PATCH /orders/:id/cancel.
  bool get canCancel =>
      (status == 'PENDING' || status == 'CONFIRMED') && paymentStatus != 'PAID';

  String get statusLabel => switch (status) {
    'PENDING' => 'Chờ xác nhận',
    'CONFIRMED' => 'Đã xác nhận',
    'PREPARING' => 'Đang chuẩn bị',
    'SHIPPING' => 'Đang giao',
    'COMPLETED' => 'Hoàn thành',
    'CANCELLED' => 'Đã hủy',
    _ => status,
  };
}

class OrderLine {
  const OrderLine({
    required this.name,
    required this.quantity,
    required this.subtotal,
    this.imageUrl,
  });

  factory OrderLine.fromJson(Map<String, dynamic> json) => OrderLine(
    name: json['productName'] as String,
    quantity: json['quantity'] as int,
    subtotal: json['subtotal'] as num,
    imageUrl: json['imageUrl'] as String?,
  );

  final String name;
  final int quantity;
  final num subtotal;
  final String? imageUrl;
}

class OrderDetail extends OrderSummary {
  const OrderDetail({
    required super.id,
    required super.orderCode,
    required super.status,
    required super.paymentStatus,
    required super.grandTotal,
    required super.createdAt,
    required this.receiverName,
    required this.phone,
    required this.address,
    required this.items,
    this.pickupStoreName,
    this.pickupAt,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    final summary = OrderSummary.fromJson(json);
    final pickupStore = json['pickupStore'] as Map<String, dynamic>?;
    final pickupAt = json['pickupAt'] as String?;
    return OrderDetail(
      id: summary.id,
      orderCode: summary.orderCode,
      status: summary.status,
      paymentStatus: summary.paymentStatus,
      grandTotal: summary.grandTotal,
      createdAt: summary.createdAt,
      receiverName: json['receiverName'] as String,
      phone: json['phone'] as String,
      address: json['address'] as String,
      items: (json['items'] as List<dynamic>)
          .map((item) => OrderLine.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      pickupStoreName: pickupStore?['name'] as String?,
      pickupAt: pickupAt == null ? null : DateTime.parse(pickupAt).toLocal(),
    );
  }

  final String receiverName;
  final String phone;
  final String address;
  final List<OrderLine> items;
  final String? pickupStoreName;
  final DateTime? pickupAt;
}

class OrderPage {
  const OrderPage({required this.items, required this.hasMore});

  final List<OrderSummary> items;
  final bool hasMore;
}
