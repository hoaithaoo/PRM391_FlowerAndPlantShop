enum UserRole {
  user,
  admin;

  static UserRole fromString(String? value) {
    if (value?.toUpperCase() == 'ADMIN') return UserRole.admin;
    return UserRole.user;
  }

  String toApiString() => name.toUpperCase();
}

enum AccountStatus {
  active,
  disabled;

  static AccountStatus fromString(String? value) {
    if (value?.toUpperCase() == 'DISABLED') return AccountStatus.disabled;
    return AccountStatus.active;
  }

  String toApiString() => name.toUpperCase();
}

enum OrderStatus {
  pending('Chờ duyệt'),
  confirmed('Đã xác nhận'),
  processing('Đang chuẩn bị'),
  shipping('Đang giao'),
  delivered('Đã giao'),
  cancelled('Đã hủy');

  final String label;
  const OrderStatus(this.label);

  static OrderStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'CONFIRMED':
        return OrderStatus.confirmed;
      case 'PROCESSING':
        return OrderStatus.processing;
      case 'SHIPPING':
        return OrderStatus.shipping;
      case 'DELIVERED':
        return OrderStatus.delivered;
      case 'CANCELLED':
        return OrderStatus.cancelled;
      case 'PENDING':
      default:
        return OrderStatus.pending;
    }
  }

  String toApiString() => name.toUpperCase();
}

enum PaymentStatus {
  pending('Chờ thanh toán'),
  paid('Đã thanh toán'),
  failed('Thất bại'),
  refunded('Đã hoàn tiền');

  final String label;
  const PaymentStatus(this.label);

  static PaymentStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'PAID':
        return PaymentStatus.paid;
      case 'FAILED':
        return PaymentStatus.failed;
      case 'REFUNDED':
        return PaymentStatus.refunded;
      case 'PENDING':
      default:
        return PaymentStatus.pending;
    }
  }

  String toApiString() => name.toUpperCase();
}

enum InvoiceStatus {
  issued('Đã xuất'),
  paid('Đã thanh toán'),
  cancelled('Đã hủy');

  final String label;
  const InvoiceStatus(this.label);

  static InvoiceStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'PAID':
        return InvoiceStatus.paid;
      case 'CANCELLED':
        return InvoiceStatus.cancelled;
      case 'ISSUED':
      default:
        return InvoiceStatus.issued;
    }
  }

  String toApiString() => name.toUpperCase();
}

enum PaymentProvider {
  sepay('SePay (QR Chuyển Khoản)'),
  cod('Tiền mặt (COD)');

  final String label;
  const PaymentProvider(this.label);

  static PaymentProvider fromString(String? value) {
    if (value?.toUpperCase() == 'COD') return PaymentProvider.cod;
    return PaymentProvider.sepay;
  }

  String toApiString() => name.toUpperCase();
}
